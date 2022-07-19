--[[
--This file is part of zenroom
--
--Copyright (C) 2022 Dyne.org foundation
--designed, written and maintained by Alberto Lerda and Denis Roio
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
--Last modified by Alberto Lerda
--on Monday, 20th June 2022
--]]

local ED = require'ed'

ZEN.add_schema(
   {
      eddsa_public_key = { import = O.from_base58,
			   export = O.to_base58 },
      eddsa_signature = { import = O.from_base58,
			  export = O.to_base58 }
   }
)

-- generate the private key
When('create the eddsa key',function()
	initkeyring'eddsa'
	ACK.keyring.eddsa = ED.secgen()
end)

-- generate the public key
When('create the eddsa public key',function()
	empty'eddsa public key'
	local sk = havekey'eddsa'
	ACK.eddsa_public_key = ED.pubgen(sk)
	new_codec('eddsa public key', { zentype = 'element',
					encoding = 'base58'})
end)

local function _pubkey_from_secret(sec)
   local sk = have(sec)
   initkeyring'eddsa'
   ED.pubgen(sk)
   ACK.keyring.eddsa = sk
end

When("create the eddsa key with secret key ''",
     _pubkey_from_secret
)

When("create the eddsa key with secret ''",
     _pubkey_from_secret
)

When("create the eddsa public key with secret key ''",function(sec)
	local sk = have(sec)
	initkeyring'eddsa'
	ACK.keyring.eddsa = sk
	empty'eddsa public key'
	ACK.eddsa_public_key = ED.pubgen(sk)
	new_codec('eddsa public key', { zentype = 'element',
					encoding = 'base58'})
end)

-- generate the sign for a msg and verify
When("create the eddsa signature of ''",function(doc)
	local sk = havekey'eddsa'
	local obj = have(doc)
	empty'eddsa signature'
	ACK.eddsa_signature = ED.sign(sk, ZEN.serialize(obj))
	new_codec('eddsa signature', { zentype = 'element',
				       encoding = 'base58'})
end)

IfWhen("verify the '' has a eddsa signature in '' by ''",function(msg, sig, by)
	  local pk = load_pubkey_compat(by, 'eddsa')
	  local m = have(msg)
	  local s = have(sig)
	  ZEN.assert(
	     ED.verify(pk, s, ZEN.serialize(m)),
	     'The signature by '..by..' is not authentic'
	  )
end)
