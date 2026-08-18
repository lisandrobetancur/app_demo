import 'dart:io';

import 'package:sqa_reporter/sqa_reporter.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// The requirements tree and its pages: how the epic → feature hierarchy is
/// built from what `scenario()` declared, how coverage rolls up a branch, and
/// what the pages do with a requirement nobody tested.
void main() {
  late Directory out;
  late Directory results;
  late ParsedRun run;
  late List<RequirementNode> roots;
  late String capabilities;

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
    writeRequirementPages(
      run,
      results,
      platform: 'web',
      generatedAt: DateTime.utc(2026, 8, 18, 10, 5),
    );
    capabilities = File('${results.path}/capabilities.html').readAsStringSync();
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
        capabilitiesHtml(
          <RequirementNode>[empty],
          platform: 'web',
          generatedAt: DateTime.utc(2026),
        ),
        contains('No tests'),
        reason: 'an empty track, not a full bar of some default colour',
      );
    });
  });

  group('capabilities.html', () {
    test('lists the whole tree, features indented under their epic', () {
      expect(capabilities, contains('>Access<'));
      expect(capabilities, contains('Authentication'));
      expect(capabilities, contains('class="requirement-row level-0"'));
      expect(capabilities, contains('class="requirement-row level-1"'));
      expect(capabilities, contains('1 epic, 2 features'));
    });

    test('every feature links to its own page, and the page exists', () {
      for (final RequirementNode feature in featuresIn(roots)) {
        expect(capabilities, contains('href="${featureReportName(feature)}"'));
        expect(
          File('${results.path}/${featureReportName(feature)}').existsSync(),
          isTrue,
        );
      }
    });

    test('shows a coverage bar whose widths are the share of each verdict', () {
      expect(capabilities, contains('class="progress-bar"'));
      expect(capabilities, contains('width:100.0000%'));
      expect(capabilities, contains('title="SUCCESS: 1 of 1"'));
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
  });

  group('the menu and the dashboard', () {
    test('Requirements is a live link now, not a disabled label', () {
      final String index = File(
        '${results.path}/index.html',
      ).readAsStringSync();
      expect(index, contains('href="capabilities.html"'));
      expect(index, isNot(contains('Available in a later phase')));
    });

    test('the dashboard summarises coverage per root requirement', () {
      final String index = File(
        '${results.path}/index.html',
      ).readAsStringSync();
      expect(index, contains('Functional Coverage'));
    });
  });

  group('branding', () {
    test('no design source name, and no external URL', () {
      expect(capabilities.toLowerCase(), isNot(contains('serenity')));
      expect(capabilities, isNot(contains('http://')));
      expect(capabilities, isNot(contains('https://')));
    });
  });
}
