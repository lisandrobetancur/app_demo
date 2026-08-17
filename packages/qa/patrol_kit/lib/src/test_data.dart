import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'log.dart';

/// Test data, read from JSON files at run time.
///
/// The data a suite runs with belongs outside the code that runs it: a price,
/// a coupon, an account is something QA edits, and editing it should not mean
/// touching Dart. A parent file lists the others, so adding a data set is one
/// line in one place and the loader never has to be told what exists.
///
/// ```json
/// // patrol_test/data/index.json
/// {
///   "version": 1,
///   "datasets": {
///     "users":    "users.json",
///     "products": "products.json",
///     "coupons":  "coupons.json"
///   }
/// }
/// ```
///
/// ## Why assets and not `File`
///
/// A Patrol test is compiled **into** the application binary and runs where
/// the app runs — inside a browser tab on web, on the device on Android and
/// iOS. There is no `dart:io` on web and no repository checkout on a phone,
/// so reading the file from disk works on exactly one of the three platforms.
/// Flutter assets are the one channel that resolves the same way on all of
/// them, which is why the default [TestDataSource] goes through `rootBundle`.
///
/// The cost is that assets declared by the app under test are bundled into
/// *every* build of it, release included. In this repository that is fine. In
/// an app that ships, it means test fixtures — possibly with credentials —
/// travelling in the production binary, which is why the source is an
/// interface: point it at [InMemoryTestDataSource] and the same API reads
/// data that was compiled in from a generator instead, with nothing added to
/// the app's asset manifest.

/// A failure to *read* the data, as opposed to a failure of the product.
///
/// An [Error] and not a `TestFailure` on purpose: a missing file or an absent
/// field means the test could not check what it came to check, so the report
/// marks the step **broken** rather than failed. The distinction is the same
/// one a WebDriver suite draws between an assertion failure and a
/// `NoSuchElementException`.
class TestDataError extends Error {
  TestDataError(this.message);

  final String message;

  @override
  String toString() => 'TestDataError: $message';
}

/// Where the JSON comes from.
///
/// The seam that keeps the loader independent of how the bytes arrive.
abstract class TestDataSource {
  /// Reads the file at [path], relative to whatever root the source uses.
  Future<String> read(String path);

  /// Named in errors, so a missing file says where it was looked for.
  String describe(String path);
}

/// Reads the files out of the Flutter asset bundle.
///
/// The paths in the index are resolved against [basePath], and [basePath] is
/// what the app declares under `flutter: assets:` in its pubspec.
class AssetTestDataSource implements TestDataSource {
  const AssetTestDataSource({this.basePath = 'patrol_test/data'});

  final String basePath;

  @override
  Future<String> read(String path) async {
    try {
      return await rootBundle.loadString(describe(path));
    } on Object catch (error) {
      throw TestDataError(
        'No se pudo leer el asset ${describe(path)}: $error\n'
        'Revisa que la carpeta esté declarada en el pubspec de la app:\n'
        '  flutter:\n'
        '    assets:\n'
        '      - $basePath/',
      );
    }
  }

  @override
  String describe(String path) => '$basePath/$path';
}

/// Reads the files out of a map held in memory.
///
/// For unit tests of the kit, and for a project that would rather generate
/// its data into Dart than ship it as an asset — see the note at the top of
/// this file.
class InMemoryTestDataSource implements TestDataSource {
  const InMemoryTestDataSource(this.files);

  /// Keyed by the same paths the index uses.
  final Map<String, String> files;

  @override
  Future<String> read(String path) async {
    final String? content = files[path];
    if (content == null) {
      throw TestDataError(
        'No hay datos en memoria para "$path". '
        'Disponibles: ${files.keys.join(', ')}',
      );
    }
    return content;
  }

  @override
  String describe(String path) => 'memoria:$path';
}

/// The loaded data sets, keyed by the names the index gives them.
///
/// Loaded once per run — from the launcher, before the first test touches the
/// screen — and read synchronously from then on, so a page object or a test
/// body can reach a value without an `await` in the middle of a sentence.
class TestDataStore {
  const TestDataStore._();

  static final Map<String, DataSet> _sets = <String, DataSet>{};
  static bool _loaded = false;

  /// Whether [load] has run.
  static bool get isLoaded => _loaded;

