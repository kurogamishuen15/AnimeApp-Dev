#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
project_root=$(cd -- "$script_dir/../.." && pwd -P)
fixture="$project_root/.ai-local/f2.2/fixtures/spike.mp4"
generator="$script_dir/generate_f2_2_fixture.sh"
fixture_directories=(
  "$project_root/.ai-local"
  "$project_root/.ai-local/f2.2"
  "$project_root/.ai-local/f2.2/fixtures"
)

for directory in "${fixture_directories[@]}"; do
  if [[ -L "$directory" ]]; then
    printf 'Refusing symlinked fixture directory: %s\n' "$directory" >&2
    exit 2
  fi
done
if [[ ! -e "$fixture" ]]; then
  "$generator"
fi
for directory in "${fixture_directories[@]}"; do
  if [[ -L "$directory" || ! -d "$directory" ]]; then
    printf 'Invalid project-local fixture directory: %s\n' "$directory" >&2
    exit 2
  fi
done
if [[ -L "$fixture" || ! -f "$fixture" ]]; then
  printf 'Invalid project-local media fixture: %s\n' "$fixture" >&2
  exit 2
fi
if ! command -v ffprobe >/dev/null 2>&1; then
  printf '%s\n' 'ffprobe is required to validate the local fixture.' >&2
  exit 127
fi
ffprobe -v error -select_streams v:0 \
  -show_entries stream=codec_name,width,height \
  -of default=noprint_wrappers=1 "$fixture" >/dev/null

export KONGROO_F2_2_SPIKE=1
export KONGROO_PROJECT_ROOT="$project_root"
cd -- "$project_root/app"
if [[ "${KONGROO_F2_2_RUN_RELEASE_BUNDLE:-0}" == 1 ]]; then
  bundle="$project_root/app/build/linux/x64/release/bundle/anime_app"
  if [[ ! -x "$bundle" ]]; then
    printf 'Spike release bundle is not built: %s\n' "$bundle" >&2
    exit 2
  fi
  exec "$bundle"
fi
exec "${FLUTTER_BIN:-flutter}" run -d linux \
  -t lib/main_player_spike.dart "$@"
