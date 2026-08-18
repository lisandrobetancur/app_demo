import 'dart:io';

import 'package:sqa_reporter/sqa_reporter.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// The gallery against the presentation it replicates: one slide per capture
/// with the owning step as its caption, numbered bullets, prev/next controls,
/// the deep link a thumbnail arrives on, and a page only where there is
/// something to show.
void main() {
  late Directory out;
  late Directory results;
  late ParsedRun run;
  late RunCase passing;
  late RunCase broken;
  late String gallery;

  setUpAll(() {
    out = Directory.systemTemp.createTempSync('sqa_gallery_test');
    results = Directory('${out.path}/results');
    final File input = File('${out.path}/results.json')
      ..writeAsStringSync(playwrightReport());
    run = parsePlaywright(input);
    passing = run.cases.first;
    broken = run.cases.last;
    writeSerenityResults(run, results, platform: 'web');
    writeTestPages(
      run,
      results,
      platform: 'web',
      generatedAt: DateTime.utc(2026, 8, 18, 10, 5),
    );
    writeScreenshotPages(
      run,
      results,
      platform: 'web',
      generatedAt: DateTime.utc(2026, 8, 18, 10, 5),
    );
    gallery = File(
      '${results.path}/${screenshotsReportName(passing)}',
    ).readAsStringSync();
  });

  tearDownAll(() => out.deleteSync(recursive: true));

  group('the files', () {
    test('one gallery per test that captured something, and none for the '
        'tests that did not', () {
      expect(
        File('${results.path}/${screenshotsReportName(passing)}').existsSync(),
        isTrue,
      );
      expect(capturesOf(broken), isEmpty);
      expect(
        File('${results.path}/${screenshotsReportName(broken)}').existsSync(),
        isFalse,
      );
    });

    test('is named by the same digest as the test it belongs to', () {
      expect(
        screenshotsReportName(passing),
        '${reportDigest(passing)}_screenshots.html',
      );
    });
  });

  group('the carousel', () {
    test('holds one slide per capture, first one visible', () {
      final List<Capture> captures = capturesOf(passing);
      expect(captures, hasLength(2));
      expect(gallery, contains('data-count="2"'));
      expect(gallery, contains('<figure class="slide" data-slide="0">'));
      expect(
        gallery,
        contains('<figure class="slide" data-slide="1" hidden>'),
        reason: 'only the first slide shows before the script runs',
      );
    });

    test('captions each slide with the step that took the capture', () {
      expect(gallery, contains('Log in as the demo user'));
    });

    test('shows the images the JSON references, and they exist', () {
      final Map<CapturedShot, String> names = shotNamesFor(passing);
      expect(names, hasLength(2));
      for (final String file in names.values) {
        expect(gallery, contains('src="$file"'));
        expect(File('${results.path}/$file').existsSync(), isTrue);
      }
    });

    test('has numbered bullets and prev/next controls', () {
      expect(gallery, contains('<button class="bullet active" data-goto="0"'));
      expect(gallery, contains('data-goto="1"'));
      expect(gallery, contains('class="carousel-prev"'));
      expect(gallery, contains('class="carousel-next"'));
    });
  });

  group('the link from the step table', () {
    test('a thumbnail opens the gallery at its own capture', () {
      final String page = File(
        '${results.path}/${htmlReportName(passing)}',
      ).readAsStringSync();
      final List<Capture> captures = capturesOf(passing);
      for (int i = 0; i < captures.length; i += 1) {
        expect(
          page,
          contains('href="${screenshotsReportName(passing)}?screenshot=$i"'),
        );
      }
    });

    test('the page also offers the gallery as a whole', () {
      final String page = File(
        '${results.path}/${htmlReportName(passing)}',
      ).readAsStringSync();
      expect(page, contains('View all 2 screenshots'));
    });

    test('the gallery links back to the test it belongs to', () {
      expect(gallery, contains('href="${htmlReportName(passing)}"'));
    });
  });

  group('captures', () {
    test('are ordered children-first, matching the JSON writer', () {
      final List<Capture> captures = capturesOf(passing);
      expect(captures.map((Capture c) => c.shot.name), <String>[
        'before_login',
        'after_login',
      ]);
      expect(captures.every((Capture c) => c.depth == 0), isTrue);
    });

    test('a nested step contributes its depth to the caption', () {
      final StepNode child = StepNode(
        name: 'inner',
        kind: StepKind.business,
        start: 0,
        stop: 1,
        shots: <CapturedShot>[
          CapturedShot(
            name: 'inner_shot',
            bytes: passing.steps.first.shots.first.bytes,
          ),
        ],
      );
      final RunCase nested = RunCase(
        suite: 'nested_test',
        name: 'has a nested capture',
        status: RunStatus.passed,
        start: 0,
        stop: 2,
        thread: 'worker-0',
        steps: <StepNode>[
          StepNode(
            name: 'outer',
            kind: StepKind.business,
            start: 0,
            stop: 2,
            children: <StepNode>[child],
          ),
        ],
      );
      expect(capturesOf(nested).single.depth, 1);
      expect(
        screenshotsPageHtml(
          nested,
          platform: 'web',
          generatedAt: DateTime.utc(2026),
        ),
        contains('› inner'),
        reason: 'one chevron per level, as the reference marks depth',
      );
    });
  });

  group('branding', () {
    test('no design source name, and no external URL', () {
      expect(gallery.toLowerCase(), isNot(contains('serenity')));
      expect(gallery, isNot(contains('http://')));
      expect(gallery, isNot(contains('https://')));
    });
  });
}
