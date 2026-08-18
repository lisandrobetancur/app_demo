/// The site's static assets, written from scratch.
///
/// Nothing in this file is copied from anywhere: the layout facts it encodes
/// (an off-white page, a white banner, a blue project title on the right, a
/// tabbed card, result colours per status) come from *reading* the design
/// source's stylesheet and templates, and every rule here was authored for
/// this generator. That is the clean-room line this project drew: structure
/// and appearance are facts, files are not, and no file crosses.
///
/// The charts are CSS-only — a conic-gradient donut and flex bars — so the
/// generated site is fully self-contained: no script libraries, no fonts, no
/// network requests at render time.
library;

/// The result palette, one entry per verdict the writer emits.
///
/// The rgba values are the ones the reference report uses for the same
/// verdicts (documented in `docs/sqa-reporter/00-serenity-spec.md` §6) — kept
/// identical on purpose, because matching the colours is what makes a report
/// readable by someone who already knows how to read the original.
const Map<String, ({String fill, String border, String solid})> resultColors =
    <String, ({String fill, String border, String solid})>{
      'SUCCESS': (
        fill: 'rgba(153,204,51,0.5)',
        border: 'rgba(153,204,51,1)',
        solid: '#99cc33',
      ),
      'FAILURE': (
        fill: 'rgba(255,22,49,0.5)',
        border: 'rgba(255,22,49,1)',
        solid: '#ff1631',
      ),
      'ERROR': (
        fill: 'rgba(255,97,8,0.5)',
        border: 'rgba(255,97,8,1)',
        solid: '#ff6108',
      ),
      'SKIPPED': (
        fill: 'rgba(238,224,152,0.75)',
        border: 'rgba(238,224,152,1)',
        solid: '#b8860b',
      ),
      'UNDEFINED': (
        fill: 'rgba(83,50,168,0.5)',
        border: 'rgba(83,50,168,1)',
        solid: '#5332a8',
      ),
    };

/// The glyph shown in a result cell, per verdict. Plain text rather than an
/// icon font: one fewer asset, and the `title` attribute carries the word.
const Map<String, String> resultGlyphs = <String, String>{
  'SUCCESS': '✓',
  'FAILURE': '✗',
  'ERROR': '!',
  'SKIPPED': '»',
  'UNDEFINED': '?',
};

/// The favicon, written to `favicon.svg` beside `index.html`.
///
/// What the report is, in sixteen pixels: a checked-off result on a clipboard,
/// in the report's own navy with the verdict green it uses everywhere else.
/// Drawn here rather than fetched, so the site still asks the network for
/// nothing, and as SVG so it stays sharp on any tab.
const String siteFavicon = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <rect width="32" height="32" rx="7" fill="#0A1B3A"/>
  <rect x="8" y="5" width="16" height="22" rx="2.5" fill="#ffffff"/>
  <rect x="12" y="3" width="8" height="4" rx="1.5" fill="#0A1B3A"/>
  <path d="M11.5 16.5l3 3 6-6.5" fill="none" stroke="#99cc33"
        stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="11.5" y="22" width="9" height="1.8" rx="0.9" fill="#d7dde6"/>
</svg>
''';

/// The stylesheet, written to `sqa-reporter.css` beside `index.html`.
const String siteCss = '''
/* SQA Reporter — all rules authored for this generator. */

:root {
  /* The colour titles and subtitles are set in. Links keep their own blue:
     the two must stay distinguishable. */
  --title: #0A1B3A;
  --link: #428bca;
}

* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  font-size: 16px;
  font-family: "Helvetica Neue", Calibri, Helvetica, Arial, sans-serif;
  background-color: #f7f8f3;
  color: #333;
}

a { text-decoration: none; color: var(--link); }
a:hover { text-decoration: underline; }

/* ── Banner ─────────────────────────────────────────────────────────── */

