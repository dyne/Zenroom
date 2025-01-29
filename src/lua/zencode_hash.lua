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
--on Monday, 13th January 2025
--]]


-- hashing
local valid_hashes <const> = {
    sha256 = true,
    sha512 = true,
    sha3_256 = true,
    sha3_512 = true,
    shake256 = true,
    keccak256 = true
}
local function _hash(s, n, d)
    local src = have(s)
    n = n or CONF.hash
    d = d or 'hash'
    -- serialize tables using zenroom's algo
    if not valid_hashes[n] then
        error("Hash algorithm not known: ".. n)
    end
    src = zencode_serialize(src)
    -- from init: HASH = require('zenroom_hash')
    local _hf <const> = HASH:init(n)
    ACK[d] = _hf:process(src)
    new_codec(d, { zentype = 'e' })
end

When("create hash of ''", _hash)
When("create hash of '' using ''", _hash)

--https://github.com/multiformats/multicodec/blob/master/table.cs
local function _multihash(n, obj)
    local prefix <const> = {
        sha256 = OCTET.from_hex'12',
        sha512 = OCTET.from_hex'13',
        sha3_512 = OCTET.from_hex'14',
        sha3_256 = OCTET.from_hex'16',
        shake_256 = OCTET.from_hex'19',
        keccak_256 = OCTET.from_hex'1b'
    }
    local pfx <const> = prefix[n]
    if not pfx then error("Multihash not supported: "..n,2) end
    return pfx..obj
end

ZEN:add_schema(
    {
        multihash_sha256 = {
            import = nil,
            export = function(obj)
                return _multihash('sha256',obj)
            end
        }
})
When("create multihash of ''",
     function(s)
         _hash(s,nil,'multihash')
         CODEC['multihash'].schema = 'multihash_'..CONF.hash
end)
When("create multihash of '' using ''",
     function(s, n)
         _hash(s, n,'multihash')
         CODEC['multihash'].schema = 'multihash_'..n
end)

When("create hash to point '' of ''",function(curve, object)
    local F = _G[curve]
    zencode_assert(
            luatype(F.hashtopoint) == 'function',
            'Hash type ' .. curve .. ' is invalid (no hashtopoint)'
    )
    empty'hash_to_point'
    local obj = have(object)
    ACK.hash_to_point = F.hashtopoint(zencode_serialize(obj))
    new_codec('hash_to_point', { zentype='e' })
end)

When("create hashes of each object in ''",function(arr)
        local A = have(arr)
        local count = isarray(A)
        zencode_assert(count > 0, 'Object is not an array: ' .. arr)
        ACK.hashes = deepmap(sha256, A)
	new_codec('hashes', {zentype='a' })
    end
)

-- HMAC from RFC2104.
When("create HMAC of '' with key ''",function(obj, key)
        local src = have(obj)
        if luatype(src) == 'table' then
            src = zencode_serialize(src)
        end
        local hkey = have(key)
        -- static int hash_hmac(lua_State *L) {
        --     hash *h   = hash_arg(L,1);
        --     octet *k  = o_arg(L, 2);
        --     octet *in = o_arg(L, 3);
        ACK.HMAC = HASH.new(CONF.hash):hmac(hkey, src)
	new_codec('HMAC', { zentype = 'e' })
    end
)

When("create key derivation of ''",function(obj)
        local src = have(obj)
        if luatype(src) == 'table' then
            src = zencode_serialize(src)
        end
        ACK.key_derivation = HASH.new(CONF.hash):kdf(src)
	new_codec('key_derivation', { zentype = 'e' })
    end
)

When("create key derivations of each object in ''",function(tab)
        local t = have(tab)
        zencode_assert(luatype(t) == 'table', 'Object is not a table: ' .. tab)
        ACK.key_derivations =
	    deepmap(
		function(v)
		    return HASH.new(CONF.hash):kdf(v)
		end,
		t)
	 new_codec('key derivations', {zentype = CODEC[tab].zentype})
    end
)

local function _pbkdf2_f(src, pass, n)
    if luatype(src) == 'table' then
	    src = zencode_serialize(src)
    end
    ACK.key_derivation =
	HASH.new('sha512'):pbkdf2(src,
				  {salt = pass,
				   iterations = n,
				   length = 32})
    new_codec('key derivation', { zentype = 'e' })
end

When("create key derivation of '' with password ''",function(obj, salt)
	_pbkdf2_f(have(obj), have(salt), 5000)
    end
)

When("create key derivation of '' with '' rounds",function(obj, iter)
	local n = tonumber(iter) or tonumber(tostring(have(iter)))
	_pbkdf2_f(have(obj), nil, n)
    end
)

When("create key derivation of '' with '' rounds with password ''",function(obj, iter, salt)
	local n = tonumber(iter) or tonumber(tostring(have(iter)))
	_pbkdf2_f(have(obj), have(salt), n)
    end
)
