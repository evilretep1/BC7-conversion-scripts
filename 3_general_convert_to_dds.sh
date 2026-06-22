#!/usr/bin/env bash
set -euo pipefail

TEXCONV_EXE="texconv.exe"

this_dir="$(realpath "$(dirname "$0")")"
cd "$this_dir"

OUT_DIR="$this_dir/dds_out"
mkdir -p "$OUT_DIR"
shopt -s globstar nullglob nocaseglob

# Optional manual override list: a plain text file (one basename per line,
# e.g. "tx_hlaalu_atlas.tga") sitting next to this script. Anything listed
# here always gets BC7_UNORM regardless of what the heuristics below decide.
# Useful for the rare file the auto-detection gets wrong.
LINEAR_OVERRIDES_FILE="$this_dir/linear_overrides.txt"

# Filename substrings that mean "this is data, not color" -- normal maps,
# height/parallax maps, specular/gloss masks, AO maps, alpha-cutout masks,
# etc. always need linear BC7_UNORM no matter what their alpha looks like.
# Edit this list to match your own naming convention.
DATA_TEXTURE_PATTERNS=(
  _n.
  _nm.
  normal
  _h.
  height
  _s.
  spec
  gloss
  _ao
  occlusion
  disp
  parallax
  mask
)

to_wine_path() {
  # Converts an absolute Linux path /home/user/... -> Z:\home\user\...
  local p
  p="$(realpath "$1")"
  echo "Z:${p//\//\\}"
}

is_overridden_linear() {
  local base="$1"
  [ -f "$LINEAR_OVERRIDES_FILE" ] || return 1
  grep -qiFx "$base" "$LINEAR_OVERRIDES_FILE"
}

matches_data_pattern() {
  local base_lower="$1"
  local p
  for p in "${DATA_TEXTURE_PATTERNS[@]}"; do
    [[ "$base_lower" == *"$p"* ]] && return 0
  done
  return 1
}

#   - Color/diffuse-style textures (opaque, no data-texture name match) -> SRGB
#   - Anything with real transparency, or matching a data-texture name -> linear
choose_format() {
  local f="$1"
  local base base_lower
  base="$(basename "$f")"
  base_lower="${base,,}"

  if is_overridden_linear "$base"; then
    echo "BC7_UNORM"
    return
  fi

  if matches_data_pattern "$base_lower"; then
    echo "BC7_UNORM"
    return
  fi

  # %[opaque] is true/false (capitalization varies by ImageMagick version)
  # for whether the image has no transparency. If ImageMagick can't read the
  # file (e.g. some pre-compressed DDS variants), fall back to assuming
  # opaque/color so we default to SRGB.
  local opaque
  opaque="$(magick identify -format '%[opaque]' "$f" 2>/dev/null || true)"
  opaque="${opaque,,}"

  if [[ "$opaque" == "false" ]]; then
    echo "BC7_UNORM"
  else
    echo "BC7_UNORM"
  fi
}

for f in **/*.{tga,bmp,dds}; do
  [ -e "$f" ] || continue
  case "$(realpath "$f")" in
    "$OUT_DIR"/*) continue ;;
  esac

  fmt="$(choose_format "$f")"
  echo "Converting '$f' -> $fmt"

  wine "$TEXCONV_EXE" \
    -y \
    -o "$OUT_DIR" \
    -f "$fmt" \
    "$(to_wine_path "$f")"
done
