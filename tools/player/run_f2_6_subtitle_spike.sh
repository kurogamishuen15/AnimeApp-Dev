#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
project_root=$(cd -- "$script_dir/../.." && pwd -P)
fixture="$project_root/.ai-local/f2.6/fixtures/subtitles-v2.mkv"

for directory in \
  "$project_root/.ai-local" \
  "$project_root/.ai-local/f2.6" \
  "$project_root/.ai-local/f2.6/fixtures"; do
  if [[ -L "$directory" ]]; then
    printf 'Refusing symlinked fixture directory: %s\n' "$directory" >&2
    exit 2
  fi
done

if [[ -L "$fixture" || ! -f "$fixture" ]]; then
  printf 'F2.6 fixture is missing or invalid: %s\n' "$fixture" >&2
  printf 'Generate it with tools/player/generate_f2_6_subtitle_fixture.sh.\n' >&2
  exit 2
fi

export KONGROO_F2_6_SUBTITLE_FIXTURE=1
exec "$script_dir/run_f2_2_spike.sh" "$@"
