#!/bin/bash
set -euo pipefail

if ! command -v magick >/dev/null 2>&1; then
  echo "This script requires a working installation of ImageMagick in \$PATH."
  exit 1
fi

type="${1:-}"

usage() {
  cat <<EOF
This script requires one argument, which is the type of texture you want to atlas.

Usage:

  ${0} (all | mushrooms | hlaalu | imperial | redoran | urn | velothi | woodpoles)

EOF
  exit 1
}

target_exists() {
  local target_file="$1"
  if [ -f "ATL/${target_file}" ]; then
    echo "The file '${this_dir}/ATL/${target_file}' already exists. Move or remove it, then run this script again."
    exit 1
  fi
}

# Inputs: accept any image extension (by basename)
EXTS=(dds png jpg jpeg tga bmp tif tiff webp)

find_source() {
  local basename="$1"   # e.g. tx_bc_mushroom_01 (NO extension)
  local dir="${2:-.}"
  local ext f

  for ext in "${EXTS[@]}"; do
    f="${dir}/${basename}.${ext}"
    if [ -f "$f" ]; then
      printf '%s' "$f"
      return 0
    fi
  done

  echo "Missing input for '${basename}' (tried: ${EXTS[*]})" >&2
  exit 1
}

if [ -z "${type}" ]; then
  usage
fi

this_dir="$(realpath "$(dirname "$0")")"
cd "$this_dir"
mkdir -p ATL

rm -f ATL/temp*.bmp

# NOTE: -type TrueColor is forced on every final atlas write below.
# Without it, ImageMagick can emit a colormapped (indexed/paletted) TGA
# for low-color or heavily-padded images. DirectXTex's TGA loader
# (used by texconv.exe) does not support colormapped TGA at all, and
# silently reads garbage pixel data for those files -- which is why
# atlases were coming out white after the texconv step.

