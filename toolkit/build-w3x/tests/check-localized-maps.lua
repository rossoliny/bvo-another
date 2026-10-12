package.path = './?.lua;./?/init.lua;' .. package.path
require 'utility'
local filesystem = require 'bee.filesystem'
local stormlib = require 'ffi.stormlib'
local english_map = assert(stormlib.open(filesystem.path(arg[1]), true))
local russian_map = assert(stormlib.open(filesystem.path(arg[2]), true))
local expected_script = assert(io.load(filesystem.path(arg[3])))
local expected_english_profile = assert(io.load(filesystem.path(arg[4])))
local expected_russian_profile = expected_english_profile:gsub('Name=Heart of the Bount', 'Name=Сердце Баунта', 1)
    :gsub('Tip=Purchase Heart of the Bount', 'Tip=Купить Сердце Баунта', 1)
assert(expected_russian_profile ~= expected_english_profile)
assert(english_map:load_file('units\\itemstrings.txt') == expected_english_profile)
assert(russian_map:load_file('units\\itemstrings.txt') == expected_russian_profile)
local english_inventory, russian_inventory = {}, {}
for filename in assert(english_map:load_file('(listfile)')):gmatch('[^\r\n]+') do
    english_inventory[filename] = true
    if filename:lower() ~= 'units\\itemstrings.txt' then
        assert(english_map:load_file(filename) == russian_map:load_file(filename), 'Locale changes gameplay file: ' .. filename)
    end
end
for filename in assert(russian_map:load_file('(listfile)')):gmatch('[^\r\n]+') do
    russian_inventory[filename] = true
    assert(english_inventory[filename], 'Unexpected RU archive member: ' .. filename)
end
for filename in pairs(english_inventory) do assert(russian_inventory[filename], 'Missing RU member: ' .. filename) end
assert(english_map:load_file('scripts\\war3map.j') == expected_script)
assert(russian_map:load_file('scripts\\war3map.j') == expected_script)
english_map:close()
russian_map:close()
print('PASS: only the two selected text fields differ; filenames, inventory and all gameplay bytes match')
