/// The marker-stream parser: one test's captured output in, the model out.
///
/// This is the parsing half of the pipeline,
/// which is the working reference for how the markers arrive. The semantics
/// are kept identical on purpose — two consumers of one stream must agree on
/// its edges — and where the original earned a rule the hard way, the rule
/// travels with its reasoning.
///
/// Three streams arrive interleaved in the same stdout:
///
///  * `PATROL_STEP` — the business steps the suite declares. Top level,
///    nestable.
///  * `PATROL_LOG` — Patrol's own interactions (tap, enterText…), hanging
///    under whichever business step was open.
///  * `PATROL_ASSERT` — one record per assertion, a leaf under the step that
///    made it, so a green step shows what it actually verified.
///
/// plus `PATROL_SHOT` (chunked screenshots), `PATROL_META` / `PATROL_PARAM`
/// (the scenario taxonomy and test data — they belong to the test, not to a
/// step), `PATROL_TAGS`, and `PATROL_TRACE` (the run log; `warn` and `error`
/// also become leaves, because a warning nobody opens an attachment to read
/// did not happen).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'model.dart';

/// What one test's stdout parsed into.
class MarkerParse {
  const MarkerParse({
    required this.steps,
    required this.orphanShots,
    required this.meta,
    required this.params,
    required this.tags,
    required this.logLines,
  });

  final List<StepNode> steps;
  final List<CapturedShot> orphanShots;
  final ScenarioMeta? meta;
  final List<RunParam> params;
  final List<String> tags;
  final List<String> logLines;
}

final RegExp _ansi = RegExp('\x1B?\\[[0-9;]*m');

/// Strips the ANSI colour codes Patrol writes into its log lines.
String stripAnsi(String text) => text.replaceAll(_ansi, '');

/// How far the marker stream's clock has to move to land on the transport's.
///
/// Patrol stamps its `PATROL_LOG` lines with the *device's* wall clock and no
/// timezone: `2026-08-18T20:10:41.123` is whatever the phone or the browser
/// thinks the time is, and reading it gives an instant only if you already
/// know where that device was. The transport's own start — Playwright's
/// `startTime`, which is real UTC — does not have that problem.
///
/// Mixing the two is what made a web run come out five hours long: the suite
/// runs with `--web-timezone=America/Bogota`, so every marker read as UTC
/// landed five hours before the test that produced it, and widening the test
/// to cover its steps stretched it across the gap.
///
/// The drift between the first marker and the test's start is therefore two
/// things added together: real elapsed time, in seconds, and a difference of
/// timezones, which is always a whole number of quarter-hours — no zone on
/// earth is offset by anything finer. Rounding to the nearest quarter-hour
/// separates them: the timezone part comes out exactly and is removed, and the
/// seconds of real waiting survive, which matters because that gap is the app
/// launching before the first interaction.
///
/// Both clocks the same, as on a device log where the start comes from the
/// stream itself: the drift is seconds, it rounds to zero, and nothing moves.
///
/// Bounded by what a timezone can actually be — the inhabited world spans
/// UTC−12 to UTC+14 — so a drift larger than that is not a timezone and gets
/// no correction. Something else is wrong then (a seeded clock in a test, a
/// truncated log), and silently dragging every step across years to meet it
/// would hide that rather than fix it.
int _clockShift(int firstMarker, int startTime) {
  const int quarterHour = 15 * 60 * 1000;
  const int farthestZone = 15 * 60 * 60 * 1000;
  final int shift =
      ((firstMarker - startTime) / quarterHour).round() * quarterHour;
  return shift.abs() > farthestZone ? 0 : shift;
}

