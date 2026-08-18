import 'dart:io';

import 'package:sqa_reporter/sqa_reporter.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// The dashboard against the layout it replicates: the branded banner, the
/// per-platform project title, the summary numbers, the scenario table, and
/// the branding rule — the design source's name appears nowhere in the site.
void main() {
  late Directory out;
  late File inputFile;
  late String html;

  setUpAll(() {
    out = Directory.systemTemp.createTempSync('sqa_dashboard_test');
    inputFile = File('${out.path}/results.json')
      ..writeAsStringSync(playwrightReport());
    final ParsedRun run = parsePlaywright(inputFile);
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

    test('the wordmark links home', () {
      expect(html, contains('<a class="wordmark" href="index.html">'));
    });

    test('carries one title line, worded by platform', () {
      expect(html, contains('E2E test report web'));
      expect(projectTitleFor('web'), 'E2E test report web');
      expect(projectTitleFor('android'), 'E2E test report mobile');
      expect(projectTitleFor('ios'), 'E2E test report mobile');
      expect(
        html,
        isNot(contains('projectsubtitle')),
        reason: 'the two lines became one',
      );
    });

    test('a given title replaces the default everywhere', () {
      final String custom = dashboardHtml(
        parsePlaywright(inputFile),
        platform: 'web',
        title: 'Reporte E2E · Tyba',
        generatedAt: DateTime.utc(2026, 8, 18, 10, 5),
      );
      expect(custom, contains('Reporte E2E · Tyba'));
      expect(custom, isNot(contains('E2E test report web')));
    });
  });

  group('the summary', () {
    test('counts the run: two tests, half of them passing', () {
      expect(html, contains('2 tests'));
      expect(html, contains('<span class="donut-label">50%</span>'));
    });

    test('writes each share on its own segment of the doughnut', () {
      expect(
        RegExp('donut-slice-label').allMatches(html).length,
        2,
        reason: 'one label per verdict that occurred',
      );
      expect(html, contains('>50%</span>'));
    });

    test('the legend names every verdict, counting the ones that occurred', () {
      expect(html, contains('Passing Test Cases (1)'));
      expect(html, contains('Broken Test Cases (1)'));
      expect(
        html,
        contains('Failed Test Cases</li>'),
        reason: 'a verdict with no tests is listed without a count, not hidden',
      );
    });

    test('the outcomes chart has a labelled axis', () {
      expect(html, contains('class="y-tick"'));
      expect(html, contains('class="gridline"'));
      expect(html, contains('class="bar-value"'));
    });

    test('the performance chart buckets tests by how long they took', () {
      expect(html, contains('Test Performance'));
      expect(html, contains('Number of tests per duration'));
      expect(html, contains('1 to 10 seconds'));
      expect(html, contains('10 minutes or over'));
    });

    test('key statistics include the run clock and durations', () {
      expect(html, contains('Key Statistics'));
      expect(html, contains('Tests started'));
      expect(html, contains('Cumulative test time'));
    });

    test('the tags the run declared are shown with their counts', () {
      expect(html, contains('smoke_test'));
      expect(html, contains('class="tag-count">1</span>'));
    });
  });

  group('the axis', () {
    test('rounds up to a step that divides it', () {
      expect(niceAxis(0), (top: 1, step: 1));
      expect(niceAxis(1), (top: 1, step: 1));
      expect(niceAxis(6), (top: 6, step: 1));
      expect(niceAxis(45), (top: 45, step: 5), reason: '0..45 in nine steps');
      expect(
        niceAxis(51),
        (top: 60, step: 10),
        reason: 'step 5 would need eleven ticks, so the step grows instead',
      );
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

    test('carries a filter, a page size and sortable headers', () {
      expect(html, contains('class="table-filter"'));
      expect(html, contains('class="page-size"'));
      expect(html, contains('class="sortable"'));
      expect(html, contains('class="table-info"'));
      expect(html, contains('class="pagination"'));
    });

    test('sorts each column by what it means, not by how it reads', () {
      // A duration sorts by milliseconds and a result by severity, so "2s"
      // does not sort after "10s" and FAILURE comes before SUCCESS.
      expect(html, contains('data-order="2600"'));
      expect(html, contains('data-order="2"'), reason: 'ERROR ranks second');
    });

    test('has no manual-test section: every test here is automated', () {
      expect(html, isNot(contains('Manual Tests')));
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
