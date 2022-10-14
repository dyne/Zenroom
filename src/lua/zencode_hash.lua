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
--on Friday, 26th November 2021
--]]


-- hashing single strings
When(
    "create the hash of ''",
    function(s)
        local src = have(s)
        if luatype(src) == 'table' then
            src = ZEN.serialize(src) -- serialize tables using zenroom's algo
        end
        ACK.hash = HASH.new(CONF.hash):process(src)
	new_codec('hash', { zentype = 'element' })
    end
)

When(
    "create the hash of '' using ''",
    function(s, h)
        local src = have(s)
        if luatype(src) == 'table' then
            src = ZEN.serialize(src)
        end
        if strcasecmp(h, 'sha256') then
            ACK.hash = sha256(src)
        elseif strcasecmp(h, 'sha512') then
            ACK.hash = sha512(src)
        end
        ZEN.assert(ACK.hash, 'Invalid hash: ' .. h)
	new_codec('hash', { zentype = 'element' })
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
        local A = have(arr)
        local count = isarray(A)
        ZEN.assert(count > 0, 'Object is not an array: ' .. arr)
        ACK.hash_to_point = deepmap(F.hashtopoint, A)
	new_codec('hash_to_point', { luatype='table', zentype='array' })
    end
)

When(
    "create the hashes of each object in ''",
    function(arr)
        local A = have(arr)
        local count = isarray(A)
        ZEN.assert(count > 0, 'Object is not an array: ' .. arr)
        ACK.hashes = deepmap(sha256, A)
	new_codec('hashes', { luatype='table', zentype='array' })
    end
)

-- HMAC from RFC2104.
When(
    "create the HMAC of '' with key ''",
    function(obj, key)
        local src = have(obj)
        if luatype(src) == 'table' then
            src = ZEN.serialize(src)
        end
        local hkey = have(key)
        -- static int hash_hmac(lua_State *L) {
        --     hash *h   = hash_arg(L,1);
        --     octet *k  = o_arg(L, 2);
        --     octet *in = o_arg(L, 3);
        ACK.HMAC = HASH.new(CONF.hash):hmac(hkey, src)
	new_codec('HMAC', { zentype = 'element' })
    end
)

When(
    "create the key derivation of ''",
    function(obj)
        local src = have(obj)
        if luatype(src) == 'table' then
            src = ZEN.serialize(src)
        end
        ACK.key_derivation = HASH.new(CONF.hash):kdf(src)
	new_codec('key_derivation', { zentype = 'element' })
    end
)

When(
    "create the key derivations of each object in ''",
    function(tab)
        local t = have(tab)
        ZEN.assert(luatype(t) == 'table', 'Object is not a table: ' .. tab)
        ACK.key_derivations =
	    deepmap(
		function(v)
		    return HASH.new(CONF.hash):kdf(v)
		end,
		t)
	 new_codec('key derivations', { luatype = 'table',
					zentype = ZEN.CODEC[tab].zentype})
    end
)

local function _pbkdf2_f(src, pass, n)
    if luatype(src) == 'table' then
	    src = ZEN.serialize(src)
    end
    ACK.key_derivation =
	HASH.new('sha512'):pbkdf2(src,
				  {salt = pass,
				   iterations = n,
				   length = 32})
    new_codec('key derivation', { zentype = 'element' })
end

When(
    "create the key derivation of '' with password ''",
    function(obj, salt)
	_pbkdf2_f(have(obj), have(salt), 5000)
    end
)

When(
    "create the key derivation of '' with '' rounds",
    function(obj, iter)
	local n = tonumber(iter) or tonumber(tostring(have(iter)))
	_pbkdf2_f(have(obj), nil, n)
    end
)

When(
    "create the key derivation of '' with '' rounds with password ''",
    function(obj, iter, salt)
	local n = tonumber(iter) or tonumber(tostring(have(iter)))
	_pbkdf2_f(have(obj), have(salt), n)
    end
)