  /// Reads the index and every file it lists.
  ///
  /// Call it once, from the launcher:
  ///
  /// ```dart
  /// await TestDataStore.load();
  /// ```
  ///
  /// Loading every data set up front rather than on first use is deliberate:
  /// a malformed JSON file then fails the run at the launcher, with the file
  /// name in the message, instead of half way through a step where it reads
  /// as a product failure.
  static Future<void> load({
    TestDataSource source = const AssetTestDataSource(),
    String index = 'index.json',
  }) async {
    _sets.clear();

    final Map<String, Object?> parsed = _decodeObject(
      await source.read(index),
      source.describe(index),
    );

    final Object? datasets = parsed['datasets'];
    if (datasets is! Map<String, Object?>) {
      throw TestDataError(
        '${source.describe(index)} debe tener un objeto "datasets" que liste '
        'los archivos, por ejemplo {"datasets": {"users": "users.json"}}.',
      );
    }
    if (datasets.isEmpty) {
      throw TestDataError(
        '${source.describe(index)} no lista ningún archivo. Un índice vacío '
        'deja la suite sin datos y sin decirlo.',
      );
    }

    for (final MapEntry<String, Object?> entry in datasets.entries) {
      final Object? path = entry.value;
      if (path is! String) {
        throw TestDataError(
          'El data set "${entry.key}" en ${source.describe(index)} debe '
          'apuntar a un nombre de archivo, no a ${path.runtimeType}.',
        );
      }
      _sets[entry.key] = DataSet._parse(
        name: entry.key,
        raw: await source.read(path),
        origin: source.describe(path),
      );
    }

    _loaded = true;
    Log.debug(
      'Datos de prueba cargados',
      data: <String, Object>{
        'index': source.describe(index),
        'datasets': _sets.keys.toList(),
      },
    );
  }

  /// The data set the index registered under [name].
  static DataSet dataset(String name) {
    if (!_loaded) {
      throw TestDataError(
        'Los datos de prueba no se han cargado. Llama a '
        'TestDataStore.load() en el launcher, antes del primer test.',
      );
    }
    final DataSet? set = _sets[name];
    if (set == null) {
      throw TestDataError(
        'No existe el data set "$name". El índice registró: '
        '${_sets.keys.join(', ')}',
      );
    }
    return set;
  }

  /// Forgets everything loaded. For tests of the kit.
  static void reset() {
    _sets.clear();
    _loaded = false;
  }
}

/// One JSON file's worth of data.
///
/// Two shapes are accepted, because the two are what data actually looks
/// like:
///
///  * An **object**, whose keys name the records — `{"demo": {…}}`. Read one
///    by name with [record]; a test that says `users.record('demo')` still
///    reads when someone adds a third user.
///  * An **array** of objects — `[{…}, {…}]`. Read them in order with [rows],
///    which is the shape a data-driven test loops over.
///
/// An object also exposes [rows], in declaration order, so a data set can be
/// named *and* iterated.
class DataSet {
  const DataSet._({
    required this.name,
    required this.origin,
    required Map<String, DataRecord> keyed,
    required List<DataRecord> rows,
  }) : _keyed = keyed,
       _rows = rows;

  /// The name the index gave this set.
  final String name;

  /// Where it was read from, for error messages.
  final String origin;

  final Map<String, DataRecord> _keyed;
  final List<DataRecord> _rows;

  /// Every record, in the order the file declares them.
  List<DataRecord> get rows => List<DataRecord>.unmodifiable(_rows);

  /// The names of the keyed records, empty for an array file.
  List<String> get keys => _keyed.keys.toList(growable: false);

  /// How many records the file holds.
  int get length => _rows.length;

  /// The record filed under [key].
  DataRecord record(String key) {
    final DataRecord? found = _keyed[key];
    if (found == null) {
      throw TestDataError(
        _keyed.isEmpty
            ? '$origin es una lista, no tiene registros con nombre. Usa '
                  '.rows para recorrerla.'
            : 'No existe el registro "$key" en $origin. Hay: '
                  '${_keyed.keys.join(', ')}',
      );
    }
    return found;
  }

  /// The record at [index] of an array file.
  DataRecord row(int index) {
    if (index < 0 || index >= _rows.length) {
      throw TestDataError(
        'La fila $index no existe en $origin, que tiene ${_rows.length}.',
      );
    }
    return _rows[index];
  }

  static DataSet _parse({
    required String name,
    required String raw,
    required String origin,
  }) {
    final Object? decoded = _decode(raw, origin);

    if (decoded is Map<String, Object?>) {
      final Map<String, DataRecord> keyed = <String, DataRecord>{};
      for (final MapEntry<String, Object?> entry in decoded.entries) {
        final Object? value = entry.value;
        if (value is! Map<String, Object?>) {
          throw TestDataError(
            'El registro "${entry.key}" en $origin debe ser un objeto, '
            'no ${value.runtimeType}.',
          );
        }
        keyed[entry.key] = DataRecord._(
          value,
          path: '$name.${entry.key}',
          origin: origin,
        );
      }
      return DataSet._(
        name: name,
        origin: origin,
        keyed: keyed,
        rows: keyed.values.toList(growable: false),
      );
    }

    if (decoded is List<Object?>) {
      final List<DataRecord> rows = <DataRecord>[];
      for (int i = 0; i < decoded.length; i++) {
        final Object? value = decoded[i];
        if (value is! Map<String, Object?>) {
          throw TestDataError(
            'La fila $i en $origin debe ser un objeto, no '
            '${value.runtimeType}.',
          );
        }
        rows.add(DataRecord._(value, path: '$name[$i]', origin: origin));
      }
      return DataSet._(
        name: name,
        origin: origin,
        keyed: const <String, DataRecord>{},
        rows: rows,
      );
    }

    throw TestDataError(
      '$origin debe contener un objeto o una lista en su raíz, no '
      '${decoded.runtimeType}.',
    );
  }
}

