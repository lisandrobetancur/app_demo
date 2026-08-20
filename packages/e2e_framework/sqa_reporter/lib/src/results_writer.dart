/// The results serialiser: the model in, one JSON file per test out.
///
/// The schema is defined by this file and pinned by `results_writer_test.dart`
/// — there is no external specification to consult, and the tests are what a
/// change has to get past. Its rules, all in [prune]: nulls omitted, empty
/// collections omitted, dates as ISO-8601 strings, enums by name, file values
/// as bare names.
///
/// The JSON exists because a report is two audiences. The HTML is for people;
/// this is for whatever reads a run afterwards — a dashboard, a trend, a
/// script that counts. Keeping it separate means the pages can be rewritten
/// without breaking anything downstream.
///
/// Nothing here knows where the model came from. A second output format is a
/// second file like this one.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'markers.dart';
import 'model.dart';

/// Our vocabulary → the names the JSON carries.
///
/// The distinction worth keeping is FAILURE against ERROR: an assertion the
/// product did not meet, versus a test that could not do its job. The suite
/// already computes it — see `promoteStatus` — and losing it here would turn
/// a stale locator into a product defect on every dashboard downstream.
const Map<RunStatus, String> resultName = <RunStatus, String>{
  RunStatus.passed: 'SUCCESS',
  RunStatus.failed: 'FAILURE',
  RunStatus.broken: 'ERROR',
  RunStatus.skipped: 'SKIPPED',
  RunStatus.unknown: 'UNDEFINED',
};

/// Writes one JSON per case, screenshots beside them, into
/// [outputDir]. Returns how many result files were written.
int writeResults(
  ParsedRun run,
  Directory outputDir, {
  required String platform,
}) {
  if (outputDir.existsSync()) {
    outputDir.deleteSync(recursive: true);
  }
  outputDir.createSync(recursive: true);

  int written = 0;
  for (final RunCase testCase in run.cases) {
    final Map<String, Object?> outcome = _outcomeFor(
      testCase,
      run,
      platform: platform,
      outputDir: outputDir,
    );
    final String fileName = reportFileName(testCase);
    File(
      '${outputDir.path}${Platform.pathSeparator}$fileName',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(outcome));
    written += 1;
  }
  return written;
}

/// sha256 hex of the complete name — the digest that pairs every artefact of
/// one test: `<digest>.json`, `<digest>.html`, and the `<digest12>-NN-*.png`
/// screenshots. A digest and not the test's name: names carry spaces,
/// accents and slashes, and one of the three platforms would mangle any
/// scheme that kept them.
String reportDigest(RunCase testCase) =>
    sha256.convert(utf8.encode(completeNameOf(testCase))).toString();

/// The JSON result file's name.
String reportFileName(RunCase testCase) => '${reportDigest(testCase)}.json';

/// The HTML detail page's name — same digest, so the two point at each other
/// without an index.
String htmlReportName(RunCase testCase) => '${reportDigest(testCase)}.html';

/// `storyTitle + ":" + name` — what makes a test identifiable across runs.
/// The story title is the feature the scenario declared, or the suite file
/// when it declared none.
String completeNameOf(RunCase testCase) =>
    '${testCase.meta?.feature ?? testCase.suite}:${testCase.name}';

Map<String, Object?> _outcomeFor(
  RunCase testCase,
  ParsedRun run, {
  required String platform,
  required Directory outputDir,
}) {
  final ScenarioMeta? meta = testCase.meta;
  final String storyTitle = meta?.feature ?? testCase.suite;

  final ({int start, int stop}) bounds = widenedBoundsOf(testCase);
  final int start = bounds.start;
  final int stop = bounds.stop;
  final int duration = stop - start;

  final RunStatus result = promoteStatus(testCase.status, testCase.steps);

  final List<StepNode> steps = presentedStepsOf(testCase);
  final _StepWriter stepWriter = _StepWriter(outputDir, shotNamesFor(testCase));
  final List<Map<String, Object?>> testSteps = <Map<String, Object?>>[
    for (final StepNode step in steps) stepWriter.write(step, level: 0),
  ];
  // The run log is deliberately not carried here. Every line worth acting on
  // — warn and error — is already a step of its own in the tree above, so the
  // log could only ever add the `info` narration: a blob nobody opens, on
  // every test. `logLines` stays on the model, so a surface that wants it can
  // have it without re-parsing anything.

  final Map<String, Object?> featureTag = _featureTag(meta, storyTitle);

  return prune(<String, Object?>{
        'id': '${testCase.suite}#${testCase.name}',
        'name': testCase.name,
        'title': testCase.name,
        'methodName': testCase.name,
        'testCaseName': testCase.suite,
        'description': meta?.description,
        'testSteps': testSteps,
        'userStory': _userStory(meta, testCase.suite),
        'featureTag': featureTag,
        'tags': _tags(testCase, featureTag, platform),
        'result': resultName[result],
        'startTime': isoUtc(start),
        'duration': duration,
        'durationInSeconds': duration / 1000,
        'testRunTimestamp': run.startedAt ?? isoUtc(start),
        'context': platform,
        'manual': false,
        'isManualTestingUpToDate': false,
        'testData': testCase.params.isEmpty
            ? null
            : testCase.params
                  .map((RunParam p) => '${p.name}=${p.value}')
                  .join(', '),
        if (testCase.failureMessage != null) ...<String, Object?>{
          'testFailureCause': <String, Object?>{
            // The marker stream carries no exception class, so this is a
            // reading rather than a fact: the first line's leading identifier
            // when it looks like a type name, and the generic verdict when it
            // does not.
            'errorType': _errorTypeFrom(testCase.failureMessage!),
            'message': testCase.failureTrace ?? testCase.failureMessage,
          },
          'testFailureClassname': _errorTypeFrom(testCase.failureMessage!),
          'testFailureMessage': testCase.failureMessage,
        },
      })!
      as Map<String, Object?>;
}

