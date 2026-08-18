import 'dart:io';

import 'package:sqa_reporter/sqa_reporter.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// The dashboard against the layout it replicates: the branded banner, the
/// per-platform project title, the summary numbers, the scenario table, and
/// the branding rule — the design source's name appears nowhere in the site.
void main() {
  late Directory out;
  late String html;

  setUpAll(() {
    out = Directory.systemTemp.createTempSync('sqa_dashboard_test');
    final File input = File('${out.path}/results.json')
      ..writeAsStringSync(playwrightReport());
    final ParsedRun run = parsePlaywright(input);
    writeSerenityResults(
      run,
      Directory('${out.path}/results'),
      platform: 'web',
    );
    final File index = writeDashboard(
      run,
      Directory('${out.path}/results'),
      platform: 'web',
      generatedAt: DateTime.utc(2026, 8, 18, 10, 5),
    );
    html = index.readAsStringSync();
  });

  tearDownAll(() => out.deleteSync(recursive: true));

  group('the site files', () {
    test('land beside the JSON results, with the stylesheet', () {
      expect(File('${out.path}/results/index.html').existsSync(), isTrue);
      expect(File('${out.path}/results/sqa-reporter.css').existsSync(), isTrue);
      expect(
        Directory('${out.path}/results').listSync().whereType<File>().where(
          (File f) => f.path.endsWith('.json'),
        ),
        hasLength(2),
        reason: 'the dashboard must not delete the results it describes',
      );
    });
  });

  group('the banner', () {
    test('names the report SQA Reporter, not the design source', () {
      expect(html, contains('<title>SQA Reporter</title>'));
      expect(html, contains('SQA <span class="accent">Reporter</span>'));
    });

    test('titles the project by platform', () {
      expect(html, contains('Test e2e Web'));
      expect(projectTitleFor('android'), 'Test e2e Mobile');
      expect(projectTitleFor('ios'), 'Test e2e Mobile');
    });
  });

  group('the summary', () {
    test('counts the run: two cases, half of them passing', () {
      expect(html, contains('2 test cases'));
      expect(html, contains('<span class="donut-label">50%</span>'));
    });

    test('legend and bars carry only the verdicts that occurred', () {
      expect(html, contains('Passing (1)'));
      expect(html, contains('Broken (1)'));
      expect(html, isNot(contains('Failed (0)')));
    });

    test('key statistics include the run clock and durations', () {
      expect(html, contains('Key Statistics'));
      expect(html, contains('Tests started'));
      expect(html, contains('Cumulative test time'));
    });
  });

  group('the scenario table', () {
    test('lists both tests with feature, name and verdict', () {
      expect(html, contains('<td>Authentication</td>'));
      expect(html, contains('logs in with the seeded demo account'));
      expect(html, contains('title="SUCCESS"'));
      expect(html, contains('title="ERROR"'));
    });

    test('escapes what the run put in its names', () {
      expect(
        escapeHtml('<b>bold</b> & "quoted"'),
        '&lt;b&gt;bold&lt;/b&gt; &amp; &quot;quoted&quot;',
      );
    });
  });

  group('formatting', () {
    test('durations read as their largest two units', () {
      expect(compoundDuration(450), '450ms');
      expect(compoundDuration(2600), '2s 600ms');
      expect(compoundDuration(65000), '1m 5s');
      expect(compoundDuration(3660000), '1h 1m');
    });
  });

  group('branding', () {
    test('no occurrence of the design source name anywhere in the site', () {
      for (final File file
          in Directory(
            '${out.path}/results',
          ).listSync().whereType<File>().where(
            (File f) => f.path.endsWith('.html') || f.path.endsWith('.css'),
          )) {
        expect(
          file.readAsStringSync().toLowerCase(),
          isNot(contains('serenity')),
        );
      }
    });

    test('the site is self-contained: no external URL is referenced', () {
      expect(html, isNot(contains('http://')));
      expect(html, isNot(contains('https://')));
    });
  });
}
