import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The semantics identifiers are a contract with QA's black-box suites
/// (Playwright, Appium, Maestro), which address the app by them and cannot be
/// checked by the compiler. This guards the parts of that contract a typo or a
/// careless addition breaks silently:
///
///  * every identifier is `<screen>_<element>_<type>` snake_case;
///  * no two places declare the same one;
///  * no fixed identifier starts with the prefix of a parameterised family —
///    `cart_item_<id>` next to a `cart_item_removed_text` would make a locator
///    like `[flt-semantics-identifier^="cart_item_"]`, the usual way to count
///    a list's items, count the snackbar too;
///  * no widget writes an identifier as a loose string instead of using the
///    constants.
///
/// It reads the sources rather than importing them: the classes live in every
/// feature's constants package, and a test that imported each one would have
/// to be edited every time a feature is added — which is when it matters most.
void main() {
  // `flutter test` runs from the package root: packages/apps/market_app.
  final List<Directory> roots = <Directory>[
    Directory('lib'),
    Directory('../../features'),
    Directory('../../ui'),
  ];

  Iterable<File> dartFiles() sync* {
    for (final Directory root in roots) {
      for (final FileSystemEntity entity in root.listSync(
        recursive: true,
        followLinks: false,
      )) {
        final String path = entity.path;
        if (entity is File &&
            path.endsWith('.dart') &&
            !path.contains('/build/') &&
            !path.contains('/.dart_tool/')) {
          yield entity;
        }
      }
    }
  }

  final List<File> idFiles = dartFiles()
      .where((File file) => file.path.endsWith('_semantic_ids.dart'))
      .toList();

  final RegExp fixedPattern = RegExp(
    r"static const String (\w+)\s*=\s*'([^']*)';",
  );
  final RegExp familyPattern = RegExp(
    r"static String (\w+)\([^)]*\)\s*=>\s*'([^'$]*)\$",
  );
  final RegExp snakeCase = RegExp(r'^[a-z0-9]+(_[a-z0-9]+)*$');

  /// identifier → where it is declared.
  final Map<String, List<String>> fixed = <String, List<String>>{};

  /// family prefix → where it is declared.
  final Map<String, List<String>> families = <String, List<String>>{};

  for (final File file in idFiles) {
    final String source = file.readAsStringSync();
    for (final RegExpMatch match in fixedPattern.allMatches(source)) {
      (fixed[match.group(2)!] ??= <String>[]).add(
        '${file.path} · ${match.group(1)}',
      );
    }
    for (final RegExpMatch match in familyPattern.allMatches(source)) {
      (families[match.group(2)!] ??= <String>[]).add(
        '${file.path} · ${match.group(1)}()',
      );
    }
  }

  test('the identifier files are found', () {
    // Fails if the folders move, rather than letting every check below pass
    // over an empty list.
    expect(idFiles, isNotEmpty);
    expect(fixed.length, greaterThan(100));
    expect(families, isNotEmpty);
  });

  test('every identifier is snake_case', () {
    final List<String> wrong = <String>[
      for (final String id in fixed.keys)
        if (!snakeCase.hasMatch(id)) id,
      for (final String prefix in families.keys)
        if (!prefix.endsWith('_') ||
            !snakeCase.hasMatch(prefix.substring(0, prefix.length - 1)))
          '$prefix…',
    ];
    expect(wrong, isEmpty);
  });

  test('no identifier is declared twice', () {
    final Map<String, List<String>> duplicated = <String, List<String>>{
      for (final MapEntry<String, List<String>> entry in fixed.entries)
        if (entry.value.length > 1) entry.key: entry.value,
      for (final MapEntry<String, List<String>> entry in families.entries)
        if (entry.value.length > 1) '${entry.key}…': entry.value,
    };
    expect(duplicated, isEmpty);
  });

  test('no identifier starts with the prefix of a parameterised family', () {
    final List<String> shadowing = <String>[
      for (final String prefix in families.keys) ...<String>[
        for (final String id in fixed.keys)
          if (id.startsWith(prefix)) '$id starts with $prefix…',
        for (final String other in families.keys)
          if (other != prefix && other.startsWith(prefix))
            '$other… starts with $prefix…',
      ],
    ];
    expect(shadowing, isEmpty);
  });

  test('no widget writes an identifier as a loose string', () {
    final RegExp loose = RegExp(r"identifier:\s*'");
    final List<String> offenders = <String>[
      for (final File file in dartFiles())
        if (!file.path.endsWith('_semantic_ids.dart') &&
            loose.hasMatch(file.readAsStringSync()))
          file.path,
    ];
    expect(offenders, isEmpty);
  });
}
