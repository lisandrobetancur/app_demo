/// The requirements pages: `capabilities.html` — the whole epic → feature
/// tree with coverage rolled up — and one page per feature listing the
/// scenarios under it.
///
/// The reference splits this across a page per requirement type and a page
/// per requirement, because its trees run three levels deep and a single
/// table would not fit. Ours is two levels, so the top page shows the whole
/// tree at once — an epic row with its features indented beneath it — and
/// only a feature, which holds the scenarios, earns a page of its own.
///
/// The columns are the reference's: tests, scenarios, % pass, the verdict
/// icon, and a segmented bar whose widths are the share of each verdict.
library;

import 'dart:io';

import '../markers.dart';
import '../model.dart';
import '../requirements.dart';
import '../serenity_writer.dart';
import 'dashboard.dart' show compoundDuration, escapeHtml, resultIcon;
import 'page_chrome.dart';
import 'site_assets.dart';

/// `<slug>_feature.html` — one feature's page.
String featureReportName(RequirementNode feature) =>
    featureReportNameOf(feature.name);

/// The same name from the feature's name alone, for the pages that know what
/// feature a test belongs to but not the tree it sits in — a breadcrumb, for
/// one. Both go through `slugOf`, so they cannot drift apart.
String featureReportNameOf(String featureName) =>
    '${slugOf(featureName)}_feature.html';

/// Writes `capabilities.html` and one page per feature. Returns the files
/// written, the tree's own page first.
List<File> writeRequirementPages(
  ParsedRun run,
  Directory outputDir, {
  required String platform,
  String? title,
  Duration offset = reportOffset,
  DateTime? generatedAt,
}) {
  outputDir.createSync(recursive: true);
  final DateTime stamp = generatedAt ?? DateTime.now().toUtc();
  final List<RequirementNode> roots = requirementsOf(run);

  return <File>[
    File('${outputDir.path}${Platform.pathSeparator}capabilities.html')
      ..writeAsStringSync(
        capabilitiesHtml(
          roots,
          platform: platform,
          title: title,
          offset: offset,
          generatedAt: stamp,
        ),
      ),
    for (final RequirementNode feature in featuresIn(roots))
      File(
        '${outputDir.path}${Platform.pathSeparator}'
        '${featureReportName(feature)}',
      )..writeAsStringSync(
        featurePageHtml(
          feature,
          platform: platform,
          title: title,
          offset: offset,
          generatedAt: stamp,
        ),
      ),
  ];
}

/// The requirements overview: the whole tree, with each row's coverage.
String capabilitiesHtml(
  List<RequirementNode> roots, {
  required String platform,
  required DateTime generatedAt,
  String? title,
  Duration offset = reportOffset,
}) {
  final int featureCount = featuresIn(roots).length;
  final int epicCount = roots
      .where((RequirementNode root) => root.type == 'epic')
      .length;

  final StringBuffer rows = StringBuffer();
  for (final RequirementNode root in roots) {
    rows.write(_row(root, level: 0));
    for (final RequirementNode child in root.children) {
      rows.write(_row(child, level: 1));
    }
  }

  final StringBuffer page = StringBuffer()
    ..writeln('<!DOCTYPE html>')
    ..writeln('<html lang="en">')
    ..write(pageHead())
    ..writeln('<body>')
    ..write(banner(platform, title: title))
    ..writeln('<div class="middlecontent">')
    ..writeln(
      '<span class="breadcrumbs"><a href="index.html">Home</a> &gt; '
      'Requirements</span>',
    )
    ..write(
      menuBar(
        generatedAt,
        homeActive: false,
        requirementsActive: true,
        offset: offset,
      ),
    )
    ..writeln('<h2>Requirements</h2>')
    ..writeln(
      '<div class="test-count-title">'
      '$epicCount epic${epicCount == 1 ? '' : 's'}, '
      '$featureCount feature${featureCount == 1 ? '' : 's'}</div>',
    )
    ..writeln('<div class="card standalone">')
    ..writeln('<div class="table-scroll">')
    ..writeln('<table class="table requirements-table">')
    ..writeln(
      '<thead><tr><th class="requirement-name-column">Requirement</th>'
      '<th>Type</th><th>Tests</th><th>% Pass</th><th>Result</th>'
      '<th class="coverage-column">Coverage</th></tr></thead>',
    )
    ..writeln('<tbody>')
    ..write(rows)
    ..writeln('</tbody>')
    ..writeln('</table>')
    ..writeln('</div>')
    ..writeln('</div>')
    ..writeln('</div>')
    ..write(pageFooter())
    ..writeln('<script>$siteJs</script>')
    ..writeln('</body>')
    ..writeln('</html>');
  return page.toString();
}

