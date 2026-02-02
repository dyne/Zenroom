--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2026 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
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

-- global used by _mhout and _mhin
local multihash_prefixes <const> = {
    sha256 = OCTET.from_hex'12',
    sha512 = OCTET.from_hex'13',
    sha3_512 = OCTET.from_hex'14',
    sha3_256 = OCTET.from_hex'16',
    shake_256 = OCTET.from_hex'19',
    keccak_256 = OCTET.from_hex'1b'
}

--https://github.com/multiformats/multicodec/blob/master/table.cs
local function _mhout(n, obj)
    local _size <const> = {
        sha256 = OCTET.from_number(32):copy(15,1),
        sha512 = OCTET.from_number(64):copy(15,1),
        sha3_512 = OCTET.from_number(64):copy(15,1),
        sha3_256 = OCTET.from_number(32):copy(15,1),
        shake_256 = OCTET.from_number(32):copy(15,1),
        keccak_256 = OCTET.from_number(32):copy(15,1)
    }
    local pfx <const> = multihash_prefixes[n]
    local sz <const> = _size[n]
    if not pfx then error("Multihash not supported: "..n,2) end
    if not sz  then error("Multihash not supported: "..n,2) end
    return pfx..sz..obj
end

local function _mhin(string_obj,hashtype)
    if not type(string_obj) == 'string' then
        error("Multihash invalid input: "..type(string_obj),3)
    end
    local obj <const> = CONF.input.encoding.fun(string_obj)
    local prefixes <const> = {
        ['12'] = 'sha256',
        ['13'] = 'sha512',
        ['14'] = 'sha3_512',
        ['16'] = 'sha3_256',
        ['19'] = 'shake_256',
        ['1b'] = 'keccak_256'
    }
    local _pfx
    local firstbyte <const> = obj:copy(0,1)
    if hashtype then
        _pfx = multihash_prefixes[hashtype]
        if not _pfx then
            error("Multihash not supported: "..hashtype,2) end
        if firstbyte ~= _pfx then
            error("Incorrect multihash found: "
                  ..firstbyte:hex(),2) end
        _pfx = hashtype
    else
        _pfx = prefixes[firstbyte:hex()]
    end
    if not _pfx then
        error("Multihash not supported: ".._pfx,2) end
    local sz <const> = tonumber(obj:copy(1,1):hex(),16)
    if #obj ~= sz+2 then
        error("Multihash invalid size: "..#obj,2) end
    -- return additional params for the codec
    return obj:copy(2,sz), {schema='multihash_'.._pfx}
end

ZEN:add_schema({
        multihash = {
            import=function(obj) return _mhin(obj) end,
            export=function(obj)
                error("Invalid multihash value",2) end
        },
        multihash_sha256   ={
            import=function(obj) return _mhin(obj,'sha256') end,
            export=function(obj) return _mhout('sha256',obj) end
        },
        multihash_sha512   ={
            import=function(obj) return _mhin(obj,'sha512') end,
            export=function(obj) return _mhout('sha512',obj) end
        },
        multihash_sha3_256 ={
            import=function(obj) return _mhin(obj,'sha3_256') end,
            export=function(obj) return _mhout('sha3_256',obj) end
        },
        multihash_sha3_512 ={
            import=function(obj) return  _mhin(obj,'sha3_512') end,
            export=function(obj) return _mhout('sha3_512',obj) end
        },
        multihash_shake256 ={
            import=function(obj) return _mhin(obj,'shake_256') end,
            export=function(obj) return _mhout('shake_256',obj) end
        },
        multihash_keccak256={
            import=function(obj) return _mhin(obj,'keccak_256') end,
            export=function(obj) return _mhout('keccak_256',obj) end
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
