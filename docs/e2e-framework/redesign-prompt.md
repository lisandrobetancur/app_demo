# Prompt para aplicar el rediseño "Corporate Clean" del reporte en otro proyecto

Para un proyecto que ya recibió el framework E2E de este repositorio (vía
`transplant-prompt.md`) y por tanto tiene el **mismo diseño anterior** del
reporte: banner con tile navy, donut en `conic-gradient`, barras en flexbox,
tabs en cajas.

Copia todo lo que hay bajo la línea y pégalo como primer mensaje en una sesión
de Claude Code abierta sobre el proyecto destino. Antes de pegarlo rellena el
dato entre `«»`.

---

Vas a aplicar a este proyecto el rediseño del dashboard del **E2E Test
Reporter** que ya está hecho, revisado y mergeado en el repositorio de
referencia. No es un rediseño nuevo: es un **transplante de un cambio
conocido**, con sus decisiones ya tomadas y sus trampas ya pagadas. Tu trabajo
es traerlo entero, no reinterpretarlo.

## Datos de este proyecto

- Ruta del paquete del reporter aquí: `«packages/e2e_framework/e2e_test_reporter»`
- Fuente de verdad del cambio: el PR **#42** de `lisandrobetancur/app_demo`
  (https://github.com/lisandrobetancur/app_demo/pull/42). Trae el diff con
  `gh pr diff 42` o desde la pestaña *Files changed*. Es público.

## Qué es el cambio, en una frase

Solo presentación. **Ningún dato ni lógica cambia**: los mismos marcadores
producen las mismas cifras, las mismas gráficas leen los mismos números y
llevan a la misma tabla. Lo que cambia es cómo está construida la página:
un sistema de tokens, un header de 56px, breadcrumb con chevron, tabs
subrayadas y un control segmentado, KPIs con icono, gráficas en SVG a escala,
modo oscuro por interruptor, e impresión sin chrome.

## Restricciones que no se negocian

Son las del proyecto de referencia y se heredan tal cual:

1. **El reporte generado es autocontenido.** Ninguna URL externa en ningún
   archivo que el generador escriba. Hay tests permanentes que lo afirman
   (`isNot(contains('https://'))` en las cinco páginas). Por eso las fuentes
   se **declaran** (`"Inter", -apple-system, …`) y **nunca se descargan**: un
   `<link>` a Google Fonts rompe los tests y la promesa.
2. **Sin librería de iconos.** Los iconos son un sprite SVG dibujado para el
   reporte (retícula 24px, trazo 1.75). Copiar los paths de una librería mete
   un aviso de licencia en cada reporte generado. Si te tienta "poner Lucide",
   no.
3. **Sin marcas ajenas.** Los glifos de plataforma son dispositivos genéricos,
   no logos.
4. **La paleta de las gráficas ya está validada** (separación bajo
   daltonismo y visión normal, en claro y oscuro). No la "mejores" a ojo. Si
   la cambias, pásala por un validador de paletas y muestra el resultado.
5. Sin identificadores de modelo en commits, PRs ni código.

## Qué se trae y cómo

### Se reemplazan íntegros (cópialos del diff)

| archivo | qué contiene |
|---|---|
| `lib/src/site/site_assets.dart` | tokens claro/oscuro, `resultColors` con `fill` (gráficas) y `solid` (texto, 4.5:1), `resultTokens`, favicon, marca, sprite de iconos, `icon()`, `siteCss` completo, `siteJs` |
| `lib/src/site/charts.dart` | donut, leyenda, barras e histograma en SVG; `durationBuckets` con etiquetas cortas; `niceAxis` |
| `lib/src/site/page_chrome.dart` | `banner()` con `generatedAt`, `breadcrumbs()` + `Crumb`, `menuBar()` solo tabs, footer, utilidades de hora sin cambios |

Antes de reemplazar `site_assets.dart`, **diffea el tuyo contra el de
referencia**: si tu proyecto añadió reglas CSS propias (una página extra, una
columna), tienes que llevarlas al nuevo archivo. El nuevo CSS conserva los
nombres viejos de tokens (`--title`, `--link`, `--muted`, `--rule`, `--page`,
`--card`, `--pass`, `--fail`…) como **alias** de los nuevos, justo para que
las reglas de las demás páginas sigan resolviendo sin reescribirlas.

### Se editan (aplica los hunks del diff)

- `lib/src/site/dashboard.dart`: `dashboardHtml` (breadcrumb + `topnav`,
  eyebrow sobre el `h2`, sin `<div class="card">` envolvente), `_runAgeNote`
  con icono, `_keyFigures` con `kpi-head` + icono y modificadores
  `good/bad/calm/time`, `_summaryBand` nuevo, `_tabBar` segmentado,
  `_chartHead`, `_summaryPane` con cada gráfica en su tarjeta, `_testsPane`
  con tarjetas, `_tagCloud` en tarjeta, `_keyStatisticsHead`.
- `features_page.dart`, `test_page.dart`, `screenshots_page.dart`,
  `tags_page.dart`: la llamada `banner(platform)` pasa a
  `banner(platform, generatedAt: generatedAt, offset: offset)` y el
  `<span class="breadcrumbs">…&gt;…</span>` pasa a `breadcrumbs(<Crumb>[…])`.
  Son cuatro archivos y seis sitios; no dejes ninguno con el formato viejo o
  esa página quedará sin sello de fecha.

### Tests que fijaban la presentación vieja

Van a fallar y **deben** cambiar, no borrarse. Lo que cada uno afirma ahora:

| test | antes | ahora |
|---|---|---|
| donut | `>50%</a>`, `donut-slice-label` ×2, `clip-path:polygon(` | `class="donut-center"`, `>50%</text>`, **ningún** `donut-slice-label`, `<a class="donut-wedge" href="#tests" data-result="SUCCESS" title="Passing: 1 of 2">` |
| leyenda | `Passing Test Cases (1)`, `Failed Test Cases</li>` | `Passing<span class="legend-count">1</span>`, `Failed<span class="legend-count">0</span></li>` |
| enlace de leyenda | `<li><a href="#tests" data-result="ERROR">` | `… data-result="ERROR" title="Broken: 1">` |
| buckets | `1 to 10 seconds`, `10 minutes or over` | `>&lt;1s</text>`, `>1–10s</text>`, `>&gt;10m</text>` |
| caption del histograma | `Number of tests per duration` | `Escenarios por rango de duración` |
| tokens | `--title: #0B2545`, `--link: #1d63c4` | `--brand: #1E3A8A`, `--text-primary: #0F172A`, fuentes declaradas, sin `@import` |
| breakpoints | 900 / 600 | **1024 / 640** |
| KPI con fallos | `isNot(contains('<div class="kpi good">'))` | el pass rate **siempre** lleva `good`; lo que cambia es `bad`/`calm` en *Needs attention* |
| breadcrumb (features_test) | `<a href="index.html">Home</a> &gt; Features` | `<a class="crumb" href="index.html">Home</a>` y `<span class="crumb">Features</span>`; en la página de feature `<a class="crumb" href="features.html">Features</a>` |
| `_tokenFor` | `var(--fail)` … | **igual** — los alias existen para esto |

Tests nuevos que conviene traer: banda resumen (`summary-band bad` con dos
escenarios al 50%), banda del más lento (`class="bar-fill slowest"`), barra
fantasma (`bar-ghost`), tokens en las gráficas (`stroke="var(--ch-pass)"`),
interruptor de tema, `@media print`.

## Trampas ya pagadas

1. **Los enlaces de las gráficas son `<a>` de SVG.** Su `tagName` conserva
   mayúsculas/minúsculas (`"a"`, no `"A"`). El JS que conecta gráfica → tabla
   compara `String(target.tagName).toLowerCase() !== "a"`. Si copias el JS
   viejo, los clics en el donut dejan de filtrar la tabla y nadie lo nota
   hasta que alguien lo prueba.
2. **`<1s` en un `<text>` de SVG es markup.** Viaja como `&lt;1s`; el test lo
   afirma con el escape. `charts.dart` trae `_escape()` para eso.
3. **El pass rate siempre es verde** (`kpi good`), por decisión de diseño. Un
   63% en verde lee raro; se dejó así a propósito y el test cambió. Si el
   dueño del proyecto prefiere condicionarlo, es una línea en `_keyFigures`.
4. **`resultColors.solid` lo usan otras páginas** (`_coverageBar` en
   `features_page.dart`, los iconos de resultado, las barras de título). Son
   tonos más oscuros que los de las gráficas porque tienen que sostener 4.5:1
   como texto. No los iguales a `fill`.
5. **El idioma quedó mezclado a propósito del spec original:** subtítulos de
   gráficas, eje y banda en español; el resto del reporte en inglés. Decide
   con el dueño del proyecto si unificas; son strings, no lógica.
6. **El sello de fecha conserva segundos** (`17:20:46`). Los tests de zona
   horaria lo afirman. Quitarlos es trivial, pero hazlo en el formateador y en
   los tests a la vez.
7. **El modo oscuro es solo por atributo** (`[data-theme="dark"]`), no por
   `prefers-color-scheme`: un reporte abierto desde disco no debe cambiar de
   cara según el sistema. El JS lo recuerda en `localStorage` con `try/catch`,
   porque `file://` puede negarlo.
8. **`dart format . --line-length 80` se corre dentro del paquete**, nunca
   desde la raíz.

## Cómo verificar

```sh
cd «packages/e2e_framework/e2e_test_reporter»
dart format . --line-length 80
flutter analyze --no-fatal-infos
flutter test                      # todos en verde, incluidos los de autocontención
```

Luego genera un reporte **desde un log real** (no un fixture) y ábrelo:

```sh
dart run e2e_test_reporter --input <log real> --format patrol-log --platform web --output /tmp/report
```

Mira tres páginas, no una: `index.html`, una página de feature y una página
de test. El sistema de tokens llega a las tres; si una quedó con el diseño
viejo, faltó un `banner()` o un breadcrumb. Prueba el interruptor sol/luna, la
pestaña *Test Results*, un clic sobre un segmento del donut (debe filtrar la
tabla) y la impresión (sin header ni tabs, tres gráficas en fila).

Cierra con el pipeline en verde: la autocontención se afirma en CI y es la
prueba de que no se coló ninguna URL.

## Lo que NO debes hacer

- Cargar Inter o JetBrains Mono desde una URL. Se declaran, no se descargan.
- Traer iconos de una librería. Dibújalos o copia el sprite.
- Rediseñar por tu cuenta lo que el diff ya decidió. Si algo no te convence,
  dilo y propón; no lo cambies en silencio.
- Borrar un test que falle por presentación. Se actualiza a lo que afirma
  ahora.
- Cambiar la paleta sin validador.
- Tocar `results_writer`, `markers`, `model` o `inputs`: no forman parte del
  cambio, y si el diff los toca en tu proyecto es que te equivocaste de rama.
