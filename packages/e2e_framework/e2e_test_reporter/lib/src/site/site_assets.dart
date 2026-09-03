/// The site's static assets, written from scratch.
///
/// Nothing in this file is copied from anywhere: the layout facts it encodes
/// (an off-white page, a white banner, a tabbed dashboard, result colours per
/// status) come from *reading* the design source's stylesheet and templates,
/// and every rule here was authored for this generator. That is the clean-room
/// line this project drew: structure and appearance are facts, files are not,
/// and no file crosses.
///
/// The charts are inline SVG drawn by `charts.dart` and the icons are an
/// inline sprite drawn below, so the generated site is fully self-contained:
/// no script libraries, no fonts fetched, no network requests at render time.
/// The font stacks *name* Inter and JetBrains Mono — they render wherever
/// those faces are installed — and fall back to the platform's own interface
/// face otherwise. A `<link>` to a font host would be the one external URL
/// the site's own tests forbid.
library;

/// The result palette, one entry per verdict the writer emits.
///
/// Two tones per verdict, and the split is the point:
///
///  * `solid` is the tone used where the verdict is *read* — the word SUCCESS
///    beside a title, the marker in a result cell, a coverage bar. It must
///    hold 4.5:1 as text on white, which is why these sit darker than the
///    chart tones.
///  * `fill` (and `border`, its outline) is the tone the charts are painted
///    with. Softer, because five saturated blocks side by side shout, and a
///    dashboard is read for its numbers, not its colour. The chart tones were
///    chosen against a colour-vision validator: Failed and Broken are
///    separated by lightness as much as by hue, so a reader who cannot tell
///    red from orange still sees two bars.
///
/// The chart tones are mirrored as CSS tokens in [siteCss] (`--ch-*`), with a
/// dark-mode step of each; the charts paint with the token so the theme
/// switch reaches them. This map is where the meaning lives — a rule that
/// needs a verdict colour takes it from here or from the token that mirrors
/// it, never invents one.
const Map<String, ({String fill, String border, String solid})> resultColors =
    <String, ({String fill, String border, String solid})>{
      'SUCCESS': (fill: '#388B66', border: '#388B66', solid: '#15803D'),
      'FAILURE': (fill: '#C4524E', border: '#C4524E', solid: '#B91C1C'),
      'ERROR': (fill: '#D4A13E', border: '#D4A13E', solid: '#B45309'),
      'SKIPPED': (fill: '#94A3B8', border: '#94A3B8', solid: '#475569'),
      'UNDEFINED': (fill: '#9B84D8', border: '#9B84D8', solid: '#6D28D9'),
    };

