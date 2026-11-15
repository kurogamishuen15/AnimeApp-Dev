#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
project_root=$(cd -- "$script_dir/../.." && pwd -P)
scratch=$(mktemp -d "$project_root/.ai-local/f2.2/fixture-guard-test.XXXXXX")
trap 'rm -rf -- "$scratch"' EXIT

launcher_source="$script_dir/run_f2_2_spike.sh"
generator_source="$script_dir/generate_f2_2_fixture.sh"

for linked_relative in \
  '.ai-local' \
  '.ai-local/f2.2' \
  '.ai-local/f2.2/fixtures'; do
  fake_root="$scratch/root-${linked_relative//\//-}"
  fake_player_tools="$fake_root/tools/player"
  mkdir -p -- "$fake_player_tools"
  cp -- "$launcher_source" "$fake_player_tools/run_f2_2_spike.sh"
  cp -- "$generator_source" "$fake_player_tools/generate_f2_2_fixture.sh"

  linked_path="$fake_root/$linked_relative"
  link_parent=$(dirname -- "$linked_path")
  mkdir -p -- "$link_parent"
  target="$scratch/redirect-${linked_relative//\//-}"
  case "$linked_relative" in
    '.ai-local') mkdir -p -- "$target/f2.2/fixtures" ;;
    '.ai-local/f2.2') mkdir -p -- "$target/fixtures" ;;
    '.ai-local/f2.2/fixtures') mkdir -p -- "$target" ;;
  esac
  : > "$target/spike.mp4"
  ln -s -- "$target" "$linked_path"

  for command in \
    "$fake_player_tools/run_f2_2_spike.sh" \
    "$fake_player_tools/generate_f2_2_fixture.sh"; do
    set +e
    output=$(bash "$command" 2>&1)
    status=$?
    set -e
    if [[ $status -ne 2 || "$output" != *"Refusing symlinked fixture directory"* ]]; then
      printf 'FAIL: %s accepted %s (exit %s): %s\n' \
        "${command##*/}" "$linked_relative" "$status" "$output" >&2
      exit 1
    fi
  done
done

printf '%s\n' 'PASS: launcher and fixture generator reject symlinked fixture paths at all three levels'
