--[[
--This file is part of zenroom
--
--Copyright (C) 2025 Dyne.org foundation
--designed, written and maintained Nicola Suzzi and Matteo Cristino
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License as
--published by the Free Software Foundation, either version 3 of the
--License, or (at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--You should have received a copy of the GNU Affero General Public License 
--along with this program.  If not, see <https://www.gnu.org/licenses/>.
--
--Last modified by Matteo Cristino
--on Tuesday, 8th April 2025
--]]

local MT = require'crypto_merkle'

local function _zencode_merkle_root(name, hashtype)
    local data = pick_from_path(name, true)
    if not data or type(data) ~= 'table' then
        error("Table not found in path: "..name, 2)
    end
    ACK.merkle_root = MT.create_merkle_root(data, hashtype)
    return new_codec('merkle root', {zentype = "string"})
end

When("create merkle root of ''", _zencode_merkle_root)
When("create merkle root of '' using hash ''", _zencode_merkle_root)
When("create merkle root of dictionary path ''", _zencode_merkle_root)
When("create merkle root of dictionary path '' using hash ''", _zencode_merkle_root)

-- Function to verify the integrity of a Merkle root
local function _verify_merkle_root(root, name)
    local merkle_root = have(root)
    local data_table = pick_from_path(name, true)
    if not data_table or type(data_table) ~= 'table' then
        error("Table not found in path: "..name, 2)
    end

    local computed_root = MT.create_merkle_root(data_table)
    if computed_root ~= merkle_root then
        error('The merkle root in '..root..' does not match '..name, 2)
    end
end

IfWhen("verify merkle root '' of ''", _verify_merkle_root)
IfWhen("verify merkle root '' of dictionary path ''", _verify_merkle_root)
