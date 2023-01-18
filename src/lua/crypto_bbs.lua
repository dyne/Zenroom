--[[
--This file is part of zenroom
--
--Copyright (C) 2021 Dyne.org foundation
--designed, written and maintained by Alberto Lerda
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
--]]

local bbs = {}
local hash = HASH.new('sha256')
local hash_len = 32

function bbs.hkdf_extract(salt, ikm)
    return HASH.hmac(hash, salt, ikm)
end

function bbs.hkdf_expand(prk, info, l)

    assert(#prk >= hash_len)
    assert(l <= 255 * hash_len)
    assert(l > 0)

    if type(info) == 'string' then
        info = O.from_string(info)
    end

    n = math.ceil(l/hash_len)

    -- TODO: optimize using something like table.concat for octets
    tprec = HASH.hmac(hash, prk, info .. O.from_hex('01'))
    i = 2
    t = tprec
    while l > #t do
        tprec = HASH.hmac(hash, prk, tprec .. info .. O.from_hex(string.format("%02x", i)))
        t = t .. tprec
        i = i+1
    end

    -- TODO: check that sub is not creating a copy
    return t:sub(1,l)
end

return bbs
