# Traspaso de contexto: llevar el E2E de esta POC a una app real

Este documento existe para que una sesión nueva —en otra cuenta, otro equipo u
otro momento— pueda retomar el trabajo sin volver a analizar nada. Es
autocontenido: leyéndolo se tiene todo lo que se concluyó al estudiar esta POC.

- **Repositorio de referencia (público):** https://github.com/lisandrobetancur/app_demo
- **Prompt de migración por fases:** [`docs/prompt-migracion-patrol.md`](./prompt-migracion-patrol.md)

## Cómo arrancar en otra cuenta

El repo es público, así que no hace falta transferir permisos ni exportar la
sesión. En la sesión nueva, **abierta sobre el repositorio de la app real**,
basta con:

```
Lee https://raw.githubusercontent.com/lisandrobetancur/app_demo/main/docs/e2e-handoff.md
y https://raw.githubusercontent.com/lisandrobetancur/app_demo/main/docs/prompt-migracion-patrol.md

Adopta el rol y las reglas del prompt, y empieza por la Fase 0 sobre ESTE
proyecto. Solo la Fase 0.
```

Si esa sesión no tiene salida a internet, hay dos alternativas: clonar el repo
de referencia dentro del entorno, o pegar el contenido del prompt a mano (es
autocontenido y no depende de leer esta POC).

## Qué es la POC de referencia

Marketplace de vehículos en Flutter, offline-first. Monorepo Melos con 36
paquetes bajo `packages/{apps,features,shared,ui,development}`. Corre en
Android, iOS y web desde un mismo shell. La suite E2E está hecha con **Patrol
4.6.1**, con reporte Allure y CI en GitHub Actions.

**No es una plantilla para copiar tal cual.** Es una POC construida sin
restricciones, donde se podía tocar cualquier archivo. Una app en producción
tiene restricciones distintas, y por eso lo importante del análisis siguiente
es la separación entre lo que Patrol **exige** y lo que esta POC simplemente
**eligió**.

## Archivos que vale la pena mirar

| Ruta | Qué enseña |
|---|---|
| `packages/apps/market_app/patrol_test/` | La suite completa: `pages/`, `steps/`, `support/`, tests |
| `patrol_test/pages/base_page.dart` | El contrato de la capa de páginas, documentado |
| `patrol_test/steps/auth_steps.dart` | Steps en lenguaje de negocio, sin locators |
| `patrol_test/support/app_launcher.dart` | Cómo se arranca la app dentro de un test |
| `patrol_test/support/screenshot.dart` | Captura por paso — **sin tocar la app** |
| `packages/apps/market_app/pubspec.yaml` | El bloque `patrol:` y la `dev_dependency` |
| `android/app/build.gradle.kts` | Runner + orchestrator, con el porqué comentado |
| `pubspec.yaml` (raíz) | Scripts Melos: `e2eWeb`, `e2eAndroid`, `allureWeb` |
| `tool/allure/`, `tool/e2e/` | Conversión a Allure y captura de logcat |
| `.github/workflows/e2e-*.yml` | CI de web y Android |

## Conclusión del análisis: huella real de Patrol

Esta es la parte que no se deduce leyendo el código, y la razón de ser de este
documento.

### Obligatorio (irreducible)

| Qué | Dónde | Impacto en el binario de producción |
|---|---|---|
| `patrol` en `dev_dependencies` + bloque `patrol:` | `pubspec.yaml` de la app | **Ninguno** — una `dev_dependency` no entra al release |
| Un launcher que pumpee el árbol en vez de `runApp` | archivo nuevo en la carpeta de tests | Ninguno |
| Android: `testInstrumentationRunner`, orchestrator, clase puente | `android/app/build.gradle`, `src/androidTest/` | Solo `androidTest`; no toca el APK de release |
| iOS: target `RunnerUITests` | `ios/Runner.xcodeproj` | Aditivo; no toca el target de la app |

