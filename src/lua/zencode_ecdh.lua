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
--on Saturday, 9th April 2022
--]]

ECDH = require_once'zenroom_ecdh'

-- defined outside because reused across different schemas
local function public_key_f(o)
	local res = CONF.input.encoding.fun(o)
	zencode_assert(
		ECDH.pubcheck(res),
		'Public key is not a valid point on curve'
	)
	return res
end

local function signature_f(o)
   return {
      r = schema_get(o, 'r'),
      s = schema_get(o, 's')
   }
end

ZEN:add_schema(
	{
		-- keypair (ECDH)
		public_key = {
		   import = public_key_f
		},
		ecdh_public_key = {
		   import = public_key_f
		},
		secret_message = {
		   import = function(obj)
			  return {
				 checksum = schema_get(obj, 'checksum'),
				 header = schema_get(obj, 'header'),
				 iv = schema_get(obj, 'iv'),
				 text = schema_get(obj, 'text')
			  }
		   end
		},
		signature = {
		   import = signature_f
		},
		ecdh_signature = {
		   import = signature_f
		}
	}
)

When("create ecdh key",function()
		initkeyring'ecdh'
		ACK.keyring.ecdh = ECDH.keygen().private
end)
When("create ecdh public key",function()
		empty'ecdh public key'
		local sk = havekey'ecdh'
		ACK.ecdh_public_key = ECDH.pubgen(sk)
		new_codec('ecdh public key')
	end
)

local function _ecdh_key_from_secret(sec)
    local sk = have(sec)
	initkeyring'ecdh'
	ECDH.pubgen(sk)
	ACK.keyring.ecdh = sk
end

When("create ecdh key with secret key ''",
     _ecdh_key_from_secret
)
When("create ecdh key with secret ''",
    _ecdh_key_from_secret
)

-- encrypt with a header and secret
When("encrypt secret message '' with ''",function(msg, sec)
		local text = have(msg)
		local sk = have(sec)
		empty'secret message'
		-- KDF2 sha256 on all secrets
		local secret = KDF(sk)
		ACK.secret_message = {
			header = ACK.header or OCTET.from_string('DefaultHeader'),
			iv = O.random(32)
		}
		ACK.secret_message.text, ACK.secret_message.checksum =
			ECDH.aead_encrypt(
			secret,
			text,
			ACK.secret_message.iv,
			ACK.secret_message.header
		)
		new_codec('secret message')
end)

-- decrypt with a secret
When("decrypt text of '' with ''",function(msg, sec)
		local sk = have(sec)
		local text = have(msg)
		empty'text'
		empty'checksum'
		local secret = KDF(sk)
		-- KDF2 sha256 on all secrets, this way the
		-- secret is always 256 bits, safe for direct aead_decrypt
		ACK.text, ACK.checksum =
			ECDH.aead_decrypt(
			secret,
			text.text,
			text.iv,
			text.header
		)
		zencode_assert(ACK.checksum == text.checksum,
			   'Decryption error: authentication failure, checksum mismatch')
		new_codec'text'
		new_codec'checksum'
end)

-- check various locations to find the public key
local function _pubkey_compat(_key)
	local pubkey = ACK[_key]
	if not pubkey then
		local pubkey_arr
		pubkey_arr = ACK.public_key or ACK.public_key_session or ACK.ecdh_public_key
		if luatype(pubkey_arr) == 'table' then
		   pubkey = pubkey_arr[_key]
		else
		   pubkey = pubkey_arr
		end
		zencode_assert(pubkey, 'Public key not found for: ' .. _key)
	end
	return pubkey
end

-- encrypt to a single public key
When("encrypt secret message of '' for ''",function(msg, _key)
		local sk = havekey'ecdh'
		have(msg)
		local pk = _pubkey_compat(_key)
		empty'secret message'
		local key = ECDH.session(sk, pk)
		ACK.secret_message = {
			header = ACK.header or OCTET.from_string('DefaultHeader'),
			iv = O.random(32)
		}
		ACK.secret_message.text, ACK.secret_message.checksum =
			ECDH.aead_encrypt(
			key,
			ACK[msg],
			ACK.secret_message.iv,
			ACK.secret_message.header
		)
		new_codec('secret message')
end)

When("decrypt text of '' from ''",function(secret, _key)
		local sk = havekey'ecdh'
		have(secret)
		local pk = _pubkey_compat(_key)
		local message = ACK[secret][_key] or ACK[secret]
		local session = ECDH.session(sk, pk)
		ACK.text, ACK.checksum =
			ECDH.aead_decrypt(session, message.text, message.iv, message.header)
		zencode_assert(
			ACK.checksum == message.checksum,
			'Failed verification of integrity for secret message'
		)
		new_codec'text'
		new_codec'checksum'
end)

-- sign a message and verify
local function _signing(msg, var)
   local sk = havekey'ecdh'
   empty(var)
   local obj = have(msg)
   ACK[var] = ECDH.sign(sk, zencode_serialize(obj))
   new_codec(var)
end

local function _verifying(msg, sig, by)
   local pk = _pubkey_compat(by)
   local obj = have(msg)
   local s = have(sig)
   zencode_assert(
      ECDH.verify(pk, zencode_serialize(obj), s),
      'The ecdh signature by ' .. by .. ' is not authentic'
   )
end

When("create signature of ''",function(msg)
   _signing(msg, 'signature')
end)

When("create ecdh signature of ''",function(msg)
   _signing(msg, 'ecdh_signature')
end)

-- The deterministic ecdsa/ecdh uses the default SHA512 to sign and verify.
local function _signing_det(msg, var)
    local sk = havekey'ecdh'
    empty(var)
    local obj = have(msg)
    -- 64 here means to use SHA512.
    ACK[var] = ECDH.sign_deterministic(sk, zencode_serialize(obj), 64)
    new_codec(var)
end

When("create ecdh deterministic signature of ''",function(msg)
    _signing_det(msg, "ecdh_deterministic_signature")
end)

-- The deterministic ecdsa/ecdh above uses the default SHA512 to sign and verify.
-- If one wnats to use another hash, the ECDH.verify_deterministic should be
-- called with the correct integer input.
IfWhen("verify '' has a ecdh deterministic signature in '' by ''",_verifying)

When("create ecdsa deterministic signature of ''",function(msg)
    _signing_det(msg, "ecdsa_deterministic_signature")
end)

IfWhen("verify '' has a ecdsa deterministic signature in '' by ''",_verifying)

IfWhen("verify '' has a signature in '' by ''",_verifying)

IfWhen("verify '' has a ecdh signature in '' by ''",_verifying)
