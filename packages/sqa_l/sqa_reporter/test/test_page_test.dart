import 'dart:io';

import 'package:sqa_reporter/sqa_reporter.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// The detail page against the layout it replicates: the story header and its
/// tags, the result-coloured title bar, the step tree with its nesting and
/// per-step verdict, the screenshot on the step that captured it, the failure
/// block, and the pairing with the JSON by digest.
void main() {
  late Directory out;
  late Directory results;
  late ParsedRun run;
  late String passingPage;
  late String brokenPage;

  setUpAll(() {
    out = Directory.systemTemp.createTempSync('sqa_test_page_test');
    results = Directory('${out.path}/results');
    final File input = File('${out.path}/results.json')
      ..writeAsStringSync(playwrightReport());
    run = parsePlaywright(input);
    writeSerenityResults(run, results, platform: 'web');
    writeDashboard(
      run,
      results,
      platform: 'web',
      generatedAt: DateTime.utc(2026, 8, 18, 10, 5),
    );
    writeTestPages(
      run,
      results,
      platform: 'web',
      generatedAt: DateTime.utc(2026, 8, 18, 10, 5),
    );
    passingPage = File(
      '${results.path}/${htmlReportName(run.cases.first)}',
    ).readAsStringSync();
    brokenPage = File(
      '${results.path}/${htmlReportName(run.cases.last)}',
    ).readAsStringSync();
  });

  tearDownAll(() => out.deleteSync(recursive: true));

  group('the files', () {
    test('one page per test, named by the digest of its JSON', () {
      for (final RunCase testCase in run.cases) {
        expect(htmlReportName(testCase), '${reportDigest(testCase)}.html');
        expect(
          File('${results.path}/${htmlReportName(testCase)}').existsSync(),
          isTrue,
        );
        expect(
          File('${results.path}/${reportFileName(testCase)}').existsSync(),
          isTrue,
          reason: 'the JSON and the page pair by digest',
        );
      }
    });

    test('the dashboard links every scenario row to its page', () {
      final String index = File(
        '${results.path}/index.html',
      ).readAsStringSync();
      for (final RunCase testCase in run.cases) {
        expect(index, contains('href="${htmlReportName(testCase)}"'));
      }
    });
  });

  group('the title bar', () {
    test('carries the feature, the test name and the verdict colour', () {
      expect(passingPage, contains('Authentication'));
      expect(passingPage, contains('logs in with the seeded demo account'));
      expect(passingPage, contains('test-title-bar test-SUCCESS'));
      expect(brokenPage, contains('test-title-bar test-ERROR'));
    });

    test('shows the scenario tags as badges', () {
      expect(passingPage, contains('Access (epic)'));
      expect(passingPage, contains('blocker (severity)'));
      expect(passingPage, contains('>smoke_test<'));
      expect(passingPage, contains('>web<'), reason: 'the context tag');
    });

    test('shows the description the scenario declared', () {
      expect(passingPage, contains('The door to everything else.'));
    });
  });

  group('the step tree', () {
    test('nests children behind a caret, collapsed by default', () {
      expect(passingPage, contains('data-toggle="step-section-1"'));
      expect(passingPage, contains('<tr class="step-section"'));
      expect(passingPage, contains('hidden>'));
    });

    test('shows each step with its own verdict and duration', () {
      expect(passingPage, contains('Log in as the demo user'));
      expect(passingPage, contains('tap login_submit_button'));
      expect(passingPage, contains('2s'), reason: 'the business step');
      expect(passingPage, contains('1s 500ms'), reason: 'the interaction');
    });

    test('folds the assertion expected value into its description', () {
      expect(passingPage, contains('verified: Hola, Ana'));
    });

    test('marks every step with its own verdict, not just the far column', () {
      expect(passingPage, contains('class="result-icon step-icon"'));
      expect(
        RegExp('step-icon').allMatches(passingPage).length,
        greaterThan(2),
        reason: 'one mark per step, so a bad one is a glance down the edge',
      );
    });

    test('carries the depth on the row, for the tree to read as one', () {
      expect(passingPage, contains('class="test-SUCCESS step-row level-0"'));
      expect(passingPage, contains('step-row level-1'));
    });

    test('offers to open or close the whole tree at once', () {
      expect(passingPage, contains('class="expand-all"'));
      expect(passingPage, contains('class="collapse-all"'));
    });

    test('a leaf keeps the caret\'s width, so the marks stay in a column', () {
      expect(passingPage, contains('class="caret-spacer"'));
    });

    test('a broken step reads ERROR on the page too', () {
      expect(brokenPage, contains('Open the catalog'));
      expect(brokenPage, contains('>ERROR<'));
    });
  });

  group('screenshots', () {
    test('hang off the step that captured them, by the same file the JSON '
        'references', () {
      final Map<CapturedShot, String> names = shotNamesFor(run.cases.first);
      expect(names, hasLength(2));
      for (final String file in names.values) {
        expect(passingPage, contains('src="$file"'));
        expect(File('${results.path}/$file').existsSync(), isTrue);
      }
    });

    test('the column is absent when a test captured nothing', () {
      expect(brokenPage, isNot(contains('Screenshots')));
    });
  });

  group('the log and the failure', () {
    test('there is no run log block: warn and error are steps already', () {
      expect(passingPage, isNot(contains('Run log')));
      expect(
        passingPage,
        contains('Coupon already applied'),
        reason: 'the warn line survives as its own step',
      );
    });

    test('a failing test shows the error type, message and trace', () {
      expect(brokenPage, contains('StateError'));
      expect(brokenPage, contains('wrong locator?'));
      expect(brokenPage, contains('<summary>Stack trace</summary>'));
      expect(brokenPage, contains('element.dart:68'));
    });

    test('a passing test has no failure block', () {
      expect(passingPage, isNot(contains('failure-block')));
    });
  });

  group('branding', () {
    test('no occurrence of the design source name in any page', () {
      for (final File file in results.listSync().whereType<File>().where(
        (File f) => f.path.endsWith('.html'),
      )) {
        expect(
          file.readAsStringSync().toLowerCase(),
          isNot(contains('serenity')),
        );
      }
    });

    test('the pages reference no external URL', () {
      for (final String page in <String>[passingPage, brokenPage]) {
        expect(page, isNot(contains('http://')));
        expect(page, isNot(contains('https://')));
      }
    });
  });
}
