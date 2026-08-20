/// The test detail page: one HTML file per test, named by the same digest as
/// its JSON result, so the two always pair without an index.
///
/// The layout follows the reference detail page part for part — the story
/// header with the tag badges on the right, the result icon beside the title
/// coloured by outcome, the step table with nested groups collapsed behind a
/// caret and indented twenty pixels per level, the error row under the step
/// that failed, and screenshot thumbnails on the step that captured them.
/// Every line of markup is authored here.
library;

import 'dart:io';

import '../markers.dart';
import '../model.dart';
import '../results_writer.dart';
import 'dashboard.dart' show compoundDuration, escapeHtml, resultIcon, stepIcon;
import 'features_page.dart' show featureReportNameOf;
import 'page_chrome.dart';
import 'screenshots_page.dart' show screenshotsReportName;
import 'site_assets.dart';
import 'tags_page.dart' show tagReportName;

/// Writes one detail page per case into [outputDir], beside the JSON results
/// and the screenshots they reference. Returns the files written.
List<File> writeTestPages(
  ParsedRun run,
  Directory outputDir, {
  required String platform,
  Duration offset = reportOffset,
  DateTime? generatedAt,
}) {
  outputDir.createSync(recursive: true);
  final DateTime stamp = generatedAt ?? DateTime.now().toUtc();
  return <File>[
    for (final RunCase testCase in run.cases)
      File(
        '${outputDir.path}${Platform.pathSeparator}'
        '${htmlReportName(testCase)}',
      )..writeAsStringSync(
        testPageHtml(
          testCase,
          platform: platform,
          offset: offset,
          generatedAt: stamp,
        ),
      ),
  ];
}

/// The page itself, as a string — separated from the file write so tests can
/// assert on content without a filesystem.
String testPageHtml(
  RunCase testCase, {
  required String platform,
  required DateTime generatedAt,
  Duration offset = reportOffset,
}) {
  final RunStatus status = promoteStatus(testCase.status, testCase.steps);
  final String result = resultName[status]!;
  final String feature = testCase.meta?.feature ?? testCase.suite;
  final Map<CapturedShot, String> shotNames = shotNamesFor(testCase);
  final List<StepNode> steps = presentedStepsOf(testCase);
  final bool hasShots = shotNames.isNotEmpty;

  // A thumbnail opens the gallery *at its own capture*, so the index a shot
  // has there is the index it links to here. Same traversal, same numbers.
  final List<Capture> captures = capturesOf(testCase);
  final Map<CapturedShot, int> slideOf = Map<CapturedShot, int>.identity();
  for (int i = 0; i < captures.length; i += 1) {
    slideOf[captures[i].shot] = i;
  }

  final _StepTable table = _StepTable(
    hasShots: hasShots,
    shotNames: shotNames,
    slideOf: slideOf,
    gallery: screenshotsReportName(testCase),
  );

  final StringBuffer page = StringBuffer()
    ..writeln('<!DOCTYPE html>')
    ..writeln('<html lang="en">')
    ..write(pageHead(platform))
    ..writeln('<body>')
    ..write(banner(platform))
    ..writeln('<div class="middlecontent">')
    ..writeln(
      '<span class="breadcrumbs"><a href="index.html">Home</a> &gt; '
      '<a href="${featureReportNameOf(feature)}">'
      '${escapeHtml(feature)}</a> &gt; '
      '<span class="truncate">${escapeHtml(testCase.name)}</span></span>',
    )
    ..write(menuBar(generatedAt, homeActive: false, offset: offset))
    ..write(_titleBar(testCase, result, feature, platform))
    ..writeln('<div class="card standalone">')
    ..write(
      hasShots
          ? '<p class="gallery-link"><a href="'
                '${screenshotsReportName(testCase)}">'
                'View all ${captures.length} screenshot'
                '${captures.length == 1 ? '' : 's'}</a></p>\n'
          : '',
    )
    ..write(table.render(steps))
    ..write(_failure(testCase, result))
    ..writeln('</div>')
    ..writeln('</div>')
    ..write(hasShots ? shotViewer : '')
    ..write(pageFooter())
    ..writeln('<script>$siteJs</script>')
    ..writeln('</body>')
    ..writeln('</html>');
  return page.toString();
}

String _titleBar(
  RunCase testCase,
  String result,
  String feature,
  String platform,
) {
  final ScenarioMeta? meta = testCase.meta;
  final StringBuffer badges = StringBuffer();
  void badge(String? name, String type) {
    if (name == null) {
      return;
    }
    final String label =
        '${escapeHtml(name)}'
        '${type == 'context' || type == 'tag' ? '' : ' ($type)'}';
    // A declared tag leads to the other tests that carry it; the rest name
    // this test's own taxonomy and have nowhere else to go.
    badges.write(
      type == 'tag'
          ? '<a class="tag-badge" href="${tagReportName(name)}">$label</a> '
          : '<span class="tag-badge">$label</span> ',
    );
  }

  badge(meta?.epic, 'epic');
  badge(feature, 'feature');
  badge(meta?.severity, 'severity');
  badge(platform, 'context');
  for (final String tag in testCase.tags) {
    badge(tag, 'tag');
  }

  final String description = meta?.description == null
      ? ''
      : '<div class="test-description">'
            '${escapeHtml(meta!.description!)}</div>';

  return '''
<div class="titlebar">
  <div class="story-header-row">
    <h3 class="story-header-title">${escapeHtml(feature)}</h3>
    <p class="tags">$badges</p>
  </div>
  <div class="test-title-bar test-$result">
    ${resultIcon(result)}
    <span class="test-case-title ${result.toLowerCase()}-color">
      ${escapeHtml(testCase.name)}
    </span>
    $description
  </div>
</div>
''';
}

