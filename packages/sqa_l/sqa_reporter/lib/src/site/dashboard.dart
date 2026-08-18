/// The dashboard: `index.html`, the page the report opens on.
///
/// Its shape follows the reference dashboard panel for panel — banner with the
/// project name on the right, breadcrumb bar, the main menu, one card with a
/// Summary tab (overview donut, outcomes bar chart, key statistics) and a
/// Test Results tab (the scenario table) — because matching that layout is
/// the point of the exercise. Every line of markup and style is written here;
/// see `site_assets.dart` for where the clean-room line runs.
library;

import 'dart:io';

import '../markers.dart';
import '../model.dart';
import '../requirements.dart';
import '../serenity_writer.dart';
import 'page_chrome.dart';
import 'requirements_page.dart' show coverageOverview;
import 'site_assets.dart';

/// What the report calls the project, by platform. This replaces the
/// project-name slot: the report describes the E2E suite, not the app.
String projectTitleFor(String platform) =>
    platform == 'web' ? 'Test e2e Web' : 'Test e2e Mobile';

/// Writes `index.html` and `sqa-reporter.css` into [outputDir], beside the
/// JSON results. Returns the `index.html` file.
File writeDashboard(
  ParsedRun run,
  Directory outputDir, {
  required String platform,
  DateTime? generatedAt,
}) {
  outputDir.createSync(recursive: true);
  File(
    '${outputDir.path}${Platform.pathSeparator}sqa-reporter.css',
  ).writeAsStringSync(siteCss);
  final File index =
      File('${outputDir.path}${Platform.pathSeparator}index.html')
        ..writeAsStringSync(
          dashboardHtml(
            run,
            platform: platform,
            generatedAt: generatedAt ?? DateTime.now().toUtc(),
          ),
        );
  return index;
}

/// The page itself, as a string — separated from the file write so tests can
/// assert on content without a filesystem.
String dashboardHtml(
  ParsedRun run, {
  required String platform,
  required DateTime generatedAt,
}) {
  final List<_Row> rows = run.cases.map(_Row.of).toList()
    ..sort((_Row a, _Row b) {
      final int byFeature = a.feature.compareTo(b.feature);
      return byFeature != 0 ? byFeature : a.name.compareTo(b.name);
    });

  final Map<String, int> counts = <String, int>{
    for (final String result in resultColors.keys) result: 0,
  };
  for (final _Row row in rows) {
    counts[row.result] = (counts[row.result] ?? 0) + 1;
  }
  final int total = rows.length;
  final int passing = counts['SUCCESS'] ?? 0;
  final String successLabel = total == 0
      ? '—'
      : '${(passing * 100 / total).round()}%';

  final StringBuffer page = StringBuffer()
    ..writeln('<!DOCTYPE html>')
    ..writeln('<html lang="en">')
    ..write(pageHead())
    ..writeln('<body>')
    ..write(banner(platform))
    ..writeln('<div class="middlecontent">')
    ..writeln('<span class="breadcrumbs"><a href="index.html">Home</a></span>')
    ..write(menuBar(generatedAt, homeActive: true))
    ..writeln('<h2>Test Results: All Tests</h2>')
    ..writeln('<div class="test-count-title">$total test cases</div>')
    ..write(_tabBar())
    ..writeln('<div class="card">')
    ..write(_summaryPane(rows, counts, total, successLabel, run))
    ..write(_testsPane(rows))
    ..writeln('</div>')
    ..writeln('</div>')
    ..write(pageFooter())
    ..writeln('<script>$siteJs</script>')
    ..writeln('</body>')
    ..writeln('</html>');
  return page.toString();
}

String _tabBar() => '''
<ul class="nav nav-tabs">
  <li class="active"><a href="#" data-tab="summary">Summary</a></li>
  <li><a href="#" data-tab="tests">Test Results</a></li>
</ul>
''';