/// Parses the markers out of [stdout].
///
/// [startTime] seeds the clock: `PATROL_STEP` markers carry no timestamp of
/// their own, so business steps are dated by the run's own clock — the last
/// time seen in the `PATROL_LOG` stream. Wall-clock time here would date them
/// at *parse* time, which put every business step outside its own test's
/// range in the original converter.
///
/// [startTime] is also the reference the marker clock is put back onto when
/// the two disagree — see [_clockShift].
MarkerParse parseMarkers(String stdout, int startTime) {
  final List<StepNode> root = <StepNode>[];
  final List<StepNode> businessStack = <StepNode>[];
  final List<StepNode> interactionStack = <StepNode>[];
  final Map<String, _ShotAssembly> shots = <String, _ShotAssembly>{};
  final List<CapturedShot> orphanShots = <CapturedShot>[];
  ScenarioMeta? meta;
  final List<RunParam> params = <RunParam>[];
  final List<String> tags = <String>[];
  final List<String> logLines = <String>[];
  StepNode? lastClosedBusiness;
  int clock = startTime;
  // Resolved from the first timestamped marker and then applied to every one
  // that follows. See [_clockShift].
  int? clockShift;

  List<StepNode> currentChildren() =>
      businessStack.isNotEmpty ? businessStack.last.children : root;

  for (final String raw in stripAnsi(stdout).split('\n')) {
    final int shotAt = raw.indexOf('PATROL_SHOT|');
    if (shotAt >= 0) {
      final CapturedShot? shot = _collectShot(raw.substring(shotAt), shots);
      if (shot != null) {
        // The capture happens inside the step it belongs to, but its last
        // chunk can land just after the step closed.
        final StepNode? owner = businessStack.isNotEmpty
            ? businessStack.last
            : lastClosedBusiness;
        (owner?.shots ?? orphanShots).add(shot);
      }
      continue;
    }

    final int stepAt = raw.indexOf('PATROL_STEP|');
    if (stepAt >= 0) {
      final List<String> parts = _splitLimit(raw.substring(stepAt), '|', 4);
      final String phase = parts.length > 1 ? parts[1] : '';
      final String payload = parts.length > 3 ? parts[3] : '';
      if (phase == 'begin') {
        final StepNode step = StepNode(
          name: payload,
          kind: StepKind.business,
          start: clock,
          stop: clock,
        );
        currentChildren().add(step);
        businessStack.add(step);
      } else if (businessStack.isNotEmpty) {
        final StepNode step = businessStack.removeLast()
          ..stop = clock
          ..status = _stepStatus(payload);
        lastClosedBusiness = step;
      }
      continue;
    }

    // An assertion is a leaf: it records a check that already happened, so it
    // opens and closes at once rather than joining the nesting stacks.
    final Map<String, Object?>? assertPayload = _jsonAfter(
      raw,
      'PATROL_ASSERT ',
    );
    if (assertPayload != null) {
      currentChildren().add(
        StepNode(
          name: '${assertPayload['name'] ?? 'assertion'}',
          kind: StepKind.assertion,
          status: assertPayload['status'] == 'failed'
              ? RunStatus.failed
              : RunStatus.passed,
          start: clock,
          stop: clock,
          params: <RunParam>[
            RunParam('expected', '${assertPayload['expected'] ?? ''}'),
            RunParam('actual', '${assertPayload['actual'] ?? ''}'),
          ],
        ),
      );
      continue;
    }

    final Map<String, Object?>? metaPayload = _jsonAfter(raw, 'PATROL_META ');
    if (metaPayload != null) {
      meta = ScenarioMeta(
        epic: metaPayload['epic'] as String?,
        feature: metaPayload['feature'] as String?,
        severity: metaPayload['severity'] as String?,
        description: metaPayload['description'] as String?,
      );
      continue;
    }

    final Map<String, Object?>? paramPayload = _jsonAfter(raw, 'PATROL_PARAM ');
    if (paramPayload != null) {
      final Object? name = paramPayload['name'];
      if (name != null) {
        params.add(RunParam('$name', '${paramPayload['value'] ?? ''}'));
      }
      continue;
    }

    final int tagsAt = raw.indexOf('PATROL_TAGS ');
    if (tagsAt >= 0) {
      final Object? payload = _tryJson(
        raw.substring(tagsAt + 'PATROL_TAGS '.length),
      );
      if (payload is List) {
        for (final Object? tag in payload) {
          final String value = '$tag';
          if (!tags.contains(value)) {
            tags.add(value);
          }
        }
      }
      continue;
    }

    final Map<String, Object?>? trace = _jsonAfter(raw, 'PATROL_TRACE ');
    if (trace != null) {
      final Object? message = trace['message'];
      if (message != null) {
        final String level = '${trace['level'] ?? 'info'}';
        final String suffix = trace.containsKey('data')
            ? ' ${trace['data']}'
            : '';
        logLines.add(
          '${trace['at'] ?? ''} [${level.toUpperCase()}] $message$suffix',
        );
        // Only the levels that mean something went sideways earn a row in the
        // tree; `info` and below would bury the steps they describe. A log
        // line is not a verdict on the product, so the statuses stay off the
        // failure count: skipped for a warning, broken for an error.
        if (level == 'warn' || level == 'error') {
          currentChildren().add(
            StepNode(
              name: '${level == 'warn' ? '⚠' : '✖'} $message',
              kind: StepKind.logNote,
              status: level == 'warn' ? RunStatus.skipped : RunStatus.broken,
              start: clock,
              stop: clock,
              params: trace.containsKey('data')
                  ? <RunParam>[RunParam('data', '${trace['data']}')]
                  : null,
            ),
          );
        }
      }
      continue;
    }

    final Map<String, Object?>? entry = _jsonAfter(raw, 'PATROL_LOG ');
    if (entry == null || entry['type'] != 'step') {
      continue;
    }
    final int? stamped = DateTime.tryParse(
      '${entry['timestamp']}',
    )?.millisecondsSinceEpoch;
    final int? at = stamped == null
        ? null
        : stamped - (clockShift ??= _clockShift(stamped, startTime));
    if (at != null) {
      clock = at;
    }
    if (entry['status'] == 'start') {
      final StepNode step = StepNode(
        name: stripAnsi('${entry['action'] ?? 'step'}'),
        kind: StepKind.interaction,
        start: at ?? clock,
        stop: at ?? clock,
      );
      (interactionStack.isNotEmpty
              ? interactionStack.last.children
              : currentChildren())
          .add(step);
      interactionStack.add(step);
      continue;
    }
    if (interactionStack.isEmpty) {
      continue;
    }
    final StepNode step = interactionStack.removeLast()
      ..stop = at ?? clock
      ..status = entry['status'] == 'success'
          ? RunStatus.passed
          : RunStatus.failed;
    if (entry['data'] != null) {
      step.params.add(RunParam('data', '${entry['data']}'));
    }
  }

  // Anything still open when the test died is what actually broke.
  for (final StepNode step in interactionStack) {
    step.status = RunStatus.broken;
  }
  for (final StepNode step in businessStack) {
    step.status = RunStatus.broken;
  }

  return MarkerParse(
    steps: root,
    orphanShots: orphanShots,
    meta: meta,
    params: params,
    tags: tags,
    logLines: logLines,
  );
}

