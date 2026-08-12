#!/usr/bin/env node
/**
 * Turns Patrol's web results into Allure results.
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
 *   node patrol_to_allure.mjs [--input <results.json>] [--output <dir>]
 */

import { createHash, randomUUID } from "node:crypto";
import { existsSync, mkdirSync, copyFileSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { basename, extname, resolve } from "node:path";
import { hostname } from "node:os";

const REPO_ROOT = resolve(import.meta.dirname, "../..");
const DEFAULTS = {
  input: resolve(REPO_ROOT, "packages/apps/market_app/playwright-report/results.json"),
  output: resolve(REPO_ROOT, "allure-results"),
};

/** Playwright status -> Allure status. */
const STATUS = {
  passed: "passed",
  failed: "failed",
  timedOut: "broken",
  interrupted: "broken",
  skipped: "skipped",
};

function parseArgs(argv) {
  const args = { ...DEFAULTS };
  for (let i = 0; i < argv.length; i += 2) {
    const [flag, value] = [argv[i], argv[i + 1]];
    if (flag === "--input" && value) args.input = resolve(value);
    else if (flag === "--output" && value) args.output = resolve(value);
  }
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
 */
function stepsFrom(stdout, outputDir) {
  const root = [];
  const businessStack = []; // business steps currently open
  const interactionStack = []; // patrol interactions currently open
  const shots = new Map(); // name -> { total, chunks: Map<index, string> }
  const orphanShots = [];
  let lastClosedBusiness = null;

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
        const step = { name: payload, status: "passed", start: Date.now(), stop: Date.now(), steps: [], parameters: [], attachments: [] };
        currentChildren().push(step);
        businessStack.push(step);
      } else {
        const step = businessStack.pop();
        if (step) {
          step.stop = Date.now();
          step.status = payload === "failed" ? "failed" : "passed";
          lastClosedBusiness = step;
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
  return { steps: root, orphanShots };
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

/** Copies Playwright attachments (videos, traces) next to the results. */
function attachmentsFrom(result, outputDir) {
  const attachments = [];
  for (const attachment of result.attachments ?? []) {
    if (!attachment.path || !existsSync(attachment.path)) continue;
    const source = `${randomUUID()}-attachment${extname(attachment.path)}`;
    copyFileSync(attachment.path, resolve(outputDir, source));
    attachments.push({
      name: attachment.name ?? basename(attachment.path),
      source,
      type: attachment.contentType ?? "application/octet-stream",
    });
  }
  return attachments;
}

function convert({ input, output }) {
  if (!existsSync(input)) {
    console.error(
      `No Playwright results at ${input}\n` +
        "Run the suite first:\n" +
        "  cd packages/apps/market_app && patrol test --device chrome --web-reporter='[\"list\",\"json\"]'",
    );
    process.exit(1);
  }

  rmSync(output, { recursive: true, force: true });
  mkdirSync(output, { recursive: true });

  const report = JSON.parse(readFileSync(input, "utf8"));
  let written = 0;

  for (const suite of report.suites ?? []) {
    for (const spec of suite.specs ?? []) {
      for (const test of spec.tests ?? []) {
        for (const result of test.results ?? []) {
          const { suite: suiteName, name } = splitTitle(spec.title);
          const start = Date.parse(result.startTime);
          const fullName = `${suiteName}#${name}`;
          const { steps, orphanShots } = stepsFrom(stdoutOf(result), output);

          const testResult = {
            uuid: randomUUID(),
            historyId: createHash("md5").update(fullName).digest("hex"),
            name,
            fullName,
            status: STATUS[result.status] ?? "unknown",
            statusDetails: statusDetailsFrom(result),
            stage: "finished",
            start,
            stop: start + Math.round(result.duration ?? 0),
            steps,
            // Screenshots taken before the first interaction (or after the
            // last one) have no step to hang from, so they stay on the test.
            attachments: [...orphanShots, ...attachmentsFrom(result, output)],
            parameters: result.retry > 0 ? [{ name: "retry", value: String(result.retry) }] : [],
            labels: [
              { name: "parentSuite", value: "Patrol web E2E" },
              { name: "suite", value: suiteName },
              { name: "framework", value: "patrol" },
              { name: "language", value: "dart" },
              { name: "layer", value: "e2e" },
              { name: "host", value: hostname() },
              { name: "thread", value: `worker-${result.workerIndex ?? 0}` },
            ],
          };

          writeFileSync(
            resolve(output, `${testResult.uuid}-result.json`),
            JSON.stringify(testResult, null, 2),
          );
          written += 1;
        }
      }
    }
  }

  writeMetadata(output, report);
  console.log(`Wrote ${written} Allure result(s) to ${output}`);
  if (written === 0) process.exitCode = 1;
}

/** Environment and categories shown in the report's sidebar. */
function writeMetadata(output, report) {
  const stats = report.stats ?? {};
  writeFileSync(
    resolve(output, "environment.properties"),
    [
      "app=Market",
      "layer=end-to-end",
      "runner=Patrol (web) + Playwright",
      "browser=Chromium",
      `workers=${report.config?.workers ?? 1}`,
      `seed_mode=demo`,
      `started=${stats.startTime ?? ""}`,
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