String _summaryPane(
  List<_Row> rows,
  Map<String, int> counts,
  int total,
  String successLabel,
  ParsedRun run,
) {
  final StringBuffer pane = StringBuffer()
    ..writeln('<div id="summary" class="tab-pane active">')
    ..writeln('<div class="dashboard-charts">')
    ..writeln('<div class="chart-block">')
    ..writeln('<h4>Overview</h4>')
    ..write(_donut(counts, total, successLabel))
    ..write(_legend(counts))
    ..writeln('</div>')
    ..writeln('<div class="chart-block">')
    ..writeln('<h4>Test Outcomes</h4>')
    ..write(_bars(counts))
    ..writeln('</div>')
    ..writeln('<div class="chart-block">')
    ..write(_keyStatistics(rows, run))
    ..writeln('</div>')
    ..writeln('</div>')
    ..write(coverageOverview(requirementsOf(run)))
    ..writeln('</div>');
  return pane.toString();
}

/// The overview donut, as a conic-gradient: one segment per verdict that has
/// at least one test, with the overall pass percentage in the hole.
String _donut(Map<String, int> counts, int total, String successLabel) {
  if (total == 0) {
    return '<div class="donut" style="background:#eee">'
        '<span class="donut-label">—</span></div>';
  }
  final List<String> segments = <String>[];
  double from = 0;
  for (final MapEntry<String, int> entry in counts.entries) {
    if (entry.value == 0) {
      continue;
    }
    final double to = from + entry.value * 360 / total;
    segments.add(
      '${resultColors[entry.key]!.fill} ${from.round()}deg ${to.round()}deg',
    );
    from = to;
  }
  return '<div class="donut" '
      'style="background:conic-gradient(${segments.join(', ')})">'
      '<span class="donut-label">$successLabel</span></div>';
}

String _legend(Map<String, int> counts) {
  final StringBuffer legend = StringBuffer('<ul class="chart-legend">');
  for (final MapEntry<String, int> entry in counts.entries) {
    if (entry.value == 0) {
      continue;
    }
    final ({String fill, String border, String solid}) color =
        resultColors[entry.key]!;
    legend.write(
      '<li><span class="swatch" style="background:${color.fill};'
      'border-color:${color.border}"></span>'
      '${_displayName(entry.key)} (${entry.value})</li>',
    );
  }
  legend.write('</ul>');
  return legend.toString();
}

/// The outcomes bar chart: one bar per verdict, height proportional to its
/// count against the largest.
String _bars(Map<String, int> counts) {
  final int max = counts.values.fold(
    0,
    (int carried, int count) => count > carried ? count : carried,
  );
  final StringBuffer bars = StringBuffer('<div class="bars">');
  for (final MapEntry<String, int> entry in counts.entries) {
    final ({String fill, String border, String solid}) color =
        resultColors[entry.key]!;
    final int height = max == 0 ? 0 : (entry.value * 150 / max).round();
    bars.write(
      '<div class="bar">'
      '<div class="count">${entry.value}</div>'
      '<div class="fill" style="height:${height}px;background:${color.fill};'
      'border-color:${color.border}"></div>'
      '<div class="result-label">${_displayName(entry.key)}</div>'
      '</div>',
    );
  }
  bars.write('</div>');
  return bars.toString();
}

String _keyStatistics(List<_Row> rows, ParsedRun run) {
  final List<int> durations = rows.map((_Row row) => row.durationMs).toList()
    ..sort();
  final int cumulative = durations.fold(
    0,
    (int sum, int duration) => sum + duration,
  );
  final int earliestStart = rows.isEmpty
      ? 0
      : rows
            .map((_Row row) => row.startMs)
            .reduce((int a, int b) => a < b ? a : b);
  final int latestStop = rows.isEmpty
      ? 0
      : rows
            .map((_Row row) => row.stopMs)
            .reduce((int a, int b) => a > b ? a : b);

  String row(String label, String value) =>
      '<tr><td>$label</td><td>$value</td></tr>';

  return '''
<h4>Key Statistics</h4>
<table class="table table-striped">
<tbody>
${row('Number of test cases', '${rows.length}')}
${row('Tests started', rows.isEmpty ? '—' : timestampOf(DateTime.fromMillisecondsSinceEpoch(earliestStart, isUtc: true)))}
${row('Tests finished', rows.isEmpty ? '—' : timestampOf(DateTime.fromMillisecondsSinceEpoch(latestStop, isUtc: true)))}
${row('Total duration', rows.isEmpty ? '—' : compoundDuration(latestStop - earliestStart))}
${row('Fastest test', durations.isEmpty ? '—' : compoundDuration(durations.first))}
${row('Slowest test', durations.isEmpty ? '—' : compoundDuration(durations.last))}
${row('Average execution time', durations.isEmpty ? '—' : compoundDuration(cumulative ~/ durations.length))}
${row('Cumulative test time', compoundDuration(cumulative))}
</tbody>
</table>
''';
}

