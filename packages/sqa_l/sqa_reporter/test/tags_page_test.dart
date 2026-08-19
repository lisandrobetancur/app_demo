import 'dart:io';

import 'package:sqa_reporter/sqa_reporter.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// Tags lead somewhere: the cloud and the badges point at a page listing the
/// scenarios that carried the tag, which is the selection the runner would
/// have run for it.
void main() {
  late Directory out;
  late Directory results;
  late ParsedRun run;

  setUpAll(() {
    out = Directory.systemTemp.createTempSync('sqa_tags_test');
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
    writeTagPages(
      run,
      results,
      platform: 'web',
      generatedAt: DateTime.utc(2026, 8, 18, 10, 5),
    );
  });

  tearDownAll(() => out.deleteSync(recursive: true));

  group('the tag index', () {
    test('groups the cases by the tags they declared', () {
      final Map<String, List<RunCase>> byTag = tagsOf(run);
      expect(byTag.keys, <String>['smoke_test', 'success']);
      expect(byTag['smoke_test'], hasLength(1));
      expect(
        byTag['smoke_test']!.single.name,
        'logs in with the seeded demo account',
      );
    });

    test('a run with no tags produces no pages', () {
      final ParsedRun untagged = ParsedRun(
        cases: <RunCase>[
          RunCase(
            suite: 'plain_test',
            name: 'declares nothing',
            status: RunStatus.passed,
            start: 0,
            stop: 1,
            thread: 'worker-0',
          ),
        ],
      );
      expect(tagsOf(untagged), isEmpty);
      final Directory empty = Directory('${out.path}/empty');
      expect(writeTagPages(untagged, empty, platform: 'web'), isEmpty);
    });
  });

  group('a tag page', () {
    test('exists for every tag and lists its scenarios', () {
      for (final MapEntry<String, List<RunCase>> entry in tagsOf(run).entries) {
        final File page = File('${results.path}/${tagReportName(entry.key)}');
        expect(page.existsSync(), isTrue);
        final String html = page.readAsStringSync();
        expect(html, contains('<h2>${entry.key}</h2>'));
        for (final RunCase testCase in entry.value) {
          expect(html, contains(testCase.name));
          expect(html, contains('href="${htmlReportName(testCase)}"'));
        }
      }
    });

    test('summarises how the selection did', () {
      final String html = File(
        '${results.path}/${tagReportName('smoke_test')}',
      ).readAsStringSync();
      expect(html, contains('Tag · 1 test, 100% passing'));
    });
  });

  group('what points at it', () {
    test('the dashboard cloud links each tag to its page', () {
      final String index = File(
        '${results.path}/index.html',
      ).readAsStringSync();
      for (final String tag in tagsOf(run).keys) {
        expect(
          index,
          contains('href="${tagReportName(tag)}"'),
          reason: 'a tag that leads nowhere is decoration',
        );
      }
    });

    test('a test page links its own tag badges, and only those', () {
      final String page = File(
        '${results.path}/${htmlReportName(run.cases.first)}',
      ).readAsStringSync();
      expect(page, contains('href="${tagReportName('smoke_test')}"'));
      expect(
        page,
        contains('<span class="tag-badge">Access (epic)</span>'),
        reason: 'epic, feature, severity and context have nowhere else to go',
      );
    });
  });

  group('branding', () {
    test('no design source name, and no external URL', () {
      final String html = File(
        '${results.path}/${tagReportName('success')}',
      ).readAsStringSync();
      expect(html.toLowerCase(), isNot(contains('serenity')));
      expect(html, isNot(contains('http://')));
      expect(html, isNot(contains('https://')));
    });
  });
}
