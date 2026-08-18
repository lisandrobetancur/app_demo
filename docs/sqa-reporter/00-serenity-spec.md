# Phase 0 — What Serenity actually produces, read from its source

Everything in this document was read from `serenity-bdd/serenity-core` at commit
`5ad4ad7dd31ffe5513541caec69a36ec757f7ea6` (2026-07-16, version
`5.3.12-SNAPSHOT`), obtained as a sparse clone. Where a statement comes from a
specific class, the class is named. Where something could not be determined from
the source that was read, it is marked **UNVERIFIED** rather than guessed.

The input side — how our own marker stream arrives — was read from the
converter that consumed it at the time this was written; it now lives in
`packages/sqa_l/sqa_reporter/lib/src/markers.dart`.

---

## 1 · The `aggregate` output tree

Serenity's pipeline has two halves, and the split matters for us:

**During the test run**, each finished test writes one JSON file — a serialised
`TestOutcome` — into the output directory
(`JSONTestOutcomeReporter.generateReportFor`). This is the "result file" half
that Phase 1 replicates.

**At `aggregate` time**, `HtmlAggregateStoryReporter`
(`serenity-reports/.../reports/html/`) reads every `*.json` back, computes the
aggregates, renders the FreeMarker templates, and copies the static assets in
beside them. HTML is derived from JSON; the JSON is the source of truth.

```
target/site/serenity/
├── <sha256>.json                  one per test — the serialised TestOutcome
├── <sha256>.html                  one per test — default.ftl
├── <sha256>_screenshots.html      per test with captures — screenshots.ftl
├── screenshot files (.png)        referenced by filename from the JSON
├── index.html                     dashboard — home.ftl
├── capabilities.html              requirements root — requirements.ftl
├── <requirement pages>.html       one per requirement node — requirement-type.ftl
├── <result/tag pages>.html        filtered outcome lists — outcomes-with-result.ftl
├── build-info.html                build-info.ftl
├── serenity-summary.html          text-summary.ftl
└── css/ scripts/ bootstrap/ …     the static assets, copied verbatim
```

### File naming

`TestOutcome.getReportName(ReportType.JSON)` → `ReportNamer`. Compression is on
by default (`SERENITY_COMPRESS_FILENAMES` defaults to `true` in
`ReportNamer:32`), and then the name is:

```
sha256Hex(completeName) + ".json"          (Digest.ofTextValue → DigestUtils.sha256Hex)
completeName = storyTitle + ":" + name     (TestOutcome.getCompleteName)
```

Same digest with `.html` for the page, so the JSON and its page pair by name.

---

## 2 · The JSON schema of one `TestOutcome`

**Derived from:** the non-transient instance fields of
`net.thucydides.model.domain.TestOutcome` (3 263 lines), because
`GsonJSONConverter` serialises the object with plain Gson field reflection — no
exclusion strategy, no custom `TestOutcome` adapter. What is a field is in the
JSON; what is a method is not.

One wrinkle: three package-private fields (`result`, `issues`, `versions`,
`TestOutcome:270-272`) hold **computed** values. `toJson` calls
`calculateDynamicFieldValues()` first, which copies `getResult()`,
`getIssues()`, `getVersions()` and `getTags()` into them. A replica must do the
same computation before writing.

### Serialisation rules (the registered adapters)

| Type | In JSON | Source |
|---|---|---|
| `null` field | omitted | Gson default |
| empty collection | **omitted** | `CollectionAdapter` returns null |
| `Optional<T>` | unwrapped value, or omitted | `OptionalTypeAdapter` |
| `ZonedDateTime` | `"2026-08-18T04:05:06.123-05:00[America/Bogota]"` | `ZonedDateTimeAdapter` → `toString()` |
| `File` | just the file **name**, no path | `FileSerializer` |
| enums | their Java name: `"SUCCESS"` | Gson default |

### The fields

Required — `GsonJSONConverter.isValid` rejects the file without them:

| Field | Type | Notes |
|---|---|---|
| `id` | string | non-empty or the file is discarded |
| `name` | string | empty throws `AScenarioHasNoNameException` |

