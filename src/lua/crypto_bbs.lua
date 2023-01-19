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

local hash3 = HASH.new('sha3_256')

-- RFC8017 section 4
-- converts a nonnegative integer to an octet string of a specified length.
local function i2osp(x, x_len)
    return O.new(BIG.new(x)):pad(x_len)
end

-- RFC8017 section 4
-- converts an octet string to a nonnegative integer.
local function os2ip(oct)
    return BIG.new(oct)
end
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

function bbs.keygen(ikm, key_info)
    -- TODO: add warning on curve must be BLS12-381
    local INITSALT = O.from_string("BBS-SIG-KEYGEN-SALT-")

    if not key_info then
        key_info = O.empty()
    elseif type(key_info) == 'string' then
        key_info = O.from_string(key_info)
    end

    -- using BLS381
    -- 254 < log2(r) < 255
    -- ceil((3 * ceil(log2(r))) / 16)
    l = 48
    salt = INITSALT
    sk = INT.new(0)
    while sk == INT.new(0) do
        salt = hash:process(salt)
        prk = I.spy(bbs.hkdf_extract(salt, ikm .. i2osp(0, 1)))
        okm = I.spy(bbs.hkdf_expand(prk, key_info .. i2osp(l, 2), l))
        sk = os2ip(okm) % ECP.order()
    end

    return sk
end


function bbs.sk2pk(sk)
    return ECP2.generator() * sk
end

function bbs.sign(sk, pk, headers, messages)

end

return bbs
