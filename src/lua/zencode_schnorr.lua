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
--]]

local SCH = require'crypto_schnorr_signature'

local function schnorr_public_key_f(obj)
   local res = schema_get(obj, '.')
   zencode_assert(
      SCH.pubcheck(res),
      'Schnorr public key is not valid'
   )
   return res
end

local function schnorr_signature_f(obj)
   local res = schema_get(obj, '.')
   zencode_assert(
      SCH.sigcheck(res),
      'Schnorr signature is not valid'
   )
   return res
end

ZEN:add_schema(
   {
      schnorr_public_key = schnorr_public_key_f,
      schnorr_signature = schnorr_signature_f
   }
)


-- generate the private key
When("create schnorr key",function()
	initkeyring'schnorr'
	ACK.keyring.schnorr = SCH.keygen()
end)

-- generate the public key
When("create schnorr public key",function()
	empty'schnorr public key'
	local sk = havekey'schnorr'
	ACK.schnorr_public_key = SCH.pubgen(sk)
	new_codec('schnorr public key')
end)

When("create schnorr public key with secret key ''",function(sec)
	local sk = have(sec)
	empty'schnorr public key'
	ACK.schnorr_public_key = SCH.pubgen(sk)
	new_codec('schnorr public key')
end)

local function _schnorr_key_from_secret(sec)
   local sk = have(sec)
   local o = ECP.order()
   local d = BIG.new(sk) % o
   zencode_assert(d ~= BIG.new(0), 'invalid secret key, is zero')
   initkeyring'schnorr'
   ACK.keyring.schnorr = d:octet():pad(32)
end

When("create schnorr key with secret key ''",
     _schnorr_key_from_secret
)
When("create schnorr key with secret ''",
     _schnorr_key_from_secret
)

-- generate the sign for a msg and verify
When("create schnorr signature of ''",function(doc)
	local sk = havekey'schnorr'
	local obj = have(doc)
	empty'schnorr signature'
	ACK.schnorr_signature = SCH.sign(sk, zencode_serialize(obj))
	new_codec('schnorr signature')
end)

IfWhen("verify '' has a schnorr signature in '' by ''",function(doc, sig, by)
	  local pk = load_pubkey_compat(by, 'schnorr')
	  local obj = have(doc)
	  local s = have(sig)
	  zencode_assert(
	     SCH.verify(pk, zencode_serialize(obj), s),
	     'The schnorr signature by '..by..' is not authentic'
	  )
end)
