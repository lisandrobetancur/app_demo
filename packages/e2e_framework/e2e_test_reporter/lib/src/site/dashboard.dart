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
import '../results_writer.dart';
import 'charts.dart';
import 'features_page.dart' show coverageOverview;
import 'page_chrome.dart';
import 'site_assets.dart';
import 'tags_page.dart' show tagReportName;

/// The one line naming what the report is of: the report describes the E2E
/// suite, not the app, and the platform is the only thing that distinguishes
/// two runs of it.
///
/// Derived, not configurable, and that is the point — a title someone can set
/// is a title that drifts between projects and CI jobs, and then two reports
/// of the same suite cannot be told apart by their names. The three platforms
/// the runner targets are named the way their own vendors write them; anything
/// else is titled from the platform it was given, so an unexpected value is
/// visible rather than quietly filed under one of the three.
String projectTitleFor(String platform) => switch (platform) {
  'web' => 'Web Test Report',
  'android' => 'Android Test Report',
  'ios' => 'iOS Test Report',
  _ =>
    '${platform.isEmpty ? '' : '${platform[0].toUpperCase()}'
              '${platform.substring(1)} '}Test Report',
};

/// Writes `index.html` and `e2e-test-reporter.css` into [outputDir], beside the
/// JSON results. Returns the `index.html` file.
File writeDashboard(
  ParsedRun run,
  Directory outputDir, {
  required String platform,
  Duration offset = reportOffset,
  DateTime? generatedAt,
}) {
  outputDir.createSync(recursive: true);
  File(
    '${outputDir.path}${Platform.pathSeparator}e2e-test-reporter.css',
  ).writeAsStringSync(siteCss);
  File(
    '${outputDir.path}${Platform.pathSeparator}favicon.svg',
  ).writeAsStringSync(siteFavicon);
  final File index =
      File('${outputDir.path}${Platform.pathSeparator}index.html')
        ..writeAsStringSync(
          dashboardHtml(
            run,
            platform: platform,
            offset: offset,
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
  Duration offset = reportOffset,
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
    ..write(pageHead(platform))
    ..writeln('<body>')
    ..write(banner(platform, generatedAt: generatedAt, offset: offset))
    ..writeln('<div class="middlecontent">')
    ..writeln('<div class="topnav">')
    ..writeln(
      breadcrumbs(<Crumb>[
        (label: 'Home', href: 'index.html'),
        (label: 'Overall Test Results', href: null),
      ]),
    )
    ..write(menuBar(generatedAt, homeActive: true, offset: offset))
    ..writeln('</div>')
    ..write(_runAgeNote(rows, generatedAt, offset))
    ..writeln('<div class="section-title">')
    ..writeln('<span class="eyebrow">Overview · All features</span>')
    ..writeln('<h2>Test Results: All Tests</h2>')
    ..writeln('</div>')
    ..write(_keyFigures(rows, counts, total))
    ..write(_tabBar())
    ..write(_summaryPane(rows, counts, total, run, offset))
    ..write(_testsPane(rows, run, offset))
    ..writeln('</div>')
    ..write(pageFooter())
    ..writeln('<script>$siteJs</script>')
    ..writeln('</body>')
    ..writeln('</html>');
  return page.toString();
}

/// When the run and the report are not the same age, the page says so.
///
/// A report can be rebuilt from results already on disk — that is what the
/// `report*` scripts are for — and then the generation stamp says today while
/// the run it describes is from last week. Rather than warn on the command
/// line, where it would fire on every deliberate rebuild, the page carries
/// the difference to the person reading it.
String _runAgeNote(List<_Row> rows, DateTime generatedAt, Duration offset) {
  if (rows.isEmpty) {
    return '';
  }
  final int latestStop = rows
      .map((_Row row) => row.stopMs)
      .reduce((int a, int b) => a > b ? a : b);
  final DateTime finished = DateTime.fromMillisecondsSinceEpoch(
    latestStop,
    isUtc: true,
  );
  final Duration gap = generatedAt.difference(finished);
  if (gap.inMinutes < 10) {
    return '';
  }
  return '<p class="run-age">${icon('ic-info', small: true)}'
      'Describing a run that finished '
      '<span class="mono">${timestampOf(finished, offset: offset)}</span>, '
      '${_humanGap(gap)} before this report was generated.</p>\n';
}

/// `58 minutes`, `3 hours`, `2 days` — enough to tell "just now" from "this
/// is last week's run", which is the only question being asked.
String _humanGap(Duration gap) {
  if (gap.inHours < 1) {
    return '${gap.inMinutes} minute${gap.inMinutes == 1 ? '' : 's'}';
  }
  if (gap.inDays < 1) {
    return '${gap.inHours} hour${gap.inHours == 1 ? '' : 's'}';
  }
  return '${gap.inDays} day${gap.inDays == 1 ? '' : 's'}';
}

/// The four figures the report is opened for, above everything that explains
/// them: how many scenarios ran, what share passed, how many need somebody,
/// and how long the whole thing took.
///
/// Every one of these could be found before — in the doughnut, in the legend,
/// in a statistics table halfway down the page — which is exactly the
/// argument for putting them here: a reader who only wants the verdict should
/// not have to read a chart to get it.
String _keyFigures(List<_Row> rows, Map<String, int> counts, int total) {
  final int passed = counts['SUCCESS'] ?? 0;
  final int skipped = counts['SKIPPED'] ?? 0;
  // Failed and broken are one number here on purpose: both mean a person has
  // to look at something, and which of the two it was is a question for the
  // table, not for the top of the page.
  final int attention = (counts['FAILURE'] ?? 0) + (counts['ERROR'] ?? 0);
  final List<int> durations = rows.map((_Row row) => row.durationMs).toList()
    ..sort();
  final int wallClock = rows.isEmpty
      ? 0
      : rows
                .map((_Row row) => row.stopMs)
                .reduce((int a, int b) => a > b ? a : b) -
            rows
                .map((_Row row) => row.startMs)
                .reduce((int a, int b) => a < b ? a : b);

  // Each tile: an icon on its tint, the label beside it, the figure, and one
  // line under the figure saying what it is made of. The modifier decides
  // the tint — `good` and `bad` are verdicts on the run, `calm` is the
  // attention tile when there is nothing to attend to, `time` sets the
  // duration in the mono face.
  String tile(
    String label,
    String value,
    String note, {
    required String iconId,
    String modifier = '',
  }) =>
      '<div class="kpi$modifier">'
      '<div class="kpi-head">'
      '<span class="kpi-icon">${icon(iconId)}</span>'
      '<span class="kpi-label">${escapeHtml(label)}</span>'
      '</div>'
      '<span class="kpi-value">${escapeHtml(value)}</span>'
      '<span class="kpi-note">${escapeHtml(note)}</span>'
      '</div>';

  return '<div class="kpi-row">'
      '${tile('Scenarios', '$total', skipped == 0 ? 'all of them run' : '$skipped skipped', iconId: 'ic-list-checks')}'
      '${tile('Pass rate', total == 0 ? '—' : '${(passed * 100 / total).round()}%', '$passed of $total passing', iconId: 'ic-circle-check', modifier: ' good')}'
      '${tile('Needs attention', '$attention', attention == 1 ? '1 failed or broken' : 'failed or broken', iconId: 'ic-alert-triangle', modifier: attention > 0 ? ' bad' : ' calm')}'
      '${tile('Duration', rows.isEmpty ? '—' : compoundDuration(wallClock), durations.isEmpty ? 'nothing ran' : 'slowest ${compoundDuration(durations.last)}', iconId: 'ic-timer', modifier: ' time')}'
      '</div>\n';
}

/// With three scenarios or fewer, the charts have little to say, so the run
/// is summed up in one line above them: how many ran, what share passed, how
/// long it took. The charts stay — a chart of one bar is still the chart a
/// reader learned to read.
String _summaryBand(List<_Row> rows, Map<String, int> counts, int total) {
  if (total == 0 || total > 3) {
    return '';
  }
  final int passed = counts['SUCCESS'] ?? 0;
  final int rate = (passed * 100 / total).round();
  final int wallClock =
      rows
          .map((_Row row) => row.stopMs)
          .reduce((int a, int b) => a > b ? a : b) -
      rows
          .map((_Row row) => row.startMs)
          .reduce((int a, int b) => a < b ? a : b);
  final String seconds = (wallClock / 1000).toStringAsFixed(1);
  return '<div class="summary-band${rate < 100 ? ' bad' : ''}">'
      '${icon(rate < 100 ? 'ic-alert-triangle' : 'ic-circle-check')}'
      '<span>$total scenario${total == 1 ? '' : 's'} run · '
      '$rate% passing · '
      '<span class="mono">${seconds}s</span></span>'
      '</div>\n';
}

/// The second-level tabs, as a segmented control: one surface, the active
/// segment lifted onto it.
String _tabBar() => '''
<div class="segmented" role="tablist">
  <a class="segment active" role="tab" aria-selected="true" href="#" data-tab="summary">Summary</a>
  <a class="segment" role="tab" aria-selected="false" href="#" data-tab="tests">Test Results</a>
</div>
''';

/// A chart's card head: the eyebrow with its icon, and a line under it
/// saying what the chart shows.
String _chartHead(String iconId, String title, String subtitle) =>
    '<div class="card-head">'
    '<span class="eyebrow">${icon(iconId)}$title</span>'
    '<span class="card-sub">$subtitle</span>'
    '</div>\n';

String _summaryPane(
  List<_Row> rows,
  Map<String, int> counts,
  int total,
  ParsedRun run,
  Duration offset,
) {
  final String coverage = coverageOverview(requirementsOf(run));
  final StringBuffer pane = StringBuffer()
    ..writeln('<div id="summary" class="tab-pane active">')
    ..write(_summaryBand(rows, counts, total))
    ..writeln('<div class="dashboard-charts">')
    ..writeln('<div class="card chart-block">')
    ..write(_chartHead('ic-pie-chart', 'Overview', 'How the run came out'))
    ..writeln('<div class="donut-wrap">')
    ..write(donutChart(counts, total))
    ..write(chartLegend(counts))
    ..writeln('</div>')
    ..writeln('</div>')
    ..writeln('<div class="card chart-block">')
    ..write(_chartHead('ic-bar-chart', 'Test Outcomes', 'Scenarios by verdict'))
    ..write(outcomesChart(counts))
    ..writeln('</div>')
    ..writeln('<div class="card chart-block wide">')
    ..write(_chartHead('ic-gauge', 'Test Performance', 'Scenarios by duration'))
    ..write(durationChart(rows.map((_Row row) => row.durationMs).toList()))
    ..writeln('</div>')
    ..writeln('</div>')
    // Coverage and the statistics share a row: what the run covered on the
    // left, what it cost on the right.
    ..writeln('<div class="summary-columns">')
    ..write(
      coverage.isEmpty
          ? ''
          : '<div class="card coverage-panel">$coverage</div>\n',
    )
    ..writeln('<div class="card statistics-panel">')
    ..write(_keyStatistics(rows, run, offset))
    ..writeln('</div>')
    ..writeln('</div>')
    ..write(_tagCloud(rows))
    ..writeln('</div>');
  return pane.toString();
}

String _keyStatistics(
  List<_Row> rows,
  ParsedRun run,
  Duration offset, {
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
              offset: offset,
            ),
    ),
    (
      label: 'Tests finished',
      value: rows.isEmpty
          ? '—'
          : timestampOf(
              DateTime.fromMillisecondsSinceEpoch(latestStop, isUtc: true),
              offset: offset,
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
$_keyStatisticsHead
<table class="table key-statistics">
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
  final StringBuffer cloud = StringBuffer(
    '<div class="card"><div class="card-head"><h4>Tags</h4>'
    '<span class="card-sub">The vocabulary the runner filters on</span></div>'
    '<p class="tag-cloud">',
  );
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
  cloud.write('</p></div>');
  return cloud.toString();
}

String _testsPane(List<_Row> rows, ParsedRun run, Duration offset) {
  final StringBuffer body = StringBuffer();
  for (final _Row row in rows) {
    // Every sortable cell carries the value to sort by, so the table sorts on
    // what a column *means* — a duration by milliseconds, a result by
    // severity — rather than on the text that happens to render it.
    body.writeln(
      '<tr data-result="${row.result}">'
      '<td>${escapeHtml(row.feature)}</td>'
      '<td><a href="${row.href}">${escapeHtml(row.name)}</a></td>'
      '<td data-order="${severityWeight(row.severity)}">'
      '${severityLabel(row.severity)}</td>'
      '<td data-order="${row.stepCount}">${row.stepCount}</td>'
      '<td data-order="${row.startMs}">'
      '${timestampOf(DateTime.fromMillisecondsSinceEpoch(row.startMs, isUtc: true), offset: offset)}</td>'
      '<td data-order="${row.durationMs}">'
      '${compoundDuration(row.durationMs)}</td>'
      '<td data-order="${_severityRank(row.result)}">'
      '<a href="${row.href}">${resultIcon(row.result)}</a></td>'
      '</tr>',
    );
  }

  final StringBuffer pane = StringBuffer()
    ..writeln('<div id="tests" class="tab-pane">')
    ..writeln('<div class="card">')
    ..write(_keyStatistics(rows, run, offset, twoColumn: true))
    ..writeln('</div>')
    ..writeln('<div class="card data-table">')
    ..writeln(
      '<div class="card-head"><h4>Automated Scenarios</h4>'
      '<span class="card-sub">${rows.length} scenario'
      '${rows.length == 1 ? '' : 's'}, sorted by feature</span></div>',
    )
    ..writeln('<p class="active-filter" hidden></p>')
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
    ..writeln('<div class="table-scroll">')
    ..writeln('<table class="table table-striped scenario-result-table">')
    ..writeln(
      '<thead><tr>'
      '<th class="sortable" data-sort="text">Feature</th>'
      '<th class="sortable test-name-column" data-sort="text">Scenario</th>'
      '<th class="sortable" data-sort="number">Severity</th>'
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
    ..writeln('</div>')
    ..writeln('<div class="table-footer">')
    ..writeln('<span class="table-info"></span>')
    ..writeln('<span class="pagination"></span>')
    ..writeln('</div>')
    ..writeln('</div>')
    ..write(_tagCloud(rows))
    ..writeln('</div>');
  return pane.toString();
}

/// The key-statistics card's title, above the table on both tabs.
const String _keyStatisticsHead =
    '<div class="card-head"><h4>Key Statistics</h4>'
    '<span class="card-sub">The run\'s clock and its durations</span></div>';

/// How much a failure of this scenario would matter, as the scenario itself
/// declared it.
///
/// It was travelling in the marker stream and landing on the detail page as a
/// tag, which is the one place a reader has already decided to look. On the
/// table it answers the question the table is read for: of the things that
/// went wrong, which ones matter — and, on a green run, which parts of the
/// product the suite is actually guarding.
String severityLabel(String? severity) => severity == null
    ? '<span class="severity none">—</span>'
    : '<span class="severity ${escapeHtml(severity)}">'
          '${escapeHtml(severity)}</span>';

/// Blocker first, for the same reason the Result column sorts worst first:
/// ascending puts what needs attention at the top. A scenario that declared
/// no severity sorts last rather than in the middle — it said nothing, which
/// is not the same as saying "normal".
int severityWeight(String? severity) => switch (severity) {
  'blocker' => 1,
  'critical' => 2,
  'normal' => 3,
  'minor' => 4,
  'trivial' => 5,
  _ => 6,
};

/// Worst first, so sorting the Result column ascending puts what needs
/// attention at the top — the order the reference sorts by.
int _severityRank(String result) => switch (result) {
  'FAILURE' => 1,
  'ERROR' => 2,
  'SKIPPED' => 3,
  'UNDEFINED' => 4,
  _ => 5,
};

/// The same marker at step size: small enough to sit in front of a sentence
/// without pushing it around, big enough to scan a column of them.
String stepIcon(String result) {
  final ({String fill, String border, String solid}) color =
      resultColors[result] ?? resultColors['UNDEFINED']!;
  final String glyph = resultGlyphs[result] ?? '?';
  return '<span class="result-icon step-icon" '
      'style="background:${color.solid}" title="$result">$glyph</span>';
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

/// One table row's worth of a case, with the same widening and promotion the
/// JSON writer applies, so the two surfaces never disagree about a verdict.
class _Row {
  const _Row({
    required this.feature,
    required this.name,
    required this.severity,
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
      severity: testCase.meta?.severity,
      stepCount: testCase.steps.length,
      startMs: bounds.start,
      stopMs: bounds.stop,
      result: resultName[status]!,
      href: htmlReportName(testCase),
      tags: testCase.tags,
    );
  }

  final String feature;
  final String name;

  /// What `scenario(severity:)` declared, or null when a test declared none.
  final String? severity;

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
