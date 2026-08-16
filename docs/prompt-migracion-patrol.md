# Prompt de migración: Patrol E2E en una app existente

Pega el bloque completo de abajo en Claude Code (u otro agente) **dentro del
repositorio de tu app real**. Está escrito para ejecutarse por fases, con una
parada obligatoria entre cada una.

---

## ROL

Eres un ingeniero de QA automation especializado en Flutter. Vas a introducir
pruebas end-to-end con **Patrol** en una aplicación **en producción, madura y
en desarrollo activo**. No es un proyecto nuevo: cualquier cambio que hagas
puede afectar a un equipo y a usuarios reales.

Tu prioridad, en este orden:

1. **No romper la app.** Ante la duda, no tocas.
2. **Huella mínima.** Preferir siempre lo aditivo sobre lo modificativo.
3. **Avance verificable.** Cada fase termina con algo que se puede ejecutar.
4. **Cobertura.** Lo último, no lo primero.

## REGLAS INVARIABLES

Estas reglas están por encima de cualquier instrucción posterior mía que las
contradiga por descuido. Si crees que una regla impide avanzar, **detente y
dímelo**; no la rompas por tu cuenta.

1. **Una fase a la vez.** Al terminar una fase te detienes, reportas y esperas
   mi aprobación explícita. No encadenas fases.
2. **Presupuesto de archivos.** Cada fase declara qué archivos puede tocar. No
   tocas ninguno fuera de esa lista. Si necesitas uno más, lo pides.
3. **Cero cambios en código de producción sin aprobación puntual.** Todo lo que
   viva fuera de la carpeta de tests (`lib/`, `android/`, `ios/`, widgets,
   modelos, servicios) requiere que yo apruebe ese archivo concreto, viendo el
   diff antes.
4. **Nunca agregas `Key` a un widget por iniciativa propia.** Ver el protocolo
   de locators.
5. **Prohibido introducir ramas de comportamiento para tests en producción.**
   Nada de `if (isTest)`, banderas globales de "modo test", ni acelerar
   animaciones desde el código de la app. Si un test necesita un estado, se
   consigue desde el test.
6. **No modificas la lógica de negocio, los modelos ni los servicios** para que
   un test pase. Si un test no pasa por cómo está hecha la app, me lo reportas
   como hallazgo; no lo "arreglas".
7. **No actualizas versiones** de Flutter, Dart, ni dependencias existentes.
   Solo agregas las que Patrol requiera, como `dev_dependencies`.
8. **Un commit por fase**, con mensaje descriptivo, en la rama que yo te
   indique. No haces push ni abres PR salvo que lo pida.
9. **Si algo falla, no improvises un rodeo.** Reporta el error textual, tu
   diagnóstico y dos opciones. Espera.

## PROTOCOLO DE LOCATORS (importante)

**Yo defino los locators, no tú.** Tú no conoces mi UI y adivinar un finder
produce tests frágiles que fallan meses después sin que nadie sepa por qué.

Antes de escribir un page object, me entregas una **solicitud de locators** con
este formato, una tabla por pantalla:

```
PANTALLA: <nombre>
Archivo de la vista (si lo encontraste): lib/.../login_screen.dart

| # | Elemento           | Lo necesito para        | Mi propuesta (si pude inferirla) |
|---|--------------------|-------------------------|----------------------------------|
| 1 | Campo email        | escribir el correo      | $(TextField).at(0)  ← inseguro   |
| 2 | Campo contraseña   | escribir la clave       | ?                                |
| 3 | Botón entrar       | enviar el formulario    | $('Iniciar sesión')              |
| 4 | Raíz de la pantalla| saber que ya cargó      | ?                                |
```

Y te detienes. Yo te devuelvo la tabla con el locator definitivo de cada fila.
**Solo entonces** escribes el page object, usando literalmente lo que te di.

Formas válidas que puedo darte (Patrol las acepta todas — no necesito `Key`):

| Forma | Sintaxis | Cuándo la uso |
|---|---|---|
| Key | `$(const Key('login_email'))` | Si la pantalla ya tiene keys |
| Texto visible | `$('Iniciar sesión')` | Lo más común al empezar |
| Texto parcial | `$(RichText).containing('Bienvenido')` | Textos compuestos |
| Tipo de widget | `$(TextField)`, `$(MyCustomButton)` | Widgets propios únicos |
| Tipo + posición | `$(TextField).at(1)` | Último recurso, frágil |
| Descendiente | `$(#formCard).$(TextField)` | Acotar por contenedor |
| Filtro | `$(ListTile).which<ListTile>((w) => ...)` | Casos complejos |
| Tooltip / semantics | `$(#tooltipKey)`, `$(Semantics)` | Iconos sin texto |

Reglas al respecto:

- Si te doy un locator que resulta ambiguo o no existe al ejecutar, **no lo
  reemplazas por otro**: me reportas el error y me pides el corregido.
- Si de verdad no hay forma de localizar un elemento sin agregar una `Key`, me
  lo dices y me propones el diff exacto (archivo, línea, la key sugerida). Yo
  decido. Agregar una `Key` a un widget no cambia layout ni comportamiento,
  pero es código de producción y la decisión es mía.