**En web la huella nativa es exactamente cero:** Patrol maneja Chromium vía
Playwright, sin tocar `android/` ni `ios/`. Por eso web es el camino de entrada
recomendado en un proyecto que no se quiere arriesgar.

### Lo que esta POC tiene pero NO es necesario

Verificado en el código, no estimado:

- **`appBoundaryKey` (screenshots)** — vive al 100% en
  `patrol_test/support/screenshot.dart`. Huella en la app: cero. Se replica sin
  tocar nada.
- **`AppDurations.fastMode`** — *sí* es código de producción
  (`packages/ui/design_system/lib/src/tokens/app_durations.dart` +
  `main.dart:18`). Es la única pieza de la POC que añade una rama de
  comportamiento al binario real. **En una app madura, no replicarlo.**
  Alternativa: `timeDilation` desde el test, o aceptar un `pumpAndSettle` más
  lento.
- **`seedMode` / `fileName` en la base de datos** — app-side en la POC.
  Alternativa sin tocar producción: usar el DI que ya exista para sustituir el
  repositorio o el cliente HTTP desde el launcher del test.
- **Las ~90 `Key` centralizadas en los paquetes `*_constants`** — es lo más
  vistoso de la POC y **Patrol no las requiere**. Los finders aceptan texto,
  tipo de widget, descendientes y semantics. Agregar una `Key` no cambia
  layout, render ni comportamiento, pero es código de producción: debe ser una
  decisión explícita por widget, nunca un barrido masivo.

### Riesgos al llevarlo a una app en producción, en orden

1. **Colisión con `androidTest` existente.** Solo puede haber un
   `testInstrumentationRunner`. Si el proyecto ya tiene tests instrumentados
   (Espresso, o los de algún SDK), declarar el de Patrol los rompe. Es lo
   primero que hay que verificar. Mitigación: `testBuildType` o product flavor
   dedicado a E2E.
2. **`main()` no factorizado.** Aquí `main.dart` tiene 14 líneas y el launcher
   pudo espejarlo trivialmente. Una app madura suele traer `Firebase`,
   Crashlytics, remote config, analytics y DI dentro de `main()`. Hay que
   extraer un `bootstrap()` / `createApp()` reutilizable — **este es el trabajo
   real del proyecto**, y es un refactor mecánico y verificable.
3. **`project.pbxproj` en iOS.** Agregar el target genera conflictos de merge
   si hay varias ramas vivas. Rompe el repo, no la app.
4. **Tiempo de CI.** El orchestrator reinicia el proceso por cada test (el
   porqué está comentado en `android/app/build.gradle.kts`). Correcto pero
   lento: plantearlo como job nocturno o manual, no en cada PR.

### Lo que NO es viable

Un repositorio separado solo para los tests de Patrol, sin tocar la app.
Patrol no es black-box: el test **se compila dentro del binario** e importa el
código de la app (`app_launcher.dart` importa `package:market_app/…`,
`database`, `design_system`), el CLI se ejecuta desde el paquete de la app y lo
nativo vive en sus proyectos Android/iOS. Un repo externo tendría que clonar el
workspace completo igualmente.

Lo que sí se puede: extraer `pages/`, `steps/` y `support/` a un paquete
propio, dejando en la app solo los `*_test.dart` y el bloque `patrol:`. Para
cero contacto real haría falta una herramienta black-box (Maestro, Appium)
contra el binario ya compilado, perdiendo el acceso al árbol de widgets y al
control de estado que hace valioso a Patrol.

## Decisiones ya tomadas para la migración

Están codificadas en el prompt; se listan aquí para que no se re-discutan:

- Empezar por **web** si la app real la soporta (huella nativa cero).
- **Los locators los define la persona, no el agente.** Antes de escribir un
  page object, el agente entrega una tabla de solicitud por pantalla y espera.
- **No** replicar `fastMode` ni ninguna bandera de "modo test" en producción.
- Las `Key`, si hacen falta, van **un commit por pantalla**.
- Una fase a la vez, con presupuesto de archivos declarado y parada obligatoria
  al final de cada una.
