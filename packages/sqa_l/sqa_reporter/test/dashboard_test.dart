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
    test('land beside the JSON results, with the stylesheet and icon', () {
      expect(File('${out.path}/results/index.html').existsSync(), isTrue);
      expect(File('${out.path}/results/sqa-reporter.css').existsSync(), isTrue);
      expect(File('${out.path}/results/favicon.svg').existsSync(), isTrue);
      expect(html, contains('<link rel="icon" href="favicon.svg"'));
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
      expect(
        html,
        contains('<title>SQA Reporter · Web E2E Test Report</title>'),
      );
      expect(html, contains('<span class="wordmark-sqa">SQA</span>'));
      expect(html, contains('<span class="wordmark-name">Reporter</span>'));
    });

    test('the wordmark links home, mark and all', () {
      expect(html, contains('<a class="wordmark" href="index.html">'));
      expect(
        html,
        contains('<svg class="wordmark-mark"'),
        reason: 'the figure is drawn inline: no second request for a logo',
      );
      expect(
        html,
        contains('aria-hidden="true"'),
        reason: 'decorative — the wordmark beside it already says the name',
      );
    });

    test('carries one title line, worded by platform', () {
      expect(html, contains('Web E2E Test Report'));
      expect(projectTitleFor('web'), 'Web E2E Test Report');
      expect(projectTitleFor('android'), 'Android E2E Test Report');
      expect(projectTitleFor('ios'), 'iOS E2E Test Report');
      expect(
        html,
        isNot(contains('projectsubtitle')),
        reason: 'the two lines became one',
      );
    });

    test('an unexpected platform is named after itself, not filed under one '
        'of the three', () {
      expect(projectTitleFor('macos'), 'Macos E2E Test Report');
      expect(projectTitleFor(''), 'E2E Test Report');
    });
  });

  group('the key figures', () {
    test('open the page with the four numbers it is read for', () {
      expect(html, contains('<div class="kpi-row">'));
      expect(html, contains('<span class="kpi-label">Scenarios</span>'));
      expect(html, contains('<span class="kpi-value">2</span>'));
      expect(html, contains('<span class="kpi-label">Pass rate</span>'));
      expect(html, contains('<span class="kpi-value">50%</span>'));
      expect(html, contains('1 of 2 passing'));
    });

    test('what needs a person is counted, and coloured, on its own', () {
      // One test in the fixture is broken, which is a thing somebody has to
      // look at — so the tile is marked, and the pass rate is not called
      // good news.
      expect(html, contains('<div class="kpi bad">'));
      expect(html, contains('1 failed or broken'));
      expect(
        html,
        isNot(contains('<div class="kpi good">')),
        reason: 'a run with something broken is not a clean run',
      );
    });

    test('a run with nothing to look at is called good', () {
      final String clean = dashboardHtml(
        ParsedRun(
          cases: <RunCase>[
            RunCase(
              suite: 'login_test',
              name: 'logs in',
              status: RunStatus.passed,
              start: 0,
              stop: 1000,
              thread: 'worker-0',
            ),
          ],
        ),
        platform: 'web',
        generatedAt: DateTime.utc(2026, 8, 18, 10, 5),
      );
      expect(clean, contains('<div class="kpi good">'));
      expect(clean, contains('<span class="kpi-value">100%</span>'));
      expect(clean, contains('all of them run'));
      expect(clean, isNot(contains('<div class="kpi bad">')));
    });
  });

  group('the summary', () {
    test('counts the run: two tests, half of them passing', () {
      expect(html, contains('class="donut-label"'));
      expect(html, contains('>50%</a>'));
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

  group('the charts lead into the table', () {
    test('each doughnut segment is a clickable ring sector', () {
      expect(html, contains('class="donut-wedge"'));
      expect(html, contains('data-result="SUCCESS"'));
      expect(
        html,
        contains('clip-path:polygon('),
        reason: 'a gradient cannot be clicked segment by segment',
      );
    });

    test('nothing painted over the doughnut can swallow its clicks', () {
      // The centred percentage covers the whole box in order to centre
      // itself; without this rule it sits over every segment and takes the
      // click meant for the wedge underneath, which is how the doughnut
      // ended up looking clickable while doing nothing.
      final String css = File(
        '${out.path}/results/sqa-reporter.css',
      ).readAsStringSync();
      final RegExp label = RegExp(
        r'\.donut \.donut-label \{[^}]*pointer-events: none;',
        dotAll: true,
      );
      final RegExp slice = RegExp(
        r'\.donut-slice-label \{[^}]*pointer-events: none;',
        dotAll: true,
      );
      expect(css, matches(label));
      expect(css, matches(slice));
    });

    test('bars and legend entries link to the same selection', () {
      expect(html, contains('<a class="bar-column" href="#tests"'));
      expect(html, contains('<li><a href="#tests" data-result="ERROR">'));
    });

    test('a verdict nobody hit is shown but not clickable', () {
      expect(html, contains('<li class="empty">'));
      expect(
        html,
        isNot(contains('data-result="FAILURE"')),
        reason: 'no test failed in this run, so nothing links to that view',
      );
    });

    test('the table has somewhere to say a selection is in force', () {
      expect(html, contains('class="active-filter"'));
    });
  });

  group('the run behind the report', () {
    test('says so when the run is older than the report', () {
      final String stale = dashboardHtml(
        parsePlaywright(inputFile),
        platform: 'web',
        // The fixture's run ends at 10:01; this report is built two days on.
        generatedAt: DateTime.utc(2026, 8, 20, 10, 5),
      );
      expect(stale, contains('class="run-age"'));
      expect(stale, contains('2 days before this report'));
    });

    test('stays quiet when the two are minutes apart', () {
      final String fresh = dashboardHtml(
        parsePlaywright(inputFile),
        platform: 'web',
        generatedAt: DateTime.utc(2026, 8, 18, 10, 3),
      );
      expect(fresh, isNot(contains('class="run-age"')));
    });
  });

  group('the clock the report reads in', () {
    test('shows times in UTC-5 by default: Bogotá, Lima, Quito', () {
      // The run's first test starts at 10:00:00Z, which is 05:00 there.
      expect(html, contains('2026-08-18 05:00:00 UTC-5'));
      expect(
        html,
        isNot(contains('10:00:00 UTC')),
        reason: 'a report in UTC read five hours off the suite it describes',
      );
    });

    test('the whole page moves together when the offset does', () {
      final String utc = dashboardHtml(
        parsePlaywright(inputFile),
        platform: 'web',
        offset: Duration.zero,
        generatedAt: DateTime.utc(2026, 8, 18, 10, 5),
      );
      expect(utc, contains('2026-08-18 10:00:00 UTC'));
      expect(utc, isNot(contains('UTC-5')));

      final String india = dashboardHtml(
        parsePlaywright(inputFile),
        platform: 'web',
        offset: const Duration(hours: 5, minutes: 30),
        generatedAt: DateTime.utc(2026, 8, 18, 10, 5),
      );
      expect(india, contains('2026-08-18 15:30:00 UTC+5:30'));
    });

    test('labels an offset the way a reader writes it', () {
      expect(offsetLabel(const Duration(hours: -5)), 'UTC-5');
      expect(offsetLabel(Duration.zero), 'UTC');
      expect(offsetLabel(const Duration(hours: 2)), 'UTC+2');
      expect(offsetLabel(const Duration(hours: 5, minutes: 30)), 'UTC+5:30');
    });

    test('reads the forms a person would type, and refuses the rest', () {
      expect(parseOffset('-05:00'), const Duration(hours: -5));
      expect(parseOffset('-5'), const Duration(hours: -5));
      expect(parseOffset('+0530'), const Duration(hours: 5, minutes: 30));
      expect(parseOffset('0'), Duration.zero);
      expect(parseOffset('America/Bogota'), isNull);
      expect(parseOffset('-25:00'), isNull);
      expect(parseOffset(''), isNull);
    });

    test('the JSON keeps UTC: a machine wants one unambiguous instant', () {
      final File result = Directory('${out.path}/results')
          .listSync()
          .whereType<File>()
          .firstWhere((File f) => f.path.endsWith('.json'));
      expect(result.readAsStringSync(), contains('Z"'));
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
    test('carries the severity each scenario declared, sorted worst first', () {
      expect(
        html,
        contains('<th class="sortable" data-sort="number">Severity'),
      );
      expect(html, contains('<span class="severity blocker">blocker</span>'));
      // Blocker sorts above everything, and a scenario that declared nothing
      // sorts last — saying nothing is not the same as saying "normal".
      expect(severityWeight('blocker'), lessThan(severityWeight('normal')));
      expect(severityWeight(null), greaterThan(severityWeight('trivial')));
      expect(severityLabel(null), contains('severity none'));
    });

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

    test('has no Context column: which worker ran it says nothing', () {
      expect(html, isNot(contains('>Context<')));
      expect(html, isNot(contains('worker-0')));
    });

    test('every row carries its verdict, for a chart to filter on', () {
      expect(html, contains('<tr data-result="SUCCESS">'));
      expect(html, contains('<tr data-result="ERROR">'));
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

  group('the layout', () {
    test('titles are set in the report\'s own blue, links keep theirs', () {
      final String css = File(
        '${out.path}/results/sqa-reporter.css',
      ).readAsStringSync();
      expect(css, contains('--title: #0B2545'));
      expect(css, contains('color: var(--title)'));
      expect(css, contains('--link: #1d63c4'));
    });

    test('the screenshot viewer is hidden until a screenshot is clicked', () {
      final String css = File(
        '${out.path}/results/sqa-reporter.css',
      ).readAsStringSync();
      expect(css, contains('.lightbox[hidden] { display: none; }'));
      expect(css, contains('.slides img { cursor: zoom-in; }'));
    });

    test('nothing is pinned to a minimum width, and wide tables scroll', () {
      final String css = File(
        '${out.path}/results/sqa-reporter.css',
      ).readAsStringSync();
      expect(css, isNot(contains('min-width: 1024px')));
      expect(css, contains('.table-scroll { overflow-x: auto; }'));
      expect(html, contains('<div class="table-scroll">'));
    });

    test('narrow screens get their own rules', () {
      final String css = File(
        '${out.path}/results/sqa-reporter.css',
      ).readAsStringSync();
      expect(css, contains('@media (max-width: 900px)'));
      expect(css, contains('@media (max-width: 600px)'));
      expect(html, contains('width=device-width, initial-scale=1'));
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