/// One record, with typed reads.
///
/// The accessors exist instead of handing back a raw map so that the failure
/// mode is a sentence rather than a cast error: asking for a field nobody
/// wrote, or reading a string as a number, names the field and the file it
/// came from. Everything they throw is a [TestDataError], so the step is
/// reported **broken** — the test could not run, which is not the same as the
/// product being wrong.
class DataRecord {
  const DataRecord._(this._fields, {required this.path, required this.origin});

  final Map<String, Object?> _fields;

  /// Dotted route to this record, used in errors.
  final String path;

  /// The file it came from.
  final String origin;

  /// The field names this record carries.
  List<String> get fields => _fields.keys.toList(growable: false);

  /// Whether [field] is present and not null.
  bool has(String field) => _fields[field] != null;

  /// The raw value, or null when absent. The escape hatch for a shape the
  /// typed accessors do not cover.
  Object? raw(String field) => _fields[field];

  /// Reads [field] as text.
  String string(String field) => _read<String>(field, 'un texto');

  /// Reads [field] as a whole number.
  int integer(String field) {
    final Object? value = _require(field);
    if (value is int) {
      return value;
    }
    // JSON has one number type, so 5 may arrive as 5.0 through a re-encode.
    if (value is double && value == value.roundToDouble()) {
      return value.toInt();
    }
    throw _wrongType(field, 'un entero', value);
  }

  /// Reads [field] as a number, whole or not.
  double number(String field) {
    final Object? value = _require(field);
    if (value is num) {
      return value.toDouble();
    }
    throw _wrongType(field, 'un número', value);
  }

  /// Reads [field] as a boolean.
  bool boolean(String field) => _read<bool>(field, 'un booleano');

  /// Reads [field] as a list of text.
  List<String> strings(String field) {
    final Object? value = _require(field);
    if (value is List<Object?> && value.every((Object? e) => e is String)) {
      return value.cast<String>();
    }
    throw _wrongType(field, 'una lista de textos', value);
  }

  /// Reads [field] as a nested record.
  DataRecord child(String field) {
    final Object? value = _require(field);
    if (value is Map<String, Object?>) {
      return DataRecord._(value, path: '$path.$field', origin: origin);
    }
    throw _wrongType(field, 'un objeto', value);
  }

  /// Reads [field] as a list of nested records.
  List<DataRecord> children(String field) {
    final Object? value = _require(field);
    if (value is List<Object?>) {
      final List<DataRecord> records = <DataRecord>[];
      for (int i = 0; i < value.length; i++) {
        final Object? item = value[i];
        if (item is! Map<String, Object?>) {
          throw _wrongType('$field[$i]', 'un objeto', item);
        }
        records.add(
          DataRecord._(item, path: '$path.$field[$i]', origin: origin),
        );
      }
      return records;
    }
    throw _wrongType(field, 'una lista de objetos', value);
  }

  T _read<T>(String field, String expected) {
    final Object? value = _require(field);
    if (value is T) {
      return value;
    }
    throw _wrongType(field, expected, value);
  }

  Object? _require(String field) {
    final Object? value = _fields[field];
    if (value == null) {
      throw TestDataError(
        'Falta el campo "$field" en $path ($origin). '
        'El registro tiene: ${_fields.keys.join(', ')}',
      );
    }
    return value;
  }

  TestDataError _wrongType(String field, String expected, Object? value) =>
      TestDataError(
        '"$path.$field" en $origin debería ser $expected, y es '
        '${value.runtimeType} ($value).',
      );

  @override
  String toString() => '$path$_fields';
}

Map<String, Object?> _decodeObject(String raw, String origin) {
  final Object? decoded = _decode(raw, origin);
  if (decoded is! Map<String, Object?>) {
    throw TestDataError(
      '$origin debe contener un objeto en su raíz, no ${decoded.runtimeType}.',
    );
  }
  return decoded;
}

Object? _decode(String raw, String origin) {
  try {
    return jsonDecode(raw);
  } on FormatException catch (error) {
    throw TestDataError('$origin no es JSON válido: ${error.message}');
  }
}
