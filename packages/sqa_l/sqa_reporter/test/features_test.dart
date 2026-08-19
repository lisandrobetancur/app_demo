import 'dart:io';

import 'package:sqa_reporter/sqa_reporter.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// The feature tree and its pages: how the epic → feature hierarchy is built
/// from what `scenario()` declared, how coverage rolls up a branch, and what
/// the pages do with a feature nobody tested.
void main() {
  late Directory out;
  late Directory results;
  late ParsedRun run;
  late List<RequirementNode> roots;
  late String featuresPage;

  setUpAll(() {
    out = Directory.systemTemp.createTempSync('sqa_requirements_test');
    results = Directory('${out.path}/results');
    final File input = File('${out.path}/results.json')
      ..writeAsStringSync(playwrightReport());
    run = parsePlaywright(input);
    roots = requirementsOf(run);
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
    writeFeaturePages(
      run,
      results,
      platform: 'web',
      generatedAt: DateTime.utc(2026, 8, 18, 10, 5),
    );
    featuresPage = File('${results.path}/features.html').readAsStringSync();
  });

  tearDownAll(() => out.deleteSync(recursive: true));

  group('the tree', () {
    test('epics hold their features, in declared names', () {
      final RequirementNode epic = roots.first;
      expect(epic.name, 'Access');
      expect(epic.type, 'epic');
      expect(epic.children.single.name, 'Authentication');
      expect(epic.children.single.type, 'feature');
    });

    test('a feature that declared no epic stands at the root, not under an '
        'invented one', () {
      final RequirementNode orphan = roots.last;
      expect(orphan.name, 'catalog_test');
      expect(orphan.type, 'feature');
      expect(orphan.children, isEmpty);
      expect(
        roots.map((RequirementNode r) => r.type),
        <String>['epic', 'feature'],
        reason: 'epics come first, then the features belonging to none',
      );
    });

    test('a test belongs to exactly one feature', () {
      expect(
        featuresIn(roots).map((RequirementNode f) => f.cases.length),
        <int>[1, 1],
      );
    });
  });

  group('coverage, rolled up', () {
    test('an epic counts the tests of its features', () {
      final RequirementNode epic = roots.first;
      expect(epic.cases, isEmpty, reason: 'tests hang off features');
      expect(epic.testCount, 1);
      expect(epic.counts['SUCCESS'], 1);
      expect(epic.passRate, 100);
    });

    test('the verdict of a requirement is the worst under it', () {
      expect(roots.first.result, 'SUCCESS');
      expect(roots.last.result, 'ERROR');
      expect(resultSeverity.first, 'FAILURE', reason: 'worst first');
    });

    test('a requirement with no tests has no pass rate at all', () {
      final RequirementNode empty = RequirementNode(
        name: 'Untested',
        type: 'feature',
      );
      expect(empty.testCount, 0);
      expect(empty.passRate, isNull);
      expect(empty.result, 'UNDEFINED');
      expect(
        featuresHtml(
          <RequirementNode>[empty],
          platform: 'web',
          generatedAt: DateTime.utc(2026),
        ),
        contains('No tests'),
        reason: 'an empty track, not a full bar of some default colour',
      );
    });
  });

  group('features.html', () {
    test('lists the whole tree, features indented under their epic', () {
      expect(featuresPage, contains('>Access<'));
      expect(featuresPage, contains('Authentication'));
      expect(
        featuresPage,
        contains('class="requirement-row level-0 epic-row"'),
      );
      expect(
        featuresPage,
        contains('class="requirement-row level-1 feature-row"'),
      );
      expect(featuresPage, contains('1 epic, 2 features'));
    });

    test('every feature links to its own page, and the page exists', () {
      for (final RequirementNode feature in featuresIn(roots)) {
        expect(featuresPage, contains('href="${featureReportName(feature)}"'));
        expect(
          File('${results.path}/${featureReportName(feature)}').existsSync(),
          isTrue,
        );
      }
    });

    test('can be searched, and a match keeps the epic it belongs to', () {
      expect(featuresPage, contains('class="feature-filter"'));
      // The three things the filter reads off the rows: which are features,
      // what each is called, and whose they are.
      expect(featuresPage, contains('data-name="authentication"'));
      expect(featuresPage, contains('data-of="req-access"'));
      expect(featuresPage, contains('data-features="2"'));
      expect(
        featuresPage,
        isNot(contains('class="pagination"')),
        reason: 'paging a tree orphans a feature from its epic',
      );
    });

    test('is called Features wherever the reader can see it', () {
      expect(
        File('${results.path}/capabilities.html').existsSync(),
        isFalse,
        reason: 'the page was renamed, not copied',
      );
      expect(featuresPage, contains('<h2>Features</h2>'));
      expect(
        featuresPage,
        contains('<a href="index.html">Home</a> &gt; Features'),
      );
      expect(featuresPage, contains('<li class="active"><a href="#">Features'));
      expect(
        featuresPage,
        isNot(contains('Requirements')),
        reason: 'one word for it: menu, heading and breadcrumb alike',
      );
      final String featurePage = File(
        '${results.path}/${featureReportName(featuresIn(roots).first)}',
      ).readAsStringSync();
      expect(featurePage, contains('<a href="features.html">Features</a>'));
      expect(featurePage, isNot(contains('Requirements')));
    });

    test('shows a coverage bar whose widths are the share of each verdict', () {
      expect(featuresPage, contains('class="progress-bar"'));
      expect(featuresPage, contains('width:100.0000%'));
      expect(featuresPage, contains('title="SUCCESS: 1 of 1"'));
    });
  });

  group('a feature page', () {
    test('lists its scenarios, each linking to its test page', () {
      final RequirementNode feature = roots.first.children.single;
      final String page = File(
        '${results.path}/${featureReportName(feature)}',
      ).readAsStringSync();
      expect(page, contains('logs in with the seeded demo account'));
      expect(page, contains('href="${htmlReportName(run.cases.first)}"'));
      expect(page, contains('1 test, 100% passing'));
    });

    test('a description its scenarios agree on becomes the narrative', () {
      final RequirementNode feature = roots.first.children.single;
      expect(feature.narrative, 'The door to everything else.');
      final String page = File(
        '${results.path}/${featureReportName(feature)}',
      ).readAsStringSync();
      expect(
        page,
        contains(
          '<div class="requirement-narrative">The door to everything else.',
        ),
      );
    });

    test('descriptions that differ stay with their own scenario', () {
      final RequirementNode feature = RequirementNode(
        name: 'Checkout',
        type: 'feature',
        cases: <RunCase>[
          for (final String description in <String>['pays', 'refunds'])
            RunCase(
              suite: 'checkout_test',
              name: 'the case that $description',
              status: RunStatus.passed,
              start: 0,
              stop: 1,
              thread: 'worker-0',
              meta: ScenarioMeta(
                feature: 'Checkout',
                description: 'It $description.',
              ),
            ),
        ],
      );
      expect(
        feature.narrative,
        isNull,
        reason: 'two statements about two tests are not one about the feature',
      );
      final String page = featurePageHtml(
        feature,
        platform: 'web',
        generatedAt: DateTime.utc(2026),
      );
      expect(page, isNot(contains('requirement-narrative')));
      expect(page, contains('<div class="scenario-narrative">It pays.</div>'));
      expect(
        page,
        contains('<div class="scenario-narrative">It refunds.</div>'),
      );
    });
  });

  group('the menu and the dashboard', () {
    test('Features is a live link now, not a disabled label', () {
      final String index = File(
        '${results.path}/index.html',
      ).readAsStringSync();
      expect(index, contains('href="features.html"'));
      expect(index, isNot(contains('Available in a later phase')));
    });

    test('a row of the coverage panel leads to that one, not to all of '
        'them', () {
      final String index = File(
        '${results.path}/index.html',
      ).readAsStringSync();
      // An epic has no page of its own, so it lands on its row in the tree;
      // a feature does, and that is where its scenarios are. Sending both to
      // the top of a page listing every feature answers a question nobody
      // asked.
      expect(index, contains('href="features.html#req-access"'));
      expect(
        index,
        contains('href="${featureReportName(roots.last)}"'),
        reason: 'the orphan feature at the root has a page of its own',
      );
    });

    test('lists the features under their epic, not just the epics', () {
      final String index = File(
        '${results.path}/index.html',
      ).readAsStringSync();
      // A project that declares epics used to get a panel of two rows leading
      // to a page of everything. The feature is what a reader clicks.
      final RequirementNode feature = roots.first.children.single;
      expect(index, contains('href="${featureReportName(feature)}"'));
      expect(index, contains('class="requirement-row level-1"'));
    });

    test('an epic folds its features away, and a short panel starts open', () {
      final String index = File(
        '${results.path}/index.html',
      ).readAsStringSync();
      expect(index, contains('data-fold="req-access"'));
      expect(index, contains('data-under="req-access"'));
      expect(index, contains('aria-expanded="true"'));
      expect(
        index,
        isNot(contains('data-under="req-access" hidden')),
        reason: 'two rows need no folding to be readable',
      );
    });

    test('the dashboard summarises coverage per root of the tree', () {
      final String index = File(
        '${results.path}/index.html',
      ).readAsStringSync();
      expect(index, contains('Functional Coverage'));
    });
  });

  group('branding', () {
    test('no design source name, and no external URL', () {
      expect(featuresPage.toLowerCase(), isNot(contains('serenity')));
      expect(featuresPage, isNot(contains('http://')));
      expect(featuresPage, isNot(contains('https://')));
    });
  });
}
