/// The chrome every page of the site shares: head, banner, main menu and
/// footer. One place, so the dashboard and the detail pages can never drift
/// apart.
library;

import 'dashboard.dart' show escapeHtml, projectTitleFor;

/// The document head — same stylesheet, same title, every page.
String pageHead() => '''
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>SQA Reporter</title>
<link rel="stylesheet" href="sqa-reporter.css"/>
</head>
''';

/// The banner: the report's own name on the left, the project title —
/// `Test e2e Web` / `Test e2e Mobile` by platform — on the right.
String banner(String platform) =>
    '''
<div class="topheader">
  <div class="topbanner">
    <div class="wordmark">SQA <span class="accent">Reporter</span></div>
    <div class="projectname">
      <span class="projecttitle">${escapeHtml(projectTitleFor(platform))}</span>
      <span class="projectsubtitle">E2E test report</span>
    </div>
  </div>
</div>
''';

/// The main menu with the generation stamp. [homeActive] is true on the
/// dashboard itself and [requirementsActive] on the requirements pages; a
/// page that is neither renders both as links back.
String menuBar(
  DateTime generatedAt, {
  required bool homeActive,
  bool requirementsActive = false,
}) {
  final String home = homeActive
      ? '<li class="active"><a href="#">Overall Test Results</a></li>'
      : '<li><a href="index.html">Overall Test Results</a></li>';
  final String requirements = requirementsActive
      ? '<li class="active"><a href="#">Requirements</a></li>'
      : '<li><a href="capabilities.html">Requirements</a></li>';
  return '''
<div>
  <span class="date-and-time">Report generated ${timestampOf(generatedAt)}</span>
  <ul class="nav nav-tabs">
    $home
    $requirements
  </ul>
</div>
''';
}

/// The version line at the bottom of every page.
String pageFooter() => '''
<div class="footer">
<span class="version">SQA Reporter version 0.1.0</span>
</div>
''';

/// `2026-08-18 10:00:00 UTC` — the site's one timestamp format.
String timestampOf(DateTime at) {
  String pad(int value) => value.toString().padLeft(2, '0');
  return '${at.year}-${pad(at.month)}-${pad(at.day)} '
      '${pad(at.hour)}:${pad(at.minute)}:${pad(at.second)} UTC';
}