run_one() {
  local type="$1"

  rm -f ATL/temp*.bmp

  if [ "${type}" == "mushrooms" ]; then
    file1="$(find_source "tx_bc_mushroom_01")"
    file2="$(find_source "tx_bc_mushroom_03")"

    target_file="tx_bc_mushroom_atlas.tga"
    target_exists "$target_file"

    bases=(
      tx_bc_fungusbottom_01
      tx_bc_fungustop_01
      tx_bc_fungustop_02
      tx_bc_fungusbottom_02
      tx_bc_mushroom_04
      tx_bc_mushroom_01
      tx_bc_mushroom_02
      tx_bc_mushroom_02
    )

    to_resolved=()
    for b in "${bases[@]}"; do
      to_resolved+=("$(find_source "$b")")
    done

    resolutionW="$(magick convert "$file1" -format %w info:)"
    magick convert "$file2" "$file2" +append "ATL/temp1.bmp"

    magick convert "${to_resolved[@]}" "ATL/temp1.bmp" "ATL/temp1.bmp" -resize "${resolutionW}" -append \
      -type TrueColor -compress none "ATL/$target_file"

  elif [ "${type}" == "hlaalu" ]; then
    file1="$(find_source "tx_hlaalu_wall2_01")"

    target_file="tx_hlaalu_atlas.tga"
    target_exists "$target_file"

    bases=(
      tx_hlaalu_wall2_01
      tx_hlaalu_wall2_02
      tx_hlaalu_wall2_03
      tx_hlaalu_sideedge_01
      tx_hlaalu_topedge_01
      tx_hlaalu_topedge_02
      tx_hlaalu_topedge_03
    )

    to_resolved=()
    for b in "${bases[@]}"; do
      to_resolved+=("$(find_source "$b")")
    done

    resolutionW="$(magick convert "$file1" -format %w info:)"
    resolutionH="$((resolutionW * 4))"

    magick convert "${to_resolved[@]}" -resize "${resolutionW}" -append \
      -gravity north -background black -extent "x${resolutionH}" \
      -type TrueColor -compress none "ATL/$target_file"

  elif [ "${type}" == "imperial" ]; then
    resolutionW="$(magick convert "$(find_source "tx_imp_floor_01")" -format %w info:)"
    target_file="tx_imperial_atlas1.tga"
    target_exists "$target_file"

    magick convert \
      "$(find_source "tx_imp_block_01")" "$(find_source "tx_imp_block_02")" "$(find_source "tx_imp_block_03")" "$(find_source "tx_imp_block_03")" \
      +append "ATL/temp1.bmp"

    magick convert "$(find_source "tx_imp_botfront_01")" "$(find_source "tx_imp_botfront_01")" -append "ATL/temp2.bmp"
    magick convert "$(find_source "tx_imp_botside_01")" "$(find_source "tx_imp_botside_01")" -append "ATL/temp3.bmp"
    magick convert "ATL/temp2.bmp" "ATL/temp3.bmp" +append -rotate "90" "ATL/temp4.bmp"

    magick convert "$(find_source "tx_imp_colthin_01")" "$(find_source "tx_imp_colthin_02")" "$(find_source "tx_imp_colwide_01")" +append -rotate "90" "ATL/temp5.bmp"
    magick convert "$(find_source "tx_imp_foursquares_01")" "$(find_source "tx_imp_foursquares_01")" +append "ATL/temp6.bmp"
    magick convert "$(find_source "tx_imp_full_01")" "$(find_source "tx_imp_full_01")" +append "ATL/temp7.bmp"
    magick convert "$(find_source "tx_imp_half_01")" "$(find_source "tx_imp_half_01")" "$(find_source "tx_imp_half_01")" "$(find_source "tx_imp_half_01")" +append "ATL/temp8.bmp"

    magick convert "$(find_source "tx_imp_midfront_01")" "$(find_source "tx_imp_midside_01")" +append "ATL/temp9.bmp"
    magick convert "ATL/temp9.bmp" "ATL/temp9.bmp" "ATL/temp9.bmp" "ATL/temp9.bmp" -append -rotate "90" "ATL/temp10.bmp"

    magick convert "$(find_source "tx_imp_plain_01")" "$(find_source "tx_imp_plain_01")" +append "ATL/temp11.bmp"
    magick convert "$(find_source "tx_imp_stripdark_01")" "$(find_source "tx_imp_stripdark_01")" +append "ATL/temp12.bmp"
    magick convert "$(find_source "tx_imp_stripmed_01")" "$(find_source "tx_imp_stripmed_01")" +append "ATL/temp13.bmp"

    magick convert "$(find_source "tx_imp_topfront_01")" "$(find_source "tx_imp_topside_01")" +append "ATL/temp14.bmp"
    magick convert "ATL/temp14.bmp" "ATL/temp14.bmp" -append -rotate "90" "ATL/temp15.bmp"

    magick convert \
      "$(find_source "tx_imp_archtop_01")" \
      "ATL/temp1.bmp" "ATL/temp4.bmp" \
      "$(find_source "tx_imp_ceiling_01")" \
      "$(find_source "tx_imp_ceiling_strip_01")" \
      "$(find_source "tx_imp_ceiling_strip_02")" \
      "ATL/temp5.bmp" \
      "$(find_source "tx_imp_floor_01")" \
      "$(find_source "tx_imp_floor_02")" \
      "ATL/temp6.bmp" "ATL/temp7.bmp" "ATL/temp8.bmp" "ATL/temp10.bmp" "ATL/temp11.bmp" \
      "$(find_source "tx_imp_step_01")" "$(find_source "tx_imp_step_02")" "$(find_source "tx_imp_step_03")" "$(find_source "tx_imp_step_04")" "$(find_source "tx_imp_step_05")" "$(find_source "tx_imp_step_06")" "$(find_source "tx_imp_step_06")" \
      "ATL/temp12.bmp" "ATL/temp13.bmp" "ATL/temp15.bmp" \
      -resize "${resolutionW}" -append -type TrueColor -compress none "ATL/$target_file"

    magick convert \
      "$(find_source "tx_imp_wall_01")" \
      "$(find_source "tx_imp_wall_02")" \
      "$(find_source "tx_imp_wall_03")" \
      "$(find_source "tx_imp_walltop_01")" "$(find_source "tx_imp_walltop_01")" "$(find_source "tx_imp_walltop_01")" "$(find_source "tx_imp_walltop_01")" \
      -resize "${resolutionW}" -append -type TrueColor -compress none "ATL/$target_file"

  elif [ "${type}" == "redoran" ]; then
    file1="$(find_source "tx_redoran_marble_red")"
    resolutionW="$(magick convert "$file1" -format %w info:)"
    resolutionH="$((resolutionW * 4))"

    target_file="tx_redoran_atlas.tga"
    target_exists "$target_file"

    magick convert "$(find_source "tx_redoran_barracks_trim")" "$(find_source "tx_redoran_barracks_trim")" +append "ATL/temp1.bmp"
    magick convert "$(find_source "tx_border_redoran_step_01")" "$(find_source "tx_border_redoran_step_01")" +append "ATL/temp2.bmp"
    magick convert "$(find_source "tx_block_adobe_white_01")" "$(find_source "tx_block_adobe_white_01")" +append "ATL/temp3.bmp"
    magick convert "$(find_source "tx_redoran_brokenedge_01")" "$(find_source "tx_redoran_brokenedge_01")" "$(find_source "tx_redoran_brokenedge_01")" "$(find_source "tx_redoran_brokenedge_01")" +append "ATL/temp4.bmp"

    magick convert \
      "$(find_source "tx_redoran_marble_red")" \
      "$(find_source "tx_redoran_marble_white")" \
      "$(find_source "tx_redoran_tavern_01")" \
      "ATL/temp1.bmp" "ATL/temp1.bmp" "ATL/temp2.bmp" "ATL/temp3.bmp" "ATL/temp3.bmp" \
      -resize "${resolutionW}" -append \
      -gravity north -background black -extent "x${resolutionH}" \
      -type TrueColor -compress none "ATL/$target_file"

    magick convert \
      "$(find_source "tx_redoran_hut_00")" "$(find_source "tx_redoran_hut_00")" "$(find_source "tx_redoran_hut_00")" \
      "ATL/temp1.bmp" "ATL/temp1.bmp" "ATL/temp4.bmp" "ATL/temp4.bmp" \
      -resize "${resolutionW}" -append \
      -gravity north -background black -extent "x${resolutionH}" \
      -type TrueColor -compress none "ATL/tx_redwall_atlas.tga"

  elif [ "${type}" == "urn" ]; then
    resolutionW="$(magick convert "$(find_source "tx_urn_01")" -format %w info:)"

    magick convert "$(find_source "tx_urn_plain_01")" "$(find_source "tx_urn_plain_01")" +append "ATL/temp1.bmp"

    magick convert \
      "$(find_source "tx_urn_01")" \
      "$(find_source "tx_urn_01")" \
      "$(find_source "tx_urn_top_01")" \
      "ATL/temp1.bmp" \
      "$(find_source "tx_urn_strip_01")" \
      "$(find_source "tx_urn_strip_01")" \
      -resize "${resolutionW}" -append -type TrueColor -compress none "ATL/tx_urns_atlas.tga"

  elif [ "${type}" == "velothi" ]; then
    file1="$(find_source "tx_v_floor_01")"
    file2="$(find_source "tx_v_bridgedetail_04")"

    resolutionW="$(magick convert "$file1" -format %w info:)"
    resolutionH="$((resolutionW * 16))"

    magick convert "$(find_source "tx_block_adobe_redbrown_01")" "$(find_source "tx_block_adobe_redbrown_01")" +append "ATL/temp1.bmp"

    resolutionBH="$(magick convert "$file2" -format %h info:)"
    resolutionBW="$(magick convert "$file2" -format %w info:)"
    if [ "${resolutionBH}" != "${resolutionBW}" ]; then
      magick convert "$file2" -gravity north -background black -extent "x${resolutionBW}" "$file2"
    fi

    magick convert "$file2" "$file2" +append "ATL/temp2.bmp"

    magick convert \
      "ATL/temp1.bmp" "ATL/temp2.bmp" \
      "$(find_source "tx_v_floor_01")" \
      "$(find_source "tx_v_entcover_01")" \
      "$(find_source "tx_v_bridgedetail_03")" \
      "$(find_source "tx_v_bridgedetail_01")" \
      "$(find_source "tx_v_base_10")" "$(find_source "tx_v_base_09")" "$(find_source "tx_v_base_07")" "$(find_source "tx_v_base_04")" "$(find_source "tx_v_base_02")" "$(find_source "tx_v_base_01")" \
      "$(find_source "tx_v_strip_02")" "$(find_source "tx_v_strip_04")" "$(find_source "tx_v_strip_03")" "$(find_source "tx_v_strip_01")" \
      "$(find_source "tx_v_base_08")" \
      "$(find_source "tx_wall_adobe_brown_02")" \
      "$(find_source "tx_v_b_base_01")" \
      -resize "${resolutionW}" -append \
      -gravity south -background black -extent "x${resolutionH}" \
      -type TrueColor -compress none "ATL/atlas_velothi.tga"

  elif [ "${type}" == "woodpoles" ]; then
    resolutionH="$(magick convert "$(find_source "tx_wood_brown_posts_02")" -format %w info:)"
    resolutionHalf="$((resolutionH / 2))"

    magick convert \
      "$(find_source "tx_wood_brown_rings_01")" \
      "$(find_source "tx_wood_dock_rings")" \
      -resize "${resolutionHalf}" +append "ATL/temp1.bmp"

    magick convert "$(find_source "tx_wood_wethered")" -rotate "90" "ATL/temp2.bmp"
    magick convert -size 6x8 xc:black "ATL/temp3.bmp"

    magick convert "$(find_source "tx_rope_brown_02")" "$(find_source "tx_rope_brown_02")" -append "ATL/temp4.bmp"
    magick convert "$(find_source "tx_rope_heavy")" -rotate "90" "ATL/temp5.bmp"

    magick convert \
      "$(find_source "tx_wood_brown_posts_02")" \
      "ATL/temp1.bmp" "ATL/temp2.bmp" "ATL/temp3.bmp" "ATL/temp4.bmp" "ATL/temp5.bmp" \
      -resize "x${resolutionH}" +append \
      -type TrueColor -compress none "ATL/atlas_woodpoles.tga"
  fi

  rm -f "${this_dir}"/ATL/temp*.bmp
  echo "Conversion of '${type}' is completed."
}

if [ "${type}" == "all" ]; then
  for t in mushrooms hlaalu imperial redoran urn velothi woodpoles; do
    run_one "$t"
  done
else
  run_one "$type"
fi

echo "Done. Atlases:"
ls -1 "${this_dir}"/ATL/*_atlas*.tga 2>/dev/null || true
