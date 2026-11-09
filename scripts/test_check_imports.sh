#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
DART_BIN="${DART_BIN:-dart}"
FIXTURE_ROOT="$(mktemp -d "$ROOT/.ai-local/import-check.XXXXXX")"

cleanup() {
  python3 - "$ROOT" "$FIXTURE_ROOT" <<'PY'
from pathlib import Path
import shutil
import sys

root = Path(sys.argv[1]).resolve()
target = Path(sys.argv[2]).resolve()
if target.parent != root / '.ai-local' or not target.name.startswith('import-check.'):
    raise SystemExit('Refusing to remove an unexpected fixture path')
shutil.rmtree(target)
PY
}
trap cleanup EXIT

reset_fixture() {
  rm -rf -- "$FIXTURE_ROOT/app" "$FIXTURE_ROOT/app_target"
  mkdir -p "$FIXTURE_ROOT/app/lib/domain"
  cat >"$FIXTURE_ROOT/app/pubspec.yaml" <<'EOF'
name: anime_app
EOF
}

expect_pass() {
  local label="$1"
  local output
  if ! output="$("$DART_BIN" "$ROOT/scripts/check_imports.dart" --root "$FIXTURE_ROOT" 2>&1)"; then
    printf 'ERROR: %s debía pasar.\n%s\n' "$label" "$output" >&2
    exit 1
  fi
  printf 'PASS (exit 0): %s\n' "$label"
}

expect_fail() {
  local label="$1"
  local output
  local status=0
  output="$("$DART_BIN" "$ROOT/scripts/check_imports.dart" --root "$FIXTURE_ROOT" 2>&1)" || status=$?
  if [[ "$status" -ne 1 || ("$output" != *'Se encontraron '* && "$output" != *'directorio raíz'*) ]]; then
    printf 'ERROR: %s debía fallar con exit 1. Exit=%s\n%s\n' \
      "$label" "$status" "$output" >&2
    exit 1
  fi
  printf 'PASS (exit 1 esperado): %s\n' "$label"
}

reset_fixture
cat >"$FIXTURE_ROOT/app/lib/domain/valid.dart" <<'EOF'
import 'dart:collection';
import 'package:anime_app/domain/model.dart';
EOF
expect_pass 'import Dart y contrato de dominio permitidos'

reset_fixture
cat >"$FIXTURE_ROOT/app/lib/domain/invalid_flutter.dart" <<'EOF'
import 'package:flutter/widgets.dart';
EOF
expect_fail 'dominio raíz no puede importar Flutter'

reset_fixture
cat >"$FIXTURE_ROOT/app/lib/domain/invalid_presentation.dart" <<'EOF'
export 'package:anime_app/features/player/presentation/controls.dart';
EOF
expect_fail 'dominio raíz no puede importar presentación'

reset_fixture
cat >"$FIXTURE_ROOT/app/lib/domain/invalid_infrastructure.dart" <<'EOF'
import 'package:anime_app/integrations/catalog/catalog_client.dart';
EOF
expect_fail 'dominio raíz no puede importar integración/infraestructura'

reset_fixture
mkdir -p "$FIXTURE_ROOT/app/lib/features/catalog/domain"
cat >"$FIXTURE_ROOT/app/lib/features/catalog/domain/entity.dart" <<'EOF'
import 'package:flutter/foundation.dart';
EOF
expect_fail 'dominio anidado en feature tampoco puede importar Flutter'

reset_fixture
mkdir -p "$FIXTURE_ROOT/app/lib/features/catalog/domain" "$FIXTURE_ROOT/app/lib/app"
cat >"$FIXTURE_ROOT/app/lib/features/catalog/domain/entity.dart" <<'EOF'
import '../../../app/anime_app.dart';
EOF
cat >"$FIXTURE_ROOT/app/lib/app/anime_app.dart" <<'EOF'
class AnimeApp {}
EOF
expect_fail 'import relativo no puede evadir el límite hacia composición'

reset_fixture
cat >"$FIXTURE_ROOT/app/lib/domain/invalid_platform.dart" <<'EOF'
import 'package:mobile_scanner/mobile_scanner.dart';
EOF
expect_fail 'dominio no puede importar plugin de plataforma'

reset_fixture
mkdir -p "$FIXTURE_ROOT/app/lib/features/player/presentation"
cat >"$FIXTURE_ROOT/app/lib/features/player/presentation/controls.dart" <<'EOF'
class PlayerControls {}
EOF
ln -s ../features/player/presentation/controls.dart \
  "$FIXTURE_ROOT/app/lib/domain/alias.dart"
cat >"$FIXTURE_ROOT/app/lib/domain/invalid_symlink.dart" <<'EOF'
import 'alias.dart';
EOF
expect_fail 'archivo fuente domain enlazado simbólicamente no se omite'

reset_fixture
mkdir -p "$FIXTURE_ROOT/app/lib/core/domain" \
  "$FIXTURE_ROOT/app/lib/features/catalog"
cat >"$FIXTURE_ROOT/app/lib/core/domain/entity.dart" <<'EOF'
class Entity {}
EOF
ln -s ../../core/domain "$FIXTURE_ROOT/app/lib/features/catalog/domain"
expect_fail 'directorio domain enlazado simbólicamente no se omite'

reset_fixture
mv "$FIXTURE_ROOT/app/lib" "$FIXTURE_ROOT/app/lib_target"
ln -s lib_target "$FIXTURE_ROOT/app/lib"
expect_fail 'raíz app/lib enlazada simbólicamente se rechaza'

reset_fixture
mv "$FIXTURE_ROOT/app" "$FIXTURE_ROOT/app_target"
ln -s app_target "$FIXTURE_ROOT/app"
expect_fail 'raíz app enlazada simbólicamente se rechaza'

if ! "$DART_BIN" "$ROOT/scripts/check_imports.dart" --root "$ROOT"; then
  echo 'ERROR: el código actual del proyecto debía pasar el checker.' >&2
  exit 1
fi
printf 'PASS (exit 0): árbol real del proyecto\n'
echo 'Casos del checker: positivo y diez negativos pasaron.'