The rest, grouped; all optional in the sense that null/empty is omitted:

| Field | Type | What it is |
|---|---|---|
| `scenarioId`, `methodName`, `testCaseName` | string | identity of the source test |
| `title`, `description` | string | display name and prose |
| `testSteps` | `TestStep[]` | **the step tree — section 3** |
| `userStory` | `Story` | `{id, storyName, displayName, path, pathElements, narrative, type}` — drives the requirements link |
| `featureTag` | `TestTag` | the story's feature as a tag |
| `tags` | `TestTag[]` | `{name, type, displayName}` each — computed, includes feature/context tags |
| `result` | string enum | **computed** — see vocabulary below |
| `startTime` | zoned string | |
| `duration` | long ms | |
| `durationInSeconds` | double | computed |
| `testRunTimestamp` | zoned string | |
| `testFailureCause` | `FailureCause` | `{errorType, message, stackTrace[]}` (`stackTrace` entries via `StackTraceElementSerializer`) |
| `testFailureClassname`, `testFailureMessage`, `testFailureSummary` | string | denormalised copies |
| `coreIssues`, `additionalIssues`, `issues`, `coreVersions`, `additionalVersions`, `versions` | string[] | issue tracking; empty → omitted |
| `context` | string | e.g. browser/platform; feeds a context tag |
| `driver`, `sessionId` | string | WebDriver identity |
| `manual`, `isManualTestingUpToDate`, `manualTestEvidence`, `lastTested` | | manual-test bookkeeping |
| `dataTable` | `DataTable` | data-driven examples |
| `qualifier` | string (Optional) | disambiguates parameterised runs |
| `project`, `projectKey`, `rule`, `flags`, `testSource`, `actors`, `externalLink`, `order`, `scenarioOutline`, `testOutlineName`, `testData`, `backgroundTitle`, `backgroundDescription`, `annotatedResult`, `flakyTestFailureCause` | | present in the model; mostly null for us |

`endTime` exists as a field and is serialised when set.

### The result vocabulary (`TestResult` enum)

```
UNDEFINED, SUCCESS, PENDING, IGNORED, SKIPPED, ABORTED,
FAILURE,   ERROR,   COMPROMISED, UNSUCCESSFUL
```

Serenity's `FAILURE` = a real assertion failed; `ERROR` = the test could not do
its job. That is **exactly** the failed/broken distinction our suite already
computes (`BaseSteps` decides, the converter promotes) — the two models agree
on the semantics, only the words differ.

---

## 3 · The step tree

**Class:** `net.thucydides.model.domain.TestStep`. Serialised fields:

```
number         int          global sequence number across the whole test
description    string       what the step did
duration       long ms
startTime      zoned string
result         string enum  same vocabulary as the test
children       TestStep[]   ← nesting is real recursion, same shape all the way down
screenshots    ScreenshotAndHtmlSource[]
exception      FailureCause {errorType, message, stackTrace[]}
level          int          depth, redundant with nesting but present
precondition   boolean
reportData     ReportData[] rendered as "evidence" accordions in the page
restQuery, lineNumber, externalLink, manual    (null for us)
```

A screenshot attaches to **the step that took it**, as
`{screenshot: "<filename>.png", timeStamp: <epoch ms>}` — the `File` serialiser
writes only the name, so the image sits beside the JSON in the same directory.
`TestOutcome.getScreenshots()` walks the tree and flattens; nothing at
outcome level stores them separately.

Our converter builds exactly this shape today (business steps → interactions →
assertion leaves, with attachments on the owning step). The translation is
structural renaming, not redesign.

---

## 4 · The requirements hierarchy

This is where reading the source paid off. Two findings change Phase 5:

**The level names are configuration, not gospel.**
`DefaultCapabilityTypes:22` defines `["capability", "feature", "story"]` as the
*default*, and the very next methods derive the actual list **from directory
depth**: one level of stories → `["story"]`, two → `["feature", "story"]`,
three → the full triple. The property `serenity.requirement.types` overrides it
outright. Serenity itself does not insist on three levels.

