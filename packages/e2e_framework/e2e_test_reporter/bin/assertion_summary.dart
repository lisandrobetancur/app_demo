/// Counts the assertions a run reported, per scenario, for the CI job summary:
///
///   dart run e2e_test_reporter:assertion_summary [--input <file>]
///                                           [--format playwright|patrol-log]
///                                           [--platform web|android|ios]
///
/// A green suite is not the same as a suite that verified something. Every
/// check the suite makes is reported as its own step (`PATROL_ASSERT`, see
/// `BaseSteps.should`), and those markers travel a long way to get here — out
/// of the browser console or logcat, through the transport, into the parser.
/// Any link in that chain can break *silently*: the tests still pass, and the
/// report just holds nothing behind them.
///
/// So the count goes in the job summary, visible from the pull request without
/// downloading an artifact, and a run that asserts nothing at all fails this
/// step rather than being left as a notice nobody opens.
library;

import 'dart:io';

import 'package:e2e_test_reporter/e2e_test_reporter.dart';

void main(List<String> argv) {
  final _Args args = _Args.parse(argv);
  final File input = File(args.input);

  // Two absences that look alike and mean opposite things. No results at all —
  // a cancelled run, or a suite that never got far enough — is not this step's
  // news to break: whatever was supposed to produce them is red already, and a
  // second red mark here only buries it. Say so and leave.
  if (!input.existsSync()) {
    stdout.writeln(
      'No run at ${args.input} — the suite did not get far enough to produce '
      'one. Nothing to summarize.',
    );
    return;
  }

  final ParsedRun run = args.format == 'playwright'
      ? parsePlaywright(input)
      : parsePatrolLog(input);

  // A skipped test is not a silent one: it never ran, so of course it
  // asserted nothing, and counting it among the scenarios that verify nothing
  // would turn `Tags.wip` into a warning every time somebody pauses a test.
  final List<RunCase> executed = run.cases
      .where((RunCase c) => c.status != RunStatus.skipped)
      .toList();

  final List<({String name, int total, int passed, int failed})> rows =
      <({String name, int total, int passed, int failed})>[
        for (final RunCase testCase in executed)
          (
            name: testCase.name,
            total: _count(testCase.steps, (StepNode _) => true),
            passed: _count(
              testCase.steps,
              (StepNode step) => step.status == RunStatus.passed,
            ),
            failed: _count(
              testCase.steps,
              (StepNode step) => step.status != RunStatus.passed,
            ),
          ),
      ]..sort(
        (
          ({String name, int total, int passed, int failed}) a,
          ({String name, int total, int passed, int failed}) b,
        ) => b.total.compareTo(a.total),
      );

  int total = 0;
  int passed = 0;
  int failed = 0;
  for (final ({String name, int total, int passed, int failed}) row in rows) {
    total += row.total;
    passed += row.passed;
    failed += row.failed;
  }

  final StringBuffer out = StringBuffer()
    ..writeln('### Assertions — ${args.platform}')
    ..writeln();

  if (rows.isEmpty) {
    stdout.writeln('No scenarios in ${args.input}. Nothing to summarize.');
    return;
  }

  if (total == 0) {
    // Tests ran, and they verify nothing visible. This is the case the whole
    // step exists for, so it fails rather than warns.
    out
      ..writeln('> [!CAUTION]')
      ..writeln(
        '> **The report of ${rows.length} scenario(s) contains no '
        'assertions.**',
      )
      ..writeln('>')
      ..writeln(
        '> The suite ran and came out green, but it verifies nothing '
        'visible: the',
      )
      ..writeln(
        '> `PATROL_ASSERT` markers never reached the report. Check '
        '`BaseSteps.should`,',
      )
      ..writeln('> `reportAssertion`, and the marker parser.');
    stdout.write(out);
    exitCode = 1;
    return;
  }

  out
    ..writeln('| Scenario | Assertions | Passed | Failed |')
    ..writeln('|---|---:|---:|---:|');
  for (final ({String name, int total, int passed, int failed}) row in rows) {
    out.writeln(
      '| ${row.name} | ${row.total} | ${row.passed} | ${row.failed} |',
    );
  }
  out
    ..writeln('| **Total** | **$total** | **$passed** | **$failed** |')
    ..writeln();

  // A scenario that asserts nothing is not necessarily wrong — a smoke test
  // that only has to not crash is a real thing — but it is worth seeing.
  final int silent = rows
      .where(
        (({String name, int total, int passed, int failed}) row) =>
            row.total == 0,
      )
      .length;
  if (silent > 0) {
    out.writeln(
      '> [!NOTE]\n'
      '> $silent scenario(s) reported no assertions at all.',
    );
  }
  stdout.write(out);
}

/// Assertions anywhere in the tree, counted depth-first — an assertion nested
/// three steps down is still an assertion.
int _count(List<StepNode> steps, bool Function(StepNode) keep) {
  int tally = 0;
  for (final StepNode step in steps) {
    if (step.kind == StepKind.assertion && keep(step)) {
      tally += 1;
    }
    tally += _count(step.children, keep);
  }
  return tally;
}

class _Args {
  _Args({required this.input, required this.format, required this.platform});

  factory _Args.parse(List<String> argv) {
    String? input;
    String? format;
    String? platform;
    for (int i = 0; i + 1 < argv.length; i += 2) {
      switch (argv[i]) {
        case '--input':
          input = argv[i + 1];
        case '--format':
          format = argv[i + 1];
        case '--platform':
          platform = argv[i + 1];
      }
    }
    platform ??= 'web';
    input ??= platform == 'web'
        ? '${_repoRoot()}/build/e2e/web/playwright/results.json'
        : '${_repoRoot()}/build/e2e/$platform/android_run.log';
    format ??= input.endsWith('.json') ? 'playwright' : 'patrol-log';
    return _Args(input: input, format: format, platform: platform);
  }

  final String input;
  final String format;
  final String platform;
}

/// The repo root, found by walking up to the directory that holds `.git`
/// rather than by counting `..` segments — the same rule the rest of the
/// tooling follows, for the same reason: this tree has moved before, and a hop
/// count breaks in silence when it moves again.
String _repoRoot() {
  Directory dir = Directory.current;
  while (!Directory('${dir.path}${Platform.pathSeparator}.git').existsSync() &&
      !File('${dir.path}${Platform.pathSeparator}.git').existsSync()) {
    final Directory parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current.path;
    }
    dir = parent;
  }
  return dir.path;
}
