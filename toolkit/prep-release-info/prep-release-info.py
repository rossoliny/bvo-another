"""Replace existing release versions and dates in the four map source files.

Run manually before the builder:
    python toolkit/prep-release-info/prep-release-info.py 1.5 12.10.2026

Release strings must already exist. This script does not add text or formatting.
"""

import argparse
from datetime import datetime
from pathlib import Path
import re
import struct


VERSION_VALUE = rb"[0-9]+(?:\.[0-9]+)*(?:[A-Za-z][A-Za-z0-9]*|-[A-Za-z0-9.-]+)?"
JASS_STRING = rb'(?P<text>(?:\\.|[^"\\\r\n])*)'


def update_release_values(content, release_version, release_date, needs_date=True):
    updated_content, version_count = re.subn(
        rb"(Rossoliny[ \t]+|Release:[ \t]+)" + VERSION_VALUE,
        lambda version_match: version_match[1] + release_version,
        content,
    )
    if not version_count:
        raise ValueError("missing release version after 'Rossoliny ' or 'Release: '")
    if needs_date:
        updated_content, date_count = re.subn(
            rb"(Date:[ \t]+)[0-9]{2}\.[0-9]{2}\.[0-9]{4}",
            lambda date_match: date_match[1] + release_date,
            updated_content,
        )
        if not date_count:
            raise ValueError("missing release date in 'Date: DD.MM.YYYY'")
    return updated_content


def update_text_field(content, field_pattern, release_version, release_date, needs_date=True):
    field_matches = list(re.finditer(field_pattern, content, re.MULTILINE | re.DOTALL))
    if len(field_matches) != 1:
        raise ValueError(f"expected one field matching {field_pattern!r}, found {len(field_matches)}")
    field_match = field_matches[0]
    updated_text = update_release_values(
        field_match["text"], release_version, release_date, needs_date
    )
    return content[:field_match.start("text")] + updated_text + content[field_match.end("text"):]


def read_map_strings(content, position, field_count):
    map_strings = []
    for field_index in range(field_count):
        string_end = content.index(b"\0", position)
        map_strings.append(content[position:string_end])
        position = string_end + 1
    return map_strings, position


def update_map_info(content, release_version, release_date):
    if struct.unpack_from("<I", content)[0] != 25:
        raise ValueError("unsupported war3map.w3i format; expected 25")
    map_fields, map_fields_end = read_map_strings(content, 12, 4)
    loading_fields_start = map_fields_end + 65  # Camera, dimensions, flags, tileset, loading ID.
    loading_fields, loading_fields_end = read_map_strings(content, loading_fields_start, 4)
    map_fields[0] = update_release_values(map_fields[0], release_version, release_date, False)
    map_fields[2] = update_release_values(map_fields[2], release_version, release_date)
    loading_fields[2] = update_release_values(loading_fields[2], release_version, release_date, False)
    loading_fields[3] = update_release_values(loading_fields[3], release_version, release_date)
    return (
        content[:12]
        + b"\0".join(map_fields) + b"\0"
        + content[map_fields_end:loading_fields_start]
        + b"\0".join(loading_fields) + b"\0"
        + content[loading_fields_end:]
    )


def update_map_script(content, release_version, release_date):
    content = update_text_field(
        content, rb'\bcall[ \t]+SetMapName\([ \t]*"' + JASS_STRING + rb'"[ \t]*\)',
        release_version, release_date, False,
    )
    content = update_text_field(
        content, rb'\bcall[ \t]+SetMapDescription\([ \t]*"' + JASS_STRING + rb'"[ \t]*\)',
        release_version, release_date,
    )
    for quest_title in (b"Contacts", b"Latest Version"):
        content = update_text_field(
            content,
            rb'\bcall[ \t]+CreateQuestBJ\([^,\r\n]+,[ \t]*"' + quest_title
            + rb'",[ \t]*"' + JASS_STRING + rb'"',
            release_version, release_date,
        )
    return content


def update_map_strings(content, release_version, release_date):
    for string_id in (3, 4654, 5692, 6743, 6747):
        content = update_text_field(
            content,
            rb"^STRING " + str(string_id).encode("ascii")
            + rb"\r?\n\{\r?\n(?P<text>.*?)(?=\r?\n\})",
            release_version, release_date, string_id not in (3, 4654),
        )
    return content


def update_map_skin(content, release_version, release_date):
    for skin_key in (b"UPKEEP_NONE", b"RESOURCE_UBERTIP_UPKEEP"):
        content = update_text_field(
            content, rb"^" + skin_key + rb"=(?P<text>[^\r\n]*)",
            release_version, release_date, skin_key != b"UPKEEP_NONE",
        )
    return content


def main():
    argument_parser = argparse.ArgumentParser(description=__doc__)
    argument_parser.add_argument("version", help="Rossoliny release version, e.g. 1.5")
    argument_parser.add_argument("date", help="Release date: DD.MM.YYYY")
    arguments = argument_parser.parse_args()
    if not re.fullmatch(VERSION_VALUE, arguments.version.encode("utf-8")):
        argument_parser.error("invalid release version; expected e.g. 1.5 or 1.5-rc.1")
    if not re.fullmatch(r"[0-9]{2}\.[0-9]{2}\.[0-9]{4}", arguments.date):
        argument_parser.error("release date must use DD.MM.YYYY")
    try:
        datetime.strptime(arguments.date, "%d.%m.%Y")
    except ValueError:
        argument_parser.error("invalid calendar date")

    release_version = arguments.version.encode("ascii")
    release_date = arguments.date.encode("ascii")
    content_directory = Path(__file__).resolve().parents[2] / "w3x-content"
    prepared_files = []
    for relative_path, update_function in (
        ("war3map.w3i", update_map_info),
        ("scripts/war3map.j", update_map_script),
        ("war3mapskin.txt", update_map_skin),
        ("war3map.wts", update_map_strings),
    ):
        source_path = content_directory / relative_path
        try:
            original_content = source_path.read_bytes()
            updated_content = update_function(original_content, release_version, release_date)
        except (OSError, ValueError, struct.error) as preparation_error:
            argument_parser.error(f"{source_path}: {preparation_error}; no files written")
        prepared_files.append((source_path, original_content, updated_content))

    # Validate every file before the first write.
    for source_path, original_content, updated_content in prepared_files:
        if updated_content != original_content:
            source_path.write_bytes(updated_content)
            print(f"Updated: {source_path}")
    print(f"Release info prepared: {arguments.version}, {arguments.date}")


if __name__ == "__main__":
    main()
