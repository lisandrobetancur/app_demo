import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The one ordering rule an E2E test has to obey.
///
/// Test data is read from the asset bundle, and the bundle only exists once
/// the app has been launched. So inside a test body, **nothing may read
/// `TestData` before `launchMarketApp`** — and the natural way to write a test
/// puts the metadata first, which is exactly where the temptation lies:
///
/// ```dart
/// e2eTest('…', tags: […], ($) async {
///   scenario(…);
///   testParam('Usuario', TestData.demoEmail);   // ← todavía no hay datos
///   await launchMarketApp($);
/// });
/// ```
///
/// That mistake shipped once. It cost four minutes of CI and four red tests on
/// each platform, and it could not have been caught by any suite that does not
/// launch a browser — which is why it is caught here instead, by reading the
/// source. A second of `flutter test` in place of six minutes of E2E.
///
/// The check is textual and therefore only as good as the convention: it sees
/// a direct `TestData.` read inside a test body, not one hidden behind a
/// helper the body calls. That covers the case that actually happens, and a
/// helper is called after the launch anyway because it needs the app.
void main() {
  final Directory testDir = Directory('patrol_test');

  test('no test reads TestData before launching the app', () {
    final List<File> files = testDir
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('_test.dart'))
        .toList();

    expect(
      files,
      isNotEmpty,
      reason: 'no se encontró ningún *_test.dart en ${testDir.path}; '
          '¿cambió la ruta o el directorio de trabajo?',
    );

    final List<String> offences = <String>[];

    for (final File file in files) {
      final String source = file.readAsStringSync();

      // Cada llamada a `e2eTest(` abre un cuerpo de prueba. Partir por ahí es
      // suficiente: lo que sigue a una y precede a la siguiente es el cuerpo.
      final List<String> bodies = source.split('e2eTest(')..removeAt(0);

      for (int i = 0; i < bodies.length; i++) {
        final String body = bodies[i];
        final int launchAt = body.indexOf('launchMarketApp');
        final int dataAt = body.indexOf('TestData.');

        if (dataAt < 0) {
          continue; // no lee datos: nada que ordenar
        }
        if (launchAt < 0) {
          offences.add(
            '${file.path}: la prueba #${i + 1} lee TestData pero nunca '
            'llama a launchMarketApp',
          );
          continue;
        }
        if (dataAt < launchAt) {
          final String line = body
              .substring(0, dataAt)
              .split('\n')
              .length
              .toString();
          offences.add(
            '${file.path}: la prueba #${i + 1} lee TestData (línea $line del '
            'cuerpo) antes de launchMarketApp. Los datos se cargan al '
            'arrancar la app, así que esa lectura falla con TestDataError.',
          );
        }
      }
    }

    expect(offences, isEmpty, reason: '\n${offences.join('\n')}\n');
  });
}
