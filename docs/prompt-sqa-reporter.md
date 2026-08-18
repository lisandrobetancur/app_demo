# Prompt: a Serenity-BDD-shaped report generator, written in Dart

Paste everything below the line into Claude Code (or another agent), opened on
the `app_demo` repository. It is written to run in phases, with a mandatory stop
between each one.

---

## ROLE

You are building **`sqa_reporter`**: a Dart program that turns an E2E run into
a report with the **same structure and layout as Serenity BDD's** — built
clean, copying none of Serenity's files — and which writes result files with
the **same JSON schema** Serenity's Gradle `aggregate` task produces.

**Branding and legal, non-negotiable:**

* **No Serenity file is ever copied** — no template, no CSS, no JS, no image.
  Serenity's source is read for structure, schema and layout only. Ideas and
  layout are not protected material; their files are, and copying them would
  oblige us to carry Serenity's copyright notice, which the next rule forbids.
* **The strings "Serenity", "serenity", "Serenity BDD" appear nowhere** in the
  generated site, the package's code, its assets or its output — only in
  `docs/` where the design source is honestly credited.
* The report titles itself **"SQA Reporter"**. The slot where Serenity shows
  the project name reads **"Test e2e Web"** or **"Test e2e Mobile"** according
  to the platform being reported.
* Styling is our own CSS over standard permissively-licensed libraries
  (Bootstrap, Chart.js, DataTables — MIT and similar). Their notices travel
  with their files, as everywhere else in the industry.

This is an alternative to Allure, not an addition to it. The existing Allure
pipeline keeps working untouched until the replacement is proven; the two
coexist for the whole of this work.

Your priorities, in this order:

1. **Structural fidelity to Serenity.** Same pages, same panels, same
   information in the same places; the pixels may diverge and will, since the
   styling is ours. When in doubt about structure, do what Serenity does.
2. **Evidence over inference.** Serenity is open source. Read its code, do not
   reconstruct it from blog posts.
3. **Runnable at every phase.** Each phase ends with output someone can open.
4. **Coverage of the report's surface.** Last, not first.

## WHAT ALREADY EXISTS, AND WHAT YOU MUST NOT BREAK

The suite already emits a documented marker stream. These are your input, and
they are the only input:

| Marker | Emitted by | Carries |
|---|---|---|
| `PATROL_META` | `scenario.dart` | epic, feature, severity, description |
| `PATROL_PARAM` | `scenario.dart` | the `testParam` values |
| `PATROL_STEP` | `base_steps.dart` | step open/close, with nesting |
| `PATROL_ASSERT` | `assert_report.dart` | one record per assertion, with status |
| `PATROL_SHOT` | `screenshot.dart` | screenshots, chunked |
| `PATROL_TAGS` | `tags.dart` | the test's tags |
| `PATROL_TRACE` | `log.dart` | log lines |

`packages/sqa_l/tool/allure/patrol_to_allure.mjs` already parses this
stream for Allure, on two transports — Playwright's JSON on web, the device log
on Android. **Read it first.** It is the working reference for how the markers
arrive, how the two transports differ, and where the edges are; you are writing
a second consumer of the same stream, not inventing an input format.

Do not change the markers. If you find you need data nobody emits, stop and say
so — adding a marker is a change to the kit and is my decision.

## SOURCES TO CONSULT

Serenity's report is generated from FreeMarker templates and a set of static
assets, all published:

- **Templates** —
  `https://github.com/serenity-bdd/serenity-core/tree/main/serenity-report-resources/src/main/resources/freemarker`
  Twenty of them. The ones inside your scope: `home.ftl` (dashboard),
  `default.ftl` (a single test outcome), `requirements.ftl`,
  `requirement-type.ftl`, `screenshot.ftl`, `screenshots.ftl`,
  `test-result-summary.ftl`, `outcomes-with-result.ftl`,
  `outcomes-with-duration.ftl`, `menu.ftl`, `progress.ftl`.
  Out of scope, and useful only to know they exist: `history.ftl`,
  `release.ftl`, `releases.ftl`, `coverage.ftl`, `treemap.ftl`,
  `build-info.ftl`, `progress-report.ftl`, `results-by-tagtype.ftl`,
  `text-summary.ftl`.
- **Static assets** — the CSS, JS, fonts and images in the same
  `serenity-report-resources` module. **Read-only reference** for what the
  pages load and how they are laid out; none of it is copied.
- **The JSON schema** — Serenity serialises a `TestOutcome` per test. Find the
  serialiser in `serenity-model` / `serenity-core` and derive the schema from
  the code, not from an example you found somewhere.

**Check the licence before copying anything.** Serenity is Apache 2.0 at the
time of writing; confirm it, and if you reuse CSS or assets verbatim, carry the
notice the licence requires. Report what you found — this is a legal question,
not a technical one, and I want to see it stated rather than assumed.

## INVARIABLE RULES

1. **One phase at a time.** Stop, report, wait for my explicit approval.
2. **File budget.** Each phase declares what it may touch. Nothing outside it.
3. **The reporter never imports the app, the kit, or Patrol.** It reads a
   documented intermediate model and writes files. Same rule that already
   governs `patrol_kit`, and its pubspec should enforce it the same way.
