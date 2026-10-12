-- Console entry point for the toolkit's pack command, without its GUI launcher.
package.path = './?.lua;./?/init.lua;' .. package.path
require 'utility'
local filesystem = require 'bee.filesystem'
_W2L_DIR = filesystem.path(arg[1]):parent_path():string()
local build_failed = false
local function console_message(message)
    io.stderr:write(message, '\n')
end
package.loaded['share.messager'] = {
    text = console_message,
    raw = console_message,
    title = function() end,
    progress = function() end,
    wait = function() end,
    report = function(report_type, severity, message, detail)
        if severity <= 2 then
            build_failed = true
            console_message(message)
            if detail then console_message(detail) end
        end
    end,
    exit = function(status, message)
        if status ~= 'success' then build_failed = true end
        console_message(message)
    end,
}

local source_directory = filesystem.path(arg[1])
local output_map_path = filesystem.path(arg[2])
local prepared_script_path = filesystem.path(assert(arg[5], 'Missing prepared JASS path'))
local supplied_script = assert(io.load(prepared_script_path), 'Cannot read prepared JASS')
assert(arg[3] == 'dev' or arg[3] == 'release', 'Unsupported build mode')
local build_language = arg[4] or 'en'
assert(build_language == 'en' or build_language == 'ru', 'Unsupported build language')
local file_overrides = {}
if build_language == 'ru' then
    local localization = assert(loadfile((filesystem.path(arg[0]):parent_path() / 'localize-map.lua'):string()))()
    local translated_fields, translated_files
    file_overrides, translated_fields, translated_files = localization.load_overrides(filesystem,
        source_directory, source_directory:parent_path() / 'w3x-content-ru')
    console_message(('RU: %d translated fields in %d profiles; other text uses the base language'):format(
        translated_fields, translated_files))
end
file_overrides['scripts/war3map.j'] = supplied_script
local load_plugins = require 'backend.plugin'
package.loaded['backend.plugin'] = function(converter, register_plugin)
    load_plugins(converter, register_plugin)
    register_plugin('Build', {
        info = { name = 'Build text and script' },
        on_pack = function(plugin, converter, output_archive)
            for filename, content in pairs(file_overrides) do
                output_archive:set(filename:gsub('/', '\\'), content)
            end
        end,
    })
end

table.insert(arg, 1, 'pack')
local succeeded, failure = xpcall(function()
    require('backend.cli.pack')()
    if build_failed then return end
    local preserve_original_hashes = assert(loadfile(
        (filesystem.path(arg[0]):parent_path() / 'preserve-original-hashes.lua'):string()))()
    preserve_original_hashes(output_map_path)
    local archive = assert(require('ffi.stormlib').open(output_map_path, true))
    for filename, expected_content in pairs(file_overrides) do
        assert(archive:load_file(filename:gsub('/', '\\')) == expected_content,
            'Missing or incorrect packed override: ' .. filename)
    end
    local file_list = assert(archive:load_file('(listfile)'))
    for filename in file_list:gmatch('[^\r\n]+') do
        local expected_content = file_overrides[filename:gsub('\\', '/'):lower()]
            or assert(io.load(source_directory / filename), filename)
        assert(archive:load_file(filename) == expected_content,
            'Packed file differs from source: ' .. filename)
    end
    archive:close()
end, debug.traceback)
if not succeeded then console_message(failure) end
os.exit(succeeded and not build_failed and 0 or 1)
