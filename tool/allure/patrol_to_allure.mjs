#!/usr/bin/env node
/**
 * Turns a Patrol run into Allure results, on web or on a mobile device.
 *
 * Why a converter instead of an Allure reporter: Patrol owns the Playwright
 * config that runs the web suite, and its `mapReporters` only accepts a
 * whitelist (`html`, `json`, `junit`, `list`, `dot`, `line`, `github`,
 * `null`) — `allure-playwright` is rejected outright. So the pipeline uses
 * the supported `json` reporter and translates it here.
 *
 * The translation is not a straight copy: Patrol prints a structured
 * `PATROL_LOG {…}` line for every interaction, and those become real Allure
 * steps, so the report shows "tap login_submit_button" instead of a single
 * opaque test row.
 *
 * There are two input adapters over one renderer, because the *transport*
 * differs per platform while the payload does not:
 *
 *  * `playwright` — web. Playwright captures the browser console per test,
 *    and its JSON report is the only place those lines survive.
 *  * `patrol-log` — Android and iOS. The same markers arrive through the
 *    device log (`adb logcat`, `os_log`), so the adapter has to find the test
 *    boundaries itself, from the `type: "test"` entries in the stream.
 *
 * Everything downstream — the step tree, the screenshots, the report — is
 * identical on both paths.
 *
 *   node patrol_to_allure.mjs [--input <file>] [--output <dir>]
 *                             [--format playwright|patrol-log]
 *                             [--platform web|android|ios]
 */

import { createHash, randomUUID } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { hostname } from "node:os";

const REPO_ROOT = resolve(import.meta.dirname, "../..");
// Todo lo que produce una ejecución vive bajo una sola raíz, una subcarpeta
// por plataforma:
//
//   build/e2e/
//   ├── web/{playwright,test-results,allure/{results,report}}
//   └── android/{android_run.log,allure/{results,report}}
//
// Una raíz y no cuatro repartidas por el repositorio, porque la limpieza de
// antes se olvidaba de lo que no recordaba que existía — `test-results/` no lo
// borró nadie durante meses. Con una raíz por plataforma, borrarla entera es
// una operación que no puede dejarse nada.
const E2E_ROOT = resolve(REPO_ROOT, "build/e2e");
const DEFAULTS = {
  input: resolve(E2E_ROOT, "web/playwright/results.json"),
};

/** How old an input may be before the report is probably describing an old run. */
const STALE_INPUT_MINUTES = 10;

/** Playwright status -> Allure status. */
const STATUS = {
  passed: "passed",
  failed: "failed",
  timedOut: "broken",
  interrupted: "broken",
  skipped: "skipped",
};

/**
 * `PATROL_STEP` outcome -> Allure status.
 *
 * `broken` is the one worth naming. Allure separates a test that *failed* —
 * a valid test whose expectation went unmet, so the product misbehaved — from
 * one that is *broken*, which could not check the product at all. The suite
 * decides which is which in `BaseSteps`, where the error type is still known
 * (a `TestFailure` versus a locator that matched nothing), and sends the
 * verdict here rather than leaving it to be guessed from a message.
 */
const STEP_STATUS = {
  passed: "passed",
  failed: "failed",
  broken: "broken",
};

/** `PATROL_LOG` test status -> Allure status. */
const TEST_STATUS = {
  success: "passed",
  failure: "failed",
  skip: "skipped",
};

function parseArgs(argv) {
  const args = { ...DEFAULTS };
  for (let i = 0; i < argv.length; i += 2) {
    const [flag, value] = [argv[i], argv[i + 1]];
    if (flag === "--input" && value) args.input = resolve(value);
    else if (flag === "--output" && value) args.output = resolve(value);
    else if (flag === "--format" && value) args.format = value;
    else if (flag === "--platform" && value) args.platform = value;
  }
  // A Playwright report is JSON; a device log is not. Guessing from the
  // extension keeps the common cases flag-free.
  args.format ??= args.input.endsWith(".json") ? "playwright" : "patrol-log";
  args.platform ??= args.format === "playwright" ? "web" : "android";
  args.output ??= resolve(E2E_ROOT, args.platform, "allure", "results");
  return args;
}

