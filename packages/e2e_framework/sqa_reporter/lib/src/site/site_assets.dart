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
/// These are the report's own colours, not the reference's. The first cut
/// reused the reference's values on the theory that a familiar palette reads
/// faster; in practice that palette is a bright acid green against a pure
/// red and an orange, which
/// clash beside each other and — worse — fail contrast as text: the green
/// spelling out SUCCESS on white sat near 1.9:1, well under the 4.5:1 a
/// reader with low vision needs.
///
/// So: the same five meanings, in tones chosen to sit together, to hold
/// contrast as text on white, and to be recognisably this report's rather
/// than an imitation of the one whose layout it learned from. Skipped moves
/// from mustard to a neutral slate, because "not run" is an absence, not a
/// warning.
///
/// `solid` is the tone used where colour carries meaning at full strength (a
/// verdict icon, a coverage bar) and is the one that must hold contrast;
/// `fill` and `border` are the softened pair the charts paint with.
const Map<String, ({String fill, String border, String solid})> resultColors =
    <String, ({String fill, String border, String solid})>{
      'SUCCESS': (
        fill: 'rgba(46,158,91,0.85)',
        border: 'rgba(46,158,91,1)',
        solid: '#2e9e5b',
      ),
      'FAILURE': (
        fill: 'rgba(217,45,63,0.85)',
        border: 'rgba(217,45,63,1)',
        solid: '#d92d3f',
      ),
      'ERROR': (
        fill: 'rgba(224,122,31,0.85)',
        border: 'rgba(224,122,31,1)',
        solid: '#e07a1f',
      ),
      'SKIPPED': (
        fill: 'rgba(148,163,184,0.85)',
        border: 'rgba(148,163,184,1)',
        solid: '#94a3b8',
      ),
      'UNDEFINED': (
        fill: 'rgba(124,92,214,0.85)',
        border: 'rgba(124,92,214,1)',
        solid: '#7c5cd6',
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
  <path d="M11.5 16.5l3 3 6-6.5" fill="none" stroke="#2e9e5b"
        stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>
  <rect x="11.5" y="22" width="9" height="1.8" rx="0.9" fill="#d7dde6"/>
</svg>
''';

/// The mark beside the wordmark in the banner, inline in every page.
///
/// The same idea as the favicon, drawn for the size it is read at: a navy
/// tile, a clipboard, a green tick and a line of what was checked. A report
/// of a test run is a checklist someone signed off, so that is the figure —
/// and repeating the favicon's shapes means the tab icon and the banner read
/// as one mark rather than two.
///
/// Inline rather than a second file: the banner is on every page, and an
/// `<img>` would be one more request the offline report cannot count on. It
/// is decorative — the wordmark beside it already carries the name — so it is
/// hidden from screen readers.
const String wordmarkMark = '''
<svg class="wordmark-mark" viewBox="0 0 40 40" width="34" height="34" aria-hidden="true" focusable="false">
<rect width="40" height="40" rx="10" fill="#0A1B3A"/>
<rect x="9" y="7" width="22" height="27" rx="3.5" fill="#ffffff"/>
<rect x="15" y="3.5" width="10" height="5.5" rx="2.2" fill="#0A1B3A"/>
<path d="M14 19.6l3.9 3.9L26.4 15" fill="none" stroke="#2e9e5b" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"/>
<rect x="13.5" y="27" width="13" height="2.2" rx="1.1" fill="#d7dde6"/>
</svg>''';

/// The screenshot viewer's markup, on every page that shows a capture.
///
/// One per page rather than one per picture: it shows whichever was clicked,
/// and a dialog that can be closed needs exactly one close button. The pages
/// that carry no screenshot do not carry this either — see how `siteJs` does
/// nothing when it is absent.
const String shotViewer = '''
<div class="lightbox" role="dialog" aria-modal="true" aria-label="Screenshot" hidden>
  <button class="lightbox-close" title="Close (Esc)" aria-label="Close">×</button>
  <img class="lightbox-image" src="" alt=""/>
  <p class="lightbox-caption"></p>
</div>
''';

/// The stylesheet, written to `sqa-reporter.css` beside `index.html`.
const String siteCss = '''
/* SQA Reporter — all rules authored for this generator. */

/* Every colour in the report comes from here. Two families and nothing else:
   the neutrals that build the page, and the five verdict tones (mirrored from
   `resultColors`, which is where the meaning lives). A rule that needs a
   colour takes a token; a rule that invents one is a bug. */
:root {
  /* The colour titles and subtitles are set in. Links keep their own blue:
     the two must stay distinguishable, and this blue clears 4.5:1 on white
     where the lighter one it replaced did not. */
  --title: #0B2545;
  --link: #1d63c4;
  /* The navy read back at a lower weight, for the second half of the
     wordmark and anything else that must sit beside the title without
     competing with it. */
  --title-soft: #5b6b85;

  /* Neutrals: a cool page, white cards, two weights of rule, and one muted
     ink for labels that are there to be scanned past. */
  --page: #f4f6fa;
  --card: #ffffff;
  --ink: #1f2937;
  --muted: #64748b;
  --rule: #e4e8ef;
  --rule-soft: #eef1f6;
  --hover: #f7f9fc;

  /* The verdicts, at full strength. */
  --pass: #2e9e5b;
  --fail: #d92d3f;
  --broken: #e07a1f;
  --skip: #94a3b8;
  --undefined: #7c5cd6;

  /* Not a verdict: the one blue the quantity charts are painted in, so a
     bar about duration is never mistaken for a bar about outcomes. */
  --data: #4f7fe0;
  --data-soft: #dfe8fb;
}

* { margin: 0; padding: 0; box-sizing: border-box; }

/* The system's own interface face, whichever system that is. A webfont would
   be a network request the offline report cannot make, and the old stack
   ("Helvetica Neue", Calibri) resolved to something different — and older —
   on every one of the three platforms this report is read on. */
body {
  font-size: 16px;
  font-family: system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue",
    Arial, sans-serif;
  background-color: var(--page);
  color: var(--ink);
  -webkit-font-smoothing: antialiased;
}

/* Every figure in the report is a count, a duration or a clock time, and all
   three are read down a column. Proportional digits make that column ragged. */
table, .kpi-value, .date-and-time { font-variant-numeric: tabular-nums; }

a { text-decoration: none; color: var(--link); }
a:hover { text-decoration: underline; }

/* ── Banner ─────────────────────────────────────────────────────────── */

/* White, closed off from the page by a hairline and nothing else. A band of
   colour across the full width was tried and dropped: everything else on the
   page is inset and quiet, so a full-bleed rule read as a stripe laid over
   the report rather than part of it. The one accent left in the banner is
   under the report's own name, where it marks something. */
.topheader {
  background-color: #fff;
  border-bottom: 1px solid var(--rule);
}

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

/* Mark and name on one baseline: the tile carries the colour, the name
   carries the weight. `SQA` is the part people say, so it is the part set
   solid; `Reporter` follows it lighter and spaced, which is what keeps a
   two-word wordmark from reading as two words. */
.wordmark {
  display: inline-flex;
  align-items: center;
  gap: 0.55rem;
  text-decoration: none;
  line-height: 1;
}

.wordmark:hover { text-decoration: none; }
.wordmark:hover .wordmark-name { color: var(--title); }
.wordmark-mark { display: block; flex: none; }

.wordmark-text { font-size: 1.55rem; letter-spacing: 0.02em; }
.wordmark-sqa { font-weight: 700; color: var(--title); letter-spacing: 0.04em; }
.wordmark-name {
  font-weight: 300;
  color: var(--title-soft);
  margin-left: 0.28em;
  transition: color 0.15s ease;
}

/* The right half answers "which report is this?" — one line, set in the
   title navy at a weight that holds its own against the wordmark without
   shouting over it, and with a hairline under it so the two halves of the
   banner look deliberate rather than merely opposite. */
.projectname { text-align: right; }
.projecttitle {
  display: inline-block;
  font-size: 1.35rem;
  font-weight: 600;
  letter-spacing: 0.01em;
  color: var(--title);
  padding-bottom: 0.25em;
  border-bottom: 2px solid var(--pass);
}

/* ── Content frame ──────────────────────────────────────────────────── */

.middlecontent {
  margin: 0 auto;
  padding: 0 2rem 3rem 2rem;
}

.breadcrumbs {
  color: var(--muted);
  font-size: 0.85rem;
  padding: 0.85em 0 0 0;
  display: block;
}

/* Three levels and each does one job: h2 names the page, h3 names a block
   inside it, h4 labels a panel. The labels are set as small caps rather than
   as small headings, so a panel title never competes with the page's own. */
h2 {
  font-weight: 600;
  font-size: 1.55rem;
  letter-spacing: -0.015em;
  margin: 0.35em 0 0.15em 0;
  color: var(--title);
}
h3 {
  font-weight: 600;
  font-size: 1.05rem;
  margin: 1.25em 0 0.6em 0;
  color: var(--title);
}
h4 {
  font-weight: 700;
  font-size: 0.75rem;
  letter-spacing: 0.09em;
  text-transform: uppercase;
  margin: 0 0 1em 0;
  color: var(--muted);
}

.test-count-title { font-size: 0.95rem; color: var(--muted); margin-bottom: 1em; }

/* Said plainly rather than in alarm colours: an older run is a fact about
   this report, not a fault in it. */
.run-age {
  background: #fdf8e8;
  border: 1px solid #eee0b0;
  border-radius: 8px;
  color: #7a6420;
  font-size: 0.85rem;
  margin: 0.75em 0;
  padding: 0.5em 0.9em;
}

/* ── Key figures ────────────────────────────────────────────────────── */

/* The four numbers someone opens the report to find, above everything that
   explains them. Until this strip existed the pass rate had to be read off
   the doughnut and the duration dug out of a statistics table halfway down
   the page. */
.kpi-row {
  display: flex;
  gap: 0.9rem;
  flex-wrap: wrap;
  margin: 0.25rem 0 1.25rem 0;
}

.kpi {
  flex: 1 1 0;
  min-width: 160px;
  background: var(--card);
  border: 1px solid var(--rule);
  border-radius: 12px;
  padding: 0.9rem 1.1rem;
  box-shadow: 0 1px 2px rgba(16, 24, 40, 0.04);
}

.kpi-label {
  display: block;
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.09em;
  text-transform: uppercase;
  color: var(--muted);
  margin-bottom: 0.35rem;
}

.kpi-value {
  display: block;
  font-size: 1.75rem;
  font-weight: 650;
  line-height: 1.1;
  color: var(--title);
}

.kpi-note { font-size: 0.8rem; color: var(--muted); }

/* Colour only where the number is a verdict on the run: a pass rate is good
   news, anything needing attention is not, and a count of scenarios is
   neither. */
.kpi.good .kpi-value { color: var(--pass); }
.kpi.bad .kpi-value { color: var(--fail); }

/* ── Menu and tabs ──────────────────────────────────────────────────── */

.nav-tabs {
  list-style: none;
  display: flex;
  gap: 0.35em;
  border-bottom: 1px solid var(--rule);
  margin-top: 0.5em;
}

.nav-tabs li a, .nav-tabs li span {
  display: inline-block;
  padding: 0.55em 1.1em;
  border: 1px solid transparent;
  border-radius: 8px 8px 0 0;
  font-size: 0.95rem;
  font-weight: 500;
  color: var(--link);
}

.nav-tabs li.active a, .nav-tabs li.active span {
  color: var(--title);
  font-weight: 600;
  background-color: var(--card);
  border-color: var(--rule);
  border-bottom-color: var(--card);
  cursor: default;
}

.nav-tabs li.disabled span { color: #aaa; cursor: default; }

.date-and-time {
  float: right;
  color: var(--muted);
  font-size: 0.85rem;
  padding: 0.75em 0;
}

/* ── Card with tab panes ────────────────────────────────────────────── */

/* One surface, lifted off the page by a hairline and a shadow soft enough to
   read as depth rather than as a drop shadow. The card under the tabs keeps
   its square top corners, so the active tab still looks joined to it. */
.card {
  background: var(--card);
  border: 1px solid var(--rule);
  border-top: none;
  border-radius: 0 0 12px 12px;
  padding: 1.4rem 1.5rem;
  box-shadow: 0 1px 2px rgba(16, 24, 40, 0.04),
              0 8px 20px rgba(16, 24, 40, 0.04);
}

.card.standalone {
  border-top: 1px solid var(--rule);
  border-radius: 12px;
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
  font-size: 0.78rem;
  color: var(--muted);
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

/* The centred percentage covers the whole box in order to centre itself, so
   only the hole itself takes the pointer — the rest of the box must let the
   click through to the segment underneath, or the label swallows every one
   of them. `inset: 26%` is the hole, matching `.donut::before`. */
.donut .donut-label {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2em;
  color: #444;
  z-index: 2;
  pointer-events: none;
}

.donut a.donut-label { text-decoration: none; }
.donut a.donut-label::after {
  content: "";
  position: absolute;
  inset: 26%;
  border-radius: 50%;
  pointer-events: auto;
  cursor: pointer;
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
  z-index: 2;
  pointer-events: none;
}

.chart-legend {
  list-style: none;
  font-size: 0.88rem;
  color: var(--ink);
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0.25em 1em;
}

.chart-legend li.empty { color: #a3aec0; }

.chart-legend .swatch {
  display: inline-block;
  width: 0.85em;
  height: 0.85em;
  border: 1px solid;
  border-radius: 4px;
  margin-right: 0.45em;
  vertical-align: -0.05em;
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
  font-size: 0.75rem;
  color: var(--muted);
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

.gridlines .gridline { border-top: 1px solid var(--rule-soft); }

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

/* A bar is a solid block with a rounded head, not an outlined box: the
   outline was carrying a second colour at every bar for no information. */
.bar-fill {
  width: 60%;
  min-height: 2px;
  border: 0;
  border-radius: 6px 6px 0 0;
  display: flex;
  align-items: flex-start;
  justify-content: center;
}

/* How long tests took is a quantity, not a verdict, so it is painted in the
   data blue and never in a result colour. */
.bar-fill.duration-fill { background: var(--data-soft); border-bottom: 3px solid var(--data); }

.bar-value {
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--title);
  margin-top: -1.4em;
}

.bar-label {
  position: absolute;
  top: 100%;
  padding-top: 0.35em;
  font-size: 0.72rem;
  color: var(--muted);
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

table.table {
  border-collapse: collapse;
  width: 100%;
  margin: 0.5em 0;
  font-size: 0.92rem;
}

/* Column names are labels, not headings: small caps in the muted ink, so the
   eye lands on the data under them. */
table.table th {
  text-align: left;
  padding: 0.6em 0.75em;
  border-bottom: 1px solid var(--rule);
  font-size: 0.72rem;
  font-weight: 600;
  letter-spacing: 0.07em;
  text-transform: uppercase;
  color: var(--muted);
}

table.table td {
  padding: 0.62em 0.75em;
  border-bottom: 1px solid var(--rule-soft);
}

/* No zebra striping. Fifty rows of alternating grey is a pattern the reader
   has to see past; one hairline per row and a tint under the pointer says
   the same thing quietly, and says where the pointer is besides. */
table.table tbody tr:hover { background: var(--hover); }

.key-statistics td:nth-child(2n) { color: var(--title); font-weight: 600; }

/* ── Feature search ─────────────────────────────────────────────────── */

.feature-search {
  display: flex;
  align-items: baseline;
  gap: 0.75rem;
  margin-bottom: 0.75rem;
}

.feature-search input {
  background: var(--card);
  border: 1px solid var(--rule);
  border-radius: 8px;
  padding: 0.4em 0.7em;
  font: inherit;
  font-size: 0.9rem;
  color: var(--ink);
  min-width: 16em;
}

.feature-search input:focus { outline: 2px solid var(--data); outline-offset: 1px; }
.filter-count { color: var(--muted); font-size: 0.85rem; }

/* The caret that folds an epic in the coverage panel. Same control as the
   step tree's, so a reader learns it once. */
.requirement-row .caret {
  color: var(--muted);
  font-size: 0.85em;
  transform: rotate(0deg);
  transition: transform 0.12s ease;
}

.requirement-row .caret.open { transform: rotate(90deg); }

/* ── Severity ───────────────────────────────────────────────────────── */

/* Not a verdict, so it borrows none of the verdict colours: what a failure
   *would* cost is a different question from what happened, and painting it
   red would have the table shouting about a scenario that passed. Weight
   carries it instead — the two levels somebody acts on are set solid in the
   title navy, the rest recede. */
.severity {
  font-size: 0.72rem;
  font-weight: 500;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--muted);
}

.severity.blocker, .severity.critical { color: var(--title); font-weight: 700; }
.severity.none { letter-spacing: 0; }

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
  font-size: 0.85em;
  box-shadow: 0 1px 2px rgba(16, 24, 40, 0.12);
}

/* ── The scenario table's controls ──────────────────────────────────── */

.test-count { color: var(--muted); font-weight: 500; }

.table-controls {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1em;
  margin: 0.5em 0 0.75em 0;
  font-size: 0.85rem;
  color: var(--muted);
}

.table-controls select, .table-controls input {
  background: var(--card);
  border: 1px solid var(--rule);
  border-radius: 8px;
  padding: 0.4em 0.6em;
  font: inherit;
  font-size: 0.9rem;
  color: var(--ink);
}

.table-controls select:focus, .table-controls input:focus {
  outline: 2px solid var(--data);
  outline-offset: 1px;
}

.table-controls input { min-width: 14em; }

th.sortable { cursor: pointer; user-select: none; white-space: nowrap; }
th.sortable::after { content: " ⇅"; color: #b6c0cf; font-size: 0.85em; }
th.sortable.asc::after { content: " ↑"; color: var(--link); }
th.sortable.desc::after { content: " ↓"; color: var(--link); }

.table-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 0.9em;
  font-size: 0.85rem;
  color: var(--muted);
}

.pagination { display: flex; gap: 0.25em; }

.pagination button {
  background: var(--card);
  border: 1px solid var(--rule);
  border-radius: 8px;
  color: var(--link);
  cursor: pointer;
  font: inherit;
  font-size: 0.85rem;
  min-width: 2.1em;
  padding: 0.3em 0.6em;
}

.pagination button:hover:not(:disabled):not(.active) { background: var(--hover); }

.pagination button.active {
  background: var(--title);
  border-color: var(--title);
  color: #fff;
  cursor: default;
}

.pagination button:disabled { color: #c3cbd8; cursor: default; }

.empty-note { color: var(--muted); font-size: 0.9rem; }

.active-filter {
  background: #eef3fb;
  border: 1px solid #d3e0f2;
  border-radius: 8px;
  color: #2c5480;
  font-size: 0.85rem;
  margin: 0.5em 0;
  padding: 0.45em 0.85em;
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

/* Tags are neutral by design: a tag is a label someone put on a test, not a
   verdict about it, so it borrows none of the verdict colours. */
.tag-badge.cloud {
  background: #eef2f8;
  border-color: #dbe3ef;
  color: #33507a;
  font-size: 0.8rem;
  padding: 0.28em 0.75em;
}

.tag-count {
  background: var(--card);
  border-radius: 999px;
  color: var(--muted);
  font-size: 0.9em;
  margin-left: 0.5em;
  padding: 0 0.45em;
}

/* A table wider than the window scrolls here, not on <body>: the banner,
   the charts and the menus stay where they are. */
.table-scroll { overflow-x: auto; }
.table-scroll > table { min-width: 44em; }

.version { color: var(--muted); font-size: 0.85rem; }
.footer { margin: 1.5em auto; padding: 0 2rem; }

/* ── Narrow screens ─────────────────────────────────────────────────── */

/* Two breakpoints, and both are about the same thing: panels that sit side by
   side on a desktop have nothing to gain from sharing a phone's width, so
   they stack, and the type and padding come down with them. */
@media (max-width: 900px) {
  .topbanner {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.6em;
  }

  .projectname { text-align: left; }
  .projecttitle { font-size: 1.15rem; }
  .wordmark-text { font-size: 1.35rem; }

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

  .middlecontent, .topbanner, .footer { padding-left: 1rem; }
  .middlecontent, .topbanner, .footer { padding-right: 1rem; }

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

.titlebar { margin: 1em 0 0.5em 0; }

.story-header-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 1em;
}

.story-header-title {
  font-weight: 600;
  font-size: 1.25rem;
  letter-spacing: -0.01em;
  color: var(--title);
  margin: 0;
}

.tags { text-align: right; }

.tag-badge {
  display: inline-block;
  background: #eef2f8;
  border: 1px solid #dbe3ef;
  border-radius: 999px;
  color: #33507a;
  font-size: 0.75rem;
  padding: 0.25em 0.75em;
  margin: 0.15em 0;
}

/* The verdict is said three ways at once — the icon, the word, and the tint
   this bar carries — because colour alone is not something every reader
   gets. The tint is the verdict at a tenth of its strength: enough to say
   "this one passed" from across the room, light enough to read text on. */
.test-title-bar {
  background: var(--card);
  border: 1px solid var(--rule);
  border-left-width: 4px;
  border-radius: 0 12px 12px 0;
  padding: 0.85em 1.1em;
  margin-top: 0.5em;
}

.test-case-title {
  font-size: 1.15rem;
  font-weight: 600;
  color: var(--title);
  margin-left: 0.4em;
}

/* The verdict spelled out. These are the `solid` tones, which is what makes
   the word readable: the colours they replaced sat under 2:1 on white. */
.success-color { color: var(--pass); }
.failure-color { color: var(--fail); }
.error-color { color: var(--broken); }
.skipped-color { color: #6b7a8d; }
.undefined-color { color: var(--undefined); }

.test-title-bar.test-SUCCESS { border-left-color: var(--pass); background: #eef8f2; }
.test-title-bar.test-FAILURE { border-left-color: var(--fail); background: #fdeff1; }
.test-title-bar.test-ERROR { border-left-color: var(--broken); background: #fdf5eb; }
.test-title-bar.test-SKIPPED { border-left-color: var(--skip); background: #f2f5f8; }
.test-title-bar.test-UNDEFINED { border-left-color: var(--undefined); background: #f4f1fc; }

/* A scenario row wearing its verdict, in the tone its slice has on the chart
   — the same five colours and the same five tints the test pages already use,
   so the doughnut, the row and the page a reader lands on all agree.

   A stripe down the left edge and a wash behind the row: the stripe is what
   the eye catches scanning a long table, the wash is what keeps it caught
   once the row is read. Both are the verdict's own hue, so no legend is
   needed to know which is which.

   Passing rows get NEITHER, deliberately. They are the majority and the
   baseline, and tinting them green would drown the four rows somebody opened
   the report to find — a table where everything is coloured says as little as
   one where nothing is. Green stays on the icon, where it confirms; the
   background is reserved for what needs attention. */
.table tr[data-result] > td { border-left: 0 solid transparent; }

.table tr[data-result="FAILURE"] > td:first-child,
.table tr[data-result="ERROR"] > td:first-child,
.table tr[data-result="SKIPPED"] > td:first-child,
.table tr[data-result="UNDEFINED"] > td:first-child { border-left-width: 3px; }

.table tr[data-result="FAILURE"] > td {
  background: #fdeff1;
  border-left-color: var(--fail);
}

.table tr[data-result="ERROR"] > td {
  background: #fdf5eb;
  border-left-color: var(--broken);
}

.table tr[data-result="SKIPPED"] > td {
  background: #f2f5f8;
  border-left-color: var(--skip);
}

.table tr[data-result="UNDEFINED"] > td {
  background: #f4f1fc;
  border-left-color: var(--undefined);
}

/* Hover still has to read as hover on a row that is already tinted, so it
   deepens the row's own colour rather than replacing it with the neutral
   one. */
.table tr[data-result="FAILURE"]:hover > td { background: #fbe2e6; }
.table tr[data-result="ERROR"]:hover > td { background: #fbecd9; }
.table tr[data-result="SKIPPED"]:hover > td { background: #e8edf3; }
.table tr[data-result="UNDEFINED"]:hover > td { background: #ebe5f9; }

.test-description { color: var(--muted); font-style: italic; margin-top: 0.4em; }

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
  padding: 0.55em 0.75em;
  border-bottom: 1px solid var(--rule);
  font-size: 0.72rem;
  font-weight: 600;
  letter-spacing: 0.07em;
  text-transform: uppercase;
  color: var(--muted);
}

table.step-table td {
  padding: 0.4em 0.75em;
  border-bottom: 1px solid var(--rule-soft);
  vertical-align: middle;
}

/* A group's children live in a nested table inside a spanning cell. The left
   rule is the hierarchy made visible: it runs the height of everything that
   belongs to the step above it. */
.step-section > td { padding: 0 0 0 1.6em; }
.step-section > td > table { border-left: 2px solid var(--rule); }

table.step-table.nested { margin: 0; }
table.step-table.nested td { border-bottom: 1px solid var(--rule-soft); }

.step-table tr.test-FAILURE > td { background: #fdeff1; }
.step-table tr.test-ERROR > td { background: #fdf5eb; }

.step-description-column { width: auto; }
.shot-column { width: 150px; }
.outcome-column {
  width: 130px;
  font-size: 0.72rem;
  font-weight: 600;
  letter-spacing: 0.04em;
}
.duration-column { width: 100px; color: var(--muted); font-size: 0.85rem; }

.step-description {
  line-height: 1.5;
  display: flex;
  align-items: baseline;
  gap: 0.4em;
}

/* Depth reads as weight: a business step is plain, what happens inside it is
   lighter and italic, the way the reference distinguishes them. */
.step-row.level-0 .step-text { color: var(--ink); }
.step-row.level-1 .step-text { color: #46536b; font-style: italic; }
.step-row.level-2 .step-text,
.step-row.level-3 .step-text { color: var(--muted); font-style: italic; }

.step-icon {
  width: 1.05em;
  height: 1.05em;
  line-height: 1.05em;
  font-size: 0.8em;
  flex: none;
}

.caret-spacer { display: inline-block; width: 1em; flex: none; }

/* Two toolbars, one look: the step tree's and the epic tree's. They do the
   same thing to two different trees, so a reader who has used one knows the
   other on sight. */
.step-tools,
.tree-tools { display: flex; gap: 0.5em; margin-bottom: 0.5em; }

.step-tools button,
.tree-tools button {
  background: var(--card);
  border: 1px solid var(--rule);
  border-radius: 8px;
  color: var(--link);
  cursor: pointer;
  font: inherit;
  font-size: 0.8rem;
  padding: 0.3em 0.8em;
}

.step-tools button:hover,
.tree-tools button:hover { background: var(--hover); }

/* The tree page keeps its filter and its two buttons on one line, and lets
   them wrap rather than shrink when the page is narrow. */
.tree-tools { align-items: center; flex-wrap: wrap; }

.caret {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 1em;
  line-height: 1;
  padding: 0;
  width: 1em;
  flex: none;
}

.caret.open { transform: rotate(90deg); display: inline-block; }

/* A business step is the header of what it contains, so it carries the
   weight; everything nested under it reads as detail. */
.step-row.level-0 > td:first-child { font-weight: 500; }

.screenshot {
  border: 1px solid var(--rule);
  border-radius: 6px;
  object-fit: cover;
  background: var(--card);
}

.evidence, .stacktrace { margin-top: 0.5em; }
.evidence summary, .stacktrace summary {
  color: var(--link);
  cursor: pointer;
  font-size: 0.85rem;
}

.evidence pre, .stacktrace pre, .error-message pre {
  background: var(--page);
  border: 1px solid var(--rule);
  border-radius: 8px;
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
  background: var(--card);
  border: 1px solid var(--rule);
  border-left-width: 4px;
  border-radius: 0 12px 12px 0;
  margin: 0.75em 0;
  padding: 0.75em 1em;
}

.screenshot-failure pre {
  font-size: 0.85rem;
  white-space: pre-wrap;
  color: var(--ink);
}

.gallery-link { margin-bottom: 0.75em; font-size: 0.9em; }

/* ── Features ───────────────────────────────────────────────────────── */

.requirements-table .requirement-name-column { width: 45%; }
.requirements-table .requirement-type {
  color: var(--muted);
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.requirement-row.level-0 > td { font-weight: 600; }
.requirement-row.level-1 > td { font-weight: 400; }

.coverage-column { width: 200px; }

.progress {
  display: flex;
  height: 9px;
  background: var(--rule-soft);
  border-radius: 999px;
  overflow: hidden;
}

.progress-bar { height: 100%; }

.feature-coverage { margin-bottom: 1em; }

.requirement-narrative {
  color: var(--muted);
  font-style: italic;
  margin-bottom: 0.75em;
}

.scenario-narrative { color: var(--muted); font-size: 0.85rem; }

.carousel { max-width: 800px; margin: 0 auto; }

.slides {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 320px;
  background: var(--page);
  border: 1px solid var(--rule);
  border-radius: 12px;
}

.slide { text-align: center; padding: 1em; width: 100%; }
.slide[hidden] { display: none; }

.slide img {
  max-width: 100%;
  max-height: 60vh;
  border: 1px solid var(--rule);
  border-radius: 8px;
  background: var(--card);
}

.slide figcaption {
  margin-top: 0.75em;
  color: var(--muted);
  font-size: 0.9rem;
}

.carousel-controls {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1em;
  margin-top: 1em;
}

.carousel-prev, .carousel-next {
  background: var(--card);
  border: 1px solid var(--rule);
  border-radius: 50%;
  color: var(--link);
  cursor: pointer;
  font-size: 1.4em;
  line-height: 1;
  width: 2em;
  height: 2em;
}

.carousel-prev:hover, .carousel-next:hover { background: var(--hover); }
.carousel-prev:disabled, .carousel-next:disabled {
  color: #c3cbd8;
  cursor: default;
  background: var(--card);
}

.bullets { display: flex; flex-wrap: wrap; gap: 0.35em; }

.bullet {
  background: #dde3ec;
  border: none;
  border-radius: 50%;
  color: var(--ink);
  cursor: pointer;
  font-size: 0.75em;
  width: 20px;
  height: 20px;
  line-height: 20px;
  padding: 0;
  text-align: center;
}

.bullet.active { background: var(--link); color: #fff; }

/* ── Screenshot viewer ──────────────────────────────────────────────── */

/* A screenshot in the carousel is capped at 60vh so the caption and the
   controls stay on screen, which is right for walking through a run and
   wrong for reading an error message in the app. Clicking one opens it over
   the page at its own size.
   
   It is a dialog, so it closes the three ways a dialog closes: the button,
   Escape, and clicking the darkness around it. The button exists because the
   other two are conventions somebody has to already know. */
.slides img { cursor: zoom-in; }

.lightbox {
  position: fixed;
  inset: 0;
  z-index: 50;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  padding: 3.5rem 1.5rem 2rem 1.5rem;
  background: rgba(11, 37, 69, 0.9);
}

.lightbox[hidden] { display: none; }

.lightbox-image {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
  border-radius: 8px;
  background: var(--card);
  box-shadow: 0 24px 60px rgba(0, 0, 0, 0.45);
}

.lightbox-caption {
  color: #e8edf5;
  font-size: 0.9rem;
  text-align: center;
  max-width: 60rem;
}

.lightbox-close {
  position: absolute;
  top: 1rem;
  right: 1.25rem;
  width: 2.4rem;
  height: 2.4rem;
  border: 1px solid rgba(255, 255, 255, 0.35);
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.12);
  color: #fff;
  cursor: pointer;
  font-size: 1.5rem;
  line-height: 1;
}

.lightbox-close:hover { background: rgba(255, 255, 255, 0.24); }
.lightbox-close:focus-visible { outline: 2px solid #fff; outline-offset: 2px; }

/* Nothing scrolls behind the viewer. */
body.viewing-shot { overflow: hidden; }
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

// Opening a forty-step tree one caret at a time is the tedious part of
// reading a failed run.
function setAllStepSections(open) {
  document.querySelectorAll(".step-section").forEach(function (section) {
    section.hidden = !open;
  });
  // `[data-toggle]` and not every caret: the tree's carets and the epic-folding
  // ones share a class, so the unqualified selector would spin an epic's arrow
  // without moving the rows under it — a control lying about what it did. No
  // page carries both today, and this is what stops the first one that does
  // from being where we find out.
  document.querySelectorAll(".caret[data-toggle]").forEach(function (caret) {
    caret.classList.toggle("open", open);
  });
}

document.querySelectorAll(".expand-all").forEach(function (button) {
  button.addEventListener("click", function () { setAllStepSections(true); });
});

document.querySelectorAll(".collapse-all").forEach(function (button) {
  button.addEventListener("click", function () { setAllStepSections(false); });
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

// Both tables that show the epic → feature tree fold by epic: the dashboard's
// coverage panel and the tree page. Paging them was the other option and it
// breaks the thing it is paging — an epic ends up on one page and its features
// on the next, each of them a row with no heading.
//
// Two things hide a row here, folding and filtering, and they are independent:
// a feature can be filtered out of an open epic, and a matching feature can sit
// inside one somebody folded. So neither writes `hidden` directly. Each records
// its own reason and the row stays hidden while any reason stands — otherwise
// whichever ran last would decide, and clearing a filter would reveal rows the
// reader had folded away.
function hideRowFor(row, reason, on) {
  if (on) { row.dataset[reason] = "1"; } else { delete row.dataset[reason]; }
  row.hidden = Boolean(row.dataset.folded) || Boolean(row.dataset.filtered);
}

function foldEpic(caret, open) {
  caret.classList.toggle("open", open);
  caret.setAttribute("aria-expanded", open ? "true" : "false");
  document
    .querySelectorAll('[data-under="' + caret.dataset.fold + '"]')
    .forEach(function (row) { hideRowFor(row, "folded", !open); });
}

document.querySelectorAll("[data-fold]").forEach(function (caret) {
  caret.addEventListener("click", function () {
    foldEpic(caret, !caret.classList.contains("open"));
  });
});

// Opening a dozen epics one caret at a time is the same tedium the step tree
// already has a pair of buttons for, so it gets the same pair.
function setAllEpics(open) {
  document.querySelectorAll("[data-fold]").forEach(function (caret) {
    foldEpic(caret, open);
  });
}

document.querySelectorAll(".expand-epics").forEach(function (button) {
  button.addEventListener("click", function () { setAllEpics(true); });
});

document.querySelectorAll(".collapse-epics").forEach(function (button) {
  button.addEventListener("click", function () { setAllEpics(false); });
});

// The tree page filters by name. A feature that matches brings its epic with
// it: a row that says "75% passing" under no heading is a fact about nothing.
(function () {
  var filter = document.querySelector(".feature-filter");
  if (!filter) { return; }
  var table = document.querySelector("[data-features]");
  var count = document.querySelector(".filter-count");
  var features = document.querySelectorAll("tr.feature-row");
  var epics = document.querySelectorAll("tr.epic-row");
  var carets = document.querySelectorAll("[data-fold]");
  var total = table ? parseInt(table.dataset.features, 10) : features.length;

  filter.addEventListener("input", function () {
    var needle = filter.value.trim().toLowerCase();
    var shown = 0;
    var keep = {};
    features.forEach(function (row) {
      var hit = !needle || (row.dataset.name || "").indexOf(needle) >= 0;
      hideRowFor(row, "filtered", !hit);
      if (hit) {
        shown += 1;
        if (row.dataset.under) { keep[row.dataset.under] = true; }
      }
    });
    epics.forEach(function (row) {
      hideRowFor(row, "filtered", Boolean(needle) && !keep[row.dataset.epic]);
    });
    // A match inside a folded epic is a match nobody can see, under a count
    // that claims otherwise. Searching opens what it finds.
    if (needle) {
      carets.forEach(function (caret) {
        if (keep[caret.dataset.fold]) { foldEpic(caret, true); }
      });
    }
    if (count) {
      count.hidden = !needle;
      count.textContent = shown + " of " + total + " features";
    }
  });
})();

// The screenshot viewer: one per page, opened from anywhere that shows a
// capture — the gallery's slides and the thumbnails on the step table.
//
// A screenshot is displayed small in both places for the same reason: the
// page around it has to stay readable. This is where it is read rather than
// glanced at, so it opens over everything at its own size, and it closes the
// three ways a dialog closes.
var shotViewer = (function () {
  var box = document.querySelector(".lightbox");
  if (!box) { return null; }
  var full = box.querySelector(".lightbox-image");
  var caption = box.querySelector(".lightbox-caption");
  var close = box.querySelector(".lightbox-close");
  var opener = null;

  function captionOf(image) {
    var slide = image.closest(".slide");
    var figcaption = slide ? slide.querySelector("figcaption") : null;
    if (figcaption) { return figcaption.textContent; }
    // On the step table the picture belongs to a step, and the step's own
    // text says more than the file name ever will.
    var row = image.closest("tr");
    var step = row ? row.querySelector(".step-text") : null;
    return step ? step.textContent : image.getAttribute("alt") || "";
  }

  function open(image) {
    opener = image;
    full.src = image.getAttribute("src");
    full.alt = image.getAttribute("alt") || "";
    caption.textContent = captionOf(image);
    box.hidden = false;
    document.body.classList.add("viewing-shot");
    close.focus();
  }

  function closeShot() {
    box.hidden = true;
    document.body.classList.remove("viewing-shot");
    // Back to whatever opened it, so a keyboard reader is not returned to the
    // top of the page each time.
    if (opener) { opener.focus({ preventScroll: true }); opener = null; }
  }

  close.addEventListener("click", closeShot);
  // The darkness around the picture closes it; the picture itself does not,
  // or every attempt to look closely would shut the thing.
  box.addEventListener("click", function (event) {
    if (event.target === box || event.target === caption) { closeShot(); }
  });
  document.addEventListener("keydown", function (event) {
    if (!box.hidden && event.key === "Escape") { closeShot(); }
  });

  return { open: open, close: closeShot, isOpen: function () { return !box.hidden; } };
})();

// Every capture on the page opens it. The gallery's slides are images inside
// a figure; a thumbnail on the step table is an image inside a link to the
// gallery — the link stays, so a middle click still opens the gallery and the
// page keeps working with no script at all, but a plain click reads the
// picture where the reader already is.
if (shotViewer) {
  document.querySelectorAll(".slides img").forEach(function (image) {
    image.addEventListener("click", function () { shotViewer.open(image); });
  });
  document.querySelectorAll("a.shot-link").forEach(function (link) {
    link.addEventListener("click", function (event) {
      var image = link.querySelector("img");
      if (!image || event.metaKey || event.ctrlKey || event.shiftKey) { return; }
      event.preventDefault();
      shotViewer.open(image);
    });
  });
}

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

  // Walking the run inside the viewer: the arrows already moved the carousel
  // above, so the picture on top follows it.
  document.addEventListener("keydown", function (event) {
    if (!shotViewer || !shotViewer.isOpen()) { return; }
    if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
      var image = slides[current].querySelector("img");
      if (image) { shotViewer.open(image); }
    }
  });
});
''';
