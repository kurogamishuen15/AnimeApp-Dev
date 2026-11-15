#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
project_root=$(cd -- "$script_dir/../.." && pwd -P)
fixture_dir="$project_root/.ai-local/f2.2/fixtures"
default_output="$fixture_dir/spike.mp4"
requested_output="${1:-$default_output}"

case "$requested_output" in
  "$fixture_dir"/*) leaf_name="${requested_output#"$fixture_dir"/}" ;;
  .ai-local/f2.2/fixtures/*) leaf_name="${requested_output##*/}" ;;
  *)
    printf '%s\n' 'Output must remain inside project .ai-local/f2.2/fixtures/.' >&2
    exit 2
    ;;
esac
if [[ "$leaf_name" == */* || "$leaf_name" == . || "$leaf_name" == .. ||
      "$leaf_name" != *.mp4 ]]; then
  printf '%s\n' 'Output must be a single .mp4 filename in the fixture directory.' >&2
  exit 2
fi
output="$fixture_dir/$leaf_name"

for directory in \
  "$project_root/.ai-local" \
  "$project_root/.ai-local/f2.2" \
  "$fixture_dir"; do
  if [[ -L "$directory" ]]; then
    printf 'Refusing symlinked fixture directory: %s\n' "$directory" >&2
    exit 2
  fi
done
mkdir -p -- "$fixture_dir"

if [[ -e "$output" || -L "$output" ]]; then
  printf 'Refusing to overwrite existing fixture: %s\n' "$output" >&2
  exit 2
fi
if ! command -v ffmpeg >/dev/null 2>&1; then
  printf '%s\n' 'ffmpeg is required to generate this local synthetic fixture.' >&2
  exit 127
fi

temporary_output="${output%.mp4}.tmp.$$.mp4"
trap 'rm -f -- "$temporary_output"' EXIT
ffmpeg -hide_banner -loglevel error -nostdin -y \
  -fflags +bitexact \
  -f lavfi -i 'testsrc2=size=320x180:rate=24' \
  -f lavfi -i 'sine=frequency=440:sample_rate=48000' \
  -t 8 -map 0:v:0 -map 1:a:0 \
  -map_metadata -1 -metadata creation_time=1970-01-01T00:00:00Z \
  -c:v mpeg4 -flags:v +bitexact -q:v 5 -pix_fmt yuv420p \
  -c:a aac -flags:a +bitexact -b:a 64k \
  -movflags +faststart "$temporary_output"
mv -- "$temporary_output" "$output"
trap - EXIT
printf 'Generated synthetic F2.2 fixture: %s\n' "$output"
