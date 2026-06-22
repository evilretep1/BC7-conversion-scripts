#!/usr/bin/env bash
set -euo pipefail

TEXCONV_EXE="texconv.exe"
OUT_DIR="$PWD/dds_out"
mkdir -p "$OUT_DIR"

shopt -s globstar nullglob

to_wine_path() {
  # Converts /home/user/... -> Z:\home\user\...
  local p="$1"
  echo "Z:${p//\//\\}"
}

for f in **/*.{tga,bmp,dds}; do
  [ -e "$f" ] || continue
  wine "$TEXCONV_EXE" \
    -y \
    -o "$OUT_DIR" \
    -f BC7_UNORM \
    -r:keep \
    "$(to_wine_path "$f")"
done