/// The CSS token each verdict's chart tone lives under, so a chart painted
/// with `var(--ch-pass)` follows the theme switch.
const Map<String, String> resultTokens = <String, String>{
  'SUCCESS': '--ch-pass',
  'FAILURE': '--ch-fail',
  'ERROR': '--ch-broken',
  'SKIPPED': '--ch-skip',
  'UNDEFINED': '--ch-undef',
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
/// The same figure as the wordmark's mark — a checked box — on the brand
/// navy, so the tab icon and the banner read as one mark rather than two.
/// Drawn here rather than fetched, so the site still asks the network for
/// nothing, and as SVG so it stays sharp on any tab.
const String siteFavicon = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <rect width="32" height="32" rx="7" fill="#1E3A8A"/>
  <rect x="7" y="7" width="18" height="18" rx="3.5" fill="none" stroke="#ffffff" stroke-width="2.4"/>
  <path d="M12 16.2l2.8 2.8 5.4-6" fill="none" stroke="#ffffff" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

/// The mark beside the wordmark in the banner, inline in every page.
///
/// A checked box in the brand navy: a report of a test run is a checklist
/// somebody signed off, so that is the figure. Drawn on the same 24px grid
/// and 1.75 stroke as every other icon on the page, so it sits beside them as
/// one family.
///
/// Inline rather than a second file: the banner is on every page, and an
/// `<img>` would be one more request the offline report cannot count on. It
/// is decorative — the wordmark beside it already carries the name — so it is
/// hidden from screen readers.
const String wordmarkMark = '''
<svg class="wordmark-mark" viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false"><path d="M9 11.5l2 2 4-4.5"/><rect x="3.5" y="3.5" width="17" height="17" rx="3"/></svg>''';

/// The mark beside the report's title, one per platform.
///
/// Drawn here rather than fetched, like everything else the report shows: the
/// site asks the network for nothing, so a logo would have to be a file, and
/// a file is one more thing to lose.
///
/// **None of these is a vendor's logo, and that is deliberate.** The robot
/// and the fruit are trademarks, and this repository already decided it
/// carries no marks it does not own. What a reader needs is to tell three
/// reports apart at a glance, and the devices themselves do that: a browser
/// window has a chrome bar, one handset has a punch-hole camera and a home
/// bar, the other has a notch. Recognisable without borrowing anything.
///
/// Sized in `em` so the mark scales with the title it sits beside, and drawn
/// in `currentColor` so it takes the title's ink — including wherever that
/// colour changes. Decorative: the title spells the platform out, so a screen
/// reader that announced the drawing too would only say it twice.
String platformMark(String platform) => switch (platform) {
  'web' => _mark(
    '<rect x="2.5" y="4" width="19" height="16" rx="2.5"/>'
    '<path d="M2.5 8.5h19"/>'
    '<circle cx="5.6" cy="6.25" r="0.75" fill="currentColor" stroke="none"/>'
    '<circle cx="8.1" cy="6.25" r="0.75" fill="currentColor" stroke="none"/>'
    '<circle cx="10.6" cy="6.25" r="0.75" fill="currentColor" stroke="none"/>',
  ),
  // A square-shouldered handset with a screen drawn inside it and a nav bar
  // across the bottom.
  //
  // The difference from [ios] is deliberately coarse. Both are phones, and at
  // the size this is read — around twenty pixels beside a title — a punch-hole
  // camera against a notch is a distinction nobody can see. What survives
  // that size is silhouette and one big interior shape, so these two differ in
  // corner radius, in what crosses the top edge, and in what sits at the
  // bottom.
  'android' => _mark(
    '<rect x="5.5" y="2.5" width="13" height="19" rx="1.6"/>'
    '<path d="M5.5 5.6h13"/>'
    '<path d="M5.5 18h13"/>'
    '<path d="M9.5 20h5"/>',
  ),
  // A soft-cornered handset with a wide notch biting into the top edge.
  'ios' => _mark(
    '<rect x="6" y="2.5" width="12" height="19" rx="4"/>'
    '<path d="M9.4 2.5h5.2v1.1a1.4 1.4 0 0 1-1.4 1.4h-2.4a1.4 1.4 0 0 1-1.4-1.4z" '
    'fill="currentColor" stroke="none"/>'
    '<path d="M10 19.4h4"/>',
  ),
  // An unnamed platform gets no mark rather than a wrong one: the title
  // already shows the raw value, which is how an unexpected one is spotted.
  _ => '',
};

String _mark(String body) =>
    '<svg class="platform-mark" viewBox="0 0 24 24" fill="none" '
    'stroke="currentColor" stroke-width="1.6" stroke-linecap="round" '
    'stroke-linejoin="round" aria-hidden="true" focusable="false">$body</svg>';

/// The icon sprite, inlined once per page just inside `<body>`.
///
/// Every icon the site uses, drawn for it on a 24px grid with a 1.75 stroke —
/// the same grid and weight as the platform marks, so the whole set reads as
/// one hand. Drawn rather than taken from an icon library: a library's paths
/// come with a licence notice that would have to travel into every generated
/// report, and a checked box or a clock is not worth that.
///
/// Used through `<use href="#ic-…">`, which is a same-document reference and
/// costs no request. The sprite is hidden from layout and from screen
/// readers; each `<use>` carries its own meaning or is decorative beside a
/// word that already says it.
const String iconSprite = '''
<svg class="icon-sprite" width="0" height="0" aria-hidden="true" focusable="false">
  <symbol id="ic-check-square" viewBox="0 0 24 24"><path d="M9 11.5l2 2 4-4.5"/><rect x="3.5" y="3.5" width="17" height="17" rx="3"/></symbol>
  <symbol id="ic-clock" viewBox="0 0 24 24"><circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/></symbol>
  <symbol id="ic-chevron-right" viewBox="0 0 24 24"><path d="M9.5 6.5l5.5 5.5-5.5 5.5"/></symbol>
  <symbol id="ic-list-checks" viewBox="0 0 24 24"><path d="M3.5 7l1.75 1.75L8.5 5.5M3.5 15l1.75 1.75L8.5 13.5M12 7h8.5M12 15h8.5"/></symbol>
  <symbol id="ic-circle-check" viewBox="0 0 24 24"><circle cx="12" cy="12" r="8.5"/><path d="M8.5 12.2l2.4 2.4 4.6-5"/></symbol>
  <symbol id="ic-alert-triangle" viewBox="0 0 24 24"><path d="M12 4.2L3.4 19h17.2L12 4.2z"/><path d="M12 10v4M12 16.8h.01"/></symbol>
  <symbol id="ic-timer" viewBox="0 0 24 24"><circle cx="12" cy="13.5" r="7"/><path d="M12 10v3.5l2 1.5M9.5 3.5h5M12 3.5v3M18 7l1.2-1.2"/></symbol>
  <symbol id="ic-pie-chart" viewBox="0 0 24 24"><path d="M12 3.5a8.5 8.5 0 1 0 8.5 8.5H12z"/><path d="M14.5 3.9A8.5 8.5 0 0 1 20.1 9.5H14.5z"/></symbol>
  <symbol id="ic-bar-chart" viewBox="0 0 24 24"><path d="M4 20h16M7 16.5v-5M12 16.5v-9M17 16.5v-13"/></symbol>
  <symbol id="ic-gauge" viewBox="0 0 24 24"><path d="M4.5 16a8 8 0 1 1 15 0"/><path d="M12 16l3.5-4.5"/><circle cx="12" cy="16" r="1.2"/></symbol>
  <symbol id="ic-info" viewBox="0 0 24 24"><circle cx="12" cy="12" r="8.5"/><path d="M12 11v5M12 7.8h.01"/></symbol>
  <symbol id="ic-sun" viewBox="0 0 24 24"><circle cx="12" cy="12" r="3.5"/><path d="M12 3v2M12 19v2M3 12h2M19 12h2M5.6 5.6l1.4 1.4M17 17l1.4 1.4M5.6 18.4L7 17M17 7l1.4-1.4"/></symbol>
  <symbol id="ic-moon" viewBox="0 0 24 24"><path d="M19 14.5A7.5 7.5 0 0 1 9.5 5a7.5 7.5 0 1 0 9.5 9.5z"/></symbol>
</svg>
''';

/// One icon from [iconSprite], sized by the `i` class (18px) or `i s` (14px).
String icon(String id, {bool small = false}) =>
    '<svg class="i${small ? ' s' : ''}" aria-hidden="true" focusable="false">'
    '<use href="#$id"/></svg>';

/// The screenshot viewer's markup, on every page that shows a capture.
///
/// One per page rather than one per picture: it shows whichever was clicked,
/// and a dialog that can be closed needs exactly one close button. The pages
/// that carry no screenshot do not carry this either — see how `siteJs` does
/// nothing when it is absent.
const String shotViewer = '''
<div class="lightbox" role="dialog" aria-modal="true" aria-label="Screenshot" hidden>
  <button class="lightbox-close" title="Close (Esc)" aria-label="Close">×</button>
  <button class="lightbox-prev" title="Previous (←)" aria-label="Previous screenshot">‹</button>
  <img class="lightbox-image" src="" alt=""/>
  <button class="lightbox-next" title="Next (→)" aria-label="Next screenshot">›</button>
  <p class="lightbox-caption"></p>
</div>
''';

/// The stylesheet, written to `e2e-test-reporter.css` beside `index.html`.
const String siteCss = '''
/* E2E Test Reports — all rules authored for this generator. */

/* ============================================================
   1. TOKENS
   Every colour, face and radius on the site comes from here. Two families
   and nothing else: the neutrals and brand that build the page, and the
   semantic tones (good / danger / warning / neutral / info) the verdicts
   wear. A rule that needs a colour takes a token; a rule that invents one
   is a bug.
   ============================================================ */
:root {
  /* Named, not fetched: the report is read offline, off a CI artefact, and
     its own tests forbid an external URL. Inter and JetBrains Mono render
     where they are installed; the fallback is each platform's own interface
     face, which is the same metric family. */
  --font-sans: "Inter", -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  --font-mono: "JetBrains Mono", "SF Mono", Menlo, Consolas, monospace;

  --bg-page: #F5F7FA;
  --bg-card: #FFFFFF;
  --border: #E4E8EE;
  --text-primary: #0F172A;
  --text-secondary: #475569;
  --text-muted: #94A3B8;
  --brand: #1E3A8A;
  --brand-soft: #E8EEFB;

  /* Semantic tones: cards, chips, badges and the verdict text. */
  --success: #16A34A;  --success-soft: #DCFCE7;
  --danger: #DC2626;   --danger-soft: #FEE2E2;
  --warning: #D97706;  --warning-soft: #FEF3C7;
  --neutral: #64748B;  --neutral-soft: #F1F5F9;
  --info: #7C3AED;     --info-soft: #EDE9FE;

  /* The chart tones — mirrored from `resultColors`, where the meaning lives.
     Softer than the semantic tones on purpose: five saturated blocks side by
     side shout, and a dashboard is read for its numbers. `--ch-bar` paints
     the one chart that is about a quantity, not a verdict (how long tests
     took), so a bar about duration is never mistaken for one about outcomes;
     `--ch-slow` marks the band the slowest test fell in. */
  --ch-pass: #388B66;
  --ch-skip: #94A3B8;
  --ch-fail: #C4524E;
  --ch-broken: #D4A13E;
  --ch-undef: #9B84D8;
  --ch-bar: #7B93CF;
  --ch-slow: #D4A13E;

  /* The verdicts at reading strength: the tone a verdict *word* is set in,
     a result marker, a coverage bar. Darker than the chart tones because
     these have to hold 4.5:1 as text. */
  --pass: #15803D;
  --fail: #B91C1C;
  --broken: #B45309;
  --skip: #475569;
  --undefined: #6D28D9;

  /* Tints behind a row or a title bar wearing its verdict. */
  --pass-tint: #EEF8F2;
  --fail-tint: var(--danger-soft);
  --broken-tint: var(--warning-soft);
  --skip-tint: var(--neutral-soft);
  --undefined-tint: var(--info-soft);

  /* Surfaces. */
  --radius: 12px;
  --radius-sm: 8px;
  --shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
  --shadow-hover: 0 4px 12px rgba(15, 23, 42, 0.08);
  --grid-line: rgba(228, 232, 238, 0.3);
  --tooltip-bg: #0F172A;
  --tooltip-fg: #FFFFFF;

  /* The names the older page rules were written against, kept as aliases so
     every page reads from one set of tokens without rewriting its rules. */
  --title: var(--text-primary);
  --title-soft: var(--text-secondary);
  --link: var(--brand);
  --page: var(--bg-page);
  --card: var(--bg-card);
  --ink: var(--text-primary);
  --muted: var(--text-secondary);
  --rule: var(--border);
  --rule-soft: var(--border);
  --hover: var(--neutral-soft);
  --data: var(--ch-bar);
  --data-soft: var(--brand-soft);

  color-scheme: light;
}

/* Dark mode is a choice, made with the switch in the header and remembered
   per browser. Each token is re-stepped for the dark card rather than
   inverted: the semantic tones come up a step so they still read on navy,
   and the chart tones are the dark column of the same validated set. */
:root[data-theme="dark"] {
  --bg-page: #0F172A;
  --bg-card: #1E293B;
  --border: #334155;
  --text-primary: #F8FAFC;
  --text-secondary: #CBD5E1;
  --text-muted: #64748B;
  --brand: #93A8E8;
  --brand-soft: #1E2A4A;

  --success: #22C55E;  --success-soft: #14321F;
  --danger: #EF4444;   --danger-soft: #3B1A1A;
  --warning: #F59E0B;  --warning-soft: #3A2A0F;
  --neutral: #94A3B8;  --neutral-soft: #26324A;
  --info: #A78BFA;     --info-soft: #2A2350;

  --ch-pass: #3E9E70;
  --ch-skip: #A5B1C2;
  --ch-fail: #D0605B;
  --ch-broken: #D4A13E;
  --ch-undef: #9A86DE;
  --ch-bar: #7F98DA;
  --ch-slow: #D4A13E;

  --pass: #4ADE80;
  --fail: #F87171;
  --broken: #FBBF24;
  --skip: #CBD5E1;
  --undefined: #C4B5FD;
  --pass-tint: #14321F;

  --shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
  --shadow-hover: 0 4px 12px rgba(0, 0, 0, 0.4);
  --grid-line: rgba(51, 65, 85, 0.6);
  --tooltip-bg: #F8FAFC;
  --tooltip-fg: #0F172A;

  color-scheme: dark;
}

/* ============================================================
   2. BASE
   ============================================================ */
*, *::before, *::after { box-sizing: border-box; }
* { margin: 0; padding: 0; }

body {
  font: 400 14px/1.5 var(--font-sans);
  background-color: var(--bg-page);
  color: var(--text-primary);
  -webkit-font-smoothing: antialiased;
  /* Every figure in the report is a count, a duration or a clock time, and
     all three are read down a column. Proportional digits make that column
     ragged. */
  font-variant-numeric: tabular-nums;
}

a { text-decoration: none; color: var(--brand); }
a:hover { text-decoration: underline; }

:focus-visible { outline: 2px solid var(--brand); outline-offset: 2px; border-radius: 4px; }

button { font: inherit; color: inherit; }

h1, h2, h3, h4 { line-height: 1.2; text-wrap: balance; }

/* Three levels and each does one job: h2 names the page, h3 names a block
   inside it, h4 titles a card. */
h2 { font-size: 24px; font-weight: 700; color: var(--text-primary); }
h3 { font-size: 20px; font-weight: 600; color: var(--text-primary); margin: 8px 0; }
h4 { font-size: 16px; font-weight: 600; color: var(--text-primary); }

.eyebrow {
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-secondary);
}

.mono { font-family: var(--font-mono); }

svg.i {
  width: 18px;
  height: 18px;
  stroke: currentColor;
  fill: none;
  stroke-width: 1.75;
  stroke-linecap: round;
  stroke-linejoin: round;
  flex: none;
}
svg.i.s { width: 14px; height: 14px; }
.icon-sprite { position: absolute; }

/* ============================================================
   3. HEADER · BREADCRUMB · TABS
   ============================================================ */
.topheader {
  height: 56px;
  background: var(--bg-card);
  border-bottom: 1px solid var(--border);
}

/* Centred at 1440px and no wider: on a wider window the content centres
   rather than stretches. Nothing is pinned to a minimum width — what is too
   wide for the window scrolls inside its own box (see `.table-scroll`). */
.topbanner {
  max-width: 1440px;
  margin: 0 auto;
  height: 100%;
  padding: 0 32px;
  display: flex;
  align-items: center;
  gap: 16px;
}

.wordmark {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  color: var(--text-primary);
  font-size: 16px;
  font-weight: 600;
  line-height: 1;
}
.wordmark:hover { text-decoration: none; }
.wordmark-mark { display: block; flex: none; color: var(--brand); }
.wordmark-lead { font-weight: 600; }
.wordmark-name { color: var(--text-secondary); font-weight: 500; margin-left: 0.3em; }

.projectname { margin-left: auto; display: flex; align-items: center; gap: 16px; }

/* Which report this is, as a chip: the platform mark and the title in the
   brand tone on its soft tint. */
.projecttitle {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 28px;
  padding: 0 10px;
  border-radius: 999px;
  background: var(--brand-soft);
  color: var(--brand);
  font-size: 13px;
  font-weight: 600;
}

.platform-mark { width: 14px; height: 14px; flex: none; }

.date-and-time {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font: 400 12px/1 var(--font-mono);
  color: var(--text-muted);
}

.theme-toggle {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--border);
  background: var(--bg-card);
  color: var(--text-secondary);
  cursor: pointer;
  transition: background 150ms ease, color 150ms ease;
}
.theme-toggle:hover { background: var(--neutral-soft); color: var(--text-primary); }
.theme-toggle .moon { display: none; }
:root[data-theme="dark"] .theme-toggle .sun { display: none; }
:root[data-theme="dark"] .theme-toggle .moon { display: block; }

.middlecontent {
  max-width: 1440px;
  margin: 0 auto;
  padding: 24px 32px 48px;
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.breadcrumbs {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 13px;
  color: var(--text-secondary);
}
.breadcrumbs a { color: var(--text-secondary); }
.breadcrumbs .crumb-sep { color: var(--text-muted); }

/* The main menu: underline tabs, no boxes. */
.nav-tabs {
  list-style: none;
  display: flex;
  gap: 24px;
  border-bottom: 1px solid var(--border);
}
.nav-tabs li a, .nav-tabs li span {
  display: block;
  padding: 10px 0 12px;
  color: var(--text-secondary);
  font-weight: 500;
  border-bottom: 2px solid transparent;
  margin-bottom: -1px;
  transition: color 150ms ease, border-color 150ms ease;
}
.nav-tabs li a:hover { color: var(--text-primary); text-decoration: none; }
.nav-tabs li.active a, .nav-tabs li.active span {
  color: var(--text-primary);
  font-weight: 600;
  border-bottom-color: var(--brand);
  cursor: default;
}
.nav-tabs li.disabled span { color: var(--text-muted); cursor: default; }

.topnav { display: flex; flex-direction: column; gap: 12px; margin-top: -8px; }

/* Said plainly rather than in alarm colours: an older run is a fact about
   this report, not a fault in it. */
.run-age {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  align-self: flex-start;
  padding: 6px 12px;
  border-radius: var(--radius-sm);
  background: var(--neutral-soft);
  color: var(--text-secondary);
  font-size: 13px;
}
.run-age .i { color: var(--text-muted); }

.section-title { display: flex; flex-direction: column; gap: 6px; }
.test-count-title { font-size: 13px; color: var(--text-secondary); }

/* ============================================================
   4. KEY FIGURES
   The four numbers someone opens the report to find, above everything that
   explains them.
   ============================================================ */
.kpi-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; }

.kpi {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  transition: box-shadow 150ms ease;
}
.kpi:hover { box-shadow: var(--shadow-hover); }
.kpi-head { display: flex; align-items: center; gap: 12px; }
.kpi-icon {
  width: 36px;
  height: 36px;
  border-radius: var(--radius-sm);
  display: grid;
  place-items: center;
  background: var(--brand-soft);
  color: var(--brand);
}
.kpi-label {
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-secondary);
}
.kpi-value { font-size: 36px; font-weight: 700; line-height: 1.2; color: var(--text-primary); }
.kpi-note { font-size: 13px; color: var(--text-secondary); }

/* Colour where the number is a verdict on the run. */
.kpi.good .kpi-icon { background: var(--success-soft); color: var(--success); }
.kpi.good .kpi-value { color: var(--success); }
.kpi.bad .kpi-icon { background: var(--danger-soft); color: var(--danger); }
.kpi.bad .kpi-value { color: var(--danger); }
.kpi.calm .kpi-icon { background: var(--neutral-soft); color: var(--neutral); }
.kpi.time .kpi-value { font-family: var(--font-mono); font-size: 32px; }

/* ============================================================
   5. SEGMENTED CONTROL · SUMMARY BAND · CARDS
   ============================================================ */
.segmented {
  display: inline-flex;
  align-self: flex-start;
  padding: 3px;
  gap: 2px;
  border-radius: var(--radius-sm);
  background: var(--neutral-soft);
}
.segmented .segment {
  display: block;
  padding: 6px 14px;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
  color: var(--text-secondary);
  cursor: pointer;
  transition: background 150ms ease, color 150ms ease, box-shadow 150ms ease;
}
.segmented .segment:hover { color: var(--text-primary); text-decoration: none; }
.segmented .segment.active {
  background: var(--bg-card);
  color: var(--text-primary);
  font-weight: 600;
  box-shadow: var(--shadow);
}

.tab-pane { display: none; flex-direction: column; gap: 24px; }
.tab-pane.active { display: flex; }

/* With three scenarios or fewer the charts have little to say, so the run is
   summed up in one line above them. The charts stay: a chart of one bar is
   still the chart a reader learned to read. */
.summary-band {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 16px;
  border-radius: var(--radius);
  font-weight: 500;
  background: var(--success-soft);
  color: var(--success);
}
.summary-band.bad { background: var(--danger-soft); color: var(--danger); }
.summary-band .mono { font-weight: 600; }

.card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  transition: box-shadow 150ms ease;
}
.card:hover { box-shadow: var(--shadow-hover); }
.card.standalone { display: block; }
.card-head { display: flex; flex-direction: column; gap: 4px; }
.card-head .eyebrow { display: flex; align-items: center; gap: 8px; }
.card-head .eyebrow .i { width: 16px; height: 16px; color: var(--text-muted); }
.card-sub { font-size: 13px; color: var(--text-secondary); }

/* ============================================================
   6. CHARTS
   Drawn as SVG to one scale by `charts.dart`: the marks, the ticks and the
   labels all come off the same numbers.
   ============================================================ */
.dashboard-charts { display: grid; grid-template-columns: 1fr 1.4fr 1.4fr; gap: 16px; }

.chart-block svg.chart {
  width: 100%;
  height: 220px;
  display: block;
  font-family: var(--font-sans);
  overflow: visible;
}
.chart-block svg.chart text { fill: var(--text-muted); font-size: 12px; }
.chart-block svg.chart text.bar-value { fill: var(--text-primary); font-weight: 600; }
.chart-block svg.chart .gridline { stroke: var(--grid-line); stroke-width: 1; }
.chart-block svg.chart text.axis-title {
  fill: var(--text-secondary);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.bar-column { cursor: pointer; }
.bar-column .bar-fill { transition: opacity 150ms ease; }
.bar-column:hover .bar-fill { opacity: 0.85; }

.donut-wrap { display: flex; flex-direction: column; align-items: center; gap: 16px; }
.donut-wrap svg.chart { max-width: 200px; height: 200px; }
.donut-track { fill: none; stroke: var(--neutral-soft); stroke-width: 22; }
.donut-segment { fill: none; stroke-width: 22; }
.donut-wedge { cursor: pointer; }
.donut-wedge:hover .donut-segment { opacity: 0.85; }
.chart-block svg.chart text.donut-center { fill: var(--text-primary); font-size: 28px; font-weight: 700; }
.chart-block svg.chart text.donut-eyebrow {
  fill: var(--text-secondary);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}
.donut-label { cursor: pointer; }
.donut-label:hover text.donut-center { fill: var(--brand); }

.chart-legend {
  list-style: none;
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 13px;
  color: var(--text-primary);
}
.chart-legend li, .chart-legend li a { display: flex; align-items: center; gap: 8px; }
.chart-legend li a { color: inherit; width: 100%; }
.chart-legend li a:hover { text-decoration: none; color: var(--brand); }
.chart-legend li.empty { color: var(--text-muted); }
.chart-legend .swatch { width: 10px; height: 10px; border-radius: 50%; flex: none; }
.chart-legend li.empty .swatch { opacity: 0.4; }
.chart-legend .legend-count { margin-left: auto; font-family: var(--font-mono); font-size: 12px; }

/* The two panels under the charts: what the run covered on the left, what it
   cost on the right. */
.summary-columns { display: grid; grid-template-columns: 1.4fr 1fr; gap: 16px; }

/* ============================================================
   7. TABLES
   ============================================================ */
table.table { border-collapse: collapse; width: 100%; font-size: 13px; }

/* Column names are labels, not headings. */
table.table th {
  text-align: left;
  padding: 8px 12px;
  border-bottom: 1px solid var(--border);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-secondary);
  white-space: nowrap;
}
table.table td { padding: 10px 12px; border-bottom: 1px solid var(--border); vertical-align: middle; }
table.table tbody tr:last-child td { border-bottom: 0; }

/* No zebra striping. One hairline per row and a tint under the pointer. */
table.table tbody tr:hover > td { background: var(--neutral-soft); }

/* Key statistics read as label / value pairs, the value in the mono face. */
.key-statistics td:nth-child(2n) {
  text-align: right;
  font-family: var(--font-mono);
  font-size: 12px;
  color: var(--text-primary);
  white-space: nowrap;
}
.key-statistics td:nth-child(2n + 1) { color: var(--text-secondary); }
.key-statistics tbody tr:hover > td { background: transparent; }

/* ── Feature search ─────────────────────────────────────────────────── */
.feature-search { display: flex; align-items: center; gap: 12px; margin-bottom: 12px; }
.feature-search input,
.table-controls select,
.table-controls input {
  height: 32px;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  padding: 0 10px;
  font: inherit;
  font-size: 13px;
  color: var(--text-primary);
}
.feature-search input { min-width: 16em; }
.filter-count { color: var(--text-secondary); font-size: 13px; }

.requirement-row .caret { color: var(--text-muted); transition: transform 150ms ease; }
.requirement-row .caret.open { transform: rotate(90deg); }

/* ── Severity ───────────────────────────────────────────────────────── */
/* Not a verdict, so it borrows the *stakes* tones rather than the outcome
   ones: what a failure would cost is a different question from what
   happened. The two levels somebody acts on wear a tint, the rest recede. */
.severity {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 999px;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  background: var(--neutral-soft);
  color: var(--neutral);
}
.severity.blocker { background: var(--danger-soft); color: var(--danger); }
.severity.critical { background: var(--warning-soft); color: var(--warning); }
.severity.none { background: transparent; color: var(--text-muted); letter-spacing: 0; }

/* ── Result markers ─────────────────────────────────────────────────── */
.result-icon {
  display: inline-block;
  width: 24px;
  height: 24px;
  line-height: 24px;
  border-radius: 50%;
  color: #fff;
  text-align: center;
  font-weight: 700;
  font-size: 13px;
}

/* ── The scenario table's controls ──────────────────────────────────── */
.test-count { color: var(--text-secondary); font-weight: 500; }

.table-controls {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  font-size: 13px;
  color: var(--text-secondary);
}
.table-controls input { min-width: 14em; }

th.sortable { cursor: pointer; user-select: none; }
th.sortable:hover { color: var(--text-primary); }
th.sortable::after { content: " ⇅"; color: var(--text-muted); }
th.sortable.asc::after { content: " ↑"; color: var(--brand); }
th.sortable.desc::after { content: " ↓"; color: var(--brand); }

.table-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 13px;
  color: var(--text-secondary);
}

.pagination { display: flex; gap: 4px; }
.pagination button {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 6px;
  color: var(--text-secondary);
  cursor: pointer;
  font-size: 12px;
  min-width: 28px;
  height: 28px;
  padding: 0 8px;
}
.pagination button:hover:not(:disabled):not(.active) { background: var(--neutral-soft); }
.pagination button.active { background: var(--brand); border-color: var(--brand); color: #fff; cursor: default; }
.pagination button:disabled { color: var(--text-muted); cursor: default; }

.empty-note { color: var(--text-secondary); font-size: 13px; }

.active-filter {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  align-self: flex-start;
  background: var(--brand-soft);
  border-radius: var(--radius-sm);
  color: var(--brand);
  font-size: 13px;
  padding: 6px 12px;
}
.clear-filter { background: none; border: none; color: var(--brand); cursor: pointer; text-decoration: underline; }

/* ── Tags ───────────────────────────────────────────────────────────── */
.tag-cloud { display: flex; flex-wrap: wrap; gap: 8px; }

/* Tags are neutral by design: a tag is a label someone put on a test, not a
   verdict about it. */
.tag-badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 28px;
  padding: 0 10px;
  border-radius: 999px;
  border: 1px solid var(--border);
  background: var(--bg-card);
  color: var(--text-primary);
  font-size: 13px;
  font-weight: 500;
  transition: box-shadow 150ms ease;
}
.tag-badge.cloud { padding-right: 4px; }
.tag-badge.cloud:hover { text-decoration: none; box-shadow: var(--shadow-hover); }
.tag-count {
  display: inline-grid;
  place-items: center;
  min-width: 20px;
  height: 20px;
  padding: 0 6px;
  border-radius: 999px;
  background: var(--brand-soft);
  color: var(--brand);
  font: 600 11px var(--font-mono);
}

/* A table wider than the window scrolls here, not on <body>. */
.table-scroll { overflow-x: auto; }
.table-scroll > table { min-width: 44em; }

.footer {
  max-width: 1440px;
  margin: 0 auto;
  padding: 16px 32px 24px;
  border-top: 1px solid var(--border);
}
.version { color: var(--text-muted); font-size: 12px; }

/* ── Narrow screens ─────────────────────────────────────────────────── */
@media (max-width: 1024px) {
  .kpi-row { grid-template-columns: repeat(2, 1fr); }
  .dashboard-charts { grid-template-columns: 1fr 1fr; }
  .dashboard-charts .chart-block.wide { grid-column: 1 / -1; }
  .summary-columns { grid-template-columns: 1fr; }
  .story-header-row { flex-direction: column; align-items: flex-start; }
  .tags { text-align: left; }
}

@media (max-width: 640px) {
  .topbanner, .middlecontent, .footer { padding-left: 16px; padding-right: 16px; }
  .wordmark-name, .date-and-time { display: none; }
  .kpi-row { grid-template-columns: 1fr; }
  .dashboard-charts { grid-template-columns: 1fr; }
  .table-controls { flex-direction: column; align-items: stretch; }
  .table-controls input { min-width: 0; width: 100%; }
  .nav-tabs { flex-wrap: wrap; gap: 16px; }
  /* The two-column statistics table folds to one pair per line. */
  .key-statistics tr { display: grid; grid-template-columns: 1fr auto; }
  .key-statistics td:empty { display: none; }
}

/* ============================================================
   8. TEST DETAIL PAGE
   ============================================================ */
.titlebar { display: flex; flex-direction: column; gap: 12px; }

.story-header-row { display: flex; justify-content: space-between; align-items: baseline; gap: 16px; }
.story-header-title { font-weight: 600; font-size: 20px; color: var(--text-primary); }
.tags { text-align: right; display: flex; flex-wrap: wrap; gap: 6px; justify-content: flex-end; }

/* The verdict is said three ways at once — the icon, the word, and the tint
   this bar carries — because colour alone is not something every reader
   gets. */
.test-title-bar {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-left-width: 4px;
  border-radius: 0 var(--radius) var(--radius) 0;
  padding: 14px 18px;
}
.test-case-title { font-size: 18px; font-weight: 600; color: var(--text-primary); margin-left: 0.4em; }

/* The verdict spelled out, at reading strength. */
.success-color { color: var(--pass); }
.failure-color { color: var(--fail); }
.error-color { color: var(--broken); }
.skipped-color { color: var(--skip); }
.undefined-color { color: var(--undefined); }

.test-title-bar.test-SUCCESS { border-left-color: var(--pass); background: var(--pass-tint); }
.test-title-bar.test-FAILURE { border-left-color: var(--fail); background: var(--fail-tint); }
.test-title-bar.test-ERROR { border-left-color: var(--broken); background: var(--broken-tint); }
.test-title-bar.test-SKIPPED { border-left-color: var(--skip); background: var(--skip-tint); }
.test-title-bar.test-UNDEFINED { border-left-color: var(--undefined); background: var(--undefined-tint); }

/* A scenario row wearing its verdict: a stripe down the left edge and a wash
   behind the row, both the verdict's own tone. Passing rows get NEITHER,
   deliberately — they are the majority and the baseline, and tinting them
   would drown the rows somebody opened the report to find. */
.table tr[data-result] > td { border-left: 0 solid transparent; }

.table tr[data-result="FAILURE"] > td:first-child,
.table tr[data-result="ERROR"] > td:first-child,
.table tr[data-result="SKIPPED"] > td:first-child,
.table tr[data-result="UNDEFINED"] > td:first-child { border-left-width: 3px; }

.table tr[data-result="FAILURE"] > td {
  background: var(--fail-tint);
  border-left-color: var(--fail);
}
.table tr[data-result="ERROR"] > td {
  background: var(--broken-tint);
  border-left-color: var(--broken);
}
.table tr[data-result="SKIPPED"] > td {
  background: var(--skip-tint);
  border-left-color: var(--skip);
}
.table tr[data-result="UNDEFINED"] > td {
  background: var(--undefined-tint);
  border-left-color: var(--undefined);
}

.test-description { color: var(--text-secondary); font-style: italic; }

/* ── Step table ─────────────────────────────────────────────────────── */
table.step-table { border-collapse: collapse; width: 100%; table-layout: fixed; font-size: 13px; }
table.step-table th {
  text-align: left;
  padding: 8px 12px;
  border-bottom: 1px solid var(--border);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--text-secondary);
}
table.step-table td { padding: 8px 12px; border-bottom: 1px solid var(--border); vertical-align: middle; }

/* A group's children live in a nested table inside a spanning cell. The left
   rule is the hierarchy made visible. */
.step-section > td { padding: 0 0 0 1.6em; }
.step-section > td > table { border-left: 2px solid var(--border); }
table.step-table.nested { margin: 0; }

.step-table tr.test-FAILURE > td { background: var(--fail-tint); }
.step-table tr.test-ERROR > td { background: var(--broken-tint); }

.step-description-column { width: auto; }
.shot-column { width: 150px; }
.outcome-column { width: 130px; font-size: 11px; font-weight: 600; letter-spacing: 0.04em; text-transform: uppercase; }
.duration-column { width: 100px; color: var(--text-secondary); font-family: var(--font-mono); font-size: 12px; }

.step-description { line-height: 1.5; display: flex; align-items: baseline; gap: 0.4em; }

/* Depth reads as weight: a business step is plain, what happens inside it is
   lighter and italic. */
.step-row.level-0 .step-text { color: var(--text-primary); }
.step-row.level-1 .step-text { color: var(--text-secondary); font-style: italic; }
.step-row.level-2 .step-text,
.step-row.level-3 .step-text { color: var(--text-muted); font-style: italic; }
.step-row.level-0 > td:first-child { font-weight: 500; }

.step-icon { width: 18px; height: 18px; line-height: 18px; font-size: 11px; flex: none; }
.caret-spacer { display: inline-block; width: 1em; flex: none; }

.step-tools, .tree-tools { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.step-tools button, .tree-tools button {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 6px;
  color: var(--text-secondary);
  cursor: pointer;
  font-size: 12px;
  padding: 4px 10px;
}
.step-tools button:hover, .tree-tools button:hover { background: var(--neutral-soft); color: var(--text-primary); }

.caret { background: none; border: none; cursor: pointer; font-size: 1em; line-height: 1; padding: 0; width: 1em; flex: none; color: var(--text-muted); }
.caret.open { transform: rotate(90deg); display: inline-block; }

.screenshot { border: 1px solid var(--border); border-radius: 6px; object-fit: cover; background: var(--bg-card); }

.evidence, .stacktrace { margin-top: 8px; }
.evidence summary, .stacktrace summary { color: var(--brand); cursor: pointer; font-size: 13px; }
.evidence pre, .stacktrace pre, .error-message pre {
  background: var(--bg-page);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  padding: 12px;
  margin-top: 8px;
  overflow-x: auto;
  font-family: var(--font-mono);
  font-size: 12px;
  line-height: 1.5;
  white-space: pre-wrap;
}

/* Width and style only: the colour comes from the `test-<RESULT>` class the
   block also carries. */
.failure-block { margin-top: 24px; border-left-width: 4px; border-left-style: solid; padding-left: 16px; }

/* ============================================================
   9. SCREENSHOTS · FEATURES · CAROUSEL · VIEWER
   ============================================================ */
.screenshot-failure {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-left-width: 4px;
  border-radius: 0 var(--radius) var(--radius) 0;
  margin: 12px 0;
  padding: 12px 16px;
}
.screenshot-failure pre { font-family: var(--font-mono); font-size: 12px; white-space: pre-wrap; color: var(--text-primary); }
.gallery-link { font-size: 13px; }

.requirements-table .requirement-name-column { width: 45%; }
.requirements-table .requirement-type { color: var(--text-muted); font-size: 11px; text-transform: uppercase; letter-spacing: 0.04em; }
.requirements-table td:nth-child(2), .requirements-table td:nth-child(3) { font-family: var(--font-mono); font-size: 12px; text-align: right; }
.requirements-table th:nth-child(2), .requirements-table th:nth-child(3) { text-align: right; }
.requirement-row.level-0 > td { font-weight: 600; }
.requirement-row.level-1 > td { font-weight: 400; }

.coverage-column { width: 200px; }
.progress { display: flex; height: 6px; background: var(--neutral-soft); border-radius: 999px; overflow: hidden; min-width: 120px; }
.progress-bar { height: 100%; }
.feature-coverage { margin-bottom: 16px; }
.requirement-narrative { color: var(--text-secondary); font-style: italic; margin-bottom: 12px; }
.scenario-narrative { color: var(--text-secondary); font-size: 13px; }

.carousel { max-width: 800px; margin: 0 auto; }
.slides {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 320px;
  background: var(--bg-page);
  border: 1px solid var(--border);
  border-radius: var(--radius);
}
.slide { text-align: center; padding: 16px; width: 100%; }
.slide[hidden] { display: none; }
.slide img { max-width: 100%; max-height: 60vh; border: 1px solid var(--border); border-radius: var(--radius-sm); background: var(--bg-card); }
.slide figcaption { margin-top: 12px; color: var(--text-secondary); font-size: 13px; }

.carousel-controls { display: flex; align-items: center; justify-content: center; gap: 16px; margin-top: 16px; }
.carousel-prev, .carousel-next {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 50%;
  color: var(--brand);
  cursor: pointer;
  font-size: 1.4em;
  line-height: 1;
  width: 2em;
  height: 2em;
}
.carousel-prev:hover, .carousel-next:hover { background: var(--neutral-soft); }
.carousel-prev:disabled, .carousel-next:disabled { color: var(--text-muted); cursor: default; background: var(--bg-card); }

.bullets { display: flex; flex-wrap: wrap; gap: 6px; }
.bullet {
  background: var(--neutral-soft);
  border: none;
  border-radius: 50%;
  color: var(--text-primary);
  cursor: pointer;
  font-size: 11px;
  width: 20px;
  height: 20px;
  line-height: 20px;
  padding: 0;
  text-align: center;
}
.bullet.active { background: var(--brand); color: #fff; }

/* The screenshot viewer: a dialog, so it closes the three ways a dialog
   closes — the button, Escape, and clicking the darkness around it. */
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
  /* The sides clear the arrows, so a wide capture stops beside them instead
     of running underneath. */
  padding: 3.5rem 4.75rem 2rem 4.75rem;
  background: rgba(15, 23, 42, 0.9);
}
.lightbox[hidden] { display: none; }
.lightbox-image { max-width: 100%; max-height: 100%; object-fit: contain; border-radius: var(--radius-sm); background: var(--bg-card); box-shadow: 0 24px 60px rgba(0, 0, 0, 0.45); }
.lightbox-caption { color: #E2E8F0; font-size: 13px; text-align: center; max-width: 60rem; }
.lightbox-close, .lightbox-prev, .lightbox-next {
  position: absolute;
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
.lightbox-close { top: 1rem; right: 1.25rem; }
.lightbox-prev { left: 1.25rem; top: 50%; transform: translateY(-50%); }
.lightbox-next { right: 1.25rem; top: 50%; transform: translateY(-50%); }
.lightbox-close:hover, .lightbox-prev:hover, .lightbox-next:hover { background: rgba(255, 255, 255, 0.24); }
.lightbox-close:focus-visible, .lightbox-prev:focus-visible, .lightbox-next:focus-visible { outline: 2px solid #fff; outline-offset: 2px; }
body.viewing-shot { overflow: hidden; }

/* ============================================================
   10. PRINT · MOTION
   ============================================================ */
@media print {
  :root { --bg-page: #fff; --bg-card: #fff; --shadow: none; --shadow-hover: none; }
  .topheader, .nav-tabs, .segmented, .table-controls, .table-footer, .tree-tools, .step-tools, .theme-toggle { display: none !important; }
  .middlecontent { padding: 0; gap: 16px; }
  .kpi, .card { box-shadow: none; break-inside: avoid; }
  .dashboard-charts { grid-template-columns: 1fr 1fr 1fr; }
  .tab-pane { display: flex !important; }
}

@media (prefers-reduced-motion: reduce) { * { transition: none !important; } }
''';

/// The site's only script: the dashboard's tab switch, the theme switch, the
/// detail page's step-group carets, the scenario table and the screenshot
/// viewer, all written here. Nothing else on any page runs code.
const String siteJs = '''
document.querySelectorAll("[data-tab]").forEach(function (tab) {
  tab.addEventListener("click", function (event) {
    event.preventDefault();
    document.querySelectorAll("[data-tab]").forEach(function (t) {
      var on = t === tab;
      t.classList.toggle("active", on);
      t.setAttribute("aria-selected", on ? "true" : "false");
      t.parentElement.classList.toggle("active", on);
    });
    document.querySelectorAll(".tab-pane").forEach(function (pane) {
      pane.classList.toggle("active", pane.id === tab.dataset.tab);
    });
  });
});

// Dark mode is a choice, remembered per browser. The attribute goes on the
// root so every token flips at once; storage can be absent (a file opened
// from a sandbox), so both reads and writes are guarded.
(function () {
  var root = document.documentElement;
  try {
    var saved = localStorage.getItem("e2e-reporter-theme");
    if (saved === "dark" || saved === "light") { root.setAttribute("data-theme", saved); }
  } catch (e) {}
  document.querySelectorAll(".theme-toggle").forEach(function (button) {
    button.addEventListener("click", function () {
      var next = root.getAttribute("data-theme") === "dark" ? "light" : "dark";
      root.setAttribute("data-theme", next);
      try { localStorage.setItem("e2e-reporter-theme", next); } catch (e) {}
    });
  });
})();

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
  // without moving the rows under it — a control lying about what it did.
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

// The scenario table's filter, sort and pagination: three behaviours over the
// rows the page already carries, so the table works with the file opened
// straight off disk and the page still ships no libraries.
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

  // How a chart hands its selection to the table.
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
//
// The chart links are SVG `<a>` elements, whose tagName keeps its case, so
// the check is case-insensitive.
document.querySelectorAll("[data-result]").forEach(function (target) {
  if (String(target.tagName).toLowerCase() !== "a") { return; }
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

// Both tables that show the epic → feature tree fold by epic. Two things hide
// a row here, folding and filtering, and they are independent, so neither
// writes `hidden` directly: each records its own reason and the row stays
// hidden while any reason stands.
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
// capture. It opens over everything at its own size, and it closes the three
// ways a dialog closes.
var shotViewer = (function () {
  var box = document.querySelector(".lightbox");
  if (!box) { return null; }
  var full = box.querySelector(".lightbox-image");
  var caption = box.querySelector(".lightbox-caption");
  var close = box.querySelector(".lightbox-close");
  var previous = box.querySelector(".lightbox-prev");
  var next = box.querySelector(".lightbox-next");
  var opener = null;
  var reel = [];
  var at = -1;

  function captionOf(image) {
    var slide = image.closest(".slide");
    var figcaption = slide ? slide.querySelector("figcaption") : null;
    if (figcaption) { return figcaption.textContent; }
    var row = image.closest("tr");
    var step = row ? row.querySelector(".step-text") : null;
    return step ? step.textContent : image.getAttribute("alt") || "";
  }

  function show(index) {
    var image = reel[index];
    if (!image) { return; }
    at = index;
    opener = image;
    full.src = image.getAttribute("src");
    full.alt = image.getAttribute("alt") || "";
    var where = reel.length > 1
      ? " (" + (index + 1) + " of " + reel.length + ")"
      : "";
    caption.textContent = captionOf(image) + where;
    var many = reel.length > 1;
    previous.hidden = !many;
    next.hidden = !many;
  }

  function step(by) {
    if (reel.length < 2) { return; }
    show((at + by + reel.length) % reel.length);
  }

  function open(image) {
    var index = reel.indexOf(image);
    show(index < 0 ? 0 : index);
    box.hidden = false;
    document.body.classList.add("viewing-shot");
    close.focus();
  }

  function load(images) { reel = images; }

  function closeShot() {
    box.hidden = true;
    document.body.classList.remove("viewing-shot");
    if (opener) { opener.focus({ preventScroll: true }); opener = null; }
  }

  close.addEventListener("click", closeShot);
  previous.addEventListener("click", function () { step(-1); });
  next.addEventListener("click", function () { step(1); });
  box.addEventListener("click", function (event) {
    if (event.target === box || event.target === caption) { closeShot(); }
  });
  document.addEventListener("keydown", function (event) {
    if (box.hidden) { return; }
    if (event.key === "Escape") { closeShot(); }
    if (event.key === "ArrowLeft") { event.preventDefault(); step(-1); }
    if (event.key === "ArrowRight") { event.preventDefault(); step(1); }
  });

  return {
    open: open,
    load: load,
    close: closeShot,
    isOpen: function () { return !box.hidden; }
  };
})();

if (shotViewer) {
  shotViewer.load(Array.prototype.slice.call(
    document.querySelectorAll(".slides img, a.shot-link img")
  ));
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

  var requested = new URLSearchParams(window.location.search).get("screenshot");
  show(parseInt(requested, 10) || 0);

  document.addEventListener("keydown", function (event) {
    if (!shotViewer || !shotViewer.isOpen()) { return; }
    if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
      var image = slides[current].querySelector("img");
      if (image) { shotViewer.open(image); }
    }
  });
});
''';