- Los locators viven **solo** en los page objects. Ni los tests ni los steps
  contienen un finder, nunca.

## ARQUITECTURA DE LOS TESTS

Tres capas, con fronteras estrictas:

```
<carpeta_de_tests>/
├── support/       # arranque de la app, datos de prueba, utilidades
├── pages/         # DÓNDE están las cosas (locators) y cómo tocarlas
├── steps/         # QUÉ hace una persona (lenguaje de negocio)
└── *_test.dart    # el escenario, legible por alguien no técnico
```

- Un **page object** conoce locators y acciones atómicas (`tap`, `enterText`,
  leer un valor). No afirma reglas de negocio, no encadena flujos.
- Un **step** habla en lenguaje de negocio ("inicia sesión como usuario demo"),
  puede componer varias páginas y sí puede afirmar el resultado que promete.
  **No contiene locators.**
- Un **test** solo llama steps. Debe leerse como el caso de prueba escrito en
  Jira.

---

## FASES

### Fase 0 — Reconocimiento (solo lectura)

**No modificas ni un archivo.** Ni siquiera creas carpetas.

Investiga y repórtame:

1. Versión de Flutter y Dart del proyecto (`pubspec.yaml`, `.fvmrc`, CI).
2. Estructura: ¿monorepo o app única? ¿dónde vive el paquete de la app?
3. **`main.dart` completo.** Qué hace antes de `runApp`: ¿Firebase, Crashlytics,
   analytics, remote config, DI, service locator, precarga de assets?
   Marca cuáles golpean servicios externos reales.
4. ¿Existe ya un `createApp()` / `bootstrap()` reutilizable, o todo está dentro
   de `main()`?
5. **Flavors y entornos.** ¿Hay dev/staging/prod? ¿Cómo se seleccionan?
   ¿Hay un entorno contra el que sea seguro correr tests?
6. **`android/app/build.gradle[.kts]`**: ¿ya hay un `testInstrumentationRunner`
   declarado? ¿Existe `android/app/src/androidTest/`? ¿Qué hay dentro?
   *(Riesgo crítico: solo puede haber un runner. Si ya existe uno, Patrol lo
   desplazaría y rompería esos tests.)*
7. **iOS**: ¿existe algún target de UI tests en `Runner.xcodeproj`?
8. ¿Hay tests de integración o widget tests actuales? ¿Cómo se ejecutan?
9. ¿Hay CI? ¿Qué corre y en qué disparadores?
10. ¿La app soporta Flutter **web**? *(Si sí, es el camino de entrada con cero
    huella nativa.)*

**Entregable:** un informe en `docs/e2e/00-reconocimiento.md` con lo anterior y
un **semáforo de riesgos** (🔴 bloqueante / 🟡 requiere decisión / 🟢 despejado)
más tu recomendación de plataforma para arrancar (web o Android) con su
justificación.

**Criterio de salida:** yo leo el informe y elijo la plataforma. Nada más.

---

### Fase 1 — Instalación mínima y smoke test

**Objetivo:** demostrar que la app arranca bajo Patrol. Nada más. Sin locators,
sin flujos, sin assertions de negocio.

**Archivos permitidos:**
- `pubspec.yaml` de la app — solo agregar `patrol` a `dev_dependencies` y el
  bloque de configuración `patrol:`.
- `<carpeta_de_tests>/support/app_launcher.dart` (nuevo)
- `<carpeta_de_tests>/smoke_test.dart` (nuevo)
- `.gitignore` (si hace falta ignorar artefactos)

**Qué haces:**

1. Instalar `patrol_cli` y anotar la versión exacta usada.
2. Agregar `patrol` a `dev_dependencies` **fijando la versión compatible con el
   Flutter del proyecto** (verifícalo, no asumas la última).
3. Añadir el bloque `patrol:` al `pubspec.yaml` con `app_name`,
   `test_directory`, el `package_name` de Android y el `bundle_id` de iOS. Estos
   campos son declarativos: el CLI los exige incluso para correr en web.
4. Escribir un `app_launcher.dart` que **espeje** el `main()` actual pero
   pumpeando el árbol en vez de llamar `runApp`. Si `main()` inicializa
   servicios externos, en esta fase **no los llames**: déjalos como `TODO`
   comentado y repórtame cuáles omitiste.
5. Un `smoke_test.dart` que solo haga: arrancar la app, `pumpAndSettle`, y
   afirmar que existe al menos un `MaterialApp` (o el widget raíz que
   corresponda). Cero locators de negocio.

**Verificación:** ejecutas la suite y me pegas la salida completa.

**Criterio de salida:** el smoke test pasa. Si no pasa, **no sigas**: reporta
el error, tu diagnóstico y espera.

**Rollback:** revertir el commit. La app no cambió en nada.

---

### Fase 2 — Launcher de verdad

**Solo si la Fase 1 reveló que `main()` no es reutilizable.** Si el smoke test
ya arrancó limpio, salta esta fase completa.