.topheader { background: #fff; }

/* The page fills the window, with a margin rather than a column: a report of
   fifty scenarios has long feature and scenario names, and capping the width
   was wrapping them onto three lines while the screen sat empty on both
   sides. Nothing is pinned to a minimum width — what is too wide for the
   window scrolls inside its own box (see `.table-scroll`) instead of forcing
   the whole page sideways. */
.topbanner {
  margin: 0 auto;
  padding: 1em 1.5em;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.wordmark {
  font-size: 1.75em;
  font-weight: 300;
  color: #333;
  text-decoration: none;
}

.wordmark:hover { text-decoration: none; }
.wordmark .accent { color: var(--title); font-weight: 400; }

.projectname { text-align: right; }
.projecttitle { font-weight: normal; font-size: 2em; color: var(--title); }

/* ── Content frame ──────────────────────────────────────────────────── */

.middlecontent {
  margin: 0 auto;
  padding: 0 1.5em 2em 1.5em;
}

.breadcrumbs { color: #777; padding: 0.5em 0; display: block; }

h2 { font-weight: 300; font-size: 1.75em; margin: 0.5em 0; color: var(--title); }
h3 { font-weight: 300; font-size: 1.4em; margin: 1em 0 0.5em 0; color: var(--title); }
h4 { font-weight: 400; font-size: 1.1em; margin: 0.75em 0 0.5em 0; color: var(--title); }

.test-count-title { font-size: 1.1em; color: #555; margin-bottom: 0.75em; }

/* ── Menu and tabs ──────────────────────────────────────────────────── */

.nav-tabs {
  list-style: none;
  display: flex;
  gap: 0.25em;
  border-bottom: 1px solid #ddd;
  margin-top: 0.5em;
}

.nav-tabs li a, .nav-tabs li span {
  display: inline-block;
  padding: 0.5em 1em;
  border: 1px solid transparent;
  border-radius: 4px 4px 0 0;
  color: var(--link);
}

.nav-tabs li.active a, .nav-tabs li.active span {
  color: #555;
  background-color: #fff;
  border-color: #ddd;
  border-bottom-color: #fff;
  cursor: default;
}

.nav-tabs li.disabled span { color: #aaa; cursor: default; }

.date-and-time { float: right; color: gray; padding: 0.5em 0; }

/* ── Card with tab panes ────────────────────────────────────────────── */

.card {
  background: #fff;
  border: 1px solid #ddd;
  border-top: none;
  border-radius: 0 0 4px 4px;
  padding: 1.5em;
}

.tab-pane { display: none; }
.tab-pane.active { display: block; }

/* ── Dashboard charts ───────────────────────────────────────────────── */

.dashboard-charts {
  display: flex;
  gap: 2.5em;
  align-items: flex-start;
  flex-wrap: wrap;
  margin-bottom: 2em;
}

.chart-block { flex: 1 1 300px; min-width: 300px; }
.chart-block.wide { flex: 1 1 380px; min-width: 380px; }

.chart-caption {
  font-size: 0.8em;
  color: #777;
  text-align: center;
  margin-bottom: 0.5em;
}

/* ── Doughnut ───────────────────────────────────────────────────────── */

.donut-wrap { display: flex; justify-content: center; }

.donut {
  width: 220px;
  height: 220px;
  border-radius: 50%;
  margin: 0.5em 0 1em;
  position: relative;
}

.donut::before {
  content: "";
  position: absolute;
  inset: 26%;
  border-radius: 50%;
  background: #fff;
}

.donut .donut-label {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2em;
  color: #444;
  z-index: 2;
}

/* One transparent ring sector per segment, sitting over the gradient: this
   is what a click on "the passing slice" actually hits. */
.donut-wedge {
  position: absolute;
  inset: 0;
  z-index: 1;
  cursor: pointer;
}

.donut-wedge:hover { background: rgba(255, 255, 255, 0.25); }

.donut-slice-label {
  position: absolute;
  transform: translate(-50%, -50%);
  font-size: 0.8em;
  font-weight: 600;
  color: #444;
  z-index: 1;
}

.chart-legend {
  list-style: none;
  font-size: 0.8em;
  color: #555;
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0.25em 1em;
}

.chart-legend li.empty { color: #b0b0b0; }

.chart-legend .swatch {
  display: inline-block;
  width: 0.9em;
  height: 0.9em;
  border: 1px solid;
  margin-right: 0.4em;
  vertical-align: -0.1em;
}

/* ── Bar charts with an axis ────────────────────────────────────────── */

/* The padding is where a full-height bar's own value label sits: without it
   the number would ride over whatever the chart is captioned with. */
.plot { display: flex; height: 220px; margin: 0.5em 0 2em; padding-top: 1.2em; }
.plot.slanted-axis { margin-bottom: 5em; }

.y-axis {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  align-items: flex-end;
  padding-right: 0.4em;
  font-size: 0.75em;
  color: #888;
  /* Half a line up and down, so each number sits ON its gridline. */
  margin: -0.5em 0;
}

.y-tick { line-height: 1em; }

.plot-area { position: relative; flex: 1; }

.gridlines {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.gridlines .gridline { border-top: 1px solid #eee; }

.bars {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: flex-end;
  justify-content: space-around;
  gap: 0.5em;
}

.bar-column {
  flex: 1;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  align-items: center;
  position: relative;
  color: inherit;
}

a.bar-column { cursor: pointer; }
a.bar-column:hover { text-decoration: none; }
a.bar-column:hover .bar-fill { filter: brightness(0.92); }

.chart-legend a { color: inherit; }
.chart-legend a:hover { text-decoration: underline; }

.bar-fill {
  width: 60%;
  min-height: 1px;
  border: 1px solid;
  display: flex;
  align-items: flex-start;
  justify-content: center;
}

.bar-fill.duration-fill {
  background: rgba(120, 165, 230, 0.55);
  border-color: rgba(120, 165, 230, 1);
}

.bar-value {
  font-size: 0.75em;
  color: #444;
  margin-top: -1.4em;
}

.bar-label {
  position: absolute;
  top: 100%;
  padding-top: 0.35em;
  font-size: 0.7em;
  color: #777;
  white-space: nowrap;
}

/* Slanted labels hang BELOW the axis and rise towards their own column: the
   anchor is the label's right end, sitting under the bar it names, so the
   text runs down-left into empty space instead of up-right across the bars. */
.bar-label.slanted {
  left: 50%;
  font-size: 0.65em;
  text-align: right;
  transform-origin: 100% 0;
  transform: translateX(-100%) rotate(-35deg);
}

/* The two panels the reference puts side by side under the charts. */
.summary-columns {
  display: flex;
  gap: 2.5em;
  align-items: flex-start;
  flex-wrap: wrap;
}

.summary-columns > .coverage-panel { flex: 2 1 420px; min-width: 420px; }
.summary-columns > .statistics-panel { flex: 1 1 320px; min-width: 320px; }

/* ── Tables ─────────────────────────────────────────────────────────── */

table.table { border-collapse: collapse; width: 100%; margin: 0.5em 0; }

table.table th {
  text-align: left;
  padding: 0.5em 0.75em;
  border-bottom: 2px solid #ddd;
  font-weight: 600;
}

table.table td {
  padding: 0.5em 0.75em;
  border-bottom: 1px solid #eee;
}

table.table-striped tbody tr:nth-child(odd) { background: #f9f9f9; }

/* ── Result markers ─────────────────────────────────────────────────── */

.result-icon {
  display: inline-block;
  width: 1.4em;
  height: 1.4em;
  line-height: 1.4em;
  border-radius: 50%;
  color: #fff;
  text-align: center;
  font-weight: bold;
  font-size: 0.9em;
}

/* ── The scenario table's controls ──────────────────────────────────── */

.test-count { color: var(--title); font-weight: 600; }

.table-controls {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1em;
  margin: 0.5em 0;
  font-size: 0.85em;
  color: #555;
}

.table-controls select, .table-controls input {
  border: 1px solid #ccc;
  border-radius: 3px;
  padding: 0.25em 0.4em;
  font: inherit;
}

.table-controls input { min-width: 14em; }

th.sortable { cursor: pointer; user-select: none; white-space: nowrap; }
th.sortable::after { content: " ⇅"; color: #bbb; font-size: 0.85em; }
th.sortable.asc::after { content: " ↑"; color: #428bca; }
th.sortable.desc::after { content: " ↓"; color: #428bca; }

.table-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 0.75em;
  font-size: 0.85em;
  color: #666;
}

.pagination { display: flex; gap: 0.25em; }

.pagination button {
  background: #fff;
  border: 1px solid #ddd;
  border-radius: 3px;
  color: #428bca;
  cursor: pointer;
  font: inherit;
  min-width: 2em;
  padding: 0.25em 0.5em;
}

.pagination button.active {
  background: #333;
  border-color: #333;
  color: #fff;
  cursor: default;
}

.pagination button:disabled { color: #ccc; cursor: default; }

.empty-note { color: #777; font-size: 0.9em; }

.active-filter {
  background: #eef3f8;
  border: 1px solid #cfe0ee;
  border-radius: 4px;
  color: #38617f;
  font-size: 0.85em;
  margin: 0.5em 0;
  padding: 0.4em 0.8em;
}

.clear-filter {
  background: none;
  border: none;
  color: var(--link);
  cursor: pointer;
  font: inherit;
  text-decoration: underline;
}

.key-statistics td:nth-child(2), .key-statistics td:nth-child(4) {
  white-space: nowrap;
}

/* ── Tag cloud ──────────────────────────────────────────────────────── */

.tag-cloud { display: flex; flex-wrap: wrap; gap: 0.4em; margin-top: 0.5em; }

.tag-badge.cloud {
  background: #eef6e3;
  border-color: #cfe3b4;
  color: #4a6b28;
  font-size: 0.8em;
  padding: 0.25em 0.7em;
}

.tag-count {
  background: #fff;
  border-radius: 8px;
  color: #6b8f42;
  font-size: 0.9em;
  margin-left: 0.5em;
  padding: 0 0.4em;
}

/* A table wider than the window scrolls here, not on <body>: the banner,
   the charts and the menus stay where they are. */
.table-scroll { overflow-x: auto; }
.table-scroll > table { min-width: 44em; }

.version { color: gray; font-size: 0.85em; }
.footer { margin: 1em auto; padding: 0 1.5em; }

/* ── Narrow screens ─────────────────────────────────────────────────── */

/* Two breakpoints, and both are about the same thing: panels that sit side by
   side on a desktop have nothing to gain from sharing a phone's width, so
   they stack, and the type and padding come down with them. */
@media (max-width: 900px) {
  .topbanner {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.25em;
  }

  .projectname { text-align: left; }
  .projecttitle { font-size: 1.4em; }
  .wordmark { font-size: 1.4em; }

  .dashboard-charts { gap: 1.5em; }
  .chart-block, .chart-block.wide { flex: 1 1 100%; min-width: 0; }

  .summary-columns > .coverage-panel,
  .summary-columns > .statistics-panel {
    flex: 1 1 100%;
    min-width: 0;
  }

  .story-header-row { flex-direction: column; align-items: flex-start; }
  .tags { text-align: left; }

  .date-and-time { float: none; display: block; }

  .table-controls { flex-direction: column; align-items: stretch; }
  .table-controls input { min-width: 0; width: 100%; }

  h2 { font-size: 1.4em; }
  h3 { font-size: 1.2em; }
}

@media (max-width: 600px) {
  body { font-size: 15px; }

  .middlecontent, .topbanner, .footer { padding-left: 0.75em; }
  .middlecontent, .topbanner, .footer { padding-right: 0.75em; }

  .card { padding: 1em 0.75em; }

  .nav-tabs { flex-wrap: wrap; }

  /* The two-column statistics table folds to one pair per line — the four
     cells of a row flow into two — rather than hiding half of itself. */
  .key-statistics tr {
    display: grid;
    grid-template-columns: 1fr auto;
  }

  .key-statistics td:empty { display: none; }

  .donut { width: 180px; height: 180px; }
  .chart-legend { grid-template-columns: 1fr; }

  /* Eight duration buckets do not fit a phone. The chart scrolls inside its
     own block rather than losing its last columns off the edge. */
  .chart-block { overflow-x: auto; }
  .plot { min-width: 340px; }
  .bar-label { font-size: 0.62em; }
}

/* ── Test detail page ───────────────────────────────────────────────── */

.card.standalone { border-top: 1px solid #ddd; border-radius: 4px; }

.titlebar { margin: 1em 0 0.5em 0; }

.story-header-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 1em;
}

.story-header-title { font-weight: 300; color: var(--title); margin: 0; }

.tags { text-align: right; }

.tag-badge {
  display: inline-block;
  background: #eef3f8;
  border: 1px solid #cfe0ee;
  border-radius: 10px;
  color: #38617f;
  font-size: 0.75em;
  padding: 0.15em 0.7em;
  margin: 0.15em 0;
}

.test-title-bar {
  background: #fff;
  border: 1px solid #ddd;
  border-left-width: 5px;
  border-radius: 4px;
  padding: 0.75em 1em;
  margin-top: 0.5em;
}

.test-case-title { font-size: 1.3em; margin-left: 0.4em; }

.success-color { color: #99cc33; }
.failure-color { color: #ff1631; }
.error-color { color: #ff6108; }
.skipped-color { color: #b8860b; }
.undefined-color { color: #5332a8; }

.test-SUCCESS { border-left-color: #99cc33; }
.test-FAILURE { border-left-color: #ff1631; }
.test-ERROR { border-left-color: #ff6108; }
.test-SKIPPED { border-left-color: #b8860b; }
.test-UNDEFINED { border-left-color: #5332a8; }

.test-description { color: #777; font-style: italic; margin-top: 0.4em; }

/* ── Step table ─────────────────────────────────────────────────────── */

/* Fixed layout, so a nested table's columns land on the same grid as its
   parent's instead of being sized independently by their own contents. */
table.step-table {
  border-collapse: collapse;
  width: 100%;
  table-layout: fixed;
}

table.step-table th {
  text-align: left;
  padding: 0.5em 0.75em;
  border-bottom: 2px solid #ddd;
  color: var(--title);
  font-weight: 600;
}

table.step-table td {
  padding: 0.5em 0.75em;
  border-bottom: 1px solid #eee;
  vertical-align: top;
}

/* A group's children live in a nested table inside a spanning cell. Zeroing
   that cell's padding keeps the child columns on the parent's grid instead of
   drifting right by one cell's worth of padding at every level. */
.step-section > td { padding: 0; }

table.step-table.nested { margin: 0; }
table.step-table.nested td { border-bottom: 1px solid #f2f2f2; }

.step-table tr.test-FAILURE > td, .step-table tr.test-ERROR > td {
  background: #fff6f3;
}

.step-description-column { width: auto; }
.shot-column { width: 150px; }
.outcome-column { width: 130px; font-size: 0.85em; }
.duration-column { width: 100px; color: #666; font-size: 0.9em; }

.step-description { line-height: 1.5; }

.caret {
  background: none;
  border: none;
  color: #0e78ad;
  cursor: pointer;
  font-size: 1em;
  padding: 0;
  margin-right: 0.2em;
}

.caret.open { transform: rotate(90deg); display: inline-block; }

.screenshot {
  border: 1px solid #ddd;
  border-radius: 2px;
  object-fit: cover;
  background: #fff;
}

.evidence, .stacktrace { margin-top: 0.5em; }
.evidence summary, .stacktrace summary {
  color: #428bca;
  cursor: pointer;
  font-size: 0.85em;
}

.evidence pre, .stacktrace pre, .error-message pre {
  background: #f7f7f5;
  border: 1px solid #eee;
  border-radius: 3px;
  padding: 0.75em;
  margin-top: 0.4em;
  overflow-x: auto;
  font-size: 0.8em;
  line-height: 1.5;
  white-space: pre-wrap;
}

/* Width and style only: the colour comes from the `test-<RESULT>` class the
   block also carries, and a `border-left` shorthand here would reset it. */
.failure-block {
  margin-top: 1.5em;
  border-left-width: 5px;
  border-left-style: solid;
  padding-left: 1em;
}

/* ── Screenshots gallery ────────────────────────────────────────────── */

.screenshot-failure {
  background: #fff;
  border: 1px solid #ddd;
  border-left-width: 5px;
  border-radius: 4px;
  margin: 0.75em 0;
  padding: 0.75em 1em;
}

.screenshot-failure pre {
  font-size: 0.85em;
  white-space: pre-wrap;
  color: #555;
}

.gallery-link { margin-bottom: 0.75em; font-size: 0.9em; }

/* ── Requirements ───────────────────────────────────────────────────── */

.requirements-table .requirement-name-column { width: 45%; }
.requirements-table .requirement-type {
  color: #888;
  font-size: 0.8em;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.requirement-row.level-0 > td { font-weight: 600; }
.requirement-row.level-1 > td { font-weight: 400; }

.coverage-column { width: 200px; }

.progress {
  display: flex;
  height: 14px;
  background: #ececec;
  border-radius: 7px;
  overflow: hidden;
}

.progress-bar { height: 100%; }

.feature-coverage { margin-bottom: 1em; }

.requirement-narrative {
  color: #666;
  font-style: italic;
  margin-bottom: 0.75em;
}

.scenario-narrative { color: #888; font-size: 0.85em; }

.carousel { max-width: 800px; margin: 0 auto; }

.slides {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 320px;
  background: #fbfbfa;
  border: 1px solid #eee;
  border-radius: 4px;
}

.slide { text-align: center; padding: 1em; width: 100%; }
.slide[hidden] { display: none; }

.slide img {
  max-width: 100%;
  max-height: 60vh;
  border: 1px solid #ddd;
  background: #fff;
}

.slide figcaption {
  margin-top: 0.75em;
  color: #555;
  font-size: 0.9em;
}

.carousel-controls {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1em;
  margin-top: 1em;
}

.carousel-prev, .carousel-next {
  background: #fff;
  border: 1px solid #ddd;
  border-radius: 50%;
  color: #428bca;
  cursor: pointer;
  font-size: 1.4em;
  line-height: 1;
  width: 2em;
  height: 2em;
}

.carousel-prev:hover, .carousel-next:hover { background: #f0f6fb; }
.carousel-prev:disabled, .carousel-next:disabled {
  color: #ccc;
  cursor: default;
  background: #fff;
}

.bullets { display: flex; flex-wrap: wrap; gap: 0.35em; }

.bullet {
  background: lightgrey;
  border: none;
  border-radius: 50%;
  color: #000;
  cursor: pointer;
  font-size: 0.75em;
  width: 20px;
  height: 20px;
  line-height: 20px;
  padding: 0;
  text-align: center;
}

.bullet.active { background: #428bca; color: #fff; }
''';

/// The site's only script: the dashboard's tab switch and the detail page's
/// step-group carets, both written here. Nothing else on any page runs code.
const String siteJs = '''
document.querySelectorAll("[data-tab]").forEach(function (tab) {
  tab.addEventListener("click", function (event) {
    event.preventDefault();
    document.querySelectorAll("[data-tab]").forEach(function (t) {
      t.parentElement.classList.toggle("active", t === tab);
    });
    document.querySelectorAll(".tab-pane").forEach(function (pane) {
      pane.classList.toggle("active", pane.id === tab.dataset.tab);
    });
  });
});

document.querySelectorAll(".caret").forEach(function (caret) {
  caret.addEventListener("click", function () {
    var section = document.getElementById(caret.dataset.toggle);
    if (!section) { return; }
    section.hidden = !section.hidden;
    caret.classList.toggle("open", !section.hidden);
  });
});

// The scenario table's filter, sort and pagination. The reference gets these
// from a table plugin; this is the same three behaviours over the rows the
// page already carries, so the table works with the file opened straight off
// disk and the page still ships no libraries.
document.querySelectorAll(".data-table").forEach(function (wrapper) {
  var table = wrapper.querySelector("table");
  var body = table.querySelector("tbody");
  var headers = table.querySelectorAll("th.sortable");
  var filter = wrapper.querySelector(".table-filter");
  var pageSize = wrapper.querySelector(".page-size");
  var info = wrapper.querySelector(".table-info");
  var pagination = wrapper.querySelector(".pagination");
  var chip = wrapper.querySelector(".active-filter");
  var all = Array.prototype.slice.call(body.querySelectorAll("tr"));
  var page = 1;
  var sortIndex = -1;
  var ascending = true;
  var resultFilter = "";

  function keyOf(row, index) {
    var cell = row.children[index];
    var order = cell.getAttribute("data-order");
    return order === null ? cell.textContent.trim().toLowerCase() : +order;
  }

  function render() {
    var needle = (filter && filter.value || "").trim().toLowerCase();
    var rows = all.filter(function (row) {
      if (resultFilter && row.dataset.result !== resultFilter) { return false; }
      return !needle || row.textContent.toLowerCase().indexOf(needle) >= 0;
    });

    if (sortIndex >= 0) {
      rows = rows.slice().sort(function (a, b) {
        var left = keyOf(a, sortIndex);
        var right = keyOf(b, sortIndex);
        var order = left < right ? -1 : left > right ? 1 : 0;
        return ascending ? order : -order;
      });
    }

    var size = pageSize ? +pageSize.value : 10;
    var pages = size === 0 ? 1 : Math.max(1, Math.ceil(rows.length / size));
    if (page > pages) { page = pages; }
    var from = size === 0 ? 0 : (page - 1) * size;
    var to = size === 0 ? rows.length : Math.min(from + size, rows.length);

    body.textContent = "";
    rows.slice(from, to).forEach(function (row) { body.appendChild(row); });

    if (info) {
      info.textContent = rows.length === 0
        ? "No matching entries"
        : "Showing " + (from + 1) + " to " + to + " of " + rows.length +
          " entries";
    }

    if (pagination) {
      pagination.textContent = "";
      if (pages > 1) {
        for (var p = 1; p <= pages; p += 1) {
          var button = document.createElement("button");
          button.textContent = p;
          if (p === page) { button.className = "active"; }
          button.addEventListener("click", (function (target) {
            return function () { page = target; render(); };
          })(p));
          pagination.appendChild(button);
        }
      }
    }
  }

  headers.forEach(function (header, index) {
    header.addEventListener("click", function () {
      // Clicking the sorted column again reverses it; clicking another one
      // starts that column ascending.
      ascending = sortIndex === index ? !ascending : true;
      sortIndex = index;
      headers.forEach(function (other) {
        other.classList.remove("asc", "desc");
      });
      header.classList.add(ascending ? "asc" : "desc");
      page = 1;
      render();
    });
  });

  if (filter) {
    filter.addEventListener("input", function () { page = 1; render(); });
  }
  if (pageSize) {
    pageSize.addEventListener("change", function () { page = 1; render(); });
  }

  // How a chart hands its selection to the table: the chart knows the verdict
  // it was clicked on, the table knows how to show only those rows, and this
  // is the seam between them.
  wrapper.showOnlyResult = function (result, label) {
    resultFilter = result || "";
    page = 1;
    if (chip) {
      chip.hidden = !resultFilter;
      chip.textContent = "";
      if (resultFilter) {
        chip.appendChild(
          document.createTextNode("Showing only " + label + " ")
        );
        var clear = document.createElement("button");
        clear.className = "clear-filter";
        clear.textContent = "Show all";
        clear.addEventListener("click", function () {
          wrapper.showOnlyResult("", "");
        });
        chip.appendChild(clear);
      }
    }
    render();
  };

  render();
});

// Clicking a segment, a bar or a legend entry opens the Test Results tab
// showing only the tests behind it. A chart that cannot be asked "which ones
// were those?" is a picture; this makes it a way in.
document.querySelectorAll("[data-result]").forEach(function (target) {
  if (target.tagName !== "A") { return; }
  target.addEventListener("click", function (event) {
    event.preventDefault();
    var result = target.dataset.result;
    var label = (target.getAttribute("title") || result).split(":")[0];

    var tab = document.querySelector('[data-tab="tests"]');
    if (tab) { tab.click(); }

    document.querySelectorAll(".data-table").forEach(function (wrapper) {
      if (wrapper.showOnlyResult) { wrapper.showOnlyResult(result, label); }
    });

    var pane = document.getElementById("tests");
    if (pane && pane.scrollIntoView) {
      pane.scrollIntoView({block: "start"});
    }
  });
});

document.querySelectorAll(".carousel").forEach(function (carousel) {
  var slides = carousel.querySelectorAll(".slide");
  var bullets = carousel.querySelectorAll(".bullet");
  var previous = carousel.querySelector(".carousel-prev");
  var next = carousel.querySelector(".carousel-next");
  if (!slides.length) { return; }

  var current = 0;

  function show(index) {
    current = Math.max(0, Math.min(index, slides.length - 1));
    slides.forEach(function (slide, i) { slide.hidden = i !== current; });
    bullets.forEach(function (bullet, i) {
      bullet.classList.toggle("active", i === current);
    });
    if (previous) { previous.disabled = current === 0; }
    if (next) { next.disabled = current === slides.length - 1; }
  }

  bullets.forEach(function (bullet) {
    bullet.addEventListener("click", function () {
      show(parseInt(bullet.dataset.goto, 10) || 0);
    });
  });
  if (previous) {
    previous.addEventListener("click", function () { show(current - 1); });
  }
  if (next) {
    next.addEventListener("click", function () { show(current + 1); });
  }
  document.addEventListener("keydown", function (event) {
    if (event.key === "ArrowLeft") { show(current - 1); }
    if (event.key === "ArrowRight") { show(current + 1); }
  });

  // A thumbnail links straight to its own capture: ?screenshot=N opens the
  // gallery on that slide rather than on the first.
  var requested = new URLSearchParams(window.location.search).get("screenshot");
  show(parseInt(requested, 10) || 0);
});
''';
