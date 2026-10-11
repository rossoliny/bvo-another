local metadata = assert(loadfile(arg[1]))('module')
local release_tag = '#1.4'
local release_date = '2026-10-11'
local release_url = 'https://github.com/rossoliny/bvo-another/releases/tag/%231.4'
local display_name = 'BvO Another v1.1a Rossoliny #1.4'
local passed = 0
local function check(description, test)
    test()
    passed = passed + 1
    print('PASS: ' .. description)
end
local function rejected(operation)
    assert(not pcall(operation), 'Expected rejection')
end

check('release identity and calendar dates are validated', function()
    assert(metadata.identity(release_tag, release_date, release_url).date == '11.10.2026')
    metadata.identity('#1.10', '2028-02-29', release_url:gsub('1%.4$', '1.10'))
    rejected(function() metadata.identity(release_tag, '2026-02-29', release_url) end)
    rejected(function() metadata.identity(release_tag, release_date, release_url:gsub('1%.4$', '1.5')) end)
end)

local identity = metadata.identity(release_tag, release_date, release_url)
check('map metadata preserves author, players and all binary gameplay data', function()
    local binary_tail = '\0\255terrain and settings\0'
    local original = string.pack('<I4I4I4', 25, 3158, 6058)
        .. 'BvO Another v1.1a Rossoliny\0Author\0Original modes\0Players\0' .. binary_tail
    local result, name = metadata.map_info(original, nil, identity)
    assert(name == display_name)
    assert(result:sub(1, 12) == original:sub(1, 12))
    local parsed_name, author, description, players, next_position = string.unpack('zzzz', result, 13)
    assert(parsed_name == display_name and author == 'Author' and players == 'Players')
    assert(description:find('Original modes', 1, true))
    assert(description:find('Release #1.4', 1, true) and description:find('11.10.2026', 1, true))
    assert(description:find(release_url, 1, true))
    assert(result:sub(next_position) == binary_tail)
    rejected(function() metadata.map_info(string.pack('<I4', 28) .. original:sub(5), nil, identity) end)
end)

check('map string-table references are resolved for the stamped name and description', function()
    local original = string.pack('<I4I4I4', 25, 1, 1) .. 'TRIGSTR_003\0Author\0TRIGSTR_004\0Players\0tail'
    local strings = 'STRING 3\r\n{\r\nBvO Another v1.1a Rossoliny\r\n}\r\nSTRING 4\r\n{\r\nOriginal modes\r\n}'
    local result, name = metadata.map_info(original, strings, identity)
    assert(name == display_name and result:find('Original modes', 1, true))
    rejected(function() metadata.map_info(original, '', identity) end)
end)

local quoted_text = string.char(92, 34) .. 'text' .. string.char(92, 34)
local source_script = 'globals\n string MapDisplayName = "BvO Another v1.1a Rossoliny"\nendglobals\n'
    .. 'function main takes nothing returns nothing\n call LegitimateStartup()\nendfunction\n'
    .. 'function Info takes nothing returns nothing\n'
    .. ' call CreateQuestBJ(2,"Latest Version","Old ' .. quoted_text .. ' and link","Icon")\nendfunction\n'
    .. 'function config takes nothing returns nothing\n call SetMapName(MapDisplayName)\nendfunction\n'
check('INFO and lobby name are stamped without changing shared mode strings or gameplay', function()
    local result = metadata.script(source_script, display_name, identity)
    assert(result:find('call LegitimateStartup()', 1, true))
    assert(result:find('string MapDisplayName = "BvO Another v1.1a Rossoliny"', 1, true))
    assert(result:find('call SetMapName("' .. display_name .. '")', 1, true))
    assert(result:find(release_url, 1, true) and result:find('11.10.2026', 1, true))
    assert(result:find('|r","Icon")', 1, true))
    assert(not result:find('Old ', 1, true))
    rejected(function() metadata.script(source_script:gsub('Latest Version', 'Removed'), display_name, identity) end)
end)

check('a development script containing cheat code cannot be stamped for release', function()
    rejected(function() metadata.script(source_script .. '\ncall TestCommands_Init()\n', display_name, identity) end)
    rejected(function() metadata.script(source_script .. '\nset command = "-oneshot"\n', display_name, identity) end)
end)

check('the outer map header retains flags, player count and its fixed size', function()
    local header = 'HM3W' .. string.pack('<I4', 0) .. 'Old map name\0' .. string.pack('<I4I4', 0x4460, 10)
    header = header .. string.rep('\0', 512 - #header)
    local result = metadata.header(header, display_name)
    assert(#result == 512 and result:sub(1, 8) == header:sub(1, 8))
    local name, flags, players = string.unpack('zI4I4', result, 9)
    assert(name == display_name and flags == 0x4460 and players == 10)
end)

print(passed .. ' release metadata tests passed')
