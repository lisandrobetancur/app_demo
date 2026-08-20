import 'dart:convert';

import 'package:flutter/foundation.dart';
// For `Timeout`, which `patrolTest` takes and which reaches here through
// flutter_test rather than from Flutter itself.
import 'package:flutter_test/flutter_test.dart' show Timeout;
import 'package:meta/meta.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_finders/patrol_finders.dart' as finders;

import 'failure_report.dart';
import 'log.dart';

/// Marker the report generator reads to label a test with its tags.
const String _marker = 'PATROL_TAGS';

/// The tag vocabulary.
///
/// Tags are plain strings, which is exactly the problem: written by hand they
/// drift into `smoke`, `smoke_test` and `smokeTest`, and a filter that misses
/// a spelling silently runs fewer tests than the person who typed it thinks.
/// Naming them once here makes the compiler the thing that catches the typo.
///
/// Two axes, deliberately kept apart:
///
///  * **How much of the suite** — [smoke], [regression].
///  * **What kind of case** — [success] for the happy path, [negative] for
///    the ones that assert a rejection.
///
/// A test usually carries one of each. Nothing forbids other strings; these
/// are the ones the pipeline knows about.
///
/// And one that is neither axis: [wip], which takes a test out of every run.
class Tags {
  const Tags._();

  /// The short suite: the handful of cases that decide whether a build is
  /// worth testing further.
  static const String smoke = 'smoke_test';

  /// The full suite.
  static const String regression = 'regression';

  /// Happy path — the case where the product is asked to do its job and does.
  static const String success = 'success';

  /// Negative path — the case where the product is asked for something it
  /// must refuse, and the assertion is on the refusal.
  static const String negative = 'negative';

  /// Work in progress: being refactored or repaired, and **not run by
  /// anyone** until the tag comes off.
  ///
  /// This is the one tag the runners act on by themselves. They pass
  /// `--exclude-tags wip` on every invocation, so a test wearing it is left
  /// out of the bundle before a browser or a device is even started — not run
  /// and reported as skipped, but absent. A half-finished test that fails is
  /// noise, and noise on a red suite is what teaches people to ignore it.
  ///
  /// Which is also why it is a tag and not a comment: a commented-out test
  /// stops compiling against the app and rots in silence, while a `wip` one
  /// still has to build, still gets renamed by a refactor, and shows up in
  /// `--wip` when somebody wants to see what is unfinished.
  static const String wip = 'wip';

  /// Every tag the kit names.
  static const List<String> all = <String>[
    smoke,
    regression,
    success,
    negative,
    wip,
  ];
}

/// A Patrol test that carries tags.
///
/// Wraps `patrolTest` so a tag is declared **once** and reaches both places
/// that need it:
///
///  * **The runner**, through Patrol's own `tags:`. Filtering happens while
///    the test bundle is generated, so an excluded test is never built into
///    the binary — not built and then skipped.
///  * **The report**, through the `PATROL_TAGS` marker, which the converter
///    turns into report tags so the same vocabulary filters the
///    results.
///
/// ```dart
/// e2eTest(
///   'rejects invalid credentials',
///   tags: <String>[Tags.smoke, Tags.negative],
///   ($) async { … },
/// );
/// ```
///
/// Selecting on the command line uses boolean expressions, not just names:
///
/// ```sh
/// patrol test --device chrome --tags "smoke_test && negative"
/// patrol test --device chrome --exclude-tags "wip"
/// ```
///
/// Tags are matched against what the test declares, so a filter that names a
/// tag nobody uses selects nothing and the run reports zero tests — which is
/// why the vocabulary lives in [Tags] rather than in each test file.
///
/// The second line is not an example anybody has to type: `run_web.sh` and
/// `run_android.sh` pass it on every run, so [Tags.wip] takes a test out of
/// the bundle by itself.
@isTest
void e2eTest(
  String description,
  PatrolTesterCallback callback, {
  List<String> tags = const <String>[],
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  finders.PatrolTesterConfig config = const finders.PatrolTesterConfig(
    printLogs: true,
  ),
  PlatformAutomatorConfig? platformAutomatorConfig,
}) {
  // Installed here, while the test is being registered rather than while it
  // runs: a failed expectation prints as its message, not as forty frames of
  // async plumbing. See `failure_report.dart`.
  useCompactFailureReports();
  patrolTest(
    description,
    // `dynamic` on Patrol's side; an empty list would mean "tagged with
    // nothing", which is not the same as untagged, so it is passed as null.
    tags: tags.isEmpty ? null : tags,
    skip: skip,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    config: config,
    platformAutomatorConfig: platformAutomatorConfig,
    (PatrolIntegrationTester $) async {
      emitTags(tags);
      Log.info('▶ $description', data: <String, Object>{'tags': tags});
      await callback($);
    },
  );
}

/// Prints the tag marker the report generator turns into tags.
///
/// Exposed for the rare test that still calls `patrolTest` directly — the
/// wrapper is the ordinary way in.
void emitTags(List<String> tags) {
  if (tags.isEmpty) {
    return;
  }
  debugPrintSynchronously('$_marker ${jsonEncode(tags)}');
}