Map<String, Object?> _userStory(ScenarioMeta? meta, String suite) {
  final String? epic = meta?.epic;
  final String feature = meta?.feature ?? suite;
  final String featureSlug = slugOf(feature);
  final String path = epic == null
      ? featureSlug
      : '${slugOf(epic)}/$featureSlug';
  return <String, Object?>{
    'id': path,
    'storyName': feature,
    'displayName': feature,
    'path': path,
    'pathElements': <Map<String, Object?>>[
      if (epic != null)
        <String, Object?>{'name': slugOf(epic), 'description': epic},
      <String, Object?>{'name': featureSlug, 'description': feature},
    ],
    'type': 'feature',
  };
}

Map<String, Object?> _featureTag(ScenarioMeta? meta, String storyTitle) {
  final String? epic = meta?.epic;
  final String feature = meta?.feature ?? storyTitle;
  return <String, Object?>{
    // Nested requirement tags are parent/child by name, which is
    // what lets a two-level tree roll coverage up a branch.
    'name': epic == null ? feature : '$epic/$feature',
    'type': 'feature',
    'displayName': feature,
  };
}

List<Map<String, Object?>> _tags(
  RunCase testCase,
  Map<String, Object?> featureTag,
  String platform,
) {
  final ScenarioMeta? meta = testCase.meta;
  return <Map<String, Object?>>[
    if (meta?.epic != null)
      <String, Object?>{
        'name': meta!.epic,
        'type': 'epic',
        'displayName': meta.epic,
      },
    featureTag,
    if (meta?.severity != null)
      <String, Object?>{
        'name': meta!.severity,
        'type': 'severity',
        'displayName': meta.severity,
      },
    <String, Object?>{
      'name': platform,
      'type': 'context',
      'displayName': platform,
    },
    for (final String tag in testCase.tags)
      <String, Object?>{'name': tag, 'type': 'tag', 'displayName': tag},
  ];
}

/// The run's clock, widened to hold its own steps: two clocks measure the
/// same test — the transport from outside, the markers from inside — and they
/// disagree by a few milliseconds. Widening rather than trusting either one
/// avoids reporting a child that outlives its parent. Same rule, same reason
/// as the original converter.
({int start, int stop}) widenedBoundsOf(RunCase testCase) {
  final ({int start, int stop}) bounds = _bounds(testCase.steps);
  return (
    start: bounds.start < testCase.start ? bounds.start : testCase.start,
    stop: bounds.stop > testCase.stop ? bounds.stop : testCase.stop,
  );
}

/// The steps a report presents for [testCase]: its own tree, plus a synthetic
/// holder for any screenshot that arrived with no step open to own it —
/// The schema has no test-level screenshot slot — a reader walks the step
/// tree — so an orphan capture gets a step of its own rather than being
/// dropped.
List<StepNode> presentedStepsOf(RunCase testCase) {
  final List<StepNode> steps = List<StepNode>.of(testCase.steps);
  if (testCase.orphanShots.isNotEmpty) {
    final int stop = widenedBoundsOf(testCase).stop;
    steps.add(
      StepNode(
        name: 'Screenshots',
        kind: StepKind.business,
        start: stop,
        stop: stop,
        shots: testCase.orphanShots,
      ),
    );
  }
  return steps;
}

/// One capture, with the step that took it and the depth it sits at — the
/// gallery needs all three, and the order is the one every surface uses.
typedef Capture = ({CapturedShot shot, StepNode step, int depth});

/// Every capture in [testCase], in the order the JSON writer visits them: a
/// step's children before its own captures. One traversal, used by the JSON
/// writer, the step table and the gallery, so a capture has the same index
/// and the same file name wherever it appears.
List<Capture> capturesOf(RunCase testCase) {
  final List<Capture> captures = <Capture>[];
  void visit(StepNode step, int depth) {
    for (final StepNode child in step.children) {
      visit(child, depth + 1);
    }
    for (final CapturedShot shot in step.shots) {
      captures.add((shot: shot, step: step, depth: depth));
    }
  }

  for (final StepNode step in presentedStepsOf(testCase)) {
    visit(step, 0);
  }
  return captures;
}

