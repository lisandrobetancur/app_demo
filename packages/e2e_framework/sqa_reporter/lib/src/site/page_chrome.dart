/// The chrome every page of the site shares: head, banner, main menu and
/// footer. One place, so the dashboard and the detail pages can never drift
/// apart.
library;

import 'dashboard.dart' show escapeHtml, projectTitleFor;
import 'site_assets.dart' show wordmarkMark;

/// The document head — same stylesheet, same icon, every page.
///
/// The tab says which report this is as well as which tool wrote it: a reader
/// with the web and the Android report open at once tells them apart by their
/// tabs, which is the only place both are visible at the same time.
String pageHead(String platform) =>
    '''
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>E2E Framework · ${escapeHtml(projectTitleFor(platform))}</title>
<link rel="icon" href="favicon.svg" type="image/svg+xml"/>
<link rel="stylesheet" href="sqa-reporter.css"/>
</head>
''';

/// The banner: the report's mark and name on the left, linking home, and on
/// the right the one line saying what this report is of.
///
/// Both halves are derived, never given: the wording comes from the platform
/// the suite ran on (see [projectTitleFor]) so two reports of the same suite
/// are named the same way in every project that builds them.
String banner(String platform) =>
    '''
<div class="topheader">
  <div class="topbanner">
    <a class="wordmark" href="index.html">
      $wordmarkMark
      <span class="wordmark-text"><span class="wordmark-lead">E2E</span><span class="wordmark-name">Framework</span></span>
    </a>
    <div class="projectname">
      <span class="projecttitle">${escapeHtml(projectTitleFor(platform))}</span>
    </div>
  </div>
</div>
''';

/// The main menu with the generation stamp. [homeActive] is true on the
/// dashboard itself and [featuresActive] on the features pages; a page that
/// is neither renders both as links back.
String menuBar(
  DateTime generatedAt, {
  required bool homeActive,
  bool featuresActive = false,
  Duration offset = reportOffset,
}) {
  final String home = homeActive
      ? '<li class="active"><a href="#">Overall Test Results</a></li>'
      : '<li><a href="index.html">Overall Test Results</a></li>';
  final String features = featuresActive
      ? '<li class="active"><a href="#">Features</a></li>'
      : '<li><a href="features.html">Features</a></li>';
  return '''
<div>
  <span class="date-and-time">Report generated ${timestampOf(generatedAt, offset: offset)}</span>
  <ul class="nav nav-tabs">
    $home
    $features
  </ul>
</div>
''';
}

/// The version line at the bottom of every page.
String pageFooter() => '''
<div class="footer">
<span class="version">E2E Framework version 0.1.0</span>
</div>
''';

/// The offset the report shows its times in, when nothing else is given.
///
/// UTC−5: Bogotá, Lima and Quito, the clock the suite itself runs on — the
/// web runner pins `--web-timezone=America/Bogota`, so a report in UTC was
/// showing times five hours from the ones the app under test saw. None of
/// those three zones observes daylight saving, which is why a fixed offset is
/// exact for them and no timezone database is needed to be right.
///
/// It is also the clock the report *reads* on: Patrol writes every timestamp
/// without a zone, and this says which one it meant — see `epochOfStamp`. One
/// setting for both halves is the point, because a report that read on one
/// clock and printed on another is exactly how Android came out hours off.
///
/// `--utc-offset` on the command line moves it for a team on another clock.
const Duration reportOffset = Duration(hours: -5);

/// `2026-08-18 10:00:00 UTC-5` — the site's one timestamp format.
///
/// The instant is the same one the JSON results carry; those stay in UTC,
/// because a machine reading them wants an unambiguous instant, and the `Z`
/// says so. This is the reading for people.
String timestampOf(DateTime at, {Duration offset = reportOffset}) {
  final DateTime shown = at.toUtc().add(offset);
  String pad(int value) => value.toString().padLeft(2, '0');
  return '${shown.year}-${pad(shown.month)}-${pad(shown.day)} '
      '${pad(shown.hour)}:${pad(shown.minute)}:${pad(shown.second)} '
      '${offsetLabel(offset)}';
}

/// `UTC-5`, `UTC+2`, `UTC+5:30`, `UTC` — the offset as a reader writes it.
String offsetLabel(Duration offset) {
  if (offset == Duration.zero) {
    return 'UTC';
  }
  final Duration size = offset.abs();
  final int minutes = size.inMinutes % 60;
  return 'UTC${offset.isNegative ? '-' : '+'}${size.inHours}'
      '${minutes == 0 ? '' : ':${minutes.toString().padLeft(2, '0')}'}';
}

/// `-05:00`, `+2`, `0` → a [Duration]. Returns null when it reads as
/// anything else, so the caller can say so rather than silently using UTC.
Duration? parseOffset(String text) {
  final RegExpMatch? match = RegExp(
    r'^([+-])?(\d{1,2})(?::?(\d{2}))?$',
  ).firstMatch(text.trim());
  if (match == null) {
    return null;
  }
  final int hours = int.parse(match.group(2)!);
  final int minutes = int.parse(match.group(3) ?? '0');
  if (hours > 14 || minutes > 59) {
    return null;
  }
  final Duration size = Duration(hours: hours, minutes: minutes);
  return match.group(1) == '-' ? -size : size;
}
