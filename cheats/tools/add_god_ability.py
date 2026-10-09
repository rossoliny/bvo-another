"""Append the Warcraft 1.26-compatible cheat passive to a war3map.w3a file.

Usage: python cheats/tools/add_god_ability.py INPUT.w3a OUTPUT.w3a
Existing object records are preserved byte for byte.
"""
from pathlib import Path
import struct
import sys

DESCRIPTION = "Неуязвимость режима -whosyourdaddy. Updated by Rossoliny."


def read_table(data, offset):
    count = struct.unpack_from("<i", data, offset)[0]
    offset += 4
    if count < 0:
        raise ValueError("Negative object count")
    identifiers = set()
    for _ in range(count):
        original, custom = data[offset:offset + 4], data[offset + 4:offset + 8]
        identifiers.add(custom if custom != b"\0" * 4 else original)
        mods = struct.unpack_from("<i", data, offset + 8)[0]
        offset += 12
        if mods < 0:
            raise ValueError("Negative modification count")
        for _ in range(mods):
            kind = struct.unpack_from("<i", data, offset + 4)[0]
            offset += 16  # field, type, level, data pointer
            if kind == 3:
                offset = data.index(b"\0", offset) + 1
            elif kind in (0, 1, 2):
                offset += 4
            else:
                raise ValueError(f"Unknown field type {kind}")
            offset += 4  # end marker
            if offset > len(data):
                raise ValueError("Truncated object data")
    return offset, count, identifiers


def add_god_ability(data):
    if struct.unpack_from("<i", data)[0] != 2:
        raise ValueError("Expected Warcraft 1.26 object format version 2")
    custom_offset, _, originals = read_table(data, 4)
    end, count, customs = read_table(data, custom_offset)
    # Some editor exports keep one zero dword after the two object tables.
    if data[end:] not in (b"", b"\0" * 4):
        raise ValueError("Unexpected trailing object data")
    if b"ATwd" in originals | customs:
        raise ValueError("ATwd already exists; refusing to replace an ability")

    def integer(field, value):
        return field + struct.pack("<iiii", 0, 0, 0, value) + b"ATwd"

    def string(field, value, level=0):
        return field + struct.pack("<iii", 3, level, 0) + value.encode("utf-8") + b"\0ATwd"

    fields = [integer(b"aher", 0), integer(b"alev", 1),
              string(b"anam", "WhosYourDaddy (cheat)"), string(b"aart", ""),
              string(b"atp1", "WhosYourDaddy", 1),
              string(b"aub1", DESCRIPTION, 1), string(b"aret", DESCRIPTION, 1)]
    record = b"AvulATwd" + struct.pack("<i", len(fields)) + b"".join(fields)
    return (data[:custom_offset] + struct.pack("<i", count + 1)
            + data[custom_offset + 4:end] + record + data[end:])


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    source, destination = map(Path, sys.argv[1:])
    output = add_god_ability(source.read_bytes())
    destination.write_bytes(output)
    print(f"Added ATwd: {destination}")
