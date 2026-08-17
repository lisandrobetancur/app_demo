import 'dart:convert';

import 'package:flutter/foundation.dart';
// For `Timeout`, which `patrolTest` takes and which reaches here through
// flutter_test rather than from Flutter itself.
import 'package:flutter_test/flutter_test.dart' show Timeout;
import 'package:meta/meta.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_finders/patrol_finders.dart' as finders;

import 'log.dart';

/// Marker the Allure converter reads to label a test with its tags.
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
///  * **What kind of case** — [exito] for the happy path, [negativo] for the
///    ones that assert a rejection.
///
/// A test usually carries one of each. Nothing forbids other strings; these
/// are the ones the pipeline knows about.
class Tags {
  const Tags._();

  /// The short suite: the handful of cases that decide whether a build is
  /// worth testing further.
  static const String smoke = 'smoke_test';

  /// The full suite.
  static const String regression = 'regression';

  /// Happy path — the case where the product is asked to do its job and does.
  static const String exito = 'exito';

  /// Negative path — the case where the product is asked for something it
  /// must refuse, and the assertion is on the refusal.
  static const String negativo = 'negativo';

  /// Slow enough to be worth excluding from a quick loop.
  static const String lento = 'lento';

  /// Every tag the kit names.
  static const List<String> all = <String>[
    smoke,
    regression,
    exito,
    negativo,
    lento,
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
///    turns into Allure `tag` labels so the same vocabulary filters the
///    results.
///
/// ```dart
/// e2eTest(
///   'rechaza credenciales inválidas',
///   tags: <String>[Tags.smoke, Tags.negativo],
///   ($) async { … },
/// );
/// ```
///
/// Selecting on the command line uses boolean expressions, not just names:
///
/// ```sh
/// patrol test --device chrome --tags "smoke_test && negativo"
/// patrol test --device chrome --exclude-tags "lento"
/// ```
///
/// Tags are matched against what the test declares, so a filter that names a
/// tag nobody uses selects nothing and the run reports zero tests — which is
/// why the vocabulary lives in [Tags] rather than in each test file.
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

/// Prints the tag marker the converter turns into Allure labels.
///
/// Exposed for the rare test that still calls `patrolTest` directly — the
/// wrapper is the ordinary way in.
void emitTags(List<String> tags) {
  if (tags.isEmpty) {
    return;
  }
  debugPrintSynchronously('$_marker ${jsonEncode(tags)}');
}
