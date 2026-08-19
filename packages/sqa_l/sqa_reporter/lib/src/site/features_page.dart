/// The features pages: `features.html` — the whole epic → feature tree with
/// coverage rolled up — and one page per feature listing the scenarios under
/// it.
///
/// "Features" rather than "Requirements" on purpose: what a Patrol suite
/// declares in its metadata is a feature under an epic, and naming the page
/// after what it lists is one less translation for a reader. The tree itself
/// is still the requirements model (`requirements.dart`) — a feature is a
/// requirement, which is why the types kept that name.
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

/// Writes `features.html` and one page per feature. Returns the files
/// written, the tree's own page first.
List<File> writeFeaturePages(
  ParsedRun run,
  Directory outputDir, {
  required String platform,
  Duration offset = reportOffset,
  DateTime? generatedAt,
}) {
  outputDir.createSync(recursive: true);
  final DateTime stamp = generatedAt ?? DateTime.now().toUtc();
  final List<RequirementNode> roots = requirementsOf(run);

  return <File>[
    File('${outputDir.path}${Platform.pathSeparator}features.html')
      ..writeAsStringSync(
        featuresHtml(
          roots,
          platform: platform,
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
          offset: offset,
          generatedAt: stamp,
        ),
      ),
  ];
}

/// The features overview: the whole tree, with each row's coverage.
String featuresHtml(
  List<RequirementNode> roots, {
  required String platform,
  required DateTime generatedAt,
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
    ..write(pageHead(platform))
    ..writeln('<body>')
    ..write(banner(platform))
    ..writeln('<div class="middlecontent">')
    ..writeln(
      '<span class="breadcrumbs"><a href="index.html">Home</a> &gt; '
      'Features</span>',
    )
    ..write(
      menuBar(
        generatedAt,
        homeActive: false,
        featuresActive: true,
        offset: offset,
      ),
    )
    ..writeln('<h2>Features</h2>')
    ..writeln(
      '<div class="test-count-title">'
      '$epicCount epic${epicCount == 1 ? '' : 's'}, '
      '$featureCount feature${featureCount == 1 ? '' : 's'}</div>',
    )
    ..writeln('<div class="card standalone">')
    ..writeln('<div class="table-scroll">')
    ..writeln('<table class="table requirements-table">')
    ..writeln(
      // "Name" over a column that holds both epics and the features under
      // them, with the Type column beside it saying which is which.
      '<thead><tr><th class="requirement-name-column">Name</th>'
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
    ..write(pageHead(platform))
    ..writeln('<body>')
    ..write(banner(platform))
    ..writeln('<div class="middlecontent">')
    ..writeln(
      '<span class="breadcrumbs"><a href="index.html">Home</a> &gt; '
      '<a href="features.html">Features</a> &gt; '
      '${escapeHtml(feature.name)}</span>',
    )
    ..write(
      menuBar(
        generatedAt,
        homeActive: false,
        featuresActive: true,
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
  return '<tr class="requirement-row level-$level" id="${rowAnchorOf(node)}">'
      '<td class="requirement-name-column" '
      'style="padding-left:${0.75 + level * 1.5}em">$name</td>'
      '<td class="requirement-type">${node.type}</td>'
      '<td>${node.testCount}</td>'
      '<td>${rate == null ? '—' : '${rate.round()}%'}</td>'
      '<td>${resultIcon(node.result)}</td>'
      '<td class="coverage-column">${_coverageBar(node)}</td>'
      '</tr>\n';
}

/// Where a row lives on the features page, so the dashboard can land on it.
///
/// An epic has no page of its own — it *is* a branch of the tree — so a link
/// to one has to arrive at the tree and point at the row.
String rowAnchorOf(RequirementNode node) => 'req-${slugOf(node.name)}';

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

/// One line of the dashboard's coverage panel.
///
/// A feature goes to its own page, which is where its scenarios are. An epic
/// has no page — it is a branch — so it lands on its row in the tree, and
/// reads as the heading of the features indented beneath it.
String _coverageRow(RequirementNode node, {required int level}) {
  final String href = node.type == 'feature'
      ? featureReportName(node)
      : 'features.html#${rowAnchorOf(node)}';
  final double? rate = node.passRate;
  return '<tr class="requirement-row level-$level">'
      '<td style="padding-left:${0.75 + level * 1.5}em">'
      '<a href="$href">${escapeHtml(node.name)}</a></td>'
      '<td>${node.testCount}</td>'
      '<td>${rate == null ? '—' : '${rate.round()}%'}</td>'
      '<td class="coverage-column">${_coverageBar(node)}</td>'
      '</tr>\n';
}

/// The dashboard's functional-coverage panel: the same tree, summarised, on
/// the page a reader opens first.
String coverageOverview(List<RequirementNode> roots) {
  if (roots.isEmpty) {
    return '';
  }
  // Epics with their features under them, the same shape as the tree page.
  //
  // Listing only the roots meant that a project which declares epics — most
  // of them — got a panel of two rows leading to a page of everything, which
  // is the opposite of what a reader clicking a name wants. What they are
  // after is *that* feature: its scenarios, its coverage. So the features are
  // here, each going straight to its own page, and the epic above them is the
  // grouping rather than the destination.
  final StringBuffer rows = StringBuffer();
  for (final RequirementNode root in roots) {
    rows.write(_coverageRow(root, level: 0));
    for (final RequirementNode child in root.children) {
      rows.write(_coverageRow(child, level: 1));
    }
  }
  return '''
<h4>Functional Coverage</h4>
<table class="table requirements-table">
<thead><tr><th>Name</th><th>Tests</th><th>% Pass</th>
<th class="coverage-column">Coverage</th></tr></thead>
<tbody>
$rows</tbody>
</table>
''';
}