4. **No state between runs.** No history, no trends, no comparison with the
   previous execution. This repository already decided that for Allure and the
   reasoning is in the melos scripts; a report describes one run.
5. **The Allure pipeline keeps working** until I say otherwise. You add; you do
   not replace.
6. **Every phase is verified by producing real output**, from a real run, and
   opening it. "It compiles" is not verification.
7. **If a Serenity detail cannot be determined from the source, say so** and
   propose the closest approximation. Do not silently invent.

---

## PHASES

### Phase 0 — Reconnaissance (read only, NO CODE)

Read Serenity's source and the existing `.mjs` converter. Produce a
specification, and nothing else.

Report:

1. **The `aggregate` output** — the full file and directory tree it produces.
   Which files are per-test, which are aggregate, which are static assets.
2. **The JSON schema of one `TestOutcome`** — every top-level field, its type,
   and which are required. Name the Java class you derived it from.
3. **How a step tree is represented** in that JSON: nesting, status, duration,
   and how a screenshot attaches to a step.
4. **How the requirements hierarchy is built** — where Serenity gets
   capability → feature → story, and how coverage is rolled up a branch.
5. **The mapping** from our markers to that schema, field by field. Mark every
   field we cannot fill and say what it would take.
6. **The assets inventory** — what CSS/JS the replica needs, their size, and
   whether they are self-contained or fetch anything at runtime.
7. **The licence**, stated plainly.

**Deliverable:** `docs/sqa-reporter/00-serenity-spec.md`.

**Exit criterion:** I read it and decide what is in and out. Nothing else.

---

### Phase 1 — The model and the JSON

**Goal:** a Dart package that reads the marker stream and writes Serenity-schema
JSON. No HTML yet.

**Allowed files:** `packages/sqa_l/sqa_reporter/**` (new package), and the root
`pubspec.yaml` to add it to the workspace.

The name is free: the existing Node converter stays `tool/allure/`, which is
what it is — a converter to Allure. `sqa_reporter` is reserved for this.

The package holds two things kept apart: a **model** of a run (tests, steps,
assertions, screenshots, metadata) that owes nothing to any output format, and
a **serialiser** that writes Serenity's schema from it. A second output format
should later be a second serialiser, not a rewrite.

**Verification:** run the real suite, produce the JSON, and diff its shape
against the spec from Phase 0 field by field. Paste the diff.

**Exit criterion:** the JSON matches the documented schema, and you have said
which fields are stubbed and why.

---

### Phase 2 — The site skeleton

**Goal:** the dashboard — Serenity's `home.ftl` equivalent — rendering real
data.

**Allowed files:** the reporter package, plus a new assets directory.

Write our own stylesheet over stock Bootstrap (and friends), matching the
layout: the same panels in the same places, the same result colours, the same
summary counts. No Serenity asset crosses over — see the branding rules.

**Verification:** screenshots of Serenity's dashboard beside yours. Name every
structural difference; visual divergence from our own styling is expected and
listed, not fixed. Verify also that a grep for "serenity" over the generated
site returns nothing.

---

### Phase 3 — The test detail page

**Goal:** `default.ftl`'s equivalent — one page per test, with the step tree,
durations, status per step, and the failure when there is one.

**Verification:** a passing test and a failing one, both rendered, both
compared against Serenity's rendering of the same shape.

---

### Phase 4 — Screenshots

**Goal:** each capture attached to the step that produced it, in Serenity's
lightbox presentation.

The markers arrive chunked; the existing `.mjs` already solves reassembly on
both transports. Read how, and say whether you reused the approach or improved
it.

---

### Phase 5 — The requirements hierarchy

**Goal:** the capability → feature → story tree with coverage rolled up.

This is the part with a real design decision in it, so bring it to me before
building: our `scenario(epic:, feature:)` is the obvious source — note there
is deliberately no `story`, so the third level has to come from somewhere or be
dropped — but
Serenity derives its hierarchy from a directory structure, and the two do not
map cleanly. **Propose the mapping and stop.**

---

### Phase 6 — Wiring

**Goal:** `melos run sqaReportWeb` and the Android equivalent, beside the
existing Allure scripts, and a CI step that publishes both.

**Allowed files:** root `pubspec.yaml`, `packages/sqa_l/tool/e2e/*.sh`,
`.github/workflows/e2e-*.yml`.

**Exit criterion:** a CI run produces both reports from one suite execution.

---

## OUT OF SCOPE, DELIBERATELY

History, trends, flakiness, releases, code coverage, treemaps, REST query
reporting, manual test annotations. Say so if you think one of them is load-
bearing for something in scope, but do not build it.

## REPORT FORMAT WHEN CLOSING EACH PHASE

```
## Phase N — <name>  [COMPLETED | BLOCKED]

**Files touched:** (exact list, +lines/-lines)

**Verification run:**
  <command>
  <real output, unsummarised>

**Fidelity gaps:** (what does not match Serenity yet, and why)
**Decisions I made without asking:** (and the alternative I rejected)
**Open questions:**

**Proposed next phase:** — awaiting approval.
```

## START

Phase 0 only. Read, do not write code.
