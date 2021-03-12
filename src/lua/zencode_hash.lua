--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2021 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
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
--Last modified by Denis Roio
--on Friday, 12th March 2021 1:19:33 pm
--]]


-- hashing single strings
When(
    "create the hash of ''",
    function(s)
        -- TODO: hash an array
        local src = ACK[s]
        ZEN.assert(src, 'Object not found: ' .. s)
        if luatype(src) == 'table' then
            src = ZEN.serialize(src) -- serialize tables using zenroom's algo
        end
        ACK.hash = HASH.new(CONF.hash):process(src)
    end
)

When(
    "create the hash of '' using ''",
    function(s, h)
        local src = ACK[s]
        ZEN.assert(src, 'Object not found: ' .. s)
        if luatype(src) == 'table' then
            src = ZEN.serialize(src)
        end
        if strcasecmp(h, 'sha256') then
            ACK.hash = sha256(src)
        elseif strcasecmp(h, 'sha512') then
            ACK.hash = sha512(src)
        end
        ZEN.assert(ACK.hash, 'Invalid hash: ' .. h)
    end
)

-- random and hashing operations
When(
    "create the random object of '' bits",
    function(n)
        local bits = tonumber(n)
        ZEN.assert(bits, 'Invalid number of bits: ' .. n)
        ACK.random_object = OCTET.random(math.ceil(bits / 8))
    end
)

When(
    "create the hash to point '' of each object in ''",
    function(what, arr)
        local F = _G[what]
        ZEN.assert(
            luatype(F.hashtopoint) == 'function',
            'Hash type ' .. what .. ' is invalid (no hashtopoint)'
        )
        local A = ACK[arr]
        ZEN.assert(A, 'Object not found: ' .. arr)
        local count = isarray(A)
        ZEN.assert(count > 0, 'Object is not an array: ' .. arr)
        ACK.hash_to_point = deepmap(F.hashtopoint, A)
    end
)

When(
    "create the hashes of each object in ''",
    function(arr)
        local A = ACK[arr]
        ZEN.assert(A, 'Object not found: ' .. arr)
        local count = isarray(A)
        ZEN.assert(count > 0, 'Object is not an array: ' .. arr)
        ACK.hashes = deepmap(sha256, A)
    end
)

-- HMAC from RFC2104.
When(
    "create the HMAC of '' with key ''",
    function(obj, key)
        local src = ACK[obj]
        ZEN.assert(src, 'Object not found: ' .. obj)
        if luatype(src) == 'table' then
            src = ZEN.serialize(src)
        end
        local hkey = ACK[key]
        ZEN.assert(hkey, 'Key not found: ' .. key)
        ACK.HMAC = HASH.new(CONF.hash):hmac(hkey, obj)
    end
)

When(
    "create the key derivation of ''",
    function(obj)
        local src = ACK[obj]
        ZEN.assert(src, 'Object not found: ' .. obj)
        if luatype(src) == 'table' then
            src = ZEN.serialize(src)
        end
        ACK.key_derivation = HASH.new(CONF.hash):kdf(src)
    end
)

When(
    "create the key derivation of '' with password ''",
    function(obj, salt)
        local src = ACK[obj]
        ZEN.assert(src, 'Object not found: ' .. obj)
        if luatype(src) == 'table' then
            src = ZEN.serialize(src)
        end
        local pass = ACK[salt]
        ZEN.assert(pass, 'Password not found: ' .. salt)
        ACK.key_derivation =
            HASH.new(CONF.hash):pbkdf2(src, {salt = pass}) -- , iterations = 10000, length = 32
    end
)
