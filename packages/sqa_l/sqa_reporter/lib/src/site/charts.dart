/// The dashboard's three charts, drawn with CSS and arithmetic done here.
///
/// The reference draws these on a charting library: a doughnut with the share
/// written on each segment and the overall pass rate in the hole, a bar chart
/// of outcomes with a labelled Y axis, and a histogram of how long tests took.
/// Same three charts, same readings, computed in Dart and laid out with a
/// conic gradient and flexbox — which is what keeps the generated site free of
/// libraries.
library;

import 'dart:math' as math;

import 'site_assets.dart';

/// The verdict order every chart and legend uses, so a colour always means
/// the same thing in the same position.
const List<String> chartOrder = <String>[
  'SUCCESS',
  'SKIPPED',
  'FAILURE',
  'ERROR',
  'UNDEFINED',
];

/// The label each verdict carries in the charts.
const Map<String, String> chartLabels = <String, String>{
  'SUCCESS': 'Passing',
  'SKIPPED': 'Skipped',
  'FAILURE': 'Failed',
  'ERROR': 'Broken',
  'UNDEFINED': 'Undefined',
};

/// The doughnut: one segment per verdict, its share written on it, and the
/// overall pass rate in the middle.
String donutChart(Map<String, int> counts, int total) {
  if (total == 0) {
    return '<div class="donut-wrap"><div class="donut" '
        'style="background:#ececec"><span class="donut-label">—</span>'
        '</div></div>';
  }

  final List<String> segments = <String>[];
  final StringBuffer wedges = StringBuffer();
  final StringBuffer labels = StringBuffer();
  double from = 0;
  for (final String result in chartOrder) {
    final int count = counts[result] ?? 0;
    if (count == 0) {
      continue;
    }
    final double sweep = count * 360 / total;
    final double to = from + sweep;
    segments.add(
      '${resultColors[result]!.fill} '
      '${from.toStringAsFixed(2)}deg ${to.toStringAsFixed(2)}deg',
    );

    // A gradient cannot be clicked segment by segment, so each segment also
    // gets a transparent ring sector on top of it: the same arc, as a
    // polygon, which is what makes "click the passing slice" possible without
    // a charting library.
    wedges.write(
      '<a class="donut-wedge" href="#tests" data-result="$result" '
      'title="${chartLabels[result]}: $count of $total" '
      'style="clip-path:${_ringSector(from, to)}"></a>',
    );

    // The share is written on the segment itself, as the reference does, and
    // only when there is room for it: a sliver of a degree gets a colour in
    // the ring and its number in the legend instead.
    final int percentage = (count * 100 / total).round();
    if (percentage >= 5) {
      final double middle = (from + to) / 2 * math.pi / 180;
      // 36% of the box from the centre: outside the hole, inside the rim.
      final double x = 50 + 36 * math.sin(middle);
      final double y = 50 - 36 * math.cos(middle);
      labels.write(
        '<span class="donut-slice-label" '
        'style="left:${x.toStringAsFixed(2)}%;top:${y.toStringAsFixed(2)}%">'
        '$percentage%</span>',
      );
    }
    from = to;
  }

  final int passing = counts['SUCCESS'] ?? 0;
  // The hole is where a reader's cursor goes first — it is where the number
  // is, and with a single verdict it is most of what the chart looks like.
  // Leaving it inert made the whole doughnut feel dead, so it leads to the
  // table with nothing filtered out: the middle reads the whole run.
  return '<div class="donut-wrap">'
      '<div class="donut" '
      'style="background:conic-gradient(${segments.join(', ')})">'
      '$wedges'
      '$labels'
      '<a class="donut-label" href="#tests" data-result="" '
      'title="All tests">${(passing * 100 / total).round()}%</a>'
      '</div></div>';
}

/// One segment of the ring as a `clip-path` polygon: out along the rim from
/// [fromDegrees] to [toDegrees], back along the inside of the hole. Stepping
/// the arc every few degrees is close enough that the edge reads as a curve
/// and the click lands where the colour is.
String _ringSector(double fromDegrees, double toDegrees) {
  const double outer = 50;
  const double inner = 26; // the hole, matching `.donut::before`'s inset
  final int steps = math.max(2, ((toDegrees - fromDegrees) / 4).ceil());
  final List<String> points = <String>[];

  String at(double degrees, double radius) {
    final double a = degrees * math.pi / 180;
    final double x = 50 + radius * math.sin(a);
    final double y = 50 - radius * math.cos(a);
    return '${x.toStringAsFixed(2)}% ${y.toStringAsFixed(2)}%';
  }

  for (int i = 0; i <= steps; i += 1) {
    points.add(at(fromDegrees + (toDegrees - fromDegrees) * i / steps, outer));
  }
  for (int i = steps; i >= 0; i -= 1) {
    points.add(at(fromDegrees + (toDegrees - fromDegrees) * i / steps, inner));
  }
  return 'polygon(${points.join(', ')})';
}

