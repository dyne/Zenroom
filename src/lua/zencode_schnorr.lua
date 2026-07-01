--[[
--This file is part of zenroom
--
--Copyright (C) 2022-2026 Dyne.org foundation
--designed, written and maintained by Alberto Lerda and Denis Roio
--BIP-340 secp256k1 migration
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
--]]

-- Zencode Schnorr scenario: BIP-340 secp256k1 Schnorr signatures.
-- Sizes: schnorr_public_key = 32B (x-only), schnorr_signature = 64B (r||s).
-- Messages are preprocessed with a Zenroom domain tag before signing:
-- tagged_hash("Zenroom/Schnorr/BIP340", zencode_serialize(obj))

local SCH = require'crypto_schnorr_signature'

local function schnorr_public_key_f(obj)
   local res = schema_get(obj, '.')
   zencode_assert(
      SCH.pubcheck(res),
      'Schnorr public key is not valid'
   )
   zencode_assert(
      #res == 32,
      'Schnorr public key must be 32 bytes (BIP-340 x-only).' ..
      ' Old 48-byte BLS381 keys are not supported.'
   )
   return res
end

local function schnorr_signature_f(obj)
   local res = schema_get(obj, '.')
   zencode_assert(
      SCH.sigcheck(res),
      'Schnorr signature is not valid'
   )
   zencode_assert(
      #res == 64,
      'Schnorr signature must be 64 bytes (BIP-340).' ..
      ' Old 80-byte BLS381 signatures are not supported.'
   )
   return res
end

ZEN:add_schema(
   {
      schnorr_public_key = schnorr_public_key_f,
      schnorr_signature = schnorr_signature_f
   }
)

-- Domain-separated message preprocessing for Zencode objects.
-- Uses the Zenroom domain tag to prevent cross-context reuse.
-- This is NOT Bitcoin Taproot transaction signing.
-- For BIP-341 TapSighash, hash the message externally and pass it as a raw OCTET.
local function zenroom_message(obj)
   -- BIP-340 signs arbitrary bytes, so zencode_serialize
   -- encodes the object deterministically.
   -- Domain separation: tagged_hash("Zenroom/Schnorr/BIP340", msg)
   return SECP.bip340_tagged_hash("Zenroom/Schnorr/BIP340",
                                   zencode_serialize(obj))
end

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
   zencode_assert(#sk == 32, 'Secret key must be 32 bytes')
   initkeyring'schnorr'
   ACK.keyring.schnorr = sk
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
	ACK.schnorr_signature = SCH.sign(sk, zenroom_message(obj))
	new_codec('schnorr signature')
end)

IfWhen("verify '' has a schnorr signature in '' by ''",function(doc, sig, by)
	  local pk = load_pubkey_compat(by, 'schnorr')
	  local obj = have(doc)
	  local s = have(sig)
	  zencode_assert(
	     SCH.verify(pk, zenroom_message(obj), s),
	     'The schnorr signature by '..by..' is not authentic'
	  )
end)
