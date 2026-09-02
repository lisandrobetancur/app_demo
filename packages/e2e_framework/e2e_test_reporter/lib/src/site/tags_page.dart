/// A page per tag: the scenarios that carried it.
///
/// A tag in the cloud that leads nowhere is decoration. The vocabulary here
/// is the one the runner filters on (`--tags=smoke_test`), so the useful
/// question a reader asks of a tag is "which tests would that selection have
/// run, and how did they do" — which is exactly what this page answers.
library;

import 'dart:io';

import '../markers.dart';
import '../model.dart';
import '../results_writer.dart';
import 'dashboard.dart' show compoundDuration, escapeHtml, resultIcon;
import 'page_chrome.dart';
import 'site_assets.dart';

/// `<slug>_tag.html` — the page for one tag.
String tagReportName(String tag) => '${slugOf(tag)}_tag.html';

/// Every tag the run declared, with the cases that carried it, in the order
/// the cloud lists them.
Map<String, List<RunCase>> tagsOf(ParsedRun run) {
  final Map<String, List<RunCase>> byTag = <String, List<RunCase>>{};
  for (final RunCase testCase in run.cases) {
    for (final String tag in testCase.tags) {
      byTag.putIfAbsent(tag, () => <RunCase>[]).add(testCase);
    }
  }
  return Map<String, List<RunCase>>.fromEntries(
    byTag.entries.toList()..sort(
      (MapEntry<String, List<RunCase>> a, MapEntry<String, List<RunCase>> b) =>
          a.key.compareTo(b.key),
    ),
  );
}

/// Writes one page per tag. Returns the files written.
List<File> writeTagPages(
  ParsedRun run,
  Directory outputDir, {
  required String platform,
  Duration offset = reportOffset,
  DateTime? generatedAt,
}) {
  outputDir.createSync(recursive: true);
  final DateTime stamp = generatedAt ?? DateTime.now().toUtc();
  return <File>[
    for (final MapEntry<String, List<RunCase>> entry in tagsOf(run).entries)
      File(
        '${outputDir.path}${Platform.pathSeparator}${tagReportName(entry.key)}',
      )..writeAsStringSync(
        tagPageHtml(
          entry.key,
          entry.value,
          platform: platform,
          offset: offset,
          generatedAt: stamp,
        ),
      ),
  ];
}

/// The page itself, as a string — separated from the file write so tests can
/// assert on content without a filesystem.
String tagPageHtml(
  String tag,
  List<RunCase> cases, {
  required String platform,
  required DateTime generatedAt,
  Duration offset = reportOffset,
}) {
  final List<RunCase> sorted = List<RunCase>.of(cases)
    ..sort((RunCase a, RunCase b) => a.name.compareTo(b.name));
  final int passing = sorted
      .where(
        (RunCase c) => promoteStatus(c.status, c.steps) == RunStatus.passed,
      )
      .length;

  final StringBuffer rows = StringBuffer();
  for (final RunCase testCase in sorted) {
    final String result =
        resultName[promoteStatus(testCase.status, testCase.steps)]!;
    final ({int start, int stop}) bounds = widenedBoundsOf(testCase);
    rows.writeln(
      '<tr data-result="$result">'
      '<td>${escapeHtml(testCase.meta?.feature ?? testCase.suite)}</td>'
      '<td><a href="${htmlReportName(testCase)}">'
      '${escapeHtml(testCase.name)}</a></td>'
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
    ..write(banner(platform, generatedAt: generatedAt, offset: offset))
    ..writeln('<div class="middlecontent">')
    ..writeln(
      breadcrumbs(<Crumb>[
        (label: 'Home', href: 'index.html'),
        (label: 'Tag', href: null),
        (label: tag, href: null),
      ]),
    )
    ..write(menuBar(generatedAt, homeActive: false, offset: offset))
    ..writeln('<h2>${escapeHtml(tag)}</h2>')
    ..writeln(
      '<div class="test-count-title">Tag · ${sorted.length} '
      'test${sorted.length == 1 ? '' : 's'}, '
      '${sorted.isEmpty ? 'none run' : '${(passing * 100 / sorted.length).round()}% passing'}'
      '</div>',
    )
    ..writeln('<div class="card standalone">')
    ..writeln('<h3>Scenarios</h3>')
    ..writeln('<table class="table table-striped">')
    ..writeln(
      '<thead><tr><th>Feature</th><th>Scenario</th><th>Steps</th>'
      '<th>Duration</th><th>Result</th></tr></thead>',
    )
    ..writeln('<tbody>')
    ..write(rows)
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
