-- Preserve the three unnamed records from Unryze 1.1a without the original map.
-- Bucket ranges end at the original record and start after the preceding empty slot.
-- The payloads of records 87 and 451 already exist under known source names.
local original_records = {
    { file = '-nicosakura-.blp', first = 919, last = 919, hash_a = 0x11de6f54, hash_b = 0x7c9b46b2 },
    { file = 'original-unnamed-232.blp', first = 812, last = 817, hash_a = 0xa7b035dd, hash_b = 0xc0fb0942 },
    { file = 'replaceabletextures\\commandbuttonsdisabled\\dispasbtnchadw.blp',
      first = 289, last = 313, hash_a = 0x90ad830b, hash_b = 0x6ee0352d },
}

return function(map_path)
    local payload = assert(io.load(map_path))
    local header = assert(payload:find('MPQ\26', 1, true))
    local _, header_size, _, version, _, hash_offset, _, hash_count =
        string.unpack('<c4I4I4I2I2I4I4I4', payload, header)
    assert(header_size == 32 and version == 0, 'Unsupported MPQ header')
    assert(hash_count >= 1024 and hash_count % 1024 == 0, 'Unsupported MPQ hash table size')
    local crypt_table = {}
    local seed = 0x100001
    for character = 0, 255 do
        for group = 0, 4 do
            seed = (seed * 125 + 3) % 0x2aaaab
            local high = (seed & 0xffff) << 16
            seed = (seed * 125 + 3) % 0x2aaaab
            crypt_table[group * 256 + character] = high | (seed & 0xffff)
        end
    end
    local function hash_name(name, kind)
        local first_seed, second_seed = 0x7fed7fed, 0xeeeeeeee
        for character in name:upper():gmatch('.') do
            local value = character:byte()
            first_seed = (crypt_table[kind * 256 + value] ~ (first_seed + second_seed)) & 0xffffffff
            second_seed = (value + first_seed + second_seed + (second_seed << 5) + 3) & 0xffffffff
        end
        return first_seed
    end
    local function transform_table(data, encrypt)
        local first_seed, second_seed = hash_name('(hash table)', 3), 0xeeeeeeee
        local words = {}
        for offset = 1, #data, 4 do
            second_seed = (second_seed + crypt_table[1024 + (first_seed & 255)]) & 0xffffffff
            local word = string.unpack('<I4', data, offset)
            local transformed = word ~ ((first_seed + second_seed) & 0xffffffff)
            local plain = encrypt and word or transformed
            first_seed = ((((~first_seed & 0xffffffff) << 21) + 0x11111111)
                | (first_seed >> 11)) & 0xffffffff
            second_seed = (plain + second_seed + (second_seed << 5) + 3) & 0xffffffff
            words[#words + 1] = string.pack('<I4', transformed)
        end
        return table.concat(words)
    end
    local table_start = header + hash_offset
    local table_end = table_start + hash_count * 16 - 1
    local decoded = transform_table(payload:sub(table_start, table_end), false)
    local records = {}
    for slot = 0, hash_count - 1 do
        local hash_a, hash_b, locale, platform, block = string.unpack('<I4I4I2I2I4', decoded, slot * 16 + 1)
        records[slot] = { hash_a, hash_b, locale, platform, block }
    end
    local function lookup(bucket, hash_a, hash_b)
        for distance = 0, hash_count - 1 do
            local slot = (bucket + distance) % hash_count
            local record = records[slot]
            if record[5] == 0xffffffff then return nil, slot end
            if record[5] ~= 0xfffffffe and record[1] == hash_a and record[2] == hash_b
                and record[3] == 0 then
                return record[5]
            end
        end
        error('MPQ hash table is full')
    end
    for _, original in ipairs(original_records) do
        local block = assert(lookup(hash_name(original.file, 0) % hash_count,
            hash_name(original.file, 1), hash_name(original.file, 2)), original.file)
        -- The original only stores the low ten bucket bits. Cover every possible
        -- bucket in a larger table; aliases share one existing compressed payload.
        for upper_bucket = 0, hash_count - 1, 1024 do
            for bucket = original.first, original.last do
                local found_block, empty_slot = lookup(upper_bucket + bucket, original.hash_a, original.hash_b)
                if found_block then
                    assert(found_block == block, 'Conflicting original MPQ hash')
                else
                    records[empty_slot] = { original.hash_a, original.hash_b, 0, 0, block }
                end
            end
        end
        for upper_bucket = 0, hash_count - 1, 1024 do
            for bucket = original.first, original.last do
                assert(lookup(upper_bucket + bucket, original.hash_a, original.hash_b) == block,
                    'Original MPQ record is unreachable')
            end
        end
    end
    local encoded = {}
    for slot = 0, hash_count - 1 do
        encoded[#encoded + 1] = string.pack('<I4I4I2I2I4', table.unpack(records[slot]))
    end
    local encrypted = transform_table(table.concat(encoded), true)
    assert(transform_table(encrypted, false) == table.concat(encoded), 'MPQ hash encryption failed')
    assert(io.save(map_path, payload:sub(1, table_start - 1) .. encrypted .. payload:sub(table_end + 1)))
end
