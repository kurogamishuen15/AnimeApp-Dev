#!/usr/bin/env bash
# Mide lanzamientos secuenciales del bundle Flutter Linux release.
set -Eeuo pipefail

usage() {
  cat <<'USAGE'
Uso: bash scripts/measure.sh [--runs N] [--idle-seconds N] [--output ARCHIVO.tsv]

Mide el bundle release existente en app/build/linux/x64/release/bundle/anime_app.
No compila. Registra primer frame Flutter, ventana si la sesión permite verla,
RSS y CPU del PID exacto lanzado. Las salidas nuevas nunca se sobrescriben.
USAGE
}

fail() { printf 'Error: %s\n' "$*" >&2; exit 2; }

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
APP="$ROOT/app/build/linux/x64/release/bundle/anime_app"
PUB_CACHE="$ROOT/.ai-local/pub-cache"
PERF_DIR="$ROOT/docs/perf"
LOCAL_DIR="$ROOT/.ai-local"
RUNS=3
IDLE_SECONDS=5
OUTPUT=''

while (($#)); do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --runs)
      (($# >= 2)) || fail "--runs requiere un número entre 1 y 10"
      [[ "$2" =~ ^[0-9]+$ ]] && ((10#$2 >= 1 && 10#$2 <= 10)) || fail "--runs requiere un número entre 1 y 10"
      RUNS=$((10#$2)); shift 2 ;;
    --idle-seconds)
      (($# >= 2)) || fail "--idle-seconds requiere un número entre 1 y 300"
      [[ "$2" =~ ^[0-9]+$ ]] && ((10#$2 >= 1 && 10#$2 <= 300)) || fail "--idle-seconds requiere un número entre 1 y 300"
      IDLE_SECONDS=$((10#$2)); shift 2 ;;
    --output)
      (($# >= 2)) || fail "--output requiere una ruta"
      OUTPUT=$2; shift 2 ;;
    *) fail "argumento desconocido: $1" ;;
  esac
done

[[ -x "$APP" ]] || fail "no existe el bundle release ejecutable: $APP. Desde app/ ejecuta: PUB_CACHE=\"$PUB_CACHE\" FLUTTER_SUPPRESS_ANALYTICS=true flutter build linux --release"
[[ ! -L "$ROOT/.ai-local" ]] || fail ".ai-local no puede ser un enlace simbólico"
mkdir -p -- "$LOCAL_DIR" "$PERF_DIR"
[[ ! -L "$ROOT/docs/perf" ]] || fail "docs/perf no puede ser un enlace simbólico"

if [[ -z "$OUTPUT" ]]; then
  OUTPUT="$PERF_DIR/measure-$(date -u +%Y%m%dT%H%M%SZ)-$$.tsv"
else
  case "$OUTPUT" in
    "$PERF_DIR/"*) OUTPUT_NAME=${OUTPUT#"$PERF_DIR/"} ;;
    docs/perf/*) OUTPUT_NAME=${OUTPUT#docs/perf/} ;;
    *) fail "--output debe estar dentro de docs/perf/" ;;
  esac
  [[ -n "$OUTPUT_NAME" && "$OUTPUT_NAME" != */* && "$OUTPUT_NAME" != . && "$OUTPUT_NAME" != .. ]] || fail "--output debe ser un nombre de archivo directo dentro de docs/perf/"
  OUTPUT="$PERF_DIR/$OUTPUT_NAME"
fi
[[ ! -e "$OUTPUT" && ! -L "$OUTPUT" ]] || fail "el archivo de salida ya existe: $OUTPUT"
if ! (set -o noclobber; : > "$OUTPUT") 2>/dev/null; then
  fail "no se pudo crear salida nueva sin sobrescribir: $OUTPUT"
fi

version="$(sed -n 's/^version:[[:space:]]*//p' "$ROOT/app/pubspec.yaml" | head -n 1)"
cpu_arch="$(uname -m)"
cpu_count="$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf 'desconocido')"
memory_kib="$(awk '/^MemTotal:/ {print $2; exit}' /proc/meminfo 2>/dev/null || true)"
os_kernel="$(uname -sr)"
stamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
clk_tck="$(getconf CLK_TCK 2>/dev/null || printf '100')"
wayland_display="${WAYLAND_DISPLAY:-}"
gdk_backend="${GDK_BACKEND:-auto}"
if [[ -n "$wayland_display" && "$gdk_backend" != x11 ]]; then
  window_observer='unavailable-wayland-session'
else
  window_observer="$(if command -v xdotool >/dev/null 2>&1; then printf xdotool; elif command -v wmctrl >/dev/null 2>&1; then printf wmctrl; else printf unavailable; fi)"
fi

{
  printf '# AnimeApp initial Linux measurement\n'
  printf '# measured_at_utc\t%s\n' "$stamp"
  printf '# app_version\t%s\n' "${version:-desconocida}"
  printf '# mode\trelease\n'
  printf '# os_kernel\t%s\n' "$os_kernel"
  printf '# cpu_arch\t%s\n' "$cpu_arch"
  printf '# online_cpu_count\t%s\n' "$cpu_count"
  printf '# memory_total_kib\t%s\n' "${memory_kib:-desconocida}"
  printf '# window_observer\t%s\n' "$window_observer"
  printf '# cpu_ticks_per_second\t%s\n' "$clk_tck"
  printf '# pub_cache\t.ai-local/pub-cache\n'
  printf 'run\tspawn_pid\tprocess_identity\tfirst_frame_ms\twindow_status\tlaunch_to_window_ms\trss_after_frame_kib\tidle_seconds\trss_after_idle_kib\tcpu_idle_avg_percent_one_core\n'
  printf '# status\tcollecting; only status=complete is a valid full run\n'
} >> "$OUTPUT"

child=''
marker=''
cleanup_child() {
  if [[ -n "$child" ]] && pid_running "$child"; then
    kill -TERM "$child" 2>/dev/null || true
    for _ in {1..30}; do
      pid_running "$child" || break
      sleep 0.1
    done
    if pid_running "$child"; then
      kill -KILL "$child" 2>/dev/null || true
      for _ in {1..20}; do pid_running "$child" || break; sleep 0.1; done
    fi
  fi
  if [[ -n "$child" ]]; then wait "$child" 2>/dev/null || true; fi
  if [[ -n "$marker" && "$marker" == "$LOCAL_DIR/frame-marker."* ]]; then rm -f -- "$marker"; fi
  child=''
  marker=''
}
on_exit() { cleanup_child; }
trap on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

pid_running() {
  local state
  kill -0 "$1" 2>/dev/null || return 1
  state="$(awk '{sub(/^.*\) /, ""); print $1}' "/proc/$1/stat" 2>/dev/null || true)"
  [[ -n "$state" && "$state" != Z && "$state" != X ]]
}

rss_kib() {
  awk '/^VmRSS:/ {print $2; found=1; exit} END {if (!found) print "NA"}' "/proc/$1/status" 2>/dev/null || printf 'NA'
}

cpu_ticks() {
  awk '{sub(/^.*\) /, ""); print $12 + $13}' "/proc/$1/stat" 2>/dev/null || printf 'NA'
}

window_present() {
  local pid=$1
  if command -v xdotool >/dev/null 2>&1; then
    [[ -n "$(xdotool search --onlyvisible --pid "$pid" 2>/dev/null || true)" ]]
  elif command -v wmctrl >/dev/null 2>&1; then
    wmctrl -lp 2>/dev/null | awk -v p="$pid" '$3 == p {found=1} END {exit !found}'
  else
    return 2
  fi
}

median() {
  local sorted=($(printf '%s\n' "$@" | sort -n))
  local n=${#sorted[@]}
  if ((n % 2)); then printf '%s' "${sorted[n/2]}"; else awk -v a="${sorted[n/2-1]}" -v b="${sorted[n/2]}" 'BEGIN {printf "%.2f", (a+b)/2}'; fi
}

frame_values=()
window_values=()
rss_frame_values=()
rss_idle_values=()
cpu_idle_values=()
for ((run=1; run<=RUNS; run++)); do
  marker="$(mktemp "$LOCAL_DIR/frame-marker.XXXXXX")"
  start_us="$(date +%s%6N)"
  ANIMEAPP_FIRST_FRAME_MARKER="$marker" PUB_CACHE="$PUB_CACHE" FLUTTER_SUPPRESS_ANALYTICS=true "$APP" >/dev/null 2>&1 &
  child=$!
  sleep 0.05
  pid_running "$child" || { printf '# incomplete\tprocess exited before sampling run %s\n' "$run" >> "$OUTPUT"; exit 1; }
  exe="$(readlink -f "/proc/$child/exe" 2>/dev/null || true)"
  expected_exe="$(readlink -f "$APP")"
  [[ "$exe" == "$expected_exe" ]] || { printf '# incomplete\tlaunched PID did not match bundle executable in run %s\n' "$run" >> "$OUTPUT"; exit 1; }

  frame_us=''
  window_status='not-observable'
  window_ms='NA'
  frame_deadline=$((SECONDS + 30))
  window_deadline=$((SECONDS + 20))
  while pid_running "$child"; do
    now_s=$SECONDS
    if [[ -z "$frame_us" && -s "$marker" ]]; then frame_us="$(cat "$marker")"; fi
    if [[ "$window_observer" == unavailable-wayland-session ]]; then
      window_status='not-observable-wayland'
    elif [[ "$window_observer" != unavailable && "$window_status" != window-detected && $now_s -lt $window_deadline ]]; then
      if window_present "$child"; then
        window_status='window-detected'
        window_ms=$(( ( $(date +%s%6N) - start_us ) / 1000 ))
      fi
    elif [[ "$window_observer" != unavailable && "$window_status" != window-detected ]]; then
      window_status='window-timeout'
    fi
    [[ -n "$frame_us" ]] && break
    ((now_s < frame_deadline)) || break
    sleep 0.05
  done
  if [[ -z "$frame_us" ]]; then
    printf '# incomplete\tfirst Flutter frame was not observed in run %s\n' "$run" >> "$OUTPUT"
    exit 1
  fi
  pid_running "$child" || { printf '# incomplete\tprocess exited before complete sample in run %s\n' "$run" >> "$OUTPUT"; exit 1; }

  if [[ "$window_observer" != unavailable && "$window_observer" != unavailable-wayland-session && "$window_status" != window-detected ]]; then
    window_status='window-timeout'
    window_deadline=$((SECONDS + 20))
    while pid_running "$child" && ((SECONDS < window_deadline)); do
      if window_present "$child"; then
        window_status='window-detected'
        window_ms=$(( ( $(date +%s%6N) - start_us ) / 1000 ))
        break
      fi
      sleep 0.05
    done
  fi

  frame_ms=$(( (frame_us - start_us) / 1000 ))
  [[ "$window_status" == window-detected ]] && window_values+=("$window_ms")
  rss_frame="$(rss_kib "$child")"
  [[ "$rss_frame" =~ ^[0-9]+$ ]] || { printf '# incomplete\tRSS after first frame unavailable in run %s\n' "$run" >> "$OUTPUT"; exit 1; }
  cpu_before="$(cpu_ticks "$child")"
  [[ "$cpu_before" =~ ^[0-9]+$ ]] || { printf '# incomplete\tCPU ticks unavailable in run %s\n' "$run" >> "$OUTPUT"; exit 1; }
  sleep "$IDLE_SECONDS"
  pid_running "$child" || { printf '# incomplete\tprocess exited before idle sample in run %s\n' "$run" >> "$OUTPUT"; exit 1; }
  rss_idle="$(rss_kib "$child")"
  cpu_after="$(cpu_ticks "$child")"
  [[ "$rss_idle" =~ ^[0-9]+$ && "$cpu_after" =~ ^[0-9]+$ ]] || { printf '# incomplete\tidle sample unavailable in run %s\n' "$run" >> "$OUTPUT"; exit 1; }
  cpu_percent="$(awk -v before="$cpu_before" -v after="$cpu_after" -v hz="$clk_tck" -v seconds="$IDLE_SECONDS" 'BEGIN {printf "%.2f", ((after-before)/hz)/seconds*100}')"

  printf '%s\t%s\tverified-bundle-executable\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$run" "$child" "$frame_ms" "$window_status" "$window_ms" "$rss_frame" "$IDLE_SECONDS" "$rss_idle" "$cpu_percent" | tee -a "$OUTPUT"
  frame_values+=("$frame_ms")
  rss_frame_values+=("$rss_frame")
  rss_idle_values+=("$rss_idle")
  cpu_idle_values+=("$cpu_percent")
  cleanup_child
  sleep 1
done

{
  printf '# median_first_frame_ms\t%s\n' "$(median "${frame_values[@]}")"
  printf '# median_launch_to_window_ms\t%s\n' "$(if ((${#window_values[@]})); then median "${window_values[@]}"; else printf NA; fi)"
  printf '# median_rss_after_frame_kib\t%s\n' "$(median "${rss_frame_values[@]}")"
  printf '# median_rss_after_idle_kib\t%s\n' "$(median "${rss_idle_values[@]}")"
  printf '# median_cpu_idle_avg_percent_one_core\t%s\n' "$(median "${cpu_idle_values[@]}")"
  printf '# complete\ttrue\n'
} >> "$OUTPUT"
printf 'Informe: %s\n' "$OUTPUT"