/** Strips the ANSI colour codes Patrol writes into its log lines. */
function stripAnsi(text) {
  // eslint-disable-next-line no-control-regex
  return text.replace(/\[[0-9;]*m/g, "");
}

/** Concatenated stdout of a Playwright test result. */
function stdoutOf(result) {
  return (result.stdout ?? [])
    .map(chunk => (typeof chunk === "string" ? chunk : (chunk.text ?? "")))
    .join("");
}

/**
 * Rebuilds Allure steps from Patrol's `PATROL_LOG` stream.
 *
 * Patrol emits one entry when an action starts and another when it finishes,
 * so entries are paired by nesting order: every `status: "start"` opens a
 * step and the next terminal entry closes the most recent open one.
 */
/**
 * Rebuilds the step tree from the interleaved markers in a test's stdout.
 *
 * Three streams arrive mixed together, and the nesting is what makes the
 * report readable:
 *
 *  * `PATROL_STEP` — the *business* steps this suite declares ("Log in as the
 *    demo user"). They become the top-level steps and can nest.
 *  * `PATROL_LOG` — Patrol's own interactions (tap, enterText, …). They hang
 *    under whichever business step was open when they happened.
 *  * `PATROL_SHOT` — a screenshot, taken when a business step closes, so it
 *    is attached to that step rather than to an individual tap.
 *  * `PATROL_ASSERT` — one assertion and its outcome, nested under the step
 *    that made it, so a green step shows what it actually verified.
 *  * `PATROL_META` / `PATROL_PARAM` — the scenario's business taxonomy and
 *    the data the case ran with. These belong to the test, not to a step, so
 *    they are collected here and returned alongside.
 *  * `PATROL_TAGS` — what the test declared to `e2eTest`, which becomes the
 *    same vocabulary the runner filters on.
 *  * `PATROL_TRACE` — the run log. Every line goes into one `run.log`
 *    attachment on the test; `warn` and `error` *also* become leaf steps,
 *    because a warning nobody opens the attachment to read did not happen.
 */
function stepsFrom(stdout, outputDir, startTime) {
  const root = [];
  const businessStack = []; // business steps currently open
  const interactionStack = []; // patrol interactions currently open
  const shots = new Map(); // name -> { total, chunks: Map<index, string> }
  const orphanShots = [];
  let meta = null;
  const params = [];
  const tags = [];
  const logLines = [];
  let lastClosedBusiness = null;

  // `PATROL_STEP` markers carry no timestamp of their own, so a business step
  // is dated by the run's own clock: the last time seen in the `PATROL_LOG`
  // stream, starting from when the test began. Wall-clock time would date them
  // at *parse* time instead — which put every business step outside its own
  // test's range and collapsed its duration to a millisecond, while the
  // interactions nested under it still showed seconds.
  let clock = startTime ?? Date.now();

  /** Where a new child belongs right now. */
  const currentChildren = () =>
    businessStack.length > 0 ? businessStack[businessStack.length - 1].steps : root;

  for (const line of stripAnsi(stdout).split("\n")) {
    const shotAt = line.indexOf("PATROL_SHOT|");
    if (shotAt >= 0) {
      const attachment = collectScreenshot(line.slice(shotAt), shots, outputDir);
      if (attachment) {
        // The capture happens inside the step it belongs to, but its last
        // chunk can land just after the step closed.
        const owner = businessStack[businessStack.length - 1] ?? lastClosedBusiness;
        (owner?.attachments ?? orphanShots).push(attachment);
      }
      continue;
    }

    const stepAt = line.indexOf("PATROL_STEP|");
    if (stepAt >= 0) {
      const [, phase, , payload] = line.slice(stepAt).split("|", 4);
      if (phase === "begin") {
        const step = { name: payload, status: "passed", start: clock, stop: clock, steps: [], parameters: [], attachments: [] };
        currentChildren().push(step);
        businessStack.push(step);
      } else {
        const step = businessStack.pop();
        if (step) {
          step.stop = clock;
          step.status = STEP_STATUS[payload] ?? "passed";
          lastClosedBusiness = step;
        }
      }
      continue;
    }

    // An assertion is a leaf: it records a check that already happened, so it
    // opens and closes at once rather than joining the nesting stacks.
    const assertAt = line.indexOf("PATROL_ASSERT ");
    if (assertAt >= 0) {
      const payload = parseJsonAfter(line, assertAt, "PATROL_ASSERT ");
      if (payload) {
        currentChildren().push({
          name: payload.name ?? "assertion",
          status: payload.status === "failed" ? "failed" : "passed",
          start: clock,
          stop: clock,
          steps: [],
          parameters: [
            { name: "expected", value: String(payload.expected ?? "") },
            { name: "actual", value: String(payload.actual ?? "") },
          ],
          attachments: [],
        });
      }
      continue;
    }

    const metaAt = line.indexOf("PATROL_META ");
    if (metaAt >= 0) {
      meta = parseJsonAfter(line, metaAt, "PATROL_META ") ?? meta;
      continue;
    }

    const paramAt = line.indexOf("PATROL_PARAM ");
    if (paramAt >= 0) {
      const payload = parseJsonAfter(line, paramAt, "PATROL_PARAM ");
      if (payload?.name) {
        params.push({ name: payload.name, value: String(payload.value ?? "") });
      }
      continue;
    }

    const tagsAt = line.indexOf("PATROL_TAGS ");
    if (tagsAt >= 0) {
      const payload = parseJsonAfter(line, tagsAt, "PATROL_TAGS ");
      if (Array.isArray(payload)) {
        for (const tag of payload) if (!tags.includes(tag)) tags.push(String(tag));
      }
      continue;
    }

    const traceAt = line.indexOf("PATROL_TRACE ");
    if (traceAt >= 0) {
      const payload = parseJsonAfter(line, traceAt, "PATROL_TRACE ");
      if (payload?.message) {
        const level = String(payload.level ?? "info");
        const suffix = payload.data === undefined ? "" : ` ${payload.data}`;
        logLines.push(`${payload.at ?? ""} [${level.toUpperCase()}] ${payload.message}${suffix}`);
        // Only the levels that mean something went sideways earn a row in the
        // tree. `info` and below would bury the steps they are describing.
        if (level === "warn" || level === "error") {
          currentChildren().push({
            name: `${level === "warn" ? "⚠" : "✖"} ${payload.message}`,
            // `broken`, not `failed`: a log line is not a verdict on the
            // product, and colouring it red would inflate the failure count.
            status: level === "warn" ? "skipped" : "broken",
            start: clock,
            stop: clock,
            steps: [],
            parameters: payload.data === undefined ? [] : [{ name: "data", value: String(payload.data) }],
            attachments: [],
          });
        }
      }
      continue;
    }

    const logAt = line.indexOf("PATROL_LOG ");
    if (logAt < 0) continue;

    let entry;
    try {
      entry = JSON.parse(line.slice(logAt + "PATROL_LOG ".length));
    } catch {
      continue; // a truncated line is not worth failing the whole report over
    }
    if (entry.type !== "step") continue;

    const at = Date.parse(entry.timestamp);
    if (Number.isFinite(at)) clock = at;
    if (entry.status === "start") {
      const step = { name: stripAnsi(entry.action ?? "step"), status: "passed", start: at, stop: at, steps: [], parameters: [], attachments: [] };
      const parent = interactionStack[interactionStack.length - 1];
      (parent ? parent.steps : currentChildren()).push(step);
      interactionStack.push(step);
      continue;
    }

    const step = interactionStack.pop();
    if (!step) continue;
    step.stop = at;
    step.status = entry.status === "success" ? "passed" : "failed";
    if (entry.data) {
      step.parameters.push({ name: "data", value: String(entry.data) });
    }
  }

  // Anything still open when the test died is what actually broke.
  for (const step of interactionStack) step.status = "broken";
  for (const step of businessStack) step.status = "broken";
  const runLog = writeRunLog(logLines, outputDir);
  return { steps: root, orphanShots, meta, params, tags, runLog };
}

/** Whether any step in the tree, at any depth, ended with [status]. */
function hasStep(steps, status) {
  return (steps ?? []).some(
    step => step.status === status || hasStep(step.steps, status),
  );
}

/** Reads the one-line JSON payload a marker carries, or null if malformed. */
function parseJsonAfter(line, at, marker) {
  try {
    return JSON.parse(line.slice(at + marker.length));
  } catch {
    return null; // a truncated line is not worth failing the whole report over
  }
}

/**
 * Writes the test's run log as a single text attachment.
 *
 * One attachment rather than a step per line: the log is the narration of how
 * the test got where it got, and it is read top to bottom when something
 * already went wrong — not scanned in a tree. The lines that do deserve to
 * interrupt the tree (`warn`, `error`) are pushed as steps where they happen.
 */
function writeRunLog(lines, outputDir) {
  if (lines.length === 0) return null;
  const source = `${randomUUID()}-attachment.txt`;
  writeFileSync(resolve(outputDir, source), `${lines.join("\n")}\n`);
  return { name: "run.log", source, type: "text/plain" };
}

/**
 * Reassembles one screenshot from the chunked `PATROL_SHOT` lines.
 *
 * The app streams base64 in 800-character pieces because a single line that
 * long gets mangled on the way out of the browser. A screenshot only becomes
 * an attachment once every piece has arrived.
 */
function collectScreenshot(line, shots, outputDir) {
  const [, name, indexRaw, totalRaw, data] = line.split("|", 5);
  if (name === "ERROR" || data === undefined) return null;

  const total = Number(totalRaw);
  const entry = shots.get(name) ?? { total, chunks: new Map() };
  entry.chunks.set(Number(indexRaw), data);
  shots.set(name, entry);
  if (entry.chunks.size !== entry.total) return null;

  const base64 = Array.from({ length: entry.total }, (_, i) => entry.chunks.get(i)).join("");
  const source = `${randomUUID()}-attachment.png`;
  writeFileSync(resolve(outputDir, source), Buffer.from(base64, "base64"));
  shots.delete(name);
  return { name, source, type: "image/png" };
}


/** Earliest start and latest stop across a step tree, for clock skew. */
function stepBounds(steps) {
  let start = Infinity;
  let stop = -Infinity;
  const visit = list => {
    for (const step of list) {
      if (Number.isFinite(step.start)) start = Math.min(start, step.start);
      if (Number.isFinite(step.stop)) stop = Math.max(stop, step.stop);
      visit(step.steps);
    }
  };
  visit(steps);
  return { start, stop };
}

/**
 * Splits Patrol's spec title into the Dart file it came from and the test
 * name: "login_test logs in …" -> { suite: "login_test", name: "logs in …" }.
 */
function splitTitle(title) {
  const match = /^(\S+_test)\s+(.*)$/.exec(title);
  return match ? { suite: match[1], name: match[2] } : { suite: "patrol", name: title };
}

function statusDetailsFrom(result) {
  const errors = result.errors ?? [];
  if (errors.length === 0) return undefined;
  return {
    message: stripAnsi(errors[0].message ?? "").split("\n").slice(0, 4).join("\n").trim(),
    trace: errors.map(error => stripAnsi(error.stack ?? error.message ?? "")).join("\n\n").trim(),
  };
}

/**
 * Web adapter: one run per Playwright result.
 *
 * Playwright already separates the tests for us and hands each one its own
 * captured stdout, so this is mostly a field rename.
 */
function fromPlaywright(input) {
  const report = JSON.parse(readFileSync(input, "utf8"));
  const runs = [];
  for (const suite of report.suites ?? []) {
    for (const spec of suite.specs ?? []) {
      for (const test of spec.tests ?? []) {
        for (const result of test.results ?? []) {
          const { suite: suiteName, name } = splitTitle(spec.title);
          const start = Date.parse(result.startTime);
          runs.push({
            suite: suiteName,
            name,
            status: STATUS[result.status] ?? "unknown",
            statusDetails: statusDetailsFrom(result),
            start,
            stop: start + Math.round(result.duration ?? 0),
            stdout: stdoutOf(result),
            thread: `worker-${result.workerIndex ?? 0}`,
            retry: result.retry ?? 0,
          });
        }
      }
    }
  }
  return { runs, startedAt: report.stats?.startTime, workers: report.config?.workers ?? 1 };
}

/**
 * Mobile adapter: one run per `type: "test"` pair in the device log.
 *
 * Nothing separates the tests here, so the adapter does it: a `start` entry
 * opens a run and the next terminal entry closes it, with every line in
 * between belonging to that test. A `TestEntry` carries the name, the status,
 * both timestamps and the error message — every field the web path takes from
 * Playwright.
 *
 * The lines must come from the device log (`adb logcat`, `os_log`), not from
 * `patrol test`'s stdout: the CLI consumes `PATROL_LOG` to pretty-print it and
 * silently drops everything else, including our own markers.
 */
function fromPatrolLog(input) {
  const runs = [];
  let current = null;

  for (const line of readFileSync(input, "utf8").split("\n")) {
    const at = line.indexOf("PATROL_LOG ");
    if (at >= 0) {
      let entry;
      try {
        entry = JSON.parse(stripAnsi(line.slice(at + "PATROL_LOG ".length)));
      } catch {
        entry = null;
      }
      if (entry?.type === "test") {
        const when = Date.parse(entry.timestamp);
        if (entry.status === "start") {
          current = { ...splitTitle(stripAnsi(entry.name)), start: when, lines: [] };
        } else if (current) {
          current.stop = when;
          current.status = TEST_STATUS[entry.status] ?? "unknown";
          if (entry.error) {
            const message = stripAnsi(entry.error);
            current.statusDetails = {
              message: message.split("\n").slice(0, 4).join("\n").trim(),
              trace: message.trim(),
            };
          }
          runs.push(current);
          current = null;
        }
        continue;
      }
    }
    // Steps and screenshots belong to whichever test is open; anything
    // printed between tests is noise from the device and is dropped.
    if (current) current.lines.push(line);
  }

  // A run still open at the end means the process died mid-test.
  if (current) {
    runs.push({ ...current, stop: current.start, status: "broken" });
  }

  return {
    runs: runs.map(run => ({ ...run, stdout: run.lines.join("\n"), thread: "device" })),
    startedAt: runs.length > 0 ? new Date(runs[0].start).toISOString() : undefined,
    workers: 1,
  };
}

function convert({ input, output, format, platform }) {
  if (!existsSync(input)) {
    console.error(
      `No ${format === "playwright" ? "Playwright results" : "device log"} at ${input}\n` +
        "Run the suite first:\n" +
        (format === "playwright"
          ? "  melos run e2eWeb"
          : "  melos run e2eAndroid"),
    );
    process.exit(1);
  }

  rmSync(output, { recursive: true, force: true });
  mkdirSync(output, { recursive: true });

  // A report is only as fresh as the run it was built from, and nothing else
  // makes that visible: the generated page is stamped with the time it was
  // generated, not the time the tests ran. Say how old the input is, and warn
  // when it is old enough that it probably belongs to an earlier run.
  const ageMinutes = Math.round((Date.now() - statSync(input).mtimeMs) / 60000);
  if (ageMinutes >= STALE_INPUT_MINUTES) {
    console.warn(
      `WARNING: ${input} is ${ageMinutes} minutes old — this report will ` +
        "describe that run, not a newer one. Re-run the suite first.",
    );
  }

  const { runs, startedAt, workers } =
    format === "playwright" ? fromPlaywright(input) : fromPatrolLog(input);
  let written = 0;

  for (const run of runs) {
          const suiteName = run.suite;
          const name = run.name;
          const fullName = `${suiteName}#${name}`;
          const { steps, orphanShots, meta, params, tags, runLog } = stepsFrom(run.stdout, output, run.start);

          // Two clocks measure the same test: Playwright times it from
          // outside, Dart timestamps the interactions from inside the browser.
          // They disagree by a few milliseconds, so the last interaction can
          // land just after Playwright called the test done. Widen the test to
          // hold its own steps rather than report a child outliving its parent.
          const bounds = stepBounds(steps);

          // Playwright reports one "failed" for both a wrong answer and a
          // broken question — it has no reason to tell them apart. The step
          // tree does: the suite marked each step as it closed. Promote that
          // verdict, so a run whose only casualty was a stale locator reads
          // as *broken* rather than as a product defect.
          const status =
            run.status === "failed" && !hasStep(steps, "failed") && hasStep(steps, "broken")
              ? "broken"
              : run.status;

          const testResult = {
            uuid: randomUUID(),
            // Scoped by platform so a web and a mobile run of the same test
            // keep separate history instead of overwriting each other.
            historyId: createHash("md5").update(`${platform}#${fullName}`).digest("hex"),
            name,
            fullName,
            status,
            statusDetails: run.statusDetails,
            stage: "finished",
            start: Math.min(run.start, bounds.start),
            stop: Math.max(run.stop, bounds.stop),
            steps,
            // Screenshots taken before the first interaction (or after the
            // last one) have no step to hang from, so they stay on the test.
            attachments: [...orphanShots, ...(runLog ? [runLog] : [])],
            // The data the case ran with, so a reader can reproduce it from
            // the report alone instead of opening the test.
            parameters: [
              ...params,
              ...(run.retry > 0 ? [{ name: "retry", value: String(run.retry) }] : []),
            ],
            // Shown as the test's description in the report.
            ...(meta?.description ? { description: meta.description } : {}),
            labels: [
              { name: "parentSuite", value: `Patrol ${platform} E2E` },
              { name: "suite", value: suiteName },
              { name: "framework", value: "patrol" },
              { name: "language", value: "dart" },
              { name: "layer", value: "e2e" },
              { name: "platform", value: platform },
              { name: "host", value: hostname() },
              { name: "thread", value: run.thread },
              // Business taxonomy. `epic`/`feature`/`story` are what Allure's
              // Behaviors view groups by, which reads by functionality rather
              // than by file; `severity` drives its filter. A test that never
              // called `scenario()` simply keeps the infrastructure labels.
              ...(meta?.epic ? [{ name: "epic", value: meta.epic }] : []),
              ...(meta?.feature ? [{ name: "feature", value: meta.feature }] : []),
              ...(meta?.story ? [{ name: "story", value: meta.story }] : []),
              ...(meta?.severity ? [{ name: "severity", value: meta.severity }] : []),
              // What the test declared to `e2eTest`. The same strings the
              // runner filters on (`patrol test --tags "smoke_test"`), so a
              // reader can reproduce a selection from the report.
              ...tags.map(tag => ({ name: "tag", value: tag })),
            ],
          };

    writeFileSync(
      resolve(output, `${testResult.uuid}-result.json`),
      JSON.stringify(testResult, null, 2),
    );
    written += 1;
  }

  writeMetadata(output, { platform, startedAt, workers });
  console.log(`Wrote ${written} Allure result(s) to ${output} (${platform})`);
  if (written === 0) process.exitCode = 1;
}

/** Environment and categories shown in the report's sidebar. */
function writeMetadata(output, { platform, startedAt, workers }) {
  writeFileSync(
    resolve(output, "environment.properties"),
    [
      "app=Market",
      "layer=end-to-end",
      `platform=${platform}`,
      platform === "web"
        ? "runner=Patrol (web) + Playwright"
        : `runner=Patrol (${platform}) + native instrumentation`,
      platform === "web" ? "browser=Chromium" : `device=${process.env.PATROL_DEVICE ?? "connected"}`,
      `workers=${workers}`,
      `seed_mode=demo`,
      `started=${startedAt ?? ""}`,
      "",
    ].join("\n"),
  );

  writeFileSync(
    resolve(output, "categories.json"),
    JSON.stringify(
      [
        {
          name: "Locator not found",
          messageRegex: ".*(Found 0 widgets|no widgets|not visible).*",
          matchedStatuses: ["failed", "broken"],
        },
        {
          name: "Failed business assertion",
          messageRegex: ".*Expected:.*",
          matchedStatuses: ["failed"],
        },
        {
          name: "Timeout",
          messageRegex: ".*(Timeout|timed out).*",
          matchedStatuses: ["broken"],
        },
      ],
      null,
      2,
    ),
  );
}

convert(parseArgs(process.argv.slice(2)));
