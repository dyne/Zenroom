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
--on Saturday, 9th April 2022
--]]

-- defined outside because reused across different schemas
local function public_key_f(o)
	local res = CONF.input.encoding.fun(o)
	ZEN.assert(
		ECDH.pubcheck(res),
		'Public key is not a valid point on curve'
	)
	return res
end

local function signature_f(o)
   return {
      r = ZEN.get(o, 'r'),
      s = ZEN.get(o, 's')
   }
end

local function warn_keypair()
   warn("Use of 'keypair' is deprecated in favor of 'keyring'")
   warn("Examples: I have my 'keyring' or I create the keyring")
end

ZEN.add_schema(
	{
		-- keypair (ECDH)
		public_key = public_key_f,
		ecdh_public_key = public_key_f,
		secret_message = function(obj)
			return {
				checksum = ZEN.get(obj, 'checksum'),
				header = ZEN.get(obj, 'header'),
				iv = ZEN.get(obj, 'iv'),
				text = ZEN.get(obj, 'text')
			}
		end,
		signature = signature_f,
		ecdh_signature = signature_f
	}
)

When(
	"create the ecdh key",
	function()
		initkeyring'ecdh'
		ACK.keyring.ecdh = ECDH.keygen().private
	end
)
When(
	"create the ecdh public key",
	function()
		empty'ecdh public key'
		local sk = havekey'ecdh'
		ACK.ecdh_public_key = ECDH.pubgen(sk)
		new_codec('ecdh public key') -- { zentype = 'element' }
	end
)
When("create the ecdh key with secret key ''",function(sec)
	local sk = have(sec)
	initkeyring'ecdh'
	ECDH.pubgen(sk)
	ACK.keyring.ecdh = sk
end)
When("create the ecdh key with secret ''",function(sec)
	local sk = have(sec)
	initkeyring'ecdh'
	ECDH.pubgen(sk)
	ACK.keyring.ecdh = sk
end)

-- encrypt with a header and secret
When(
	"encrypt the secret message '' with ''",
	function(msg, sec)
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
		new_codec('secret message', { zentype = 'dictionary' })
	end
)

-- decrypt with a secret
When(
	"decrypt the text of '' with ''",
	function(msg, sec)
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
		ZEN.assert(ACK.checksum == text.checksum,
			   'Decryption error: authentication failure, checksum mismatch')
		new_codec'text'
		new_codec'checksum'
	end
)

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
		ZEN.assert(pubkey, 'Public key not found for: ' .. _key)
	end
	return pubkey
end

-- encrypt to a single public key
When(
	"encrypt the secret message of '' for ''",
	function(msg, _key)
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
		new_codec('secret message', { zentype = 'dictionary' })
	end
)

When(
	"decrypt the text of '' from ''",
	function(secret, _key)
		local sk = havekey'ecdh'
		have(secret)
		local pk = _pubkey_compat(_key)
		local message = ACK[secret][_key] or ACK[secret]
		local session = ECDH.session(sk, pk)
		ACK.text, ACK.checksum =
			ECDH.aead_decrypt(session, message.text, message.iv, message.header)
		ZEN.assert(
			ACK.checksum == message.checksum,
			'Failed verification of integrity for secret message'
		)
		new_codec'text'
		new_codec'checksum'
	end
)

-- sign a message and verify
local function _signing(msg, var)
   local sk = havekey'ecdh'
   empty(var)
   local obj = have(msg)
   ACK[var] = ECDH.sign(sk, ZEN.serialize(obj))
   new_codec(var, { zentype = 'dictionary' })
end

local function _verifying(msg, sig, by)
   local pk = _pubkey_compat(by)
   local obj = have(msg)
   local s = have(sig)
   ZEN.assert(
      ECDH.verify(pk, ZEN.serialize(obj), s),
      'The signature by ' .. by .. ' is not authentic'
   )
end

When(
   "create the signature of ''", function(msg)
   _signing(msg, 'signature')
end)

When(
   "create the ecdh signature of ''", function(msg)
   _signing(msg, 'ecdh_signature')
end)

IfWhen(
   "verify the '' has a signature in '' by ''",
   _verifying
)

IfWhen(
   "verify the '' has a ecdh signature in '' by ''",
   _verifying
)
