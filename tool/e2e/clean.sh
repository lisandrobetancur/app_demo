#!/usr/bin/env bash
#
# Borra todo lo que genera una ejecución, de UNA plataforma.
#
#   tool/e2e/clean.sh web
#   tool/e2e/clean.sh android
#
# Todo lo generado vive bajo una sola raíz, una subcarpeta por plataforma:
#
#   build/e2e/
#   ├── web/
#   │   ├── playwright/     results.json, results.xml, el HTML de Playwright
#   │   ├── test-results/   trazas y adjuntos por test
#   │   └── allure/{results,report}
#   └── android/
#       ├── android_run.log el logcat capturado
#       └── allure/{results,report}
#
# Eso es lo que hace que esta limpieza sea de fiar. Antes los artefactos
# estaban repartidos en cuatro sitios del repositorio y este script tenía que
# enumerarlos uno a uno — y se olvidaba de los que nadie recordaba que
# existían: `test-results/` no lo borró nadie nunca. Con una raíz por
# plataforma, borrarla entera es una operación que no puede dejarse nada.
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
case "$PLATFORM" in
  web | android) ;;
  *) usage ;;
esac

targets=(
  # La raíz de esa plataforma: se lleva resultados, reporte y logs de una vez.
  "build/e2e/$PLATFORM"
  # `test_bundle.dart` es la excepción, y no por descuido: patrol_cli lo genera
  # en la raíz del paquete y no acepta otra ruta — ni podría, es código Dart
  # que tiene que compilar dentro del paquete. Se borra igual porque es un
  # residuo, y uno que quedó de una ejecución interrumpida puede no
  # corresponder a los tests que hay ahora.
  "$APP_DIR/test_bundle.dart"
  "$APP_DIR/patrol_test/test_bundle.dart"
)

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