/// Whether any step in the tree, at any depth, ended with [status].
bool hasStepWith(List<StepNode> steps, RunStatus status) => steps.any(
  (StepNode step) =>
      step.status == status || hasStepWith(step.children, status),
);

/// The verdict promotion the original converter earned: the transport reports
/// one "failed" for both a wrong answer and a broken question, but the step
/// tree knows which — the suite marked each step as it closed. A case whose
/// only casualty was a stale locator reads as broken, not as a product defect.
RunStatus promoteStatus(RunStatus transport, List<StepNode> steps) {
  if (transport == RunStatus.failed &&
      !hasStepWith(steps, RunStatus.failed) &&
      hasStepWith(steps, RunStatus.broken)) {
    return RunStatus.broken;
  }
  return transport;
}

RunStatus _stepStatus(String payload) => switch (payload) {
  'failed' => RunStatus.failed,
  'broken' => RunStatus.broken,
  _ => RunStatus.passed,
};

/// Reassembles one screenshot from its chunked `PATROL_SHOT` lines.
///
/// The app streams base64 in ~800-character pieces because a single line that
/// long gets mangled on the way out of the browser. A screenshot only becomes
/// bytes once every piece has arrived.
CapturedShot? _collectShot(String line, Map<String, _ShotAssembly> shots) {
  final List<String> parts = _splitLimit(line, '|', 5);
  if (parts.length < 5 || parts[1] == 'ERROR') {
    return null;
  }
  final String name = parts[1];
  final int? index = int.tryParse(parts[2]);
  final int? total = int.tryParse(parts[3]);
  if (index == null || total == null) {
    return null;
  }
  final _ShotAssembly entry = shots.putIfAbsent(
    name,
    () => _ShotAssembly(total),
  );
  entry.chunks[index] = parts[4];
  if (entry.chunks.length != entry.total) {
    return null;
  }
  final StringBuffer base64 = StringBuffer();
  for (int i = 0; i < entry.total; i += 1) {
    base64.write(entry.chunks[i] ?? '');
  }
  shots.remove(name);
  try {
    return CapturedShot(
      name: name,
      bytes: Uint8List.fromList(base64Decode(base64.toString())),
    );
  } on FormatException {
    return null; // a mangled chunk is not worth failing the whole report over
  }
}

class _ShotAssembly {
  _ShotAssembly(this.total);

  final int total;
  final Map<int, String> chunks = <int, String>{};
}

/// Reads the one-line JSON object a marker carries, or null if absent or
/// malformed — a truncated line is not worth failing the whole report over.
Map<String, Object?>? _jsonAfter(String line, String marker) {
  final int at = line.indexOf(marker);
  if (at < 0) {
    return null;
  }
  final Object? decoded = _tryJson(line.substring(at + marker.length));
  return decoded is Map<String, Object?> ? decoded : null;
}

Object? _tryJson(String text) {
  try {
    return jsonDecode(text);
  } on FormatException {
    return null;
  }
}

/// `String.split` with a piece limit, like the JS `split(sep, n)` the
/// original relies on: the last kept piece is *not* the remainder — pieces
/// past the limit are discarded. Safe for both marker shapes: base64 has no
/// `|` in its alphabet, so a shot chunk always splits into exactly five
/// pieces, and a step payload is the marker's last field.
List<String> _splitLimit(String text, String separator, int limit) {
  final List<String> all = text.split(separator);
  if (all.length <= limit) {
    return all;
  }
  return all.sublist(0, limit);
}
