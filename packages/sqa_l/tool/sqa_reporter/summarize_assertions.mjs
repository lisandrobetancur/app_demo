#!/usr/bin/env node
/**
 * Counts the assertions an Allure result set contains, per scenario.
 *
 * The suite reports every check it makes as its own step (`PATROL_ASSERT`,
 * see `BaseSteps.should`), which only helps if the markers actually survive
 * the trip: they are printed inside the browser, captured by Playwright per
 * test, and reassembled by the converter. Any link in that chain can break
 * quietly — and it breaks *silently*, because a suite whose assertions never
 * reached the report still passes. Green, with nothing behind it.
 *
 * So the count goes in the job summary, where it is visible without
 * downloading an artifact, and zero assertions is called out as a problem
 * rather than left as an empty table.
 *
 *   node summarize_assertions.mjs --platform web
 */

import { existsSync, readdirSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";

// The repo root, found by walking up to the directory that holds `.git`,
// rather than by counting `..` segments. This folder has moved once already;
// a hop count survives that move only if someone remembers to re-count it, and
// when they do not the failure is a path that silently resolves to the wrong
// place instead of an error.
function repoRoot(from) {
  let dir = from;
  while (!existsSync(resolve(dir, ".git"))) {
    const parent = dirname(dir);
    if (parent === dir) {
      throw new Error(`no .git found above ${from}`);
    }
    dir = parent;
  }
  return dir;
}

const REPO_ROOT = repoRoot(import.meta.dirname);

function parseArgs(argv) {
  const args = { platform: "web" };
  for (let i = 0; i < argv.length; i += 2) {
    const [flag, value] = [argv[i], argv[i + 1]];
    if (flag === "--platform" && value) args.platform = value;
    else if (flag === "--input" && value) args.input = resolve(value);
  }
  args.input ??= resolve(REPO_ROOT, "build/e2e", args.platform, "allure", "results");
  return args;
}

/**
 * An assertion is a leaf step carrying `expected` — the shape
 * `reportAssertion` gives it. Patrol's own interactions ("tap on …") carry no
 * such parameter, so they are not miscounted.
 */
function countAssertions(steps, tally) {
  for (const step of steps ?? []) {
    const isAssertion = (step.parameters ?? []).some(p => p.name === "expected");
    if (isAssertion) {
      tally.total += 1;
      if (step.status === "passed") tally.passed += 1;
      else tally.failed += 1;
    }
    countAssertions(step.steps, tally);
  }
  return tally;
}

function main() {
  const { input, platform } = parseArgs(process.argv.slice(2));

  // Two absences that look alike and mean opposite things.
  //
  // *No results at all* — a cancelled run, or a converter that already
  // failed — is not this step's news to break: the step that was supposed to
  // produce them is red already, and a second red mark here only buries it.
  // Say so and leave.
  const files = existsSync(input)
    ? readdirSync(input).filter(f => f.endsWith("-result.json"))
    : [];
  if (files.length === 0) {
    console.log(
      `No Allure results at ${input} — the suite did not get far enough to ` +
        "produce any. Nothing to summarize.",
    );
    return;
  }

  const rows = [];
  const totals = { total: 0, passed: 0, failed: 0 };
  for (const file of files) {
    const result = JSON.parse(readFileSync(resolve(input, file), "utf8"));
    const tally = countAssertions(result.steps, { total: 0, passed: 0, failed: 0 });
    rows.push({ name: result.name ?? result.fullName ?? file, ...tally });
    totals.total += tally.total;
    totals.passed += tally.passed;
    totals.failed += tally.failed;
  }
  rows.sort((a, b) => b.total - a.total);

  const out = [`### Aserciones — ${platform}`, ""];
  if (totals.total === 0) {
    // Tests ran and produced a report, and the report verifies nothing. This
    // is the case the whole step exists for, and a warning nobody opens does
    // not protect against it — so it fails.
    out.push(
      "> [!CAUTION]",
      `> **The report of ${rows.length} scenario(s) contains no assertions.**`,
      ">",
      "> The suite ran and came out green, but it verifies nothing visible: the",
      "> `PATROL_ASSERT` markers never reached the report. Check",
      "> `BaseSteps.should`, `reportAssertion` and the converter",
      "> `patrol_to_allure.mjs`.",
    );
    console.log(out.join("\n"));
    process.exitCode = 1;
    return;
  }

  out.push(
    "| Escenario | Aserciones | Pasadas | Fallidas |",
    "|---|--:|--:|--:|",
    ...rows.map(r => `| ${r.name} | ${r.total} | ${r.passed} | ${r.failed} |`),
    `| **Total** | **${totals.total}** | **${totals.passed}** | **${totals.failed}** |`,
  );
  console.log(out.join("\n"));
}

main();