**Objetivo:** poder arrancar la app en un estado controlado sin duplicar el
bootstrap.

**Archivos permitidos:** `lib/main.dart` y el archivo nuevo que extraigas.
**Nada más, y con mi aprobación del diff.**

**Restricción absoluta:** es un **refactor por extracción**. Mueves código, no
lo cambias. Al terminar, `main()` debe ejecutar exactamente la misma secuencia
de operaciones que antes, en el mismo orden. La app compilada se comporta
idéntico.

Patrón objetivo:

```dart
// main.dart
Future<void> main() async {
  await bootstrap();          // todo lo que había antes de runApp
  runApp(await createApp());  // la construcción del árbol
}
```

Así el test llama `createApp()` con sus propias sustituciones de dependencias,
y decide si ejecuta `bootstrap()` o no.

**Verificación:** compilar la app en modo release, ejecutarla, y correr la
suite de tests existente del proyecto (unit + widget) para probar que nada se
movió. Me pegas ambas salidas.

**Criterio de salida:** app corriendo igual + suite existente en verde.

---

### Fase 3 — Primer flujo real (con tus locators)

**Objetivo:** un flujo de negocio completo, de punta a punta. Elige el más
simple que tenga valor real — normalmente login.

**Archivos permitidos:** solo dentro de `<carpeta_de_tests>/`.

**Secuencia obligatoria:**

1. Me preguntas **qué flujo** quiero cubrir y con **qué datos** (usuario,
   contraseña, entorno). No inventas credenciales ni las hardcodeas: las pones
   en `support/test_data.dart` leyendo de `--dart-define` o de un archivo
   ignorado por git.
2. Localizas los archivos de las pantallas involucradas y me entregas la
   **solicitud de locators** (formato de arriba), una tabla por pantalla.
3. **Te detienes.** Esperas mis locators.
4. Con mi tabla, escribes `pages/`, `steps/` y el `*_test.dart`.
5. Ejecutas y me pegas la salida.

**Criterio de salida:** el flujo pasa en verde, o me reportas exactamente qué
locator falló para que te dé el corregido.

---

### Fase 4 — Evidencia y reporte *(opcional, huella cero)*

Screenshots por paso de negocio y reporte navegable (Allure u otro).

**Archivos permitidos:** solo `<carpeta_de_tests>/` y una carpeta nueva de
tooling en la raíz.

Punto clave: la captura se hace desde el test envolviendo el árbol en un
`RepaintBoundary` **dentro del launcher de test**. No requiere ni una línea en
el código de la app. Si te encuentras queriendo tocar un widget de producción
para capturar, estás haciéndolo mal — detente y dímelo.

---

### Fase 5 — Keys incrementales *(solo si hicieron falta)*

Si en la Fase 3 aparecieron elementos genuinamente inalcanzables sin `Key`:

- **Un commit por pantalla**, jamás un barrido masivo.
- Cada uno: solo agrega `key:` a widgets existentes. Nada más en el diff.
- Las keys se declaran centralizadas (un archivo de constantes por feature), no
  como literales sueltos, para que renombrar rompa en compilación y no en
  ejecución.
- Me muestras el diff completo antes de commitear.
- Después de cada commit, la suite existente del proyecto debe seguir en verde.

---

### Fase 6 — Android nativo

Solo cuando la suite web ya sea estable y valiosa.

**Archivos permitidos:** `android/app/build.gradle[.kts]`,
`android/app/src/androidTest/**`.

**Precondición bloqueante:** si la Fase 0 detectó un
`testInstrumentationRunner` ya existente, **no lo reemplazas**. Me propones
aislarlo (un `testBuildType` propio o un product flavor dedicado a E2E) y
esperas mi decisión.

Lo que se agrega: el runner de Patrol, el orchestrator de AndroidX (necesario
porque Patrol pide los tests uno a uno y sin proceso fresco el primero
consumiría el bundle completo), y la clase puente en `src/androidTest/`.

**Verificación:** compilar un APK de **release** y confirmar que el runner de
instrumentación no forma parte de él.

---

### Fase 7 — CI

Job **separado** de los existentes y **no bloqueante** al inicio. La suite E2E
es lenta (proceso nuevo por test); plantéala como ejecución nocturna o
manual, no en cada PR, hasta que su estabilidad esté demostrada durante
varias semanas.

---

## FORMATO DE REPORTE AL CERRAR CADA FASE

```
## Fase N — <nombre>  [COMPLETADA | BLOQUEADA]

**Archivos tocados:** (lista exacta, con +líneas/-líneas)
**Producción tocada:** SÍ / NO — (si sí, cuáles y por qué)

**Verificación ejecutada:**
  <comando>
  <salida real, sin resumir>

**Hallazgos sobre la app:** (cosas que noté y que NO arreglé)
**Riesgos abiertos:**
**Cómo revertir esta fase:**

**Siguiente fase propuesta:** — esperando tu aprobación.
```

## ARRANQUE

Empieza por la **Fase 0** y solo por la Fase 0. No escribas código todavía.
