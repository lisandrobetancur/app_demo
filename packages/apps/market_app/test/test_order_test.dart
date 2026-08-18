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
///   testParam('User', TestData.demoEmail);   // ← no data yet
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
      reason: 'found no *_test.dart under ${testDir.path}; did the path or '
          'the working directory change?',
    );

    final List<String> offences = <String>[];

    for (final File file in files) {
      final String source = file.readAsStringSync();

      // Every `e2eTest(` call opens a test body. Splitting on it is enough:
      // what follows one and precedes the next is the body.
      final List<String> bodies = source.split('e2eTest(')..removeAt(0);

      for (int i = 0; i < bodies.length; i++) {
        final String body = bodies[i];
        final int launchAt = body.indexOf('launchMarketApp');
        final int dataAt = body.indexOf('TestData.');

        if (dataAt < 0) {
          continue; // reads no data: nothing to order
        }
        if (launchAt < 0) {
          offences.add(
            '${file.path}: test #${i + 1} reads TestData but never calls '
            'launchMarketApp',
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
            '${file.path}: test #${i + 1} reads TestData (line $line of the '
            'body) before launchMarketApp. The data is loaded as the app '
            'launches, so that read fails with TestDataError.',
          );
        }
      }
    }

    expect(offences, isEmpty, reason: '\n${offences.join('\n')}\n');
  });
}
