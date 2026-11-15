#!/usr/bin/env bash
set -uo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
sdk="$project_root/.ai-local/toolchains/flutter-3.47.9/bin"
evidence_dir="$project_root/.ai-local/f2.2/evidence"
pub_cache="$project_root/.ai-local/pub-cache"
timestamp=$(date -u +%Y%m%dT%H%M%SZ)
log_file="$evidence_dir/owner-stop-gtk-close-$timestamp.log"

for directory in \
  "$project_root/.ai-local" \
  "$project_root/.ai-local/toolchains" \
  "$project_root/.ai-local/toolchains/flutter-3.47.9" \
  "$sdk" \
  "$project_root/.ai-local/f2.2"; do
  if [[ -L "$directory" ]]; then
    printf 'Refusing symlinked project-local path: %s\n' "$directory" >&2
    exit 2
  fi
done
if [[ ! -x "$sdk/flutter" ]]; then
  printf 'Project-local Flutter SDK is missing: %s\n' "$sdk/flutter" >&2
  exit 2
fi
if [[ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
  printf '%s\n' 'Run this from the owner-controlled Fedora graphical session.' >&2
  exit 2
fi

if [[ -L "$evidence_dir" ]]; then
  printf 'Refusing symlinked evidence directory: %s\n' "$evidence_dir" >&2
  exit 2
fi
mkdir -p "$evidence_dir"
if [[ -e "$log_file" || -L "$log_file" ]]; then
  printf 'Refusing to overwrite existing capture path: %s\n' "$log_file" >&2
  exit 2
fi
if [[ -L "$pub_cache" ]]; then
  printf 'Refusing symlinked Pub cache: %s\n' "$pub_cache" >&2
  exit 2
fi
mkdir -p "$pub_cache"
unset FLUTTER_ROOT
export FLUTTER_BIN="$sdk/flutter"
export PUB_CACHE="$pub_cache"

{
  printf 'started_utc=%s\n' "$timestamp"
  printf 'project_root=%s\n' "$project_root"
  printf 'flutter=%s\n' "$FLUTTER_BIN"
  "$FLUTTER_BIN" --version
} | tee "$log_file"
header_status=("${PIPESTATUS[@]}")
if [[ "${header_status[0]}" -ne 0 || "${header_status[1]}" -ne 0 ]]; then
  printf 'Failed to initialize capture log (version=%s, tee=%s).\n' \
    "${header_status[0]}" "${header_status[1]}" >&2
  exit 3
fi

set +e
(
  cd -- "$project_root/app"
  "$FLUTTER_BIN" build linux --release --no-pub -t lib/main_player_spike.dart --verbose
) 2>&1 | tee -a "$log_file"
build_status=("${PIPESTATUS[@]}")
build_exit=${build_status[0]}
if [[ "${build_status[1]}" -ne 0 ]]; then
  printf 'Capture log write failed during build (tee=%s).\n' "${build_status[1]}" >&2
  exit 3
fi
if [[ "$build_exit" -ne 0 ]]; then
  printf 'KONGROO_F2_2_BUILD_EXIT=%s\n' "$build_exit" | tee -a "$log_file"
  exit "$build_exit"
fi

printf '%s\n' 'Protocol: owner clicks Stop, waits for stopped state, then closes GTK window normally.' | tee -a "$log_file"
KONGROO_F2_2_RUN_RELEASE_BUNDLE=1 \
  "$project_root/tools/player/run_f2_2_spike.sh" 2>&1 | tee -a "$log_file"
player_status=("${PIPESTATUS[@]}")
player_exit=${player_status[0]}
set -e

if [[ "${player_status[1]}" -ne 0 ]]; then
  printf 'Capture log write failed during player run (tee=%s).\n' "${player_status[1]}" >&2
  exit 3
fi

printf 'KONGROO_F2_2_PROCESS_EXIT=%s\n' "$player_exit" | tee -a "$log_file"
printf 'finished_utc=%s\n' "$(date -u +%Y%m%dT%H%M%SZ)" | tee -a "$log_file"
printf 'evidence_log=%s\n' "$log_file"
exit "$player_exit"
