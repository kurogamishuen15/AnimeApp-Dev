#!/usr/bin/env bash
set -u
cd '/home/kyouma/Vídeos/PROYECTO ANIME/app'
unset FLUTTER_ROOT
export PUB_CACHE="$PWD/../.ai-local/pub-cache"
export PATH="$PWD/../.ai-local/toolchains/flutter-3.47.9/bin:$PATH"
sdk="$PWD/../.ai-local/toolchains/flutter-3.47.9/bin/flutter"
logs="$PWD/../docs/refactor/logs"
: > "$logs/test_baseline.txt"
for folder in core data settings domain player application home catalog; do
 printf '\n### test/%s\n' "$folder" >> "$logs/test_baseline.txt"
 timeout --kill-after=5 90 "$sdk" test --no-pub --concurrency=1 --timeout 15s --reporter expanded "test/$folder" > "$logs/test_$folder.txt" 2>&1
 result=$?
 cat "$logs/test_$folder.txt" >> "$logs/test_baseline.txt"
 printf '\nEXIT %s %s\n' "$folder" "$result" >> "$logs/test_baseline.txt"
 printf '%s exit=%s\n' "$folder" "$result"
done
timeout --kill-after=5 60 "$sdk" test --no-pub --timeout 15s --reporter expanded test/widget_test.dart >> "$logs/test_baseline.txt" 2>&1
printf '\nEXIT widget %s\n' "$?" >> "$logs/test_baseline.txt"
timeout --kill-after=5 120 "$sdk" build linux --debug --no-pub > "$logs/build_linux.txt" 2>&1
printf 'linux exit=%s\n' "$?"
timeout --kill-after=5 60 "$sdk" analyze --no-pub > "$logs/analyze_baseline.txt" 2>&1
printf 'analyze exit=%s\n' "$?"