**Consequence for us:** our two-level `scenario(epic:, feature:)` maps onto a
two-deep tree with types `["epic", "feature"]` (or Serenity's own
`["capability", "feature"]`) without bending anything. The "third level from
somewhere" question the prompt flagged dissolves: Serenity renders whatever
depth the tree has.

**How outcomes attach.** A `Requirement` node
(`requirements/model/Requirement.java`) is `{name, displayName, id, type,
path, children[], parent, narrative, tags…}` — a recursive tree. Coverage is
not stored in the tree: at render time each requirement is turned into a
`TestTag` (`type:name`) and the outcomes carrying that tag are counted;
parents roll up by recursing over `children`. So the reporter needs (a) the
tree, (b) each outcome tagged with its leaf requirement — which is what
`userStory.path`/`featureTag` and the computed `tags` provide.

Serenity builds the tree from the filesystem
(`FileSystemRequirementsTagProvider`); we build the same shape from metadata.
The tree is an *input* to rendering, not something the directory layout is
needed for.

**UNVERIFIED:** whether `aggregate` also writes a `requirements.json` datadump
alongside the HTML. The rendering side is clear; a serialised tree file was not
confirmed in the classes read. Phase 1 does not depend on it.

---

## 5 · Marker → schema mapping, field by field

Input contract as implemented by `markers.dart` and `inputs.dart` (both
transports).

| Marker / source | TestOutcome field | Notes |
|---|---|---|
| test name (Playwright title / `PATROL_LOG type:test`) | `name`, `title`, `id`, `methodName` | `id` = `suite#name` like today's `fullName` |
| suite (dart file) | `testCaseName` | |
| run start/stop | `startTime`, `duration`, `durationInSeconds`, `testRunTimestamp` | same clock model the converter uses |
| test status + step promotion | `result` | passed→`SUCCESS`, failed→`FAILURE`, broken→`ERROR`, skipped→`SKIPPED`; reuse the existing promotion rule |
| `statusDetails` (Playwright errors / `TestEntry.error`) | `testFailureCause{message, stackTrace}`, `testFailureMessage`, `testFailureSummary` | see gap G1 |
| `PATROL_STEP` begin/end | `testSteps[]` nodes: `description`, `result`, nesting | `number` = global counter, `level` = depth |
| `PATROL_LOG type:step` | child `TestStep`s | timestamps drive `startTime`/`duration` |
| `PATROL_ASSERT` | leaf `TestStep` — `description` = name, expected/actual folded into the description | see gap G2 |
| `PATROL_SHOT` | `screenshots[]` on the owning step | reassembly logic reused as-is; file written beside the JSON, referenced by name |
| `PATROL_META.epic/feature` | `userStory` (synthesised: `path` = epic/feature, `storyName` = feature, `type` = "feature"), `featureTag`, entries in `tags` | drives section 4 |
| `PATROL_META.severity` | a `TestTag {type: "severity"}` | Serenity has no severity field; a tag is its idiom |
| `PATROL_META.description` | `description` | |
| `PATROL_TAGS` | `tags[]` as `{name, type: "tag"}` | |
| `PATROL_PARAM` | `testData` (joined `name=value`) | Serenity has no per-test parameter list; `testData` is its slot for "the data this ran with" |
| `PATROL_TRACE` | leaf steps for `warn` and `error`; `info` is not written | The step-level `reportData` slot was used for a full run log at first and then dropped: every line worth acting on is already a step, so the log could only add `info` narration nobody opens. The lines stay on the model (`RunCase.logLines`) for a surface that wants them. |
| platform | `context` | also becomes a context tag, as Serenity does |

### Gaps — fields we cannot fill, and what it would take

- **G1 · `testFailureCause.errorType`.** Serenity stores the exception class
  name. Playwright's error object gives message + stack, not a Dart type. The
  closest honest value: parse the first line of the message
  (`TestFailure`, `StateError`…) when it looks like a type, else
  `"AssertionError"`. Filling it properly would need the kit to emit the
  runtime type in a marker — a kit change, flagged per the rules, **not
  needed for Phase 1**.
