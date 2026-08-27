# Prompt para trasplantar el framework E2E a otro proyecto

Copia todo lo que hay bajo la línea y pégalo como primer mensaje en una
sesión de Claude Code abierta sobre el proyecto destino.

Antes de pegarlo, rellena los tres datos entre `«»` del primer bloque. Si no
los sabes todavía, déjalos y el modelo te preguntará.

---

Vas a trasplantar a este proyecto un framework de pruebas E2E que ya existe y
está probado en otro repositorio. **No lo estás inventando: lo estás
replicando**, y este mensaje trae tanto la arquitectura como la lista de
trampas que ya costaron tiempo allá. Léelas antes de escribir la primera
línea; casi todas son silenciosas —no fallan con un error claro, sino con
cero tests, un verde falso o un cuelgue de cuarenta minutos.

## Datos de este proyecto

- App bajo prueba: «nombre del paquete Flutter, p. ej. packages/apps/mi_app»
- Identificador Android: «com.empresa.mi_app»
- Idioma de la app y locale a fijar: «es-ES, America/Bogota»

Si el proyecto no es un monorepo con melos, dilo antes de empezar: el
framework funciona igual, pero la ubicación de los paquetes y los scripts
cambian, y conviene acordarlo primero.

## Qué vas a construir

Cuatro capas, cada una con un trabajo y sólo uno:

```
patrol_test/scenarios/*_test.dart   El TEST: nombra el caso, es dueño de los datos
        ↓
patrol_test/steps/*.dart            El STEP: ejecuta y aserta lo que recibe
        ↓
patrol_test/pages/*.dart            El PAGE: sabe dónde está cada cosa en la pantalla
        ↓
patrol_kit (paquete)                El KIT: aserciones, capturas, marcadores, datos
        ↓
e2e_test_reporter (paquete)              Lee los marcadores y escribe un sitio HTML
```

Reglas de capa, que no son estéticas —cada una nació de un problema real:

- **El test es dueño de los datos.** Lee su registro dentro del cuerpo y lo
  pasa hacia abajo. Un step que busca sus propios datos esconde la mitad del
  escenario del archivo que dice definirlo.
- **El step ejecuta y aserta lo que le entregan.** Nunca lee la fuente de
  datos.
- **El page compone las interacciones de SU pantalla** (un `login()` hecho de
  sus propios campos y su botón) pero no aserta reglas de negocio ni cruza a
  otra pantalla.

## Qué se trae y qué no

**Se trae completo, tal cual** (son genéricos, no saben nada de la app):

- `patrol_kit/` — el paquete del framework: `assert_d.dart`,
  `assert_d_extensions.dart`, `assert_report.dart`, `base_page.dart`, `base_steps.dart`,
  `consequence.dart`, `element.dart`, `failure_report.dart`, `locator.dart`,
  `log.dart`, `money.dart`, `scenario.dart`, `screenshot.dart`, `tags.dart`,
  `taxonomy.dart`, `test_data.dart`, `widget_probes.dart` **y sus tests**.
- `e2e_test_reporter/` — el generador del reporte, con `bin/`, `lib/src/site/` y
  **sus tests**.
- `tool/e2e/` — `run_web.sh`, `run_android.sh`, `run_ios.sh`, `clean.sh`,
  `open_report.sh`, `watch_web.sh`, `.nvmrc`.
- Los workflows de CI y los scripts de melos.

**No se trae. Se escribe de cero para esta app:**

- `patrol_test/pages/` — los page objects.
- `patrol_test/steps/` — los steps de negocio.
- `patrol_test/scenarios/` — los escenarios.
- `patrol_test/data/` — los datos de prueba en JSON, con su `index.json`.
- `patrol_test/support/` — el lanzador de la app, y el vocabulario de
  `Features` y `Epics` de ESTE producto.
- `test/patrol_guards/` — las guardas (ver la trampa 8; el patrón se replica,
  el contenido es de esta app).

**Los tests de los dos paquetes viajan con ellos.** No son opcionales: son la
prueba de que el trasplante quedó bien, y varios de ellos existen justamente
para fijar una de las trampas de abajo.

---

# Las trampas ya pagadas

Cada una ocurrió de verdad. La causa está establecida leyendo el código
fuente del SDK o del CLI, no adivinada.

## Build y ejecución

**1 · El build debug cuelga la suite web. Constrúyela en `--profile`.**
Debug en Flutter web significa DDC: un módulo JS por librería Dart —más de
mil— servidos de a uno. Cada test de Patrol hace `page.goto("/")` en un
contexto de navegador nuevo, o sea con la caché vacía, así que **cada test
vuelve a bajar los mil**. Ese `goto` vive dentro del fixture `page` de Patrol
sin timeout propio, así que se come el timeout entero del test.

Síntoma: pasan uno o dos tests y el resto agota su timeout en silencio;
corridas de cuarenta minutos, intermitentes —en una máquina rápida entra, en
un runner lento no—. No hay commit culpable que revertir.

Regla: `--profile` por defecto en el script, `--debug` como flag para
investigaciones puntuales.

