/// The screenshots gallery: one page per test that captured anything,
/// `<digest>_screenshots.html`, reached from the thumbnails in the step table.
///
/// The reference presents captures as a carousel — one image at a time, with
/// prev/next controls, numbered bullets, keyboard navigation and a
/// `?screenshot=N` deep link so a thumbnail opens the gallery *at* its own
/// capture. It builds that on a third-party carousel library; this is the same
/// presentation written here in about forty lines of CSS and thirty of script,
/// which keeps the site free of libraries and of anything to attribute.
library;

import 'dart:io';

import '../markers.dart';
import '../model.dart';
import '../serenity_writer.dart';
import 'dashboard.dart' show escapeHtml, resultIcon;
import 'page_chrome.dart';
import 'requirements_page.dart' show featureReportNameOf;
import 'site_assets.dart';

/// `<digest>_screenshots.html` — the gallery for one test.
String screenshotsReportName(RunCase testCase) =>
    '${reportDigest(testCase)}_screenshots.html';

/// Writes a gallery page for every case that captured at least one
/// screenshot. Returns the files written.
List<File> writeScreenshotPages(
  ParsedRun run,
  Directory outputDir, {
  required String platform,
  String? title,
  DateTime? generatedAt,
}) {
  outputDir.createSync(recursive: true);
  final DateTime stamp = generatedAt ?? DateTime.now().toUtc();
  return <File>[
    for (final RunCase testCase in run.cases)
      if (capturesOf(testCase).isNotEmpty)
        File(
          '${outputDir.path}${Platform.pathSeparator}'
          '${screenshotsReportName(testCase)}',
        )..writeAsStringSync(
          screenshotsPageHtml(
            testCase,
            platform: platform,
            title: title,
            generatedAt: stamp,
          ),
        ),
  ];
}

/// The page itself, as a string — separated from the file write so tests can
/// assert on content without a filesystem.
String screenshotsPageHtml(
  RunCase testCase, {
  required String platform,
  required DateTime generatedAt,
  String? title,
}) {
  final RunStatus status = promoteStatus(testCase.status, testCase.steps);
  final String result = serenityResult[status]!;
  final String feature = testCase.meta?.feature ?? testCase.suite;
  final List<Capture> captures = capturesOf(testCase);
  final Map<CapturedShot, String> shotNames = shotNamesFor(testCase);

  final StringBuffer page = StringBuffer()
    ..writeln('<!DOCTYPE html>')
    ..writeln('<html lang="en">')
    ..write(pageHead())
    ..writeln('<body>')
    ..write(banner(platform, title: title))
    ..writeln('<div class="middlecontent">')
    ..writeln(
      '<span class="breadcrumbs"><a href="index.html">Home</a> &gt; '
      '<a href="${featureReportNameOf(feature)}">'
      '${escapeHtml(feature)}</a> &gt; '
      '<a href="${htmlReportName(testCase)}">'
      '${escapeHtml(testCase.name)}</a> &gt; Screenshots</span>',
    )
    ..write(menuBar(generatedAt, homeActive: false))
    ..writeln('<div class="titlebar">')
    ..writeln('<div class="test-title-bar test-$result">')
    ..writeln(resultIcon(result))
    ..writeln(
      '<span class="test-case-title ${result.toLowerCase()}-color">'
      '${escapeHtml(testCase.name)}</span>',
    )
    ..writeln('</div>')
    ..writeln('</div>')
    ..write(_failurePanel(testCase, result))
    ..writeln('<div class="card standalone">')
    ..write(_carousel(captures, shotNames, result))
    ..writeln('</div>')
    ..writeln('</div>')
    ..write(pageFooter())
    ..writeln('<script>$siteJs</script>')
    ..writeln('</body>')
    ..writeln('</html>');
  return page.toString();
}

/// Above the carousel on a test that did not pass: the concise error, so the
/// reader sees what went wrong beside the picture of it going wrong.
String _failurePanel(RunCase testCase, String result) {
  if (testCase.failureMessage == null) {
    return '';
  }
  return '<div class="screenshot-failure test-$result">'
      '<pre>${escapeHtml(testCase.failureMessage!)}</pre></div>\n';
}

String _carousel(
  List<Capture> captures,
  Map<CapturedShot, String> shotNames,
  String result,
) {
  final StringBuffer slides = StringBuffer();
  final StringBuffer bullets = StringBuffer();

  for (int i = 0; i < captures.length; i += 1) {
    final Capture capture = captures[i];
    final String file = shotNames[capture.shot]!;
    // The reference marks the last capture of a failing test with the
    // verdict: it is the picture of the state the test died in.
    final bool isLast = i == captures.length - 1;
    final String verdict = isLast && result != 'SUCCESS'
        ? ': <span class="${result.toLowerCase()}-color">$result</span>'
        : '';
    // Depth is shown the way the reference does it, as a chevron per level,
    // so a capture from a nested step reads as nested.
    final String depth = '›' * capture.depth;
    final String caption =
        '${depth.isEmpty ? '' : '$depth '}'
        '${escapeHtml(stepDescription(capture.step))}$verdict';

    slides.writeln(
      '<figure class="slide" data-slide="$i"${i == 0 ? '' : ' hidden'}>'
      '<img src="$file" alt="${escapeHtml(capture.shot.name)}"/>'
      '<figcaption>$caption</figcaption>'
      '</figure>',
    );
    bullets.write(
      '<button class="bullet${i == 0 ? ' active' : ''}" '
      'data-goto="$i" title="${escapeHtml(capture.shot.name)}">'
      '${i + 1}</button>',
    );
  }

  return '''
<div class="carousel" data-count="${captures.length}">
  <div class="slides">
$slides  </div>
  <div class="carousel-controls">
    <button class="carousel-prev" title="Previous screenshot">‹</button>
    <div class="bullets">$bullets</div>
    <button class="carousel-next" title="Next screenshot">›</button>
  </div>
</div>
''';
}
