local module_loader = loadfile(arg[1])
local localization = module_loader and module_loader() or {}
assert(type(localization.merge_profile) == 'function', 'Text-only localization is not implemented')

local passed_tests = 0
local function check(description, operation)
    operation()
    passed_tests = passed_tests + 1
    print('PASS: ' .. description)
end

local function rejected(translation, source, filename)
    local succeeded = pcall(localization.merge_profile, source or '[I000]\nName=Heart\nArt=Icon.blp\n',
        translation, filename or 'units/itemstrings.txt')
    assert(not succeeded, 'Expected rejection: ' .. translation)
end

check('sparse translations preserve all gameplay lines, other objects, BOM and CRLF', function()
    local source = '\239\187\191[I000]\r\nArt=Icon.blp\r\nName = Heart\r\nTip=Purchase Heart\r\n\r\n[I001]\r\nName=Ring\r\n'
    local translated, field_count = localization.merge_profile(source,
        '// Only the translated field\n[I000]\nName=Сердце\n', 'units/itemstrings.txt')
    assert(translated == source:gsub('Heart\r\nTip', 'Сердце\r\nTip'))
    assert(field_count == 1)
end)

check('empty translations leave source bytes unchanged', function()
    local source = '[I000]\nName=Heart'
    local translated, field_count = localization.merge_profile(source, '// Still untranslated\n', 'units/itemstrings.txt')
    assert(translated == source and field_count == 0)
end)

check('quoted comma-separated levels retain references, format placeholders and attribution', function()
    local source = '[A000]\nOrder=shockwave\nResearchtip=Learn [Level %d]\n'
        .. 'Ubertip="Damage <A000,DataA1>, first level.|nUpdated by Rossoliny.","Second level.|nUpdated by Rossoliny."\n'
    local translation = '[A000]\nResearchtip=Изучить [Уровень %d]\n'
        .. 'Ubertip="Урон <A000,DataA1>, первый уровень.|nUpdated by Rossoliny.","Второй уровень.|nUpdated by Rossoliny."\n'
    local translated, field_count = localization.merge_profile(source, translation, 'units/campaignabilitystrings.txt')
    assert(translated:find('Order=shockwave\n', 1, true))
    assert(translated:find('Урон <A000,DataA1>, первый уровень.', 1, true))
    assert(field_count == 2)
end)

check('gameplay and asset fields are rejected even when their values match the base', function()
    rejected('[I000]\nArt=Icon.blp\n')
    for _, field_name in ipairs {'Order', 'Hotkey', 'Requires', 'Sellitems', 'Missilespeed'} do
        rejected('[I000]\n' .. field_name .. '=1\n')
    end
end)

check('script, binary object, arbitrary profile and postfix filenames are rejected', function()
    for _, filename in ipairs {'scripts/war3map.j', 'war3map.w3a', 'units/itemfunc.txt',
        'units/itemstrings_RU.txt', '../units/itemstrings.txt'} do
        rejected('[I000]\nName=Сердце\n', nil, filename)
    end
end)

check('new objects and absent fields are rejected', function()
    rejected('[I999]\nName=Новое\n')
    rejected('[I000]\nTip=Новое\n')
end)

check('duplicate objects, duplicate fields and fields outside an object are rejected', function()
    rejected('[I000]\nName=Первое\nName=Второе\n')
    rejected('[I000]\nName=Первое\n[I000]\nName=Второе\n')
    rejected('Name=Сердце\n')
    rejected('[I000]\nNot an assignment\n')
end)

check('a translation cannot change level count or break quoted values', function()
    local source = '[A000]\nTip="First, level","Second level"\n'
    rejected('[A000]\nTip=Первый уровень\n', source, 'units/campaignabilitystrings.txt')
    rejected('[A000]\nTip="Первый уровень,Второй уровень\n', source, 'units/campaignabilitystrings.txt')
end)

check('object references and format placeholders must survive in their own levels', function()
    local source = '[A000]\nTip="First <A000,DataA1>","Second %d"\n'
    rejected('[A000]\nTip="Первый","Второй %d"\n', source, 'units/campaignabilitystrings.txt')
    rejected('[A000]\nTip="Первый %d","Второй <A000,DataA1>"\n', source, 'units/campaignabilitystrings.txt')
end)

check('invalid UTF-8 and embedded control bytes are rejected', function()
    rejected('[I000]\nName=Text\0hidden\n')
    rejected('[I000]\nName=\255\n')
    rejected('[I000]\nName=Text\rOrder=doom\n')
end)

print(passed_tests .. ' localization tests passed')