/// One feature's page: what it is, how it did, and the scenarios under it.
String featurePageHtml(
  RequirementNode feature, {
  required String platform,
  required DateTime generatedAt,
  String? title,
  Duration offset = reportOffset,
}) {
  final List<RunCase> cases = feature.allCases
    ..sort((RunCase a, RunCase b) => a.name.compareTo(b.name));

  // A description shared by every scenario describes the feature and is shown
  // once, above; descriptions that differ describe their own test and are
  // shown on their own row.
  final String? narrative = feature.narrative;

  final StringBuffer scenarios = StringBuffer();
  for (final RunCase testCase in cases) {
    final String result =
        serenityResult[promoteStatus(testCase.status, testCase.steps)]!;
    final ({int start, int stop}) bounds = widenedBoundsOf(testCase);
    final String? own = narrative == null ? testCase.meta?.description : null;
    scenarios.writeln(
      '<tr>'
      '<td><a href="${htmlReportName(testCase)}">'
      '${escapeHtml(testCase.name)}</a>'
      '${own == null ? '' : '<div class="scenario-narrative">'
                '${escapeHtml(own)}</div>'}</td>'
      '<td>${testCase.steps.length}</td>'
      '<td>${compoundDuration(bounds.stop - bounds.start)}</td>'
      '<td><a href="${htmlReportName(testCase)}">'
      '${resultIcon(result)}</a></td>'
      '</tr>',
    );
  }

  final StringBuffer page = StringBuffer()
    ..writeln('<!DOCTYPE html>')
    ..writeln('<html lang="en">')
    ..write(pageHead())
    ..writeln('<body>')
    ..write(banner(platform, title: title))
    ..writeln('<div class="middlecontent">')
    ..writeln(
      '<span class="breadcrumbs"><a href="index.html">Home</a> &gt; '
      '<a href="capabilities.html">Requirements</a> &gt; '
      '${escapeHtml(feature.name)}</span>',
    )
    ..write(
      menuBar(
        generatedAt,
        homeActive: false,
        requirementsActive: true,
        offset: offset,
      ),
    )
    ..writeln('<h2>${escapeHtml(feature.name)}</h2>')
    ..writeln('<div class="test-count-title">Feature · ${_summary(feature)}')
    ..writeln('</div>')
    ..write(
      narrative == null
          ? ''
          : '<div class="requirement-narrative">'
                '${escapeHtml(narrative)}</div>\n',
    )
    ..writeln('<div class="card standalone">')
    ..writeln('<div class="feature-coverage">${_coverageBar(feature)}</div>')
    ..writeln('<h3>Scenarios</h3>')
    ..writeln('<table class="table table-striped">')
    ..writeln(
      '<thead><tr><th>Scenario</th><th>Steps</th><th>Duration</th>'
      '<th>Result</th></tr></thead>',
    )
    ..writeln('<tbody>')
    ..write(scenarios)
    ..writeln('</tbody>')
    ..writeln('</table>')
    ..writeln('</div>')
    ..writeln('</div>')
    ..write(pageFooter())
    ..writeln('<script>$siteJs</script>')
    ..writeln('</body>')
    ..writeln('</html>');
  return page.toString();
}

String _summary(RequirementNode node) {
  final int total = node.testCount;
  final double? rate = node.passRate;
  return '$total test${total == 1 ? '' : 's'}, '
      '${rate == null ? 'none run' : '${rate.round()}% passing'}';
}

String _row(RequirementNode node, {required int level}) {
  final double? rate = node.passRate;
  final String name = level == 0 && node.type == 'epic'
      ? escapeHtml(node.name)
      : '<a href="${featureReportName(node)}">${escapeHtml(node.name)}</a>';
  return '<tr class="requirement-row level-$level">'
      '<td class="requirement-name-column" '
      'style="padding-left:${0.75 + level * 1.5}em">$name</td>'
      '<td class="requirement-type">${node.type}</td>'
      '<td>${node.testCount}</td>'
      '<td>${rate == null ? '—' : '${rate.round()}%'}</td>'
      '<td>${resultIcon(node.result)}</td>'
      '<td class="coverage-column">${_coverageBar(node)}</td>'
      '</tr>\n';
}

/// The segmented bar: one slice per verdict, its width the share of tests
/// that ended that way. A requirement with no tests shows an empty track
/// rather than a full one of some default colour.
String _coverageBar(RequirementNode node) {
  final int total = node.testCount;
  if (total == 0) {
    return '<div class="progress" title="No tests"></div>';
  }
  final Map<String, int> tally = node.counts;
  final StringBuffer bar = StringBuffer('<div class="progress">');
  for (final String result in resultColors.keys) {
    final int count = tally[result] ?? 0;
    if (count == 0) {
      continue;
    }
    final double percentage = count * 100 / total;
    bar.write(
      '<div class="progress-bar" '
      'style="width:${percentage.toStringAsFixed(4)}%;'
      'background-color:${resultColors[result]!.solid}" '
      'title="$result: $count of $total"></div>',
    );
  }
  bar.write('</div>');
  return bar.toString();
}

/// The dashboard's functional-coverage panel: the same tree, summarised, on
/// the page a reader opens first.
String coverageOverview(List<RequirementNode> roots) {
  if (roots.isEmpty) {
    return '';
  }
  final StringBuffer rows = StringBuffer();
  for (final RequirementNode root in roots) {
    rows.writeln(
      '<tr>'
      '<td><a href="capabilities.html">${escapeHtml(root.name)}</a></td>'
      '<td>${root.testCount}</td>'
      '<td>${root.passRate == null ? '—' : '${root.passRate!.round()}%'}</td>'
      '<td class="coverage-column">${_coverageBar(root)}</td>'
      '</tr>',
    );
  }
  return '''
<h4>Functional Coverage</h4>
<table class="table requirements-table">
<thead><tr><th>Requirement</th><th>Tests</th><th>% Pass</th>
<th class="coverage-column">Coverage</th></tr></thead>
<tbody>
$rows</tbody>
</table>
''';
}
