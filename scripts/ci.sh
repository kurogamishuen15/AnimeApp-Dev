#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
APP="$ROOT/app"
export PUB_CACHE="$ROOT/.ai-local/pub-cache"
export FLUTTER_SUPPRESS_ANALYTICS=true
export DART_SUPPRESS_ANALYTICS=true

for command in flutter dart python3 pkg-config; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "Falta el comando requerido: $command" >&2
    exit 2
  fi
done

mkdir -p "$PUB_CACHE"
failures=0
run_step() {
  local label="$1"
  shift
  echo "== $label =="
  if "$@"; then
    echo "OK: $label"
  else
    local result=$?
    echo "FALLO ($result): $label" >&2
    failures=$((failures + 1))
  fi
}

run_step 'Toolchain GTK' pkg-config --exists gtk+-3.0
run_step 'Integridad de memoria del proyecto' python3 "$ROOT/tools/ai/memory.py" check
run_step 'Pruebas de infraestructura de IA' python3 -W error::ResourceWarning -m unittest discover -s "$ROOT/tests/ai" -v
run_step 'Prueba sintética del comprobador de imports' bash "$ROOT/scripts/test_check_imports.sh"
run_step 'Formato Dart' dart format --output=none --set-exit-if-changed "$APP/lib" "$APP/test" "$ROOT/scripts/check_imports.dart"
run_step 'Análisis Dart alternativo' bash -c "cd \"\$1\" && dart analyze lib test" _ "$APP"
run_step 'Análisis del checker Dart' dart analyze "$ROOT/scripts/check_imports.dart"
run_step 'Dependencias Dart/Flutter' bash -c "cd \"\$1\" && flutter pub get" _ "$APP"
run_step 'Análisis Flutter' bash -c "cd \"\$1\" && flutter analyze --no-pub" _ "$APP"
run_step 'Pruebas Flutter' bash -c "cd \"\$1\" && flutter test --no-pub" _ "$APP"
run_step 'Límites de imports' dart "$ROOT/scripts/check_imports.dart" --root "$ROOT"

if (( failures > 0 )); then
  echo "CI local falló: $failures comprobación(es) obligatoria(s) con error." >&2
  exit 1
fi
echo 'CI local completada.'
