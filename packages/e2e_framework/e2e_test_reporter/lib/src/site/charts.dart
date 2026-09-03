/// The dashboard's three charts, drawn as inline SVG with the arithmetic done
/// here.
///
/// Same three readings as the reference — a doughnut with the pass rate in
/// the hole, a bar chart of outcomes against a labelled axis, and a histogram
/// of how long tests took — computed in Dart and drawn to one scale, which is
/// what keeps the generated site free of libraries. Every mark, tick and
/// label comes off the same numbers, and the colours are CSS tokens so the
/// theme switch reaches them.
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

/// The duration buckets, short enough to sit under their bars unrotated: a
/// label that has to be turned is a label nobody reads.
const List<({String label, int upperMs})> durationBuckets =
    <({String label, int upperMs})>[
      (label: '<1s', upperMs: 1000),
      (label: '1–10s', upperMs: 10000),
      (label: '10–30s', upperMs: 30000),
      (label: '30–60s', upperMs: 60000),
      (label: '1–2m', upperMs: 120000),
      (label: '2–5m', upperMs: 300000),
      (label: '5–10m', upperMs: 600000),
      (label: '>10m', upperMs: 1 << 62),
    ];

const double _donutBox = 160;
const double _donutRadius = 58;
const double _donutCentre = 80;

/// The doughnut: one ring segment per verdict, the overall pass rate in the
/// hole.
///
/// No share is written on the segments themselves: the ring carries the
/// proportion and the legend carries the count, and a third number under the
/// hole was saying what the hole already said.
String donutChart(Map<String, int> counts, int total) {
  final StringBuffer svg = StringBuffer()
    ..write(
      '<svg class="chart donut" viewBox="0 0 $_donutBox $_donutBox" '
      'role="img" aria-label="Pass rate">',
    )
    ..write(
      '<circle class="donut-track" cx="$_donutCentre" cy="$_donutCentre" '
      'r="$_donutRadius"/>',
    );

  if (total == 0) {
    svg
      ..write(
        '<text class="donut-center" x="$_donutCentre" y="${_donutCentre + 4}" '
        'text-anchor="middle">—</text>',
      )
      ..write('</svg>');
    return '<div class="donut-wrap">$svg</div>';
  }

  final double circumference = 2 * math.pi * _donutRadius;
  double offset = 0;
  for (final String result in chartOrder) {
    final int count = counts[result] ?? 0;
    if (count == 0) {
      continue;
    }
    final double length = circumference * count / total;
    // Each segment is a link: the chart is a way into the table, not a
    // picture beside it. The dash pattern draws exactly this verdict's arc,
    // starting where the previous one ended, from twelve o'clock.
    svg.write(
      '<a class="donut-wedge" href="#tests" data-result="$result" '
      'title="${chartLabels[result]}: $count of $total">'
      '<circle class="donut-segment" cx="$_donutCentre" cy="$_donutCentre" '
      'r="$_donutRadius" stroke="var(${resultTokens[result]})" '
      'stroke-dasharray="${_n(length)} ${_n(circumference - length)}" '
      'stroke-dashoffset="${_n(-offset)}" '
      'transform="rotate(-90 $_donutCentre $_donutCentre)">'
      '<title>${chartLabels[result]}: $count of $total</title>'
      '</circle></a>',
    );
    offset += length;
  }

  final int passing = counts['SUCCESS'] ?? 0;
  // The hole is where a reader's cursor goes first, so it leads to the table
  // with nothing filtered out: the middle reads the whole run.
  svg
    ..write(
      '<a class="donut-label" href="#tests" data-result="" title="All tests">'
      '<text class="donut-center" x="$_donutCentre" y="${_donutCentre + 4}" '
      'text-anchor="middle">${(passing * 100 / total).round()}%</text>'
      '<text class="donut-eyebrow" x="$_donutCentre" y="${_donutCentre + 22}" '
      'text-anchor="middle">pass rate</text></a>',
    )
    ..write('</svg>');
  return '<div class="donut-wrap">$svg</div>';
}

/// The legend under the doughnut: every verdict the vocabulary has, present
/// or not, so the reader sees at a glance that nothing was aborted rather
/// than wondering whether aborted tests are even reported. The count sits at
/// the right edge in the mono face, so a column of them lines up.
String chartLegend(Map<String, int> counts) {
  final StringBuffer legend = StringBuffer('<ul class="chart-legend">');
  for (final String result in chartOrder) {
    final int count = counts[result] ?? 0;
    final String row =
        '<span class="swatch" style="background:var(${resultTokens[result]})">'
        '</span>${chartLabels[result]}'
        '<span class="legend-count">$count</span>';
    // A verdict nobody hit is listed but not clickable: there is nothing to
    // show, and a link that lands on an empty table is worse than no link.
    legend.write(
      count == 0
          ? '<li class="empty">$row</li>'
          : '<li><a href="#tests" data-result="$result" '
                'title="${chartLabels[result]}: $count">$row</a></li>',
    );
  }
  legend.write('</ul>');
  return legend.toString();
}

/// The outcomes bar chart: one bar per verdict against a labelled axis, with
/// the count written above the bar.
String outcomesChart(Map<String, int> counts) {
  final List<_Bar> bars = <_Bar>[
    for (final String result in chartOrder)
      _Bar(
        label: chartLabels[result]!,
        value: counts[result] ?? 0,
        fill: 'var(${resultTokens[result]})',
        // Clicking a bar shows the tests behind it.
        link: (counts[result] ?? 0) == 0
            ? null
            : (
                href: '#tests',
                result: result,
                title: '${chartLabels[result]}: ${counts[result]}',
              ),
      ),
  ];
  return _barChart(bars, width: 420);
}