/// One file name per captured screenshot — `<digest12>-NN-<slug>.png`, in
/// [capturesOf] order. Shared by the JSON writer and the HTML pages so both
/// always reference the same files.
Map<CapturedShot, String> shotNamesFor(RunCase testCase) {
  final String digest = reportDigest(testCase).substring(0, 12);
  final Map<CapturedShot, String> names = Map<CapturedShot, String>.identity();
  final List<Capture> captures = capturesOf(testCase);
  for (int i = 0; i < captures.length; i += 1) {
    names[captures[i].shot] =
        '$digest-${(i + 1).toString().padLeft(2, '0')}-'
        '${slugOf(captures[i].shot.name)}.png';
  }
  return names;
}

/// A step's one-line description. An assertion leaf folds expected/actual
/// into it: there is no structured slot for them, only
/// the sentence.
String stepDescription(StepNode step) {
  if (step.kind != StepKind.assertion) {
    return step.name;
  }
  String param(String name) => step.params
      .firstWhere(
        (RunParam p) => p.name == name,
        orElse: () => RunParam(name, ''),
      )
      .value;
  return step.status == RunStatus.passed
      ? '${step.name} — verified: ${param('expected')}'
      : '${step.name} — expected: ${param('expected')}, '
            'actual: ${param('actual')}';
}

/// Writes the step tree, numbering nodes with one global counter across the
/// whole test — the step number is a sequence, not a per-level index — and
/// writing each screenshot's bytes beside the JSON, referenced by bare name
/// so a result file names the image rather than pointing at a path that only
/// existed on the machine that wrote it.
class _StepWriter {
  _StepWriter(this.outputDir, this.shotNames);

  final Directory outputDir;
  final Map<CapturedShot, String> shotNames;
  int _number = 0;

  Map<String, Object?> write(StepNode step, {required int level}) {
    _number += 1;
    final int number = _number;
    return prune(<String, Object?>{
          'number': number,
          'description': stepDescription(step),
          'startTime': isoUtc(step.start),
          'duration': step.stop - step.start,
          'result': resultName[step.status],
          'level': level,
          'precondition': false,
          'children': <Map<String, Object?>>[
            for (final StepNode child in step.children)
              write(child, level: level + 1),
          ],
          'screenshots': <Map<String, Object?>>[
            for (final CapturedShot shot in step.shots)
              <String, Object?>{
                'screenshot': _writeShot(shot),
                'timeStamp': step.stop,
              },
          ],
        })!
        as Map<String, Object?>;
  }

  String _writeShot(CapturedShot shot) {
    final String name = shotNames[shot]!;
    File(
      '${outputDir.path}${Platform.pathSeparator}$name',
    ).writeAsBytesSync(shot.bytes);
    return name;
  }
}

/// Epoch ms → the ISO-8601 UTC instant the schema
/// accepts, in the plain offset form every parser takes.
String isoUtc(int epochMs) =>
    DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: true).toIso8601String();

/// Filesystem- and path-safe lowercase name. Our own convention for story
/// paths and screenshot files, applied consistently so the requirements tree
/// and the file names agree.
String slugOf(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

/// The serialisation rules, applied recursively: null values and empty
/// collections disappear (they are indistinguishable from absent, and the encoder
/// omits nulls). Returns null when the pruned value itself becomes empty, so
/// containers collapse the same way all the way up.
Object? prune(Object? value) {
  if (value is Map<String, Object?>) {
    final Map<String, Object?> out = <String, Object?>{};
    for (final MapEntry<String, Object?> entry in value.entries) {
      final Object? pruned = prune(entry.value);
      if (pruned != null) {
        out[entry.key] = pruned;
      }
    }
    return out.isEmpty ? null : out;
  }
  if (value is List<Object?>) {
    final List<Object?> out = <Object?>[
      for (final Object? item in value)
        if (prune(item) case final Object kept) kept,
    ];
    return out.isEmpty ? null : out;
  }
  return value;
}

({int start, int stop}) _bounds(List<StepNode> steps) {
  int start = 1 << 62;
  int stop = -1 << 62;
  void visit(List<StepNode> list) {
    for (final StepNode step in list) {
      if (step.start < start) {
        start = step.start;
      }
      if (step.stop > stop) {
        stop = step.stop;
      }
      visit(step.children);
    }
  }

  visit(steps);
  return (start: start, stop: stop);
}

/// G1's heuristic: a leading `SomeTypeName:` on the first line reads as the
/// exception class; anything else is reported as a failed assertion.
String _errorTypeFrom(String message) {
  final RegExpMatch? match = RegExp(
    r'^([A-Z][A-Za-z0-9_]*(?:Error|Exception|Failure))\b',
  ).firstMatch(message.trimLeft());
  return match?.group(1) ?? 'AssertionError';
}
