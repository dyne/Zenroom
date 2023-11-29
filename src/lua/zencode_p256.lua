--[[
--This file is part of zenroom
--
--Copyright (C) 2023 Dyne.org foundation
--
--designed, written and maintained by:
--Rebecca Selvaggini, Alberto Lerda and Denis Roio
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

local P256 = require('p256')

ZEN:add_schema(
   {
      p256_public_key = { import = O.from_base64,
			   export = O.to_base64 },
      p256_signature = { import = O.from_base64,
			  export = O.to_base64 }
   }
)

-- generate the private key
When('create p256 key',function()
	initkeyring'p256'
	ACK.keyring.p256 = P256.keygen()
end)

-- generate the public key
When('create p256 public key',function()
	empty'p256 public key'
	local sk = havekey'p256'
	ACK.p256_public_key = P256.pubgen(sk)
	new_codec('p256 public key', { zentype = 'e',
					encoding = 'base64'})
end)

local function _pubkey_from_secret(sec)
   local sk = have(sec)
   initkeyring'p256'
   P256.pubgen(sk)
   ACK.keyring.p256 = sk
end

When("create p256 key with secret key ''",
     _pubkey_from_secret
)

When("create p256 key with secret ''",
     _pubkey_from_secret
)

When("create p256 public key with secret key ''",function(sec)
	local sk = have(sec)
	empty'p256 public key'
	ACK.p256_public_key = P256.pubgen(sk)
	new_codec('p256 public key', { zentype = 'e',
					encoding = 'base64'})
end)

-- generate the sign for a msg and verify
When("create p256 signature of ''",function(doc)
	local sk = havekey'p256'
	local obj = have(doc)
	empty'p256 signature'
	ACK.p256_signature = P256.sign(sk, zencode_serialize(obj))
	new_codec('p256 signature', { zentype = 'e',
				       encoding = 'base64'})
end)

IfWhen("verify '' has a p256 signature in '' by ''",function(msg, sig, by)
	  local pk = load_pubkey_compat(by, 'p256')
	  local m = have(msg)
	  local s = have(sig)
	  zencode_assert(
	     P256.verify(pk, s, zencode_serialize(m)),
	     'The p256 signature by '..by..' is not authentic'
	  )
end)