/// How long the tests took, bucketed: the question this answers is "is
/// anything unreasonably slow", and the band the slowest test fell in is
/// marked so the answer reads without the legend.
String durationChart(List<int> durationsMs) {
  final List<int> tally = List<int>.filled(durationBuckets.length, 0);
  int slowestBucket = -1;
  for (final int duration in durationsMs) {
    for (int i = 0; i < durationBuckets.length; i += 1) {
      if (duration < durationBuckets[i].upperMs) {
        tally[i] += 1;
        slowestBucket = math.max(slowestBucket, i);
        break;
      }
    }
  }

  final List<_Bar> bars = <_Bar>[
    for (int i = 0; i < durationBuckets.length; i += 1)
      _Bar(
        label: durationBuckets[i].label,
        value: tally[i],
        fill: i == slowestBucket ? 'var(--ch-slow)' : 'var(--ch-bar)',
        extraClass: i == slowestBucket ? ' slowest' : ' duration-fill',
      ),
  ];
  return _barChart(bars, width: 520);
}

class _Bar {
  const _Bar({
    required this.label,
    required this.value,
    required this.fill,
    this.link,
    this.extraClass = '',
  });

  final String label;
  final int value;
  final String fill;
  final ({String href, String result, String title})? link;
  final String extraClass;
}

const double _plotHeight = 220;
const double _padLeft = 44;
const double _padRight = 8;
const double _padTop = 22;
const double _padBottom = 30;

/// The plot frame both bar charts share: a Y axis with its ticks, gridlines
/// across the plot, the axis title down the left, and the bars sitting on the
/// baseline — each 40% of its band, its top corners rounded, its value above
/// it. A bar with nothing in it is drawn as a 2px ghost in its own colour, so
/// the axis keeps every category without looking broken.
String _barChart(List<_Bar> bars, {required double width}) {
  final int highest = bars.fold(
    0,
    (int carried, _Bar bar) => math.max(carried, bar.value),
  );
  final ({int top, int step}) axis = niceAxis(highest);
  final double plotWidth = width - _padLeft - _padRight;
  final double plotHeight = _plotHeight - _padTop - _padBottom;
  final double baseline = _padTop + plotHeight;

  final StringBuffer svg = StringBuffer(
    '<svg class="chart" viewBox="0 0 $width $_plotHeight" role="img">',
  );

  for (int value = 0; value <= axis.top; value += axis.step) {
    final double y = baseline - plotHeight * value / axis.top;
    svg
      ..write(
        '<line class="gridline" x1="$_padLeft" y1="${_n(y)}" '
        'x2="${_n(width - _padRight)}" y2="${_n(y)}"/>',
      )
      ..write(
        '<text class="y-tick" x="${_padLeft - 8}" y="${_n(y + 4)}" '
        'text-anchor="end">$value</text>',
      );
    if (axis.step == 0) {
      break;
    }
  }
  svg.write(
    '<text class="axis-title" transform="translate(12 ${_n(_padTop + plotHeight / 2)}) '
    'rotate(-90)" text-anchor="middle">Scenarios</text>',
  );

  final double band = plotWidth / bars.length;
  final double barWidth = band * 0.4;
  for (int i = 0; i < bars.length; i += 1) {
    final _Bar bar = bars[i];
    final double x = _padLeft + band * i + (band - barWidth) / 2;
    final String label = _escape(bar.label);
    if (bar.value > 0) {
      final double height = plotHeight * bar.value / axis.top;
      final double y = baseline - height;
      final double r = math.min(4, height);
      final String mark =
          '<path class="bar-fill${bar.extraClass}" d="M${_n(x)} ${_n(baseline)}'
          'V${_n(y + r)}a${_n(r)} ${_n(r)} 0 0 1 ${_n(r)}-${_n(r)}'
          'h${_n(barWidth - 2 * r)}a${_n(r)} ${_n(r)} 0 0 1 ${_n(r)} ${_n(r)}'
          'V${_n(baseline)}z" fill="${bar.fill}">'
          '<title>$label: ${bar.value}</title></path>'
          '<text class="bar-value" x="${_n(x + barWidth / 2)}" y="${_n(y - 6)}" '
          'text-anchor="middle">${bar.value}</text>';
      final ({String href, String result, String title})? link = bar.link;
      svg.write(
        link == null
            ? '<g class="bar-column">$mark</g>'
            : '<a class="bar-column" href="${link.href}" '
                  'data-result="${link.result}" title="${_escape(link.title)}">'
                  '$mark</a>',
      );
    } else {
      svg.write(
        '<rect class="bar-ghost" x="${_n(x)}" y="${_n(baseline - 2)}" '
        'width="${_n(barWidth)}" height="2" fill="${bar.fill}" opacity="0.4">'
        '<title>$label: 0</title></rect>',
      );
    }
    svg.write(
      '<text class="bar-label" x="${_n(x + barWidth / 2)}" '
      'y="${_n(_plotHeight - 10)}" text-anchor="middle">$label</text>',
    );
  }

  svg.write('</svg>');
  return svg.toString();
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

/// A coordinate with two decimals and no trailing noise.
String _n(double value) {
  final String text = value.toStringAsFixed(2);
  return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
}

/// SVG text is markup: `<1s` has to travel as `&lt;1s`.
String _escape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
