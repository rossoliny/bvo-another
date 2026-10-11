-- Execute the registered spell condition with Warcraft event inputs.
-- This checks eligibility only; native Spell Shield timing requires an in-game test.
local script_file = assert(io.open(arg[1] or 'w3x-content/scripts/war3map.j', 'rb'))
local map_script = script_file:read('*a')
script_file:close()

local condition_name = assert(map_script:match(
    'TriggerAddCondition%(%s*pE%s*,%s*Condition%(%s*function%s+([%w_]+)%s*%)%s*%)'),
    'Mamaragan spell condition is not registered')
local condition_body = assert(map_script:match(
    'function%s+' .. condition_name .. '%s+takes%s+nothing%s+returns%s+boolean%s*(.-)%s*endfunction'))
-- The condition uses shared JASS/Lua expression syntax except these two tokens.
local lua_condition_body = condition_body:gsub('!=', '~='):gsub('%f[%w]endif%f[%W]', 'end')

local cases = {
    {'Darkness Sphere shield cannot trigger another bolt', 'ANss', 'enemy', true, false},
    {'Gods Sphere shield cannot trigger another bolt', 'A07Z', 'enemy', true, false},
    {'enemy hero spells remain eligible', 'A0BI', 'enemy', true, true},
    {'active item spells remain eligible', 'AIhe', 'enemy', true, true},
    {'allied hero spells remain ineligible', 'A0BI', 'ally', true, false},
    {'nonhero spells remain ineligible', 'A0BI', 'enemy', false, false},
    {'visual lightning dummies remain ineligible', 'A07H', 'enemy', false, false},
    {'first special caster retains ordinary spell reactions', 'A0BI', 'enemy', true, true, 'first'},
    {'second special caster retains ordinary spell reactions', 'A0BI', 'enemy', true, true, 'second'},
}

local failed_cases = 0
for _, test_case in ipairs(cases) do
    local spell_caster = {owner = test_case[3], is_hero = test_case[4]}
    local enel_caster = {owner = 'ally', is_hero = true}
    local event_environment = {
        Dj = enel_caster,
        x = test_case[6] == 'first' and enel_caster or {},
        y = test_case[6] == 'second' and enel_caster or {},
        UNIT_TYPE_HERO = 'hero',
        GetSpellAbilityId = function() return test_case[2] end,
        GetSpellAbilityUnit = function() return spell_caster end,
        GetOwningPlayer = function(unit) return unit.owner end,
        IsUnitEnemy = function(unit, player) return unit.owner ~= player end,
        MG = function(unit, unit_type)
            assert(unit_type == 'hero', 'Unexpected unit type in spell condition')
            return unit.is_hero
        end,
    }
    local compile_condition = assert(load('return function()\n' .. lua_condition_body .. '\nend',
        'Mamaragan spell condition', 't', event_environment))
    local is_eligible = compile_condition()()
    if is_eligible == test_case[5] then
        print('PASS: ' .. test_case[1])
    else
        failed_cases = failed_cases + 1
        print('FAIL: ' .. test_case[1] .. '; expected ' .. tostring(test_case[5])
            .. ', got ' .. tostring(is_eligible))
    end
end
assert(failed_cases == 0, tostring(failed_cases) .. ' Mamaragan eligibility cases failed')
print('PASS: all ' .. #cases .. ' Mamaragan eligibility cases')
