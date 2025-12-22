--[[
--This file is part of zenroom
--
--Copyright (C) 2022-2025 Dyne.org foundation
--designed, written and maintained by Alberto Lerda and Denis Roio
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
--Last modified by Alberto Lerda
--on Monday, 20th June 2022
--]]

local ED = require'ed'

local already_warned = false

-- deprecation message to be removed in v6 passing to default encoding for EDDSA
local function warn_base58()
    if not already_warned then
        already_warned = true
        warn("In the next version default encoding for eddsa pk and signature will change from base58 to config-defined encoding (default: base64)")
    end
end

local schema = {
    import = function(o)
        warn_base58()
        return schema_get(o, '.', O.from_base58, tostring)
    end,
    export = function(o)
        warn_base58()
        return O.to_base58(o)
    end
}

ZEN:add_schema(
    {
        eddsa_public_key = schema,
        eddsa_signature = schema
    }
)

-- generate the private key
When("create eddsa key",function()
	initkeyring'eddsa'
	ACK.keyring.eddsa = ED.secgen()
end)

-- generate the public key
When("create eddsa public key",function()
	empty'eddsa public key'
	local sk = havekey'eddsa'
	ACK.eddsa_public_key = ED.pubgen(sk)
	new_codec('eddsa public key', { zentype = 'e',
					encoding = 'base58'})
end)

local function _pubkey_from_secret(sec)
   local sk = have(sec)
   initkeyring'eddsa'
   ED.pubgen(sk)
   ACK.keyring.eddsa = sk
end

When("create eddsa key with secret key ''",
     _pubkey_from_secret
)

When("create eddsa key with secret ''",
     _pubkey_from_secret
)

When("create eddsa public key with secret key ''",function(sec)
	local sk = have(sec)
	empty'eddsa public key'
	ACK.eddsa_public_key = ED.pubgen(sk)
	new_codec('eddsa public key', { zentype = 'e',
					encoding = 'base58'})
end)

-- generate the sign for a msg and verify
When("create eddsa signature of ''",function(doc)
	local sk = havekey'eddsa'
	local obj = have(doc)
	empty'eddsa signature'
	ACK.eddsa_signature = ED.sign(sk, zencode_serialize(obj))
	new_codec('eddsa signature', { zentype = 'e',
				       encoding = 'base58'})
end)

IfWhen("verify '' has a eddsa signature in '' by ''",function(msg, sig, by)
	  local pk = load_pubkey_compat(by, 'eddsa')
	  local m = have(msg)
	  local s = have(sig)
	  zencode_assert(
	     ED.verify(pk, s, zencode_serialize(m)),
	     'The eddsa signature by '..by..' is not authentic'
	  )
end)
