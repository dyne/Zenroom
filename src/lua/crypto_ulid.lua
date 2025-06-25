--[[
--This file is part of zenroom
--
--Copyright (C) 2021-2025 Dyne.org foundation
--designed, written and maintained by Giulio Sacchet
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License v3.0
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--Along with this program you should have received a copy of the
--GNU Affero General Public License v3.0
--If not, see http://www.gnu.org/licenses/agpl.txt
--
--
--References:
--https://datatracker.ietf.org/doc/html/rfc9562
--https://github.com/Tieske/ulid.lua/blob/master/src/ulid.lua
--
--]]

local uu = {}

local ENCODING = {
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "M", 
    "N", "P", "Q", "R", "S", "T", "V", "W", "X", "Y", "Z"
}

local function encode_time()
    time = big.new(os.time())*big.new(1000)
    len = 10
    local result = {}
    for i = len, 1, -1 do 
        local mod = (time % big.new(32)):int() 
        result[i] = ENCODING[mod+1]
        time = (time - mod) / big.new(32)
    end 
    return table.concat(result)
end

local function encode_random()
    len = 16
    local result = {}
    for i = 1, len do
      result[i] = ENCODING[math.floor(math.random() * 32) + 1]
    end
    return table.concat(result)
end

function uu.ulid()
    return encode_time() .. encode_random()
end


function uu.uuid_v1()
    time = big.new(os.time())*big.from_decimal(10000000)+big.from_decimal("122192928000000000")
    local time_low = time:octet():sub(5,8):hex()
    local time_mid = time:octet():sub(3,4):hex()
    local time_high = time:octet():sub(1,2):__shl(4)
    time_high = O.concat(time_high,O.from_hex("11")):shr_circular(4):sub(1,2):hex()

    local clock_sequence_1 = O.random(1)
    clock_sequence_1 = clock_sequence_1:__band(O.from_hex("0x3F")):__bor(O.from_hex("0x80"))
    local clock_sequence_2 = O.random(1)
    clock_sequence = O.concat(clock_sequence_1,clock_sequence_2):hex()

    local node = O.random(1)
    node = node:__bor(O.from_hex("0x01"))
    local b = O.random(5)
    node = O.concat(node,b):hex()

    return string.format("%s-%s-%s-%s-%s", time_low, time_mid, time_high, clock_sequence, node)
end

function uu.uuid_v4()
    local part_1 = O.random(4):hex()
    local part_2 = O.random(2):hex()
    local part_3 = O.random(1)
    part_3 = part_3:__band(O.from_hex("0x0F")):__bor(O.from_hex("0x40"))
    part_3 = O.concat(part_3,O.random(1)):hex()
    local part_4 = O.random(1)
    part_4 = part_4:__band(O.from_hex("0x3F")):__bor(O.from_hex("0x80"))
    part_4 = O.concat(part_4,O.random(1)):hex()
    local part_5 = O.random(6):hex()
    return string.format("%s-%s-%s-%s-%s", part_1, part_2, part_3, part_4, part_5)
end 

return uu
