#!/usr/bin/env bash
#
# Borra todo lo que genera una ejecución, de UNA plataforma.
#
#   tool/e2e/clean.sh web
#   tool/e2e/clean.sh android
#
# Por plataforma y no todo junto, porque un reporte de web y uno de Android
# describen entornos distintos y se guardan aparte: correr la suite web no
# debe llevarse por delante el último resultado de dispositivo.
#
# Se ejecuta al PRINCIPIO de cada corrida, no al final. La diferencia importa:
# limpiar al terminar deja la máquina limpia pero también borra la evidencia
# de lo que acaba de fallar. Limpiar al empezar garantiza lo único que hace
# falta garantizar — que nada de lo que quede en disco venga de la corrida
# anterior.
#
# Eso no es manía de orden. Patrol sobrescribe sus resultados cuando termina
# bien, pero una corrida que muere antes de tiempo deja los de ayer en su
# sitio, y el reporte siguiente se construye sobre ellos sin decir una
# palabra: sale fechado "ahora" con datos viejos.
set -euo pipefail

cd "$(dirname "$0")/../.."

APP_DIR="packages/apps/market_app"

usage() {
  echo "uso: tool/e2e/clean.sh <web|android>" >&2
  exit 2
}

PLATFORM="${1:-}"

# `test_bundle.dart` lo regenera patrol_cli en cada corrida, en las dos
# plataformas. Se borra siempre: es un residuo, y uno que quedó de una
# ejecución interrumpida puede no corresponder a los tests que hay ahora.
COMMON=(
  "$APP_DIR/test_bundle.dart"
  "$APP_DIR/patrol_test/test_bundle.dart"
)

case "$PLATFORM" in
  web)
    targets=(
      # results.json (de donde salen los marcadores), results.xml (JUnit para
      # CI) y el HTML de Playwright.
      "$APP_DIR/playwright-report"
      # Trazas y adjuntos por test que escribe Playwright. Nadie los limpiaba.
      "$APP_DIR/test-results"
      # Resultados convertidos y reporte de Allure.
      "allure/web"
      "${COMMON[@]}"
    )
    ;;
  android)
    targets=(
      # El logcat capturado: la única vía por la que los marcadores salen de
      # un dispositivo.
      "build/e2e/android_run.log"
      "allure/android"
      "${COMMON[@]}"
    )
    ;;
  *)
    usage
    ;;
esac

removed=0
for target in "${targets[@]}"; do
  if [[ -e "$target" ]]; then
    rm -rf "$target"
    echo "  borrado  $target"
    removed=$((removed + 1))
  fi
done

if [[ "$removed" -eq 0 ]]; then
  echo "Limpieza ($PLATFORM): no había nada de una corrida anterior."
else
  echo "Limpieza ($PLATFORM): $removed elemento(s)."
fi