- **G2 · assertion expected/actual.** Serenity has no structured slot; they
  fold into the step description. Nothing lost visually; the structure is lost.
- **G3 · `driver`.** Nothing in the stream names the browser. `environment
  .properties` in CI knows; the marker stream does not. Leave null or set from
  the platform. A kit change could emit it; cosmetic.
- **G4 · `dataTable`.** Our data-driven login test loops *inside* one test, so
  it is one outcome, not a Serenity examples table. Representing it as a
  `DataTable` would require `PATROL_STEP`-level row markers — kit change,
  explicitly out of Phase 1.
- **G5 · issues/versions/manual/actors/rule/flags** — no source in our world;
  omitted, which the format allows (empty → absent).

Nothing in the gaps blocks a faithful per-test JSON or the dashboard.

---

## 6 · The assets inventory

`serenity-report-resources/src/main/resources/`:

| | Size | Contents |
|---|---|---|
| `freemarker/` | 548 KB | the 20 templates |
| `report-resources/` | **21 MB** | everything the site loads |

The 21 MB breaks down as: `bootstrap-icons/` 9.4 MB + `icons/` 5.6 MB (icon
sets — the bulk is optional glyphs), `bootstrap/` 1.7 MB, `jquery-ui` 1.1 MB,
`jit/` 736 KB (treemap lib — out of scope), `images/` 376 KB, `datatables/`
372 KB, `chartjs/` 348 KB, `scripts/` 184 KB, plus smaller: swiper, dygraph,
jqtree, `css/` 68 KB (Serenity's own styling), prism, favicons.

**Self-contained: yes.** The only URL in any template is the W3C SVG namespace.
No CDN, no fonts fetched, no runtime requests. Copy the directory and the site
works from `file://`.

**Decision, added after review:** none of this is copied. The owner requires
that nothing of Serenity's exists anywhere in the product — and copying files
verbatim would oblige carrying Serenity's copyright notice, which contradicts
that. The inventory above stays as a *read-only reference* for what the pages
load; the working set becomes stock Bootstrap, bootstrap-icons, DataTables and
Chart.js obtained from their own distributions (MIT and similar), plus our own
stylesheet. Layout and structure are followed by eye; formats and field names
are not protected material.

---

## 7 · The licence

**Apache License 2.0** — root `licence.txt`, copyright
*2011-2016 John Ferguson Smart*.

What it means for this work, stated plainly:

- Copying the templates, CSS, JS and images verbatim into our repository is
  **permitted**, including commercially and modified, with **no permission and
  no notification** to the author.
- Redistribution obligations, all mechanical: ship a copy of the licence next
  to the copied material, keep existing copyright notices, and state that
  changes were made. One `LICENSE`/`NOTICE` file under the asset directory
  satisfies this.
- The bundled third-party libraries (Bootstrap, jQuery, DataTables, Chart.js…)
  carry their own permissive licences (MIT/similar); their notices travel with
  their files.
- Apache 2.0 grants **no trademark rights**: the product must not be presented
  as "Serenity BDD". The planned rename already covers this.

**Decision, added after review:** the obligations above never trigger,
because no Serenity file is redistributed. The product is built clean: own
CSS over stock MIT libraries, Serenity read for structure and schema only.
The generated site, the package and its output contain no occurrence of the
string "Serenity" in any casing; the report titles itself **SQA Reporter**,
and the project-name slot reads **Test e2e Web** or **Test e2e Mobile** by
platform. Serenity is credited in `docs/` as the design source, which is
honesty, not an obligation.

*(A reading of the licence, not legal advice.)*

---

## What Phase 1 builds on this

A Dart package with a format-agnostic run model (the converter's parsed form,
essentially) and one serialiser producing: per test, a `TestOutcome` JSON named
`sha256(completeName).json`, with the fields, adapters' conventions and computed
values above; screenshots written beside it. Verified by diffing shape against
this section 2, field by field.