/// The step table: recursive rows, a caret that toggles each group's nested
/// table (collapsed by default, as the reference renders them), the run log
/// as evidence under the last top-level step, and per-row outcome and
/// duration.
class _StepTable {
  _StepTable({
    required this.hasShots,
    required this.shotNames,
    required this.slideOf,
    required this.gallery,
  });

  final bool hasShots;
  final Map<CapturedShot, String> shotNames;
  final Map<CapturedShot, int> slideOf;
  final String gallery;
  int _section = 0;

  String render(List<StepNode> steps) {
    final int columns = hasShots ? 4 : 3;
    final StringBuffer table = StringBuffer()
      // Opening a deep tree one caret at a time is the tedious part of
      // reading a failed run, so the whole tree can be opened at once.
      ..writeln('<div class="step-tools">')
      ..writeln('<button class="expand-all">Expand all</button>')
      ..writeln('<button class="collapse-all">Collapse all</button>')
      ..writeln('</div>')
      ..writeln('<table class="step-table">')
      ..writeln(
        '<tr class="step-titles">'
        '<th class="step-description-column">Steps</th>'
        '${hasShots ? '<th class="shot-column">Screenshots</th>' : ''}'
        '<th class="outcome-column">Outcome</th>'
        '<th class="duration-column" title="Duration">Duration</th>'
        '</tr>',
      );
    for (int i = 0; i < steps.length; i += 1) {
      table.write(_stepRows(steps[i], level: 0, columns: columns));
    }
    table.writeln('</table>');
    return table.toString();
  }

  String _stepRows(StepNode step, {required int level, required int columns}) {
    final String result = resultName[step.status]!;
    final bool isGroup = step.children.isNotEmpty;
    final StringBuffer rows = StringBuffer();

    _section += 1;
    final int section = _section;

    // Every row carries its own verdict as a mark, not only as a word in a
    // far column: scanning a tree of forty steps for the one that went wrong
    // should be a glance down the left edge, not a read across each line.
    final String mark = stepIcon(result);
    final String caret = isGroup
        ? '<button class="caret ${result.toLowerCase()}-color" '
              'data-toggle="step-section-$section" '
              'title="Show the steps inside">▸</button>'
        : '<span class="caret-spacer"></span>';

    rows.writeln(
      '<tr class="test-$result step-row level-$level">'
      '<td class="step-description-column">'
      '<div class="step-description">'
      '$caret$mark<span class="step-text">'
      '${escapeHtml(stepDescription(step))}</span></div></td>'
      '${hasShots ? '<td class="shot-column">${_thumbs(step)}</td>' : ''}'
      '<td class="outcome-column ${result.toLowerCase()}-color">$result</td>'
      '<td class="duration-column">'
      '${compoundDuration(step.stop - step.start)}</td>'
      '</tr>',
    );

    if (isGroup) {
      rows.writeln(
        '<tr class="step-section" id="step-section-$section" hidden>'
        '<td colspan="$columns"><table class="step-table nested">',
      );
      for (final StepNode child in step.children) {
        rows.write(_stepRows(child, level: level + 1, columns: columns));
      }
      rows.writeln('</table></td></tr>');
    }
    return rows.toString();
  }

  String _thumbs(StepNode step) => <String>[
    for (final CapturedShot shot in step.shots)
      // Still a link, and still to this capture's place in the gallery: a
      // middle click opens it there, and with no script at all the thumbnail
      // keeps working. A plain click opens the viewer instead, because
      // somebody reading a step wants to see *this* picture, not to leave the
      // page they are reading.
      '<a class="shot-link" href="$gallery?screenshot=${slideOf[shot] ?? 0}" '
          'title="Open this screenshot">'
          '<img class="screenshot" src="${shotNames[shot]}" '
          'alt="${escapeHtml(shot.name)}" width="48" height="48"/></a>',
  ].join(' ');
}

/// The failure block, when the test carries one: the parsed error type and
/// the message.
///
/// No stack trace. A Patrol trace is frames of the test harness and the
/// framework — `element.dart`, `binding.dart`, the runner — and the line that
/// would name your own step is the step the tree already shows as broken. It
/// took a fold on every failing test to say nothing the reader could act on.
/// The full trace stays in the JSON result, for anything that wants it.
String _failure(RunCase testCase, String result) {
  if (testCase.failureMessage == null) {
    return '';
  }
  return '''
<div class="failure-block test-$result">
  <h3 class="${result.toLowerCase()}-color">${escapeHtml(_errorTitle(testCase))}</h3>
  <div class="error-message"><pre>${escapeHtml(testCase.failureMessage!)}</pre></div>
</div>
''';
}

String _errorTitle(RunCase testCase) {
  final RegExpMatch? match = RegExp(
    r'^([A-Z][A-Za-z0-9_]*(?:Error|Exception|Failure))\b',
  ).firstMatch(testCase.failureMessage!.trimLeft());
  return match?.group(1) ?? 'Failed assertion';
}
