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
import 'charts.dart';
import 'page_chrome.dart';
import 'requirements_page.dart' show coverageOverview;
import 'site_assets.dart';
import 'tags_page.dart' show tagReportName;

/// The one line naming what the report is of, when nothing was given: the
/// report describes the E2E suite, not the app, and the platform is the only
/// thing that distinguishes two runs of it.
///
/// Every page takes a `title` that overrides this, and the CLI exposes it as
/// `--title`, so a project that wants its own wording sets it in one place —
/// the melos script that builds the report — rather than editing the
/// generator.
String projectTitleFor(String platform) =>
    'E2E test report ${platform == 'web' ? 'web' : 'mobile'}';

/// Writes `index.html` and `sqa-reporter.css` into [outputDir], beside the
/// JSON results. Returns the `index.html` file.
File writeDashboard(
  ParsedRun run,
  Directory outputDir, {
  required String platform,
  String? title,
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
            title: title,
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
  String? title,
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

  final StringBuffer page = StringBuffer()
    ..writeln('<!DOCTYPE html>')
    ..writeln('<html lang="en">')
    ..write(pageHead())
    ..writeln('<body>')
    ..write(banner(platform, title: title))
    ..writeln('<div class="middlecontent">')
    ..writeln('<span class="breadcrumbs"><a href="index.html">Home</a></span>')
    ..write(menuBar(generatedAt, homeActive: true))
    ..writeln('<h2>Test Results: All Tests</h2>')
    ..writeln(
      '<div class="test-count-title">'
      '<span class="test-count">$total test${total == 1 ? '' : 's'}</span>'
      '</div>',
    )
    ..write(_tabBar())
    ..writeln('<div class="card">')
    ..write(_summaryPane(rows, counts, total, run))
    ..write(_testsPane(rows, run))
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
  ParsedRun run,
) {
  final StringBuffer pane = StringBuffer()
    ..writeln('<div id="summary" class="tab-pane active">')
    ..writeln('<div class="dashboard-charts">')
    ..writeln('<div class="chart-block">')
    ..writeln('<h4>Overview</h4>')
    ..write(donutChart(counts, total))
    ..write(chartLegend(counts))
    ..writeln('</div>')
    ..writeln('<div class="chart-block">')
    ..writeln('<h4>Test Outcomes</h4>')
    ..write(outcomesChart(counts))
    ..writeln('</div>')
    ..writeln('<div class="chart-block wide">')
    ..writeln('<h4>Test Performance</h4>')
    ..writeln('<div class="chart-caption">Number of tests per duration</div>')
    ..write(durationChart(rows.map((_Row row) => row.durationMs).toList()))
    ..writeln('</div>')
    ..writeln('</div>')
    // Coverage and the statistics share a row, as they do in the reference:
    // what the run covered on the left, what it cost on the right.
    ..writeln('<div class="summary-columns">')
    ..writeln('<div class="coverage-panel">')
    ..write(coverageOverview(requirementsOf(run)))
    ..writeln('</div>')
    ..writeln('<div class="statistics-panel">')
    ..write(_keyStatistics(rows, run))
    ..writeln('</div>')
    ..writeln('</div>')
    ..write(_tagCloud(rows))
    ..writeln('</div>');
  return pane.toString();
}

String _keyStatistics(
  List<_Row> rows,
  ParsedRun run, {
  bool twoColumn = false,
}) {
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

  // The statistics themselves are the same on both tabs; only the shape
  // differs — one column beside the charts, two where the table needs the
  // width.
  final List<({String label, String value})>
  stats = <({String label, String value})>[
    (label: 'Number of scenarios', value: '${rows.length}'),
    (label: 'Total number of test cases', value: '${rows.length}'),
    (
      label: 'Tests started',
      value: rows.isEmpty
          ? '—'
          : timestampOf(
              DateTime.fromMillisecondsSinceEpoch(earliestStart, isUtc: true),
            ),
    ),
    (
      label: 'Tests finished',
      value: rows.isEmpty
          ? '—'
          : timestampOf(
              DateTime.fromMillisecondsSinceEpoch(latestStop, isUtc: true),
            ),
    ),
    (
      label: 'Total duration',
      value: rows.isEmpty ? '—' : compoundDuration(latestStop - earliestStart),
    ),
    (
      label: 'Fastest test',
      value: durations.isEmpty ? '—' : compoundDuration(durations.first),
    ),
    (
      label: 'Slowest test',
      value: durations.isEmpty ? '—' : compoundDuration(durations.last),
    ),
    (
      label: 'Average execution time',
      value: durations.isEmpty
          ? '—'
          : compoundDuration(cumulative ~/ durations.length),
    ),
    (label: 'Cumulative test time', value: compoundDuration(cumulative)),
  ];

  final StringBuffer body = StringBuffer();
  if (twoColumn) {
    for (int i = 0; i < stats.length; i += 2) {
      final ({String label, String value})? second = i + 1 < stats.length
          ? stats[i + 1]
          : null;
      body.writeln(
        '<tr><td>${stats[i].label}</td><td>${stats[i].value}</td>'
        '<td>${second?.label ?? ''}</td><td>${second?.value ?? ''}</td></tr>',
      );
    }
  } else {
    for (final ({String label, String value}) stat in stats) {
      body.writeln('<tr><td>${stat.label}</td><td>${stat.value}</td></tr>');
    }
  }

  return '''
<h3>Key Statistics</h3>
<table class="table table-striped key-statistics">
<tbody>
$body</tbody>
</table>
''';
}

/// Every tag the run declared, with how many tests carried it — the same
/// vocabulary the runner filters on, so a reader can reproduce a selection.
String _tagCloud(List<_Row> rows) {
  final Map<String, int> tally = <String, int>{};
  for (final _Row row in rows) {
    for (final String tag in row.tags) {
      tally[tag] = (tally[tag] ?? 0) + 1;
    }
  }
  if (tally.isEmpty) {
    return '';
  }
  final List<String> names = tally.keys.toList()..sort();
  final StringBuffer cloud = StringBuffer('<h3>Tags</h3><p class="tag-cloud">');
  for (final String name in names) {
    // Each tag leads to the scenarios that carried it: the tag vocabulary is
    // what the runner filters on, so the question worth answering is which
    // tests that selection covers.
    cloud.write(
      '<a class="tag-badge cloud" href="${tagReportName(name)}">'
      '${escapeHtml(name)}'
      '<span class="tag-count">${tally[name]}</span></a> ',
    );
  }
  cloud.write('</p>');
  return cloud.toString();
}

String _testsPane(List<_Row> rows, ParsedRun run) {
  final StringBuffer body = StringBuffer();
  for (final _Row row in rows) {
    // Every sortable cell carries the value to sort by, so the table sorts on
    // what a column *means* — a duration by milliseconds, a result by
    // severity — rather than on the text that happens to render it.
    body.writeln(
      '<tr>'
      '<td>${escapeHtml(row.feature)}</td>'
      '<td><a href="${row.href}">${escapeHtml(row.name)}</a></td>'
      '<td>${escapeHtml(row.context)}</td>'
      '<td data-order="${row.stepCount}">${row.stepCount}</td>'
      '<td data-order="${row.startMs}">'
      '${timestampOf(DateTime.fromMillisecondsSinceEpoch(row.startMs, isUtc: true))}</td>'
      '<td data-order="${row.durationMs}">'
      '${compoundDuration(row.durationMs)}</td>'
      '<td data-order="${_severityRank(row.result)}">'
      '<a href="${row.href}">${resultIcon(row.result)}</a></td>'
      '</tr>',
    );
  }

  final StringBuffer pane = StringBuffer()
    ..writeln('<div id="tests" class="tab-pane">')
    ..write(_keyStatistics(rows, run, twoColumn: true))
    ..writeln('<h3>Automated Scenarios</h3>')
    ..writeln('<div class="data-table">')
    ..writeln('<div class="table-controls">')
    ..writeln(
      '<label class="entries">'
      '<select class="page-size">'
      '<option>10</option><option>25</option><option>50</option>'
      '<option>100</option><option value="0">All</option>'
      '</select> entries per page</label>',
    )
    ..writeln(
      '<label class="filter">'
      '<input type="search" class="table-filter" placeholder="Filter"/>'
      '</label>',
    )
    ..writeln('</div>')
    ..writeln('<table class="table table-striped scenario-result-table">')
    ..writeln(
      '<thead><tr>'
      '<th class="sortable" data-sort="text">Feature</th>'
      '<th class="sortable test-name-column" data-sort="text">Scenario</th>'
      '<th class="sortable" data-sort="text">Context</th>'
      '<th class="sortable" data-sort="number">Steps</th>'
      '<th class="sortable" data-sort="number">Started</th>'
      '<th class="sortable" data-sort="number">Total Duration</th>'
      '<th class="sortable" data-sort="number">Result</th>'
      '</tr></thead>',
    )
    ..writeln('<tbody>')
    ..write(body)
    ..writeln('</tbody>')
    ..writeln('</table>')
    ..writeln('<div class="table-footer">')
    ..writeln('<span class="table-info"></span>')
    ..writeln('<span class="pagination"></span>')
    ..writeln('</div>')
    ..writeln('</div>')
    ..write(_tagCloud(rows))
    ..writeln('</div>');
  return pane.toString();
}

/// Worst first, so sorting the Result column ascending puts what needs
/// attention at the top — the order the reference sorts by.
int _severityRank(String result) => switch (result) {
  'FAILURE' => 1,
  'ERROR' => 2,
  'SKIPPED' => 3,
  'UNDEFINED' => 4,
  _ => 5,
};

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
    required this.tags,
  });

  factory _Row.of(RunCase testCase) {
    final RunStatus status = promoteStatus(testCase.status, testCase.steps);
    // The widened clock, the same one the JSON writer and the detail page
    // use: the row must not report a test as shorter than the steps it holds.
    final ({int start, int stop}) bounds = widenedBoundsOf(testCase);
    return _Row(
      feature: testCase.meta?.feature ?? testCase.suite,
      name: testCase.name,
      context: testCase.thread,
      stepCount: testCase.steps.length,
      startMs: bounds.start,
      stopMs: bounds.stop,
      result: serenityResult[status]!,
      href: htmlReportName(testCase),
      tags: testCase.tags,
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

  /// What the test declared to `e2eTest`, for the tag cloud.
  final List<String> tags;

  int get durationMs => stopMs - startMs;
}
