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

/// The stylesheet, written to `sqa-reporter.css` beside `index.html`.
const String siteCss = '''
/* SQA Reporter — all rules authored for this generator. */

* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  font-size: 16px;
  font-family: "Helvetica Neue", Calibri, Helvetica, Arial, sans-serif;
  background-color: #f7f8f3;
  color: #333;
}

a { text-decoration: none; color: #428bca; }
a:hover { text-decoration: underline; }

/* ── Banner ─────────────────────────────────────────────────────────── */

.topheader { background: #fff; }

.topbanner {
  max-width: 1200px;
  min-width: 1024px;
  margin: 0 auto;
  padding: 1em;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.wordmark { font-size: 1.75em; font-weight: 300; color: #333; }
.wordmark .accent { color: #428bca; font-weight: 400; }

.projectname { text-align: right; }
.projecttitle { font-weight: normal; font-size: 2em; color: #428bca; }
.projectsubtitle {
  font-weight: normal; font-style: italic; font-size: 1.25em;
  color: #428bca; display: block;
}

/* ── Content frame ──────────────────────────────────────────────────── */

.middlecontent {
  max-width: 1200px;
  min-width: 1024px;
  margin: 0 auto;
  padding: 0 1em 2em 1em;
}

.breadcrumbs { color: #777; padding: 0.5em 0; display: block; }

h2 { font-weight: 300; font-size: 1.75em; margin: 0.5em 0; }
h3 { font-weight: 300; font-size: 1.4em; margin: 1em 0 0.5em 0; }
h4 { font-weight: 400; font-size: 1.1em; margin: 0.75em 0 0.5em 0; }

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
  color: #428bca;
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
  gap: 3em;
  align-items: flex-start;
  flex-wrap: wrap;
}

.chart-block { min-width: 280px; }

.donut {
  width: 200px;
  height: 200px;
  border-radius: 50%;
  margin: 1em auto;
  position: relative;
}

.donut::before {
  content: "";
  position: absolute;
  inset: 25%;
  border-radius: 50%;
  background: #fff;
}

.donut .donut-label {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5em;
  color: #444;
  z-index: 1;
}

.chart-legend { list-style: none; font-size: 0.85em; color: #555; }
.chart-legend li { display: inline-block; margin-right: 1em; }
.chart-legend .swatch {
  display: inline-block;
  width: 0.9em;
  height: 0.9em;
  border: 1px solid;
  margin-right: 0.35em;
  vertical-align: -0.1em;
}

.bars {
  display: flex;
  align-items: flex-end;
  gap: 1.25em;
  height: 200px;
  margin: 1em 0;
  padding: 0 0.5em;
  border-bottom: 1px solid #ddd;
}

.bars .bar { width: 3em; text-align: center; }
.bars .bar .fill { border: 1px solid; }
.bars .bar .count { font-size: 0.9em; color: #444; }
.bars .bar .result-label { font-size: 0.75em; color: #777; }

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

.version { color: gray; font-size: 0.85em; }
.footer { max-width: 1200px; min-width: 1024px; margin: 1em auto; padding: 0 1em; }
''';

/// The only script on the page: the Summary / Test Results tab switch,
/// written for this page.
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
''';
