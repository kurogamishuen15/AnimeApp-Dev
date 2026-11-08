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

mkdir -p "$FIXTURE_ROOT/app/lib/domain"
cat >"$FIXTURE_ROOT/app/pubspec.yaml" <<'EOF'
name: anime_app
EOF

cat >"$FIXTURE_ROOT/app/lib/domain/valid.dart" <<'EOF'
// import 'package:flutter/widgets.dart';
import 'dart:collection';

const sample = "import 'package:flutter/material.dart';";
final values = <String>[];
EOF
"$DART_BIN" "$ROOT/scripts/check_imports.dart" --root "$FIXTURE_ROOT"

cat >"$FIXTURE_ROOT/app/lib/domain/invalid_flutter.dart" <<'EOF'
import
  /* multiline directive with an alias */
  'package:flutter/widgets.dart'
  as widgets;
EOF
if "$DART_BIN" "$ROOT/scripts/check_imports.dart" --root "$FIXTURE_ROOT"; then
  echo 'ERROR: el import de Flutter debía fallar.' >&2
  exit 1
fi
python3 - "$FIXTURE_ROOT/app/lib/domain/invalid_flutter.dart" <<'PY'
from pathlib import Path
import sys
Path(sys.argv[1]).unlink()
PY

cat >"$FIXTURE_ROOT/app/lib/domain/invalid_presentation.dart" <<'EOF'
export 'package:anime_app/features/player/presentation/controls.dart'
    show PlayerControls;
EOF
if "$DART_BIN" "$ROOT/scripts/check_imports.dart" --root "$FIXTURE_ROOT"; then
  echo 'ERROR: el export de presentación debía fallar.' >&2
  exit 1
fi

echo 'Prueba sintética de imports: caso válido y dos casos prohibidos detectados.'
