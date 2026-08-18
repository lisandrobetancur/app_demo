/// The run model: what a suite execution *was*, in terms that owe nothing to
/// any output format.
///
/// Everything downstream of the input adapters speaks this vocabulary and
/// nothing else. A second output format is a second serialiser over these
/// types, not a rewrite — which is the whole reason the model exists as its
/// own file instead of living inside the writer.
library;

import 'dart:typed_data';

/// The outcome vocabulary, shared by cases and steps.
///
/// `failed` and `broken` are deliberately distinct: a failed case is a valid
/// test whose expectation went unmet — the product misbehaved — while a
/// broken one could not check the product at all. The suite decides which is
/// which where the error type is still known (`BaseSteps`), and every
/// consumer downstream preserves the verdict instead of re-guessing it.
enum RunStatus { passed, failed, broken, skipped, unknown }

/// One executed test.
class RunCase {
  RunCase({
    required this.suite,
    required this.name,
    required this.status,
    required this.start,
    required this.stop,
    required this.thread,
    this.retry = 0,
    this.failureMessage,
    this.failureTrace,
    List<StepNode>? steps,
    List<CapturedShot>? orphanShots,
    this.meta,
    List<RunParam>? params,
    List<String>? tags,
    List<String>? logLines,
  }) : steps = steps ?? <StepNode>[],
       orphanShots = orphanShots ?? <CapturedShot>[],
       params = params ?? <RunParam>[],
       tags = tags ?? <String>[],
       logLines = logLines ?? <String>[];

  /// The Dart file the test came from, without extension: `login_test`.
  final String suite;

  /// The test's own name: `logs in with the seeded demo account`.
  final String name;

  final RunStatus status;

  /// Epoch milliseconds, as reported by the transport.
  final int start;
  final int stop;

  /// Where the test ran: `worker-0` on web, `device` on mobile.
  final String thread;
  final int retry;

  /// The first lines of the failure, when there is one, and the full trace.
  final String? failureMessage;
  final String? failureTrace;

  /// The step tree — business steps, interactions and assertion leaves.
  final List<StepNode> steps;

  /// Screenshots that arrived with no step open to own them.
  final List<CapturedShot> orphanShots;

  final ScenarioMeta? meta;

  /// The data the case declared it ran with (`testParam`).
  final List<RunParam> params;

  /// What the test declared to `e2eTest` — the runner filters on the same
  /// strings, so a reader can reproduce a selection from the report.
  final List<String> tags;

  /// The `PATROL_TRACE` narration, one line per entry.
  final List<String> logLines;

  int get duration => stop - start;
}

/// One node of the step tree. Business steps, Patrol interactions, assertion
/// records and warn/error log lines all take this shape; only [kind] says
/// which one a node was.
class StepNode {
  StepNode({
    required this.name,
    required this.kind,
    required this.start,
    required this.stop,
    this.status = RunStatus.passed,
    List<StepNode>? children,
    List<RunParam>? params,
    List<CapturedShot>? shots,
  }) : children = children ?? <StepNode>[],
       params = params ?? <RunParam>[],
       shots = shots ?? <CapturedShot>[];

  final String name;
  final StepKind kind;
  RunStatus status;
  final int start;
  int stop;
  final List<StepNode> children;
  final List<RunParam> params;
  final List<CapturedShot> shots;
}

enum StepKind { business, interaction, assertion, logNote }

/// A reassembled screenshot: the bytes, not a path. Where the file lands is
/// the serialiser's decision, not the model's.
class CapturedShot {
  const CapturedShot({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// The business taxonomy a test declared through `scenario()`.
///
/// Two levels, deliberately: this repository dropped `story` because declared
/// one-to-one with the tests it was a second name for each of them. The
/// requirements tree is therefore epic → feature, and the test's own name is
/// the leaf.
class ScenarioMeta {
  const ScenarioMeta({
    this.epic,
    this.feature,
    this.severity,
    this.description,
  });

  final String? epic;
  final String? feature;
  final String? severity;
  final String? description;
}

class RunParam {
  const RunParam(this.name, this.value);

  final String name;
  final String value;
}

/// A whole parsed execution: every case, plus what the transport knew about
/// the run itself.
class ParsedRun {
  const ParsedRun({required this.cases, this.startedAt, this.workers = 1});

  final List<RunCase> cases;
  final String? startedAt;
  final int workers;
}
