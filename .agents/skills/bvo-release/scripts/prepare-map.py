"""Stamp a separate build map with release metadata using the bundled Lua runtime."""

import argparse
from pathlib import Path
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repository', type=Path, default=Path.cwd())
    parser.add_argument('--input', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--tag', required=True)
    parser.add_argument('--date', required=True, help='Release date: YYYY-MM-DD')
    parser.add_argument('--url', required=True)
    arguments = parser.parse_args()
    repository = arguments.repository.resolve(strict=True)
    input_map = arguments.input.resolve(strict=True)
    output_map = arguments.output.resolve()
    build_directory = (repository / 'build').resolve(strict=True)
    if not output_map.is_relative_to(build_directory) or output_map.suffix.lower() != '.w3x':
        parser.error('Output must be a .w3x map inside this repository\'s build/ directory')
    if output_map.exists() or not output_map.parent.is_dir():
        parser.error('Output must be a new file in an existing build directory')
    if not (repository / '.agents/skills/bvo-build/SKILL.md').is_file():
        parser.error('The repository must contain the bvo-build skill')
    converter_directory = repository / 'toolkit/W3x2Lni v2.7.2'
    helper_script = Path(__file__).with_name('stamp-release.lua').resolve(strict=True)
    completed = subprocess.run([
        str(converter_directory / 'bin/w3x2lni-lua.exe'), str(helper_script),
        str(repository), str(input_map), str(output_map),
        arguments.tag, arguments.date, arguments.url, 'resolved-paths',
    ], cwd=converter_directory / 'script', check=False)
    return completed.returncode


if __name__ == '__main__':
    raise SystemExit(main())
