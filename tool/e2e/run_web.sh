#!/usr/bin/env bash
#
# Corre la suite E2E en el navegador y deja el reporte generado.
#
#   tool/e2e/run_web.sh [--headed]
#
# Tres cosas en un comando, en este orden: limpiar lo de la corrida anterior,
# correr, y generar el reporte. Es el modelo de `aggregate` de Serenity — el
# reporte es parte de la ejecución, no un paso que alguien tiene que acordarse
# de lanzar después. Abrirlo sigue siendo aparte (`melos run allureServeWeb`):
# generar y abrir son decisiones distintas, y en CI sólo existe la primera.
#
# EL PUNTO DELICADO es el código de salida. El reporte tiene que generarse
# TAMBIÉN cuando la suite falla, que es justo cuando alguien lo va a abrir —
# pero el comando entero debe seguir saliendo en rojo, o CI daría por buena
# una corrida con tests caídos. Por eso el reporte no va encadenado con `&&`
# a la corrida: el estado de la suite se guarda, el reporte se construye pase
# lo que pase, y al final se sale con el estado guardado.
#
# `set -e` sigue activo para todo lo demás — la limpieza y el parseo de
# argumentos SÍ deben abortar si fallan — y se desactiva sólo alrededor de la
# corrida, que es el único punto donde un código distinto de cero es un
# resultado y no un error.
set -euo pipefail

cd "$(dirname "$0")/../.."

APP_DIR="packages/apps/market_app"

HEADLESS=true
TAGS=()
for arg in "$@"; do
  case "$arg" in
    --headed) HEADLESS=false ;;
    --tags=*) TAGS=(--tags "${arg#--tags=}") ;;
    *)
      echo "argumento no reconocido: $arg" >&2
      echo "uso: tool/e2e/run_web.sh [--headed] [--tags=<expresión>]" >&2
      exit 2
      ;;
  esac
done

tool/e2e/clean.sh web

# Rutas ABSOLUTAS, y no es un detalle de estilo. `--web-results-dir` y
# `--web-report-dir` acaban en las variables de entorno que lee la
# playwright.config.ts que trae Patrol, y Playwright resuelve una ruta
# relativa contra el directorio de SU config — dentro del paquete de patrol en
# el pub-cache, no contra donde estás tú. Una relativa aquí escribiría los
# resultados dentro de la caché de paquetes.
OUT="$PWD/build/e2e/web"

# `--web-locale` no es cosmético: un navegador headless recién creado puede
# no reportar ningún idioma, y el motor de Flutter lanza "Invalid argument:
# Incorrect locale information provided" antes de pintar un frame — la app no
# arranca y la corrida reporta cero tests en vez de un fallo. Fijarlo además
# hace que local y CI coincidan, y la suite afirma sobre textos en español.
# La zona horaria se fija por lo mismo, antes de que una aserción de fecha
# dependa de dónde esté la máquina.
#
# Tres reporters, cada uno para un lector distinto: `list` para la terminal,
# `json` para el convertidor de Allure y `junit` para CI. El `json` no es
# opcional: la captura por test de Playwright es el único canal que saca los
# marcadores de screenshot del navegador.
status=0
set +e
(
  cd "$APP_DIR" && patrol test \
    --device chrome \
    "${TAGS[@]+"${TAGS[@]}"}" \
    --web-report-dir="$OUT/playwright" \
    --web-results-dir="$OUT/test-results" \
    --web-headless="$HEADLESS" \
    --web-locale=es-ES \
    --web-timezone=America/Bogota \
    --web-reporter='["list","json","junit"]'
) || status=$?
set -e

echo
echo "── Generando el reporte ──────────────────────────────────────────────"
# Sin `&&` con lo de arriba, y a propósito: una suite roja es exactamente
# cuando el reporte hace falta.
node tool/allure/patrol_to_allure.mjs --platform web \
  && npx --prefix tool/allure allure awesome "$OUT/allure/results" \
       --output "$OUT/allure/report" --report-name "Market E2E · Web" \
  || echo "El reporte no se pudo generar (la suite salió con $status)." >&2

echo
echo "Reporte:  build/e2e/web/allure/report  ·  ábrelo con: melos run allureServeWeb"
exit "$status"
