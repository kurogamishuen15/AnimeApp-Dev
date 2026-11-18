#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
project_root=$(cd -- "$script_dir/../.." && pwd -P)
build_mode=debug
codec_mode=system
download_codec=false

for argument in "$@"; do
  case "$argument" in
    --debug) build_mode=debug ;;
    --release) build_mode=release ;;
    --openh264) codec_mode=openh264 ;;
    --system-codec) codec_mode=system ;;
    --download-codec) download_codec=true ;;
    --help)
      printf '%s\n' 'Usage: run_kongroo_linux.sh [--debug|--release] [--openh264|--system-codec]'
      printf '%s\n' 'Use --download-codec to download the optional codec separately and exit.'
      exit 0
      ;;
    *) printf 'Unknown option: %s\n' "$argument" >&2; exit 64 ;;
  esac
done

codec_dir="$project_root/.ai-local/native-codecs/openh264-2.6.0"
codec="$codec_dir/libopenh264.so.8"
codec_sha256=2f0cde7c6a6abcf5cae76942894ea42897fa677bce4ed6c91a24dd1b041d5f04
for directory in "$project_root/.ai-local" "$project_root/.ai-local/native-codecs" "$codec_dir"; do
  if [[ -L "$directory" ]]; then
    printf 'Refusing symlinked codec directory: %s\n' "$directory" >&2
    exit 2
  fi
done

if [[ "$download_codec" == true ]]; then
  if [[ "$(uname -m)" != x86_64 ]]; then
    printf '%s\n' 'This codec download is for Linux x86_64.' >&2
    exit 2
  fi
  mkdir -p -- "$codec_dir"
  stage=$(mktemp -d "$codec_dir/download.XXXXXX")
  trap 'rm -rf -- "$stage"' EXIT
  curl --fail --location --proto '=https' --connect-timeout 10 --max-time 60 \
    --max-filesize 8388608 \
    'https://ciscobinary.openh264.org/libopenh264-2.6.0-linux64.8.so.bz2' \
    --output "$stage/codec.bz2"
  python3 - "$stage/codec.bz2" "$stage/libopenh264.so.8" <<'PY'
import bz2
import sys
from pathlib import Path
with bz2.open(sys.argv[1], 'rb') as source:
    data = source.read(2 * 1024 * 1024 + 1)
if len(data) > 2 * 1024 * 1024 or not data.startswith(b'\x7fELF'):
    raise ValueError('Invalid or oversized codec binary')
Path(sys.argv[2]).write_bytes(data)
PY
  printf '%s  %s\n' "$codec_sha256" "$stage/libopenh264.so.8" | sha256sum --check --status
  curl --fail --location --proto '=https' --connect-timeout 10 --max-time 30 \
    'https://www.openh264.org/BINARY_LICENSE.txt' --output "$stage/BINARY_LICENSE.txt"
  mv -- "$stage/libopenh264.so.8" "$codec"
  mv -- "$stage/BINARY_LICENSE.txt" "$codec_dir/BINARY_LICENSE.txt"
  rm -rf -- "$stage"
  trap - EXIT
  printf 'Optional codec prepared in %s\n' "$codec_dir"
  printf 'License: %s\n' "$codec_dir/BINARY_LICENSE.txt"
  exit 0
fi

if [[ "$codec_mode" == openh264 ]]; then
  if [[ -L "$codec" || ! -f "$codec" || ! -f "$codec_dir/BINARY_LICENSE.txt" ]]; then
    printf '%s\n' 'Use --download-codec to obtain the optional project-local codec from Cisco.' >&2
    exit 2
  fi
  printf '%s  %s\n' "$codec_sha256" "$codec" | sha256sum --check --status
  printf '%s\n' 'OpenH264 Video Codec provided by Cisco Systems, Inc.'
  printf 'License: %s\n' "$codec_dir/BINARY_LICENSE.txt"
  export LD_LIBRARY_PATH="$codec_dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

binary="$project_root/app/build/linux/x64/$build_mode/bundle/anime_app"
if [[ ! -x "$binary" ]]; then
  printf 'Build the Linux %s application before launching it.\n' "$build_mode" >&2
  exit 2
fi
cd -- "$project_root"
exec "$binary"
