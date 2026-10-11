-- Console entry point for the toolkit's pack command, without its GUI launcher.
package.path = './?.lua;./?/init.lua;' .. package.path
require 'utility'
local fs = require 'bee.filesystem'
_W2L_DIR = fs.path(arg[1]):parent_path():string()
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

local source_directory = fs.path(arg[1])
local output_map_path = fs.path(arg[2])
local supplied_script = assert(io.read 'a')
local release_script_content = arg[3] == 'release' and supplied_script or nil
local load_plugins = require 'backend.plugin'
package.loaded['backend.plugin'] = function(converter, register_plugin)
    load_plugins(converter, register_plugin)
    if release_script_content then
        register_plugin('Build', {
            info = { name = 'Release script' },
            on_pack = function(plugin, converter, output_archive)
                output_archive:set('scripts\\war3map.j', release_script_content)
            end,
        })
    end
end

table.insert(arg, 1, 'pack')
local succeeded, failure = xpcall(function()
    require('backend.cli.pack')()
    if build_failed then return end
    local archive = assert(require('ffi.stormlib').open(output_map_path, true))
    local file_list = assert(archive:load_file('(listfile)'))
    for filename in file_list:gmatch('[^\r\n]+') do
        local expected_content
        if filename:lower() == 'scripts\\war3map.j' and release_script_content then
            expected_content = release_script_content
        else
            expected_content = assert(io.load(source_directory / filename), filename)
        end
        assert(archive:load_file(filename) == expected_content,
            'Packed file differs from source: ' .. filename)
    end
    archive:close()
end, debug.traceback)
if not succeeded then console_message(failure) end
os.exit(succeeded and not build_failed and 0 or 1)
