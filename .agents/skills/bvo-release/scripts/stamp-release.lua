-- Run with the repository's W3x2Lni Lua runtime from its script/ directory.
local metadata = {}

local function escape_jass(text)
    return (text:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\r', ''):gsub('\n', '\\n'))
end

function metadata.identity(tag, date, url)
    assert(tag:match('^#%d+%.%d+[%d%.]*$') and not tag:match('%.%.') and not tag:match('%.$'),
        'Expected a release tag such as #1.4')
    local year, month, day = date:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
    year, month, day = tonumber(year), tonumber(month), tonumber(day)
    assert(year and year >= 2000 and month >= 1 and month <= 12, 'Invalid release date')
    local month_lengths = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
    if year % 400 == 0 or (year % 4 == 0 and year % 100 ~= 0) then month_lengths[2] = 29 end
    assert(day >= 1 and day <= month_lengths[month], 'Invalid release date')
    local expected_url = 'https://github.com/rossoliny/bvo-another/releases/tag/%23' .. tag:sub(2)
    assert(url == expected_url, 'Release URL must refer to the supplied tag')
    return { tag = tag, date = string.format('%02d.%02d.%04d', day, month, year), url = url }
end

local function resolve_string(text, string_table)
    local string_id = text:match('^TRIGSTR_(%d+)$')
    if not string_id then return text end
    assert(string_table, 'Missing map string table')
    for entry_id, entry_text in string_table:gmatch('STRING%s+(%d+)%s*{(.-)}') do
        if tonumber(entry_id) == tonumber(string_id) then
            return entry_text:match('^%s*(.-)%s*$')
        end
    end
    error('Missing map string: ' .. text)
end

function metadata.map_info(content, string_table, identity)
    assert(string.unpack('<I4', content) == 25, 'Unsupported W3I version; expected this map\'s format 25')
    local name, author, description, players, next_position = string.unpack('zzzz', content, 13)
    name = resolve_string(name, string_table)
    description = resolve_string(description, string_table)
    assert(name:match('^BvO Another'), 'Unexpected map identity')
    local display_name = name:gsub(' #%d+[%d%.]*$', '') .. ' ' .. identity.tag
    assert(not description:find('Release #%d'), 'Use a fresh bvo-build output, not an already stamped map')
    description = description .. '\r\n\r\nRelease ' .. identity.tag .. ' — ' .. identity.date .. '\r\n' .. identity.url
    return content:sub(1, 12) .. string.pack('zzzz', display_name, author, description, players)
        .. content:sub(next_position), display_name
end

function metadata.script(content, display_name, identity)
    assert(not content:find('TestCommands_', 1, true), 'Cheat code remains in the map; run bvo-build --release')
    assert(not content:find('"-oneshot"', 1, true), 'A cheat command remains in the map')
    local description_prefix = 'call%s+CreateQuestBJ%(%s*2%s*,%s*"Latest Version"%s*,%s*"'
    local call_start, quote_position = content:find(description_prefix)
    assert(call_start, 'INFO / Latest Version entry not found')
    assert(not content:find(description_prefix, quote_position + 1), 'Multiple Latest Version entries')
    local closing_quote = quote_position + 1
    while closing_quote <= #content do
        local character = content:sub(closing_quote, closing_quote)
        if character == '\\' then
            closing_quote = closing_quote + 2
        elseif character == '"' then
            break
        else
            closing_quote = closing_quote + 1
        end
    end
    assert(closing_quote <= #content, 'Unterminated INFO description')
    local release_description = display_name .. '\nRelease ' .. identity.tag .. ' — ' .. identity.date
        .. '\n|c001ce6b9' .. identity.url .. '|r'
    content = content:sub(1, quote_position) .. escape_jass(release_description) .. content:sub(closing_quote)
    local replacements
    content, replacements = content:gsub('(call%s+SetMapName%()([^\r\n]-)(%))', function(prefix, argument, suffix)
        return prefix .. '"' .. escape_jass(display_name) .. '"' .. suffix
    end)
    assert(replacements == 1, 'Expected one lobby SetMapName call')
    return content
end

function metadata.header(content, display_name)
    assert(#content == 512 and content:sub(1, 4) == 'HM3W', 'Unsupported outer map header')
    local old_name, flags_position = string.unpack('z', content, 9)
    local remainder = content:sub(flags_position)
    local available = 512 - 8 - #display_name - 1
    assert(available >= 8, 'Release map name is too long')
    if #remainder > available then
        assert(remainder:sub(available + 1):match('^%z*$'), 'Map header contains unexpected trailing data')
        remainder = remainder:sub(1, available)
    end
    return content:sub(1, 8) .. display_name .. '\0' .. remainder .. string.rep('\0', available - #remainder)
end

if ... == 'module' then return metadata end

package.path = './?.lua;./?/init.lua;' .. package.path
require 'utility'
local filesystem = require 'bee.filesystem'
local stormlib = require 'ffi.stormlib'
assert(#arg == 7 and arg[7] == 'resolved-paths', 'Run prepare-map.py, which validates canonical paths first')
local repository = filesystem.absolute(filesystem.path(arg[1]))
local input_path = filesystem.absolute(filesystem.path(arg[2]))
local output_argument = filesystem.path(arg[3])
local output_parent = filesystem.absolute(output_argument):parent_path()
local output_path = output_parent / output_argument:filename()
local build_root = (repository / 'build'):string():gsub('\\', '/'):lower()
local normalized_parent = output_parent:string():gsub('\\', '/'):lower()
assert(normalized_parent == build_root or normalized_parent:sub(1, #build_root + 1) == build_root .. '/',
    'Release maps must stay inside the repository build/ directory')
assert(output_path:extension():string():lower() == '.w3x', 'Output must be a .w3x map')
assert(not filesystem.exists(output_path), 'Output already exists; preserve it or choose a new build filename')
local temporary_path = filesystem.path(output_path:string() .. '.partial.w3x')
local extracted_script_path = filesystem.path(output_path:string() .. '.j')
assert(not filesystem.exists(temporary_path) and not filesystem.exists(extracted_script_path), 'Output sidecar already exists')
local identity = metadata.identity(arg[4], arg[5], arg[6])

local input_archive = assert(stormlib.open(input_path, true), 'Cannot read input map')
local original_files = {}
local file_count = 0
for filename in assert(input_archive:load_file('(listfile)')):gmatch('[^\r\n]+') do
    if filename:sub(1, 1) ~= '(' then
        original_files[filename] = assert(input_archive:load_file(filename), filename)
        file_count = file_count + 1
    end
end
input_archive:close()
local function find_file(required_name)
    for filename, content in pairs(original_files) do
        if filename:lower() == required_name then return filename, content end
    end
end
local script_name, script_content = find_file('scripts\\war3map.j')
local info_name, info_content = find_file('war3map.w3i')
local strings_name, strings_content = find_file('war3map.wts')
assert(script_name and info_name, 'Missing map script or metadata')
local stamped_info, display_name = metadata.map_info(info_content, strings_content, identity)
local stamped_script = metadata.script(script_content, display_name, identity)
local expected_files = { [info_name] = stamped_info, [script_name] = stamped_script }
local original_container = assert(io.load(input_path))
assert(original_container:sub(513, 516) == 'MPQ\26', 'Expected MPQ archive at offset 512')
local stamped_header = metadata.header(original_container:sub(1, 512), display_name)

assert(io.save(temporary_path, original_container), 'Cannot create release map copy')
local output_archive = assert(stormlib.open(temporary_path, false), 'Cannot open release map copy')
for filename, content in pairs(expected_files) do
    assert(output_archive:save_file(filename, content), 'Cannot stamp ' .. filename)
end
output_archive:close()
local container_file = assert(io.open(temporary_path:string(), 'r+b'))
assert(container_file:write(stamped_header))
container_file:close()

local verified_archive = assert(stormlib.open(temporary_path, true))
local verified_count = 0
for filename in assert(verified_archive:load_file('(listfile)')):gmatch('[^\r\n]+') do
    if filename:sub(1, 1) ~= '(' then
        assert(original_files[filename], 'Unexpected new archive file: ' .. filename)
        verified_count = verified_count + 1
    end
end
assert(verified_count == file_count, 'Archive file inventory changed')
for filename, original_content in pairs(original_files) do
    assert(verified_archive:load_file(filename) == (expected_files[filename] or original_content),
        'Unexpected resource change: ' .. filename)
end
verified_archive:close()
assert(io.load(input_path) == original_container, 'Input map changed')
assert(io.save(extracted_script_path, stamped_script), 'Cannot save final script for pjass verification')
filesystem.rename(temporary_path, output_path)
print('Prepared: ' .. output_path:string())
print('Final JASS: ' .. extracted_script_path:string())
print('Verified ' .. file_count .. ' archive files; only INFO, lobby name and map metadata changed')
