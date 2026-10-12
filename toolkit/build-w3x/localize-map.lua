-- Merge sparse text translations without copying gameplay data from another locale.
local localization = {}
local allowed_profiles = {}
for _, filename in ipairs {
    'campaignabilitystrings.txt', 'campaignunitstrings.txt', 'campaignupgradestrings.txt',
    'commonabilitystrings.txt', 'itemabilitystrings.txt', 'itemstrings.txt',
} do
    allowed_profiles['units/' .. filename] = true
end

local allowed_fields = {}
for _, field_name in ipairs {
    'Name', 'Tip', 'Ubertip', 'Researchtip', 'Researchubertip', 'Description',
    'Bufftip', 'Buffubertip', 'Propernames', 'Revivetip', 'Awakentip', 'Untip', 'Unubertip',
} do
    allowed_fields[field_name:lower()] = true
end

local function parse_profile(content, filename)
    assert(utf8.len(content), 'Invalid UTF-8: ' .. filename)
    assert(not content:find('[%z\1-\8\11\12\14-\31]'), 'Control byte in profile: ' .. filename)
    local byte_order_mark = content:sub(1, 3) == '\239\187\191' and content:sub(1, 3) or ''
    content = content:sub(#byte_order_mark + 1)
    local lines, objects = {}, {}
    local current_object
    local position = 1
    while position <= #content do
        local newline_position = content:find('\n', position, true)
        local line = content:sub(position, newline_position and newline_position - 1 or #content)
        local ending = newline_position and '\n' or ''
        if line:sub(-1) == '\r' then line, ending = line:sub(1, -2), '\r' .. ending end
        assert(not line:find('\r', 1, true), 'Embedded line break in profile: ' .. filename)
        local record = { text = line, ending = ending }
        lines[#lines + 1] = record
        local trimmed_line = line:match('^%s*(.-)%s*$')
        if trimmed_line ~= '' and trimmed_line:sub(1, 2) ~= '//' then
            local object_id = trimmed_line:match('^%[([^%]]+)%]$')
            if object_id then
                assert(#object_id == 4 and not objects[object_id], 'Invalid or duplicate object: ' .. filename .. ':' .. object_id)
                current_object = {}
                objects[object_id] = current_object
            else
                local field_name, value = line:match('^%s*([%w_]+)%s*=%s*(.-)%s*$')
                assert(current_object and field_name, 'Expected an object field: ' .. filename .. ':' .. #lines)
                local normalized_field = field_name:lower()
                assert(not current_object[normalized_field], 'Duplicate field: ' .. filename .. ':' .. field_name)
                record.field_name, record.value = field_name, value
                current_object[normalized_field] = record
            end
        end
        position = newline_position and newline_position + 1 or #content + 1
    end
    return lines, objects, byte_order_mark
end

local function split_values(value)
    local values = {}
    local position = 1
    while true do
        while value:sub(position, position):match('%s') do position = position + 1 end
        local text
        if value:sub(position, position) == '"' then
            local closing_quote = value:find('"', position + 1, true)
            assert(closing_quote, 'Unterminated quoted text')
            text = value:sub(position + 1, closing_quote - 1)
            position = closing_quote + 1
            while value:sub(position, position):match('%s') do position = position + 1 end
            assert(position > #value or value:sub(position, position) == ',', 'Unexpected text after a quote')
        else
            local comma_position = value:find(',', position, true)
            text = value:sub(position, comma_position and comma_position - 1 or #value):match('^%s*(.-)%s*$')
            assert(not text:find('"', 1, true), 'Quote inside unquoted text')
            position = comma_position or #value + 1
        end
        values[#values + 1] = text
        if position > #value then return values end
        position = position + 1
    end
end

local function protected_tokens(text)
    local tokens = {}
    for token in text:gmatch('<[^<>]+>') do tokens[#tokens + 1] = token end
    for token in text:gmatch('%%[%d%$%-+%.]*[cdeEfgGiopsuxX]') do tokens[#tokens + 1] = token end
    table.sort(tokens)
    return table.concat(tokens, '\0')
end

function localization.merge_profile(source_content, translated_content, filename)
    filename = filename:gsub('\\', '/'):lower()
    assert(allowed_profiles[filename], 'Unsupported translation file: ' .. filename)
    local source_lines, source_objects, byte_order_mark = parse_profile(source_content, filename)
    local _, translated_objects = parse_profile(translated_content, 'RU/' .. filename)
    local translated_fields = 0
    for object_id, translated_fields_by_name in pairs(translated_objects) do
        local source_object = assert(source_objects[object_id], 'Unknown translated object: ' .. filename .. ':' .. object_id)
        for field_name, translated_record in pairs(translated_fields_by_name) do
            local location = filename .. ':' .. object_id .. ':' .. translated_record.field_name
            assert(allowed_fields[field_name], 'Non-text translation field: ' .. location)
            local source_record = assert(source_object[field_name], 'Missing source field: ' .. location)
            local source_values = split_values(source_record.value)
            local translated_values = split_values(translated_record.value)
            assert(#source_values == #translated_values, 'Translation changes value/level count: ' .. location)
            for level, source_value in ipairs(source_values) do
                assert(protected_tokens(source_value) == protected_tokens(translated_values[level]),
                    'Translation changes references or format placeholders: ' .. location .. ':' .. level)
            end
            local assignment_prefix = assert(source_record.text:match('^(%s*[%w_]+%s*=%s*)'))
            source_record.text = assignment_prefix .. translated_record.value
            translated_fields = translated_fields + 1
        end
    end
    local output = { byte_order_mark }
    for _, record in ipairs(source_lines) do output[#output + 1] = record.text .. record.ending end
    return table.concat(output), translated_fields
end

function localization.load_overrides(filesystem, source_directory, translation_directory)
    assert(filesystem.is_directory(translation_directory), 'Missing RU directory: ' .. translation_directory:string())
    local overrides, translated_fields, translated_files = {}, 0, 0
    local function scan_directory(directory, prefix)
        for path in directory:list_directory() do
            local filename = prefix .. path:filename():string()
            if filesystem.is_directory(path) then
                assert(filename == 'units', 'Unsupported translation directory: ' .. filename)
                scan_directory(path, filename .. '/')
            elseif filename ~= 'README.md' then
                local normalized_filename = filename:lower()
                assert(allowed_profiles[normalized_filename], 'Unsupported translation file: ' .. filename)
                assert(not overrides[normalized_filename], 'Duplicate translation file: ' .. filename)
                local source_content = assert(io.load(source_directory / normalized_filename), 'Missing source profile: ' .. filename)
                local translated_content = assert(io.load(path), 'Cannot read translation: ' .. filename)
                local merged_content, field_count = localization.merge_profile(source_content, translated_content, filename)
                overrides[normalized_filename] = merged_content
                translated_fields = translated_fields + field_count
                translated_files = translated_files + 1
            end
        end
    end
    scan_directory(translation_directory, '')
    return overrides, translated_fields, translated_files
end

return localization
