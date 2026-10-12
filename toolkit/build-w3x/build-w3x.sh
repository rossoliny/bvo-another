#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.."
repository_root=$PWD
build_mode=dev
selected_languages=en
language_option_seen=false
usage() {
    echo "Usage: $0 [--release] [--lang en|ru|en,ru]"
}
while (( $# > 0 )); do
    case $1 in
        --release) build_mode=release; shift ;;
        --lang)
            if (( $# < 2 )) || $language_option_seen; then
                usage >&2; exit 1
            fi
            selected_languages=$2
            language_option_seen=true
            shift 2
            ;;
        --help|-h) usage; exit 0 ;;
        *) usage >&2; exit 1 ;;
    esac
done
case $selected_languages in
    en|ru|en,ru|ru,en) ;;
    *) echo "Unsupported language list: $selected_languages" >&2; usage >&2; exit 1 ;;
esac
IFS=, read -r -a build_languages <<< "$selected_languages"

converter_directory="$repository_root/toolkit/W3x2Lni v2.7.2"
converter="$converter_directory/bin/w3x2lni-lua.exe"
jass_checker="$repository_root/toolkit/JASSCraft113/pjass.exe"
map_script="$repository_root/w3x-content/scripts/war3map.j"
temporary_maps=()
temporary_script=
report="$converter_directory/log/report.log"
cleanup() {
    rm -f -- "${temporary_maps[@]}" "$temporary_script" "$report"
    rmdir -- "$converter_directory/log" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

[[ -x "$converter" && -x "$jass_checker" ]] || {
    echo "Missing executable tool from toolkit/" >&2; exit 1
}
for required_file in scripts/war3map.j war3map.w3i War3map.w3e War3map.wpm; do
    [[ -f "w3x-content/$required_file" ]] || {
        echo "Missing map file: w3x-content/$required_file" >&2
        exit 1
    }
done

if [[ ,$selected_languages, == *,ru,* && ! -d w3x-content-ru ]]; then
    echo "Missing translation directory: w3x-content-ru/" >&2
    exit 1
fi

read_map_script() {
    if [[ $build_mode == dev ]]; then
        cat -- "$map_script"
        return
    fi
    awk '
        /^[[:space:]]*function TestCommands_/ { in_cheat_function = 1 }
        in_cheat_function {
            if (/^[[:space:]]*endfunction/) in_cheat_function = 0
            next
        }
        /TestCommands_/ { next }
        { print }
    ' "$map_script"
}

mkdir -p -- build
temporary_script=$(mktemp "build/.BvO_Another_${build_mode}.XXXXXX.j")
read_map_script > "$temporary_script"
successful_checks=0
for check_attempt in {1..10}; do
    echo "pjass attempt $check_attempt/10"
    if "$jass_checker" "$repository_root/toolkit/JASSCraft113/common.j" \
        "$repository_root/toolkit/JASSCraft113/blizzard.j" "$temporary_script"; then
        successful_checks=$((successful_checks + 1))
    fi
done
case $successful_checks in
    10) check_severity=SUCCESS ;;
    7|8|9) check_severity=WARNING ;;
    4|5|6) check_severity='CRITICAL WARNING' ;;
    1|2|3) check_severity=ERROR ;;
    0) check_severity='CRITICAL ERROR' ;;
esac
echo "$check_severity: pjass $successful_checks/10 successful" >&2
(( successful_checks >= 4 )) || exit 1
for build_language in "${build_languages[@]}"; do
    echo "Packing language: $build_language"
    temporary_map=$(mktemp "build/.BvO_Another_${build_mode}_${build_language}.XXXXXX.w3x")
    temporary_maps+=("$temporary_map")
    (cd -- "$converter_directory/script"
        "$converter" "$repository_root/toolkit/build-w3x/pack-map.lua" \
            "$repository_root/w3x-content" "$repository_root/$temporary_map" \
            "$build_mode" "$build_language" "$repository_root/$temporary_script")
    grep -q '^Result: 0 errors, 0 warnings' "$report" || { cat "$report" >&2; exit 1; }
    [[ -s "$temporary_map" && $(head -c 4 -- "$temporary_map") == HM3W ]]
done
for language_index in "${!build_languages[@]}"; do
    output_map="build/BvO_Another_${build_mode}_${build_languages[$language_index]}.w3x"
    mv -f -- "${temporary_maps[$language_index]}" "$output_map"
    echo "Built: $output_map"
done
