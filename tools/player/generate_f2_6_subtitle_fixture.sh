#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
project_root=$(cd -- "$script_dir/../.." && pwd -P)
fixture_dir="$project_root/.ai-local/f2.6/fixtures"
output="$fixture_dir/subtitles-v2.mkv"
mov_text_output="$fixture_dir/mov-text.mp4"
base_fixture="$project_root/.ai-local/f2.2/fixtures/spike.mp4"

for directory in \
  "$project_root/.ai-local" \
  "$project_root/.ai-local/f2.2" \
  "$project_root/.ai-local/f2.2/fixtures" \
  "$project_root/.ai-local/f2.6" \
  "$fixture_dir"; do
  if [[ -L "$directory" ]]; then
    printf 'Refusing symlinked fixture directory: %s\n' "$directory" >&2
    exit 2
  fi
done
mkdir -p -- "$fixture_dir"
for target in "$output" "$mov_text_output"; do
  if [[ -e "$target" || -L "$target" ]]; then
    printf 'Refusing to overwrite existing fixture: %s\n' "$target" >&2
    exit 2
  fi
done
if [[ ! -f "$base_fixture" ]]; then
  "$project_root/tools/player/generate_f2_2_fixture.sh"
fi
if ! command -v ffmpeg >/dev/null 2>&1; then
  printf '%s\n' 'ffmpeg is required to generate the F2.6 subtitle fixture.' >&2
  exit 127
fi

temporary="$fixture_dir/.subtitle-fixture-$$.mkv"
srt="$fixture_dir/.subtitle-fixture-$$.srt"
ass="$fixture_dir/.subtitle-fixture-$$.ass"
unlabeled_srt="$fixture_dir/.subtitle-fixture-$$-unlabeled.srt"
temporary_mp4="$fixture_dir/.subtitle-fixture-$$.mp4"
trap 'rm -f -- "$temporary" "$temporary_mp4" "$srt" "$ass" "$unlabeled_srt"' EXIT
cat >"$srt" <<'EOF'
1
00:00:00,500 --> 00:00:02,500
Kongroo internal English subtitle
EOF
cat >"$ass" <<'EOF'
[Script Info]
ScriptType: v4.00+
PlayResX: 320
PlayResY: 180
[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,18,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,0,0,0,0,100,100,0,0,1,2,0,2,10,10,8,1
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:03.00,0:00:05.00,Default,,0,0,0,,Kongroo internal ASS subtitle
EOF
cat >"$unlabeled_srt" <<'EOF'
1
00:00:05,200 --> 00:00:06,500
Subtitle with no language metadata
EOF
ffmpeg -hide_banner -loglevel error -nostdin -y \
  -i "$base_fixture" -i "$srt" -i "$ass" -i "$unlabeled_srt" \
  -map 0:v:0 -map 0:a:0 -map 1:s:0 -map 2:s:0 -map 3:s:0 \
  -c:v copy -c:a copy -c:s srt -c:s:1 ass -c:s:2 srt \
  -metadata:s:s:0 language=eng -metadata:s:s:0 title='English SRT' \
  -metadata:s:s:1 language=jpn -metadata:s:s:1 title='Japanese ASS' \
  "$temporary"
mv -- "$temporary" "$output"
ffmpeg -hide_banner -loglevel error -nostdin -y \
  -i "$base_fixture" -i "$srt" \
  -map 0:v:0 -map 0:a:0 -map 1:s:0 \
  -c:v copy -c:a copy -c:s mov_text \
  -metadata:s:s:0 language=eng -metadata:s:s:0 title='English mov_text' \
  "$temporary_mp4"
mv -- "$temporary_mp4" "$mov_text_output"
trap - EXIT
rm -f -- "$srt" "$ass" "$unlabeled_srt"
printf 'Generated F2.6 internal subtitle fixtures: %s and %s\n' \
  "$output" "$mov_text_output"
