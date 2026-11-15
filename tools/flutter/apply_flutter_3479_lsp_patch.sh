#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
sdk="$project_root/.ai-local/toolchains/flutter-3.47.9"
patch_file="$project_root/tools/flutter/patches/flutter-3.47.9-lsp-content-length-utf8.patch"
expected_revision=c197ca5199e9ee5661e865596c9c07294dfab51c

for directory in \
  "$project_root/.ai-local" \
  "$project_root/.ai-local/toolchains" \
  "$sdk" \
  "$sdk/packages" \
  "$sdk/packages/flutter_tools" \
  "$sdk/packages/flutter_tools/lib" \
  "$sdk/packages/flutter_tools/lib/src" \
  "$sdk/packages/flutter_tools/lib/src/dart" \
  "$sdk/bin" \
  "$sdk/bin/cache"; do
  if [[ -L "$directory" ]]; then
    printf 'Refusing symlinked Flutter SDK path: %s\n' "$directory" >&2
    exit 2
  fi
done
if [[ -L "$patch_file" ]]; then
  printf 'Refusing symlinked patch file: %s\n' "$patch_file" >&2
  exit 2
fi
if ! git -C "$sdk" rev-parse --show-toplevel >/dev/null 2>&1; then
  printf 'Expected isolated Flutter SDK is missing: %s\n' "$sdk" >&2
  exit 2
fi
actual_revision=$(git -C "$sdk" rev-parse HEAD)
if [[ "$actual_revision" != "$expected_revision" ]]; then
  printf 'Refusing unexpected Flutter SDK revision: %s\n' "$actual_revision" >&2
  exit 2
fi

source_file="$sdk/packages/flutter_tools/lib/src/dart/analysis.dart"
if [[ -L "$source_file" ]]; then
  printf 'Refusing symlinked Flutter tool source: %s\n' "$source_file" >&2
  exit 2
fi
if rg -q 'encodedMessage = utf8\.encode\(message\)' "$source_file"; then
  echo 'UTF-8 Content-Length backport is already applied.'
else
  if ! rg -q 'Content-Length: \$\{message\.length\}' "$source_file"; then
    echo 'Flutter tool source does not match the expected unpatched state.' >&2
    exit 2
  fi
  git -C "$sdk" apply --check "$patch_file"
  git -C "$sdk" apply "$patch_file"
  echo 'Applied the upstream-equivalent LSP UTF-8 fix.'
fi

# The Flutter launcher keys its snapshot cache by SDK revision, not source mtime.
# Removing the stamp forces a rebuild from this modified source checkout.
rm -f "$sdk/bin/cache/flutter_tools.stamp"
echo 'Invalidated the local Flutter tool snapshot; next invocation rebuilds it.'