/// The legend under the doughnut: every verdict the vocabulary has, present
/// or not, so the reader sees at a glance that nothing was aborted rather
/// than wondering whether aborted tests are even reported.
String chartLegend(Map<String, int> counts) {
  final StringBuffer legend = StringBuffer('<ul class="chart-legend">');
  for (final String result in chartOrder) {
    final int count = counts[result] ?? 0;
    final ({String fill, String border, String solid}) color =
        resultColors[result]!;
    // A verdict nobody hit is listed but not clickable: there is nothing to
    // show, and a link that lands on an empty table is worse than no link.
    final String label =
        '<span class="swatch" style="background:${color.fill};'
        'border-color:${color.border}"></span>'
        '${chartLabels[result]} Test Cases'
        '${count == 0 ? '' : ' ($count)'}';
    legend.write(
      count == 0
          ? '<li class="empty">$label</li>'
          : '<li><a href="#tests" data-result="$result">$label</a></li>',
    );
  }
  legend.write('</ul>');
  return legend.toString();
}

/// The outcomes bar chart: one bar per verdict against a labelled axis, with
/// the count written inside the bar.
String outcomesChart(Map<String, int> counts) {
  final int highest = chartOrder.fold(
    0,
    (int carried, String result) => math.max(carried, counts[result] ?? 0),
  );
  final ({int top, int step}) axis = niceAxis(highest);

  final StringBuffer bars = StringBuffer();
  for (final String result in chartOrder) {
    final int count = counts[result] ?? 0;
    final ({String fill, String border, String solid}) color =
        resultColors[result]!;
    final double height = axis.top == 0 ? 0 : count * 100 / axis.top;
    // Clicking a bar shows the tests behind it, so the chart is a way into
    // the table rather than a picture beside it.
    final String column =
        '<div class="bar-fill" style="height:${height.toStringAsFixed(2)}%;'
        'background:${color.fill};border-color:${color.border}">'
        '${count == 0 ? '' : '<span class="bar-value">$count</span>'}'
        '</div>'
        '<div class="bar-label">${chartLabels[result]}</div>';
    bars.write(
      count == 0
          ? '<div class="bar-column">$column</div>'
          : '<a class="bar-column" href="#tests" data-result="$result" '
                'title="${chartLabels[result]}: $count">$column</a>',
    );
  }

  return _plot(axis: axis, bars: bars.toString(), extraClass: '');
}

/// How long the tests took, bucketed the way the reference buckets them: the
/// question this answers is "is anything unreasonably slow", and the buckets
/// are what make that visible without reading every row.
String durationChart(List<int> durationsMs) {
  const List<({String label, int upperMs})> buckets =
      <({String label, int upperMs})>[
        (label: 'Under 1 second', upperMs: 1000),
        (label: '1 to 10 seconds', upperMs: 10000),
        (label: '10 to 30 seconds', upperMs: 30000),
        (label: '30 to 60 seconds', upperMs: 60000),
        (label: '1 to 2 minutes', upperMs: 120000),
        (label: '2 to 5 minutes', upperMs: 300000),
        (label: '5 to 10 minutes', upperMs: 600000),
        (label: '10 minutes or over', upperMs: 1 << 62),
      ];

  final List<int> tally = List<int>.filled(buckets.length, 0);
  for (final int duration in durationsMs) {
    for (int i = 0; i < buckets.length; i += 1) {
      if (duration < buckets[i].upperMs) {
        tally[i] += 1;
        break;
      }
    }
  }

  final int highest = tally.fold(0, math.max);
  final ({int top, int step}) axis = niceAxis(highest);

  final StringBuffer bars = StringBuffer();
  for (int i = 0; i < buckets.length; i += 1) {
    final double height = axis.top == 0 ? 0 : tally[i] * 100 / axis.top;
    bars.write(
      '<div class="bar-column">'
      '<div class="bar-fill duration-fill" '
      'style="height:${height.toStringAsFixed(2)}%">'
      '${tally[i] == 0 ? '' : '<span class="bar-value">${tally[i]}</span>'}'
      '</div>'
      '<div class="bar-label slanted">${buckets[i].label}</div>'
      '</div>',
    );
  }

  return _plot(axis: axis, bars: bars.toString(), extraClass: ' slanted-axis');
}

/// The plot frame both bar charts share: a Y axis with its ticks, gridlines
/// across the plot, and the bars sitting on the baseline.
String _plot({
  required ({int top, int step}) axis,
  required String bars,
  required String extraClass,
}) {
  final StringBuffer ticks = StringBuffer();
  final StringBuffer lines = StringBuffer();
  for (int value = axis.top; value >= 0; value -= axis.step) {
    ticks.write('<div class="y-tick">$value</div>');
    lines.write('<div class="gridline"></div>');
    if (axis.step == 0) {
      break;
    }
  }
  return '<div class="plot$extraClass">'
      '<div class="y-axis">$ticks</div>'
      '<div class="plot-area">'
      '<div class="gridlines">$lines</div>'
      '<div class="bars">$bars</div>'
      '</div>'
      '</div>';
}

/// A rounded axis top and a step that divides it — the axis reads 0, 5, 10 …
/// rather than 0, 3.7, 7.4, and a chart of one test still has an axis.
({int top, int step}) niceAxis(int highest) {
  if (highest <= 0) {
    return (top: 1, step: 1);
  }
  for (final int step in <int>[1, 2, 5, 10, 25, 50, 100, 250, 500, 1000]) {
    final int top = (highest / step).ceil() * step;
    if (top ~/ step <= 9) {
      return (top: top, step: step);
    }
  }
  final int step = (highest / 8).ceil();
  return (top: step * 8, step: step);
}