String _testsPane(List<_Row> rows) {
  final StringBuffer pane = StringBuffer()
    ..writeln('<div id="tests" class="tab-pane">')
    ..writeln('<h3>Automated Scenarios</h3>')
    ..writeln('<table class="table table-striped scenario-result-table">')
    ..writeln(
      '<thead><tr><th>Feature</th><th>Scenario</th><th>Context</th>'
      '<th>Steps</th><th>Started</th><th>Total Duration</th>'
      '<th>Result</th></tr></thead>',
    )
    ..writeln('<tbody>');
  for (final _Row row in rows) {
    pane.writeln(
      '<tr>'
      '<td>${escapeHtml(row.feature)}</td>'
      '<td><a href="${row.href}">${escapeHtml(row.name)}</a></td>'
      '<td>${escapeHtml(row.context)}</td>'
      '<td>${row.stepCount}</td>'
      '<td>${timestampOf(DateTime.fromMillisecondsSinceEpoch(row.startMs, isUtc: true))}</td>'
      '<td>${compoundDuration(row.durationMs)}</td>'
      '<td><a href="${row.href}">${resultIcon(row.result)}</a></td>'
      '</tr>',
    );
  }
  pane
    ..writeln('</tbody>')
    ..writeln('</table>')
    ..writeln('</div>');
  return pane.toString();
}

/// The coloured round marker a result cell shows, with the verdict spelled
/// out in the `title` attribute.
String resultIcon(String result) {
  final ({String fill, String border, String solid}) color =
      resultColors[result] ?? resultColors['UNDEFINED']!;
  final String glyph = resultGlyphs[result] ?? '?';
  return '<span class="result-icon" style="background:${color.solid}" '
      'title="$result">$glyph</span>';
}

/// `2s 600ms`, `1m 5s`, `450ms` — largest two units that apply.
String compoundDuration(int ms) {
  if (ms < 1000) {
    return '${ms}ms';
  }
  final int hours = ms ~/ 3600000;
  final int minutes = (ms % 3600000) ~/ 60000;
  final int seconds = (ms % 60000) ~/ 1000;
  final int millis = ms % 1000;
  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }
  if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  }
  return millis == 0 ? '${seconds}s' : '${seconds}s ${millis}ms';
}

/// Minimal HTML escaping for text that lands between tags or in a quoted
/// attribute.
String escapeHtml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _displayName(String result) => switch (result) {
  'SUCCESS' => 'Passing',
  'FAILURE' => 'Failed',
  'ERROR' => 'Broken',
  'SKIPPED' => 'Skipped',
  _ => 'Undefined',
};

/// One table row's worth of a case, with the same widening and promotion the
/// JSON writer applies, so the two surfaces never disagree about a verdict.
class _Row {
  const _Row({
    required this.feature,
    required this.name,
    required this.context,
    required this.stepCount,
    required this.startMs,
    required this.stopMs,
    required this.result,
    required this.href,
  });

  factory _Row.of(RunCase testCase) {
    final RunStatus status = promoteStatus(testCase.status, testCase.steps);
    return _Row(
      feature: testCase.meta?.feature ?? testCase.suite,
      name: testCase.name,
      context: testCase.thread,
      stepCount: testCase.steps.length,
      startMs: testCase.start,
      stopMs: testCase.stop,
      result: serenityResult[status]!,
      href: htmlReportName(testCase),
    );
  }

  final String feature;
  final String name;
  final String context;
  final int stepCount;
  final int startMs;
  final int stopMs;
  final String result;

  /// The detail page this row links to.
  final String href;

  int get durationMs => stopMs - startMs;
}