**2 · En profile, `enterText` escribe en el vacío sin avisar.**
`integration_test` nunca registra el teclado simulado, así que `enterText`
publica su valor al cliente `-1`. El framework acepta ese `-1`
**sólo dentro de un `assert`** (*"in debug builds we allow -1 as a magical
client ID"*). En debug el texto entra; en profile los asserts se compilan
fuera y el mensaje se descarta: `enterText` reporta éxito y el campo queda
vacío.

Regla: antes de escribir, en web, registra el mock —
`$.tester.testTextInput.register()`. `patrol_finders` ya lo hace, pero con
`if (!kIsWeb)`, que es justo el hueco.

**3 · Fija el locale y la zona horaria, o la app no arranca.**
Un navegador headless recién creado puede no reportar idioma, y el motor de
Flutter lanza `Invalid argument: Incorrect locale information provided`
**antes de pintar un frame**. La app nunca arranca y la corrida reporta
**cero tests**, no un fallo.

Regla: `--web-locale=«es-ES» --web-timezone=«America/Bogota»` siempre.

**4 · Rutas absolutas para los directorios de resultados.**
`--web-report-dir` y `--web-results-dir` llegan al `playwright.config.ts` que
Patrol trae, y Playwright resuelve una ruta relativa **contra el directorio
de SU config** — dentro del paquete en la caché de pub, no contra donde estás.
Una ruta relativa escribe los resultados dentro de la caché.

**5 · Todo lanzamiento pasa por el script. Sin excepciones.**
Allá el paso de CI que diagnosticaba un fallo escribía su propio
`patrol test`, sin los flags de locale — y entonces reportó el crash del
locale como causa de cuatro tests que en realidad habían agotado su timeout.
Un diagnóstico que miente cuesta más que no tenerlo.

**6 · Baja el timeout por test.** El de Patrol son diez minutos. Medido
contra una suite real eso no es un límite, es una eternidad: una corrida con
cuatro tests colgados costaba cuarenta minutos para decir lo que dos habrían
dicho. `PATROL_WEB_TIMEOUT=120000`.

**7 · El runner de Android debe leer sus argumentos en bucle, no por
posición.** Si lee "primero el serial, luego los flags", un `--tags=smoke`
se toma por serial y falla minutos después en palabras de adb.

## Datos de prueba

**8 · Los datos viven en el asset bundle, que no existe hasta que la app
arranca.** Nada puede leerlos antes de lanzarla — y la forma natural de
escribir un test pone los metadatos primero, que es justo donde está la
tentación:

```dart
e2eTest('…', ($) async {
  testParam('Usuario', TestData.demoEmail);   // ← todavía no hay datos
  await launchApp($);
});
```

Ese error costó cuatro minutos de CI y cuatro tests rojos por plataforma.

Regla: escribe una guarda que **lea el código fuente** de los escenarios y
falle si ve un acceso a los datos antes del lanzamiento. Corre en
`flutter test`, sin navegador, en un segundo. Ponla bajo `test/`, **no** bajo
el directorio de Patrol: `flutter test` sólo mira en `test/`, y `patrol test`
se llevaría la guarda al dispositivo.

**9 · La guarda debe recorrer en profundidad.** `patrol_cli` busca
`*_test.dart` con `listSync(recursive: true)`. Una guarda que no recorra
subcarpetas deja de vigilar en cuanto alguien agrupa los escenarios — pasó,
y la guarda se pilló a sí misma en la mudanza.

**10 · Los archivos de datos con clave, no como lista.** Una lista entrega
filas por posición, que es exactamente como una fila insertada arriba
re-apunta en silencio todos los tests de abajo.

## El reporte y sus marcadores

**11 · `debugPrintSynchronously`, nunca `debugPrint`.** Las capturas viajan
al runner como base64 por la consola, en trozos. `debugPrint` limita a ~1 KB/s
y **descarta el resto en silencio**, lo que despedaza la imagen.

**12 · Las marcas de tiempo de Patrol no llevan zona.** Vienen de
`DateTime.now().toIso8601String()`. Las del transporte (el `startTime` de
Playwright) sí son UTC y lo dicen con `Z`. Leer una marca sin zona como UTC
desplaza el reporte —cinco horas, en el caso de allá— y además hace el
resultado dependiente de la máquina.

Regla: una marca sin zona pertenece a la zona en que está fijado el reporte.

**13 · Nunca metas una contraseña en el nombre de un step.** Los nombres de
step se publican: van por el flujo de marcadores al HTML, que CI sube y
GitHub Pages sirve.

**14 · La foto automática al terminar un step fotografía la pantalla
equivocada.** Un step que termina navegando —un login que envía el
formulario— fotografía el **destino**, no su trabajo; y el siguiente step
fotografía lo mismo. Dos imágenes idénticas, y el formulario diligenciado
—lo que uno abre el reporte a ver— no se captura nunca.

Regla: por defecto no capturar mientras el step va bien, y sí al fallar
—esa es la única que nadie puede colocar de antemano—. El resto lo pone quien
escribe el step, en el momento que elige.

## Calidad de los tests

**15 · El verde falso.** Un test que sólo aserta el estado negativo —"el
botón está deshabilitado"— pasa igual cuando la app está muerta, porque un
botón deshabilitado es también lo que muestra una app que no recibió nada.
Allá fue el único test que "pasó" en una corrida donde la escritura no
llegaba.

Regla: si asertas que algo está bloqueado, aserta también que **se desbloquea**
con datos válidos. Sin ese contraste el test no distingue "la validación
funciona" de "no llegó nada".

**16 · Un test por caso.** Tres rechazos en un bucle dentro de un test dan
una fila en el reporte y un rojo que nombra el bucle. Separados, cada uno
tiene su nombre, su fila y su foto.

## CI

**17 · Pon techo de tiempo al job y a los pasos que pueden colgarse.** Allá un
`npx playwright install` —un paso de cuarenta segundos— se quedó **tres horas
y cuarenta y ocho minutos** porque un mirror de apt dejó de responder. El
default de GitHub lo habría dejado seis horas.

**18 · El reporte se construye aunque la suite falle** —que es justo cuando
alguien lo va a abrir— **pero el comando sale rojo igual.** Guarda el código
de salida de la suite, construye el reporte pase lo que pase, y sal con el
guardado. No encadenes con `&&`.

**19 · Cuenta las aserciones en el resumen del job.** Una suite verde no es lo
mismo que una suite que verificó algo: si el flujo de marcadores se rompe, los
tests siguen pasando y el reporte queda vacío. El fallo es silencioso, así que
hay que hacerlo visible.

## Entorno y herramientas

**20 · Nada de `read -t` en los scripts.** macOS trae bash 3.2, donde el
timeout de `read` es indistinguible del fin de archivo. Un vigilante escrito
así mató una corrida sana con SIGPIPE a los dieciocho segundos.

**21 · `dart format . --line-length 80` desde dentro del paquete**, no desde
la raíz.

**22 · melos 7 lee su configuración del `pubspec.yaml` raíz**, no de un
`melos.yaml`.

## Marcas y licencias

**23 · El sitio generado no pide nada a la red.** Ni librerías, ni fuentes, ni
CDNs: gráficas con CSS puro y JS escrito a mano. Escribe un test permanente
que aserte que ninguna página contiene una URL externa — es la clase de cosa
que se rompe sin que nadie se entere.

**24 · Ningún logo de fabricante.** El robot de Android está bajo CC BY (exige
atribución); el logo de Apple está expresamente prohibido a terceros. Si
quieres un icono por plataforma, dibuja glifos neutros de dispositivo: una
ventana de navegador, un teléfono de esquinas cuadradas, uno con notch.

**25 · Si te inspiras en el diseño de otra herramienta, copia hechos, no
archivos.** Estructura y apariencia son hechos; los archivos no. Que el
repositorio no lleve nombres ni marcas ajenas en ninguna parte.

---

# Orden de trabajo

Hazlo por fases y **verifica cada una antes de seguir**. Al terminar cada
fase, dime qué quedó y qué comprobaste.

1. **El kit.** Copia `patrol_kit` con sus tests. `flutter test` verde antes de
   tocar nada más.
2. **El reporteador.** Copia `e2e_test_reporter` con sus tests. `dart test` verde.
   Genera un reporte de muestra desde los fixtures y ábrelo.
3. **Los scripts y melos.** `run_web.sh`, `run_android.sh`, `clean.sh`,
   `open_report.sh`, `watch_web.sh` y los scripts de melos. Ajusta las rutas.
4. **Un escenario mínimo de esta app** — que la app arranque y se vea la
   primera pantalla. Nada más. Corre la suite web: si aquí sale bien, las
   trampas 1 a 6 están resueltas.
5. **Las guardas** bajo `test/patrol_guards/`.
6. **El resto de escenarios**, capa por capa: page, step, escenario.
7. **CI**: los workflows, con sus techos de tiempo y el resumen de
   aserciones.

# Cómo verificar

```sh
melos run lint          # o flutter analyze
melos run testFast      # tests del kit y guardas, sin navegador
melos run e2eWeb        # la suite y el reporte
melos run openReportWeb    # abrir el reporte
```

El reporte debe mostrar: los escenarios con su veredicto, los steps
anidados, las aserciones contadas, las capturas donde las pediste, y el árbol
de features. Si algo de eso sale vacío, el flujo de marcadores está roto —
mira la trampa 11 antes que nada.

# Convenciones

- Código, nombres y comentarios **en inglés**. Los textos que salen en el
  reporte —nombres de escenario, steps, aserciones— en el idioma del equipo.
- Versiones **fijadas exactas** en los pubspec.
- Comenta el *por qué*, no el *qué*. Cada regla de arriba merece una línea
  donde alguien la rompería.

# Lo que NO debes hacer

- No inventes una arquitectura nueva: replica la de las cuatro capas.
- No te saltes los tests de los dos paquetes por ir más rápido. Son la
  prueba del trasplante.
- No pongas la suite en debug "porque es lo normal". Lee la trampa 1.
- No escribas un `patrol test` a mano fuera del script.
- No copies archivos de otras herramientas ni logos de fabricantes.
- No des una fase por buena sin correrla.
