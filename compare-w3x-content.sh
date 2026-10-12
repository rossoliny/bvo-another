#!/usr/bin/env bash
# Ladik: Open MPQ(s); Additional Listfile: lisfile/listfile.last.txt; Read-only + Deep file verification.
# Tools -> W3X Name Scanner -> Map File Scanner -> Scan -> Apply List.
# Выдели все файлы/папки -> Operations -> Extract в пустую папку, сохранив подпапки.
# File000... имеют искусственные имена: их содержимое сравнивается отдельно.
set -euo pipefail

original_directory=$(realpath -- "${1:?Usage: $0 extracted-original [current-directory]}")
current_directory=$(realpath -- "${2:-$(dirname -- "${BASH_SOURCE[0]}")/w3x-content}")
[[ -d "$original_directory" && -d "$current_directory" ]]

declare -A current_paths current_hashes
while IFS= read -r -d '' checksum_entry; do
    current_file=${checksum_entry:66}
    checksum=${checksum_entry:0:64}
    relative_path=${current_file#"$current_directory/"}
    relative_path=${relative_path,,}
    current_paths["$relative_path"]=$current_file
    current_hashes["$relative_path"]=$checksum
done < <(find "$current_directory" -type f -exec sha256sum -z -- {} +)

identical_count=0 different_count=0 missing_count=0
while IFS= read -r -d '' checksum_entry; do
    original_file=${checksum_entry:66}
    original_hash=${checksum_entry:0:64}
    relative_path=${original_file#"$original_directory/"}
    relative_path=${relative_path,,}
    if [[ -z ${current_paths[$relative_path]-} ]]; then
        printf 'MISSING\t%s\t%s\n' "$relative_path" "$original_hash"
        ((++missing_count))
    elif [[ $original_hash != "${current_hashes[$relative_path]}" ]]; then
        printf 'DIFFERENT\t%s\t%s\t%s\n' "$relative_path" "$original_hash" "${current_hashes[$relative_path]}"
        ((++different_count))
    else
        ((++identical_count))
    fi
    unset 'current_paths[$relative_path]'
done < <(find "$original_directory" -type f -exec sha256sum -z -- {} +)

for relative_path in "${!current_paths[@]}"; do
    printf 'ADDED\t%s\t%s\n' "$relative_path" "${current_hashes[$relative_path]}"
done
printf 'TOTAL\tidentical=%d\tdifferent=%d\tmissing=%d\tadded=%d\n' \
    "$identical_count" "$different_count" "$missing_count" "${#current_paths[@]}"
