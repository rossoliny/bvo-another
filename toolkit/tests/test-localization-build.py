"""Check real EN/RU packing using temporary translations and a copied map in build/."""

from hashlib import sha256
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


def file_hashes(directory):
    return {path.relative_to(directory).as_posix(): sha256(path.read_bytes()).hexdigest()
            for path in directory.rglob('*') if path.is_file()}


def run_checked(command, **options):
    completed = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, **options)
    assert completed.returncode == 0, completed.stdout.decode('utf-8', errors='replace')
    return completed.stdout


def without_cheats(script):
    output = []
    in_cheat_function = False
    for line in script.splitlines(keepends=True):
        if re.match(rb'\s*function TestCommands_', line):
            in_cheat_function = True
        if in_cheat_function:
            if re.match(rb'\s*endfunction', line):
                in_cheat_function = False
            continue
        if b'TestCommands_' not in line:
            output.append(line)
    return b''.join(output)


def main():
    repository = Path(__file__).resolve().parents[2]
    build_directory = (repository / 'build').resolve()
    build_directory.mkdir(exist_ok=True)
    converter_directory = repository / 'toolkit/W3x2Lni v2.7.2'
    lua_runtime = str(converter_directory / 'bin/w3x2lni-lua.exe')
    pack_script = str(repository / 'toolkit/pack-map.lua')
    for arguments in (['--lang'], ['--lang', 'de'], ['--lang', 'en,'],
                      ['--lang', 'en,en'], ['--lang', 'en', '--lang', 'ru']):
        completed = subprocess.run(['bash', str(repository / 'build-w3x.sh'), *arguments],
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        assert completed.returncode != 0 and b'pjass attempt' not in completed.stdout
    print('PASS: invalid and repeated language flags fail before build work')

    with tempfile.TemporaryDirectory(prefix='.localization-test-', dir=build_directory) as temporary_directory:
        fixture = Path(temporary_directory).resolve()
        assert fixture.is_relative_to(build_directory)
        source_directory = fixture / 'w3x-content'
        shutil.copytree(repository / 'w3x-content', source_directory)
        translation_directory = fixture / 'w3x-content-ru'
        (translation_directory / 'units').mkdir(parents=True)
        (translation_directory / 'README.md').write_text('Not packed', encoding='utf-8')
        translation_file = translation_directory / 'units/itemstrings.txt'
        translation_file.write_text('[I000]\nName=Сердце Баунта\nTip=Купить Сердце Баунта\n', encoding='utf-8')
        source_hashes = file_hashes(source_directory)
        translation_hashes = file_hashes(translation_directory)
        original_script = (source_directory / 'scripts/war3map.j').read_bytes()
        for build_mode in ('dev', 'release'):
            script = original_script if build_mode == 'dev' else without_cheats(original_script)
            assert (b'TestCommands_' in script) == (build_mode == 'dev')
            script_file = fixture / f'{build_mode}.j'
            script_file.write_bytes(script)
            maps = []
            for language in ('en', 'ru'):
                output_map = fixture / f'{build_mode}_{language}.w3x'
                run_checked([lua_runtime, pack_script, str(source_directory), str(output_map), build_mode, language, str(script_file)],
                            cwd=converter_directory / 'script')
                assert output_map.read_bytes()[:4] == b'HM3W'
                maps.append(output_map)
            verification = run_checked([lua_runtime, str(repository / 'toolkit/tests/check-localized-maps.lua'),
                                        *map(str, maps), str(script_file), str(source_directory / 'units/itemstrings.txt')],
                                       cwd=converter_directory / 'script')
            print(build_mode + ': ' + verification.decode('utf-8').strip())
        assert source_hashes == file_hashes(source_directory)
        assert translation_hashes == file_hashes(translation_directory)
        print('PASS: all source and translation hashes are unchanged by packing')

        for relative_filename, content in (('units/itemstrings.txt', '[I000]\nOrder=doom\n'),
                                            ('units/itemstrings_RU.txt', '[I000]\nName=Text\n'),
                                            ('scripts/war3map.j', 'function ChangedGameplay\n')):
            invalid_file = translation_directory / relative_filename
            invalid_file.parent.mkdir(exist_ok=True)
            invalid_file.write_text(content, encoding='utf-8')
            output_map = fixture / 'rejected.w3x'
            completed = subprocess.run([lua_runtime, pack_script, str(source_directory), str(output_map), 'dev', 'ru', str(fixture / 'dev.j')],
                                       cwd=converter_directory / 'script',
                                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            assert completed.returncode != 0 and not output_map.exists(), completed.stdout.decode('utf-8', errors='replace')
            invalid_file.unlink()
        print('PASS: gameplay fields, postfix files and scripts fail before map creation')

    report = converter_directory / 'log/report.log'
    report.unlink(missing_ok=True)
    if report.parent.exists() and not any(report.parent.iterdir()):
        report.parent.rmdir()
    print('Localization packing checks passed')


if __name__ == '__main__':
    main()
