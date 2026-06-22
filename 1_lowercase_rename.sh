#!/usr/bin/env bash
set -euo pipefail

root="$(realpath "$(dirname "$0")")"
cd "$root"

auto_yes=0
if [[ "${1:-}" == "-y" || "${1:-}" == "--yes" ]]; then
  auto_yes=1
fi

echo "INFO: Renaming dds/tga/bmp recursively to lowercase under:"
echo "    $root"
echo

if [[ "$auto_yes" -eq 0 ]]; then
  echo "INFO: Press Enter to proceed, Ctrl-C to cancel..."
  read -r
fi

find . -type f \( -iname '*.dds' -o -iname '*.tga' -o -iname '*.bmp' \) -print0 |
while IFS= read -r -d '' f; do
  dir="$(dirname "$f")"
  base="$(basename "$f")"
  lower="$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]')"
  if [[ "$base" != "$lower" ]]; then
    if [[ -e "$dir/$lower" ]]; then
      echo "SKIP: target exists: $dir/$lower"
      continue
    fi
    mv -v -- "$f" "$dir/$lower"
  fi
done
