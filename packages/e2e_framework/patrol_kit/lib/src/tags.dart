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
/// And one that is neither axis: [wip], which reports a test as skipped
/// instead of running it.
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

  /// Work in progress: being refactored or repaired, and **not executed**
  /// until the tag comes off.
  ///
  /// This is the one tag [e2eTest] acts on by itself: a test wearing it is
  /// registered and reported as *skipped*, and its body never runs. So it
  /// cannot fail — a half-finished test that fails is noise, and noise on a
  /// red suite is what teaches people to ignore it — but it is still there,
  /// counted under Skipped in the report, wearing the pale row of a test
  /// nobody ran.
  ///
  /// That visibility is the whole point. An excluded test is invisible and
  /// rots; a skipped one is a debt somebody can see. It is also why this is a
  /// tag and not a commented-out block: a commented test stops compiling
  /// against the app and rots the same way, while this one still builds and
  /// still gets renamed by a refactor.
  ///
  /// Nothing of what it declares reaches the report, because `scenario()` and
  /// every step live inside the body that does not run: the row shows the
  /// scenario's name and that it was skipped, and no steps.
  ///
  /// `melos run e2eWebWip` runs them and only them — see [runningWip].
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

/// Whether this run was asked for the work-in-progress tests.
///
/// Set by `--wip` on either runner, which passes
/// `--dart-define PATROL_RUN_WIP=true`. It has to be a compile-time constant
/// and not a flag read at run time: [Tags.wip] decides `skip`, and `skip` is
/// read while the test is being *registered*, before any test body — or any
/// environment lookup inside one — has had a chance to run.
const bool runningWip = bool.fromEnvironment('PATROL_RUN_WIP');

/// Whether a test carrying [tags] should be registered as skipped.
///
/// An explicit `skip:` always wins: a test that says why it is skipped knows
/// better than a tag. Otherwise [Tags.wip] skips, unless this run asked for
/// exactly those.
///
/// Returns null rather than false for "run it", because that is what
/// `patrolTest` wants: false would still be an answer, and null is the
/// absence of one.
bool? skipFor(List<String> tags, {bool? explicit, bool wipRun = runningWip}) {
  if (explicit != null) {
    return explicit;
  }
  return tags.contains(Tags.wip) && !wipRun ? true : null;
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
/// ```
///
/// Tags are matched against what the test declares, so a filter that names a
/// tag nobody uses selects nothing and the run reports zero tests — which is
/// why the vocabulary lives in [Tags] rather than in each test file.
///
/// One tag is read here rather than by the runner: [Tags.wip] decides
/// `skip` — see [skipFor].
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
    // The tag decides, so an author writes `Tags.wip` and nothing else: no
    // second thing to remember, and no way to tag one and forget the other.
    skip: skipFor(tags, explicit: skip),
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
