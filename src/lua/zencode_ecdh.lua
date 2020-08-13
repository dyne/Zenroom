-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2019 Dyne.org foundation
-- designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

-- defined outside because reused across different schemas
function public_key_f(o)
   local res = CONF.input.encoding.fun(o)
   ZEN.assert(ECDH.pubcheck(res),
			  "Public key is not a valid point on curve")
   return res
end

ZEN.add_schema({
	  -- keypair (ECDH)
	  public_key = public_key_f,
      keypair = function(obj)
         return { public_key  = public_key_f(obj.public_key),
                  private_key = ZEN.get(obj, 'private_key') }
	  end,
	  secret_message = function(obj)
		 return { checksum = ZEN.get(obj, 'checksum'),
				  header   = ZEN.get(obj, 'header'),
				  iv       = ZEN.get(obj, 'iv'),
				  text     = ZEN.get(obj, 'text') }
	  end,
	  signature = function(obj)
		 return { r = ZEN.get(obj, 'r'),
				  s = ZEN.get(obj, 's')}

	  end
})

-- generate keypair
local function f_keygen()
   local kp = ECDH.keygen()
   ACK.keypair = { public_key = kp.public,
				   private_key = kp.private }
end
When("create the keypair", f_keygen)

-- encrypt with a header and secret
When("encrypt the secret message '' with ''", function(msg, sec)
		ZEN.assert(ACK[msg], "Data to encrypt not found: message")
		ZEN.assert(ACK[sec], "Secret used to encrypt not found: "..sec)
		-- KDF2 sha256 on all secrets
		local secret = KDF(ACK[sec])
		ACK.secret_message = { header = ACK.header or 'empty',
							   iv = O.random(32) }
		ACK.secret_message.text, ACK.secret_message.checksum =
		   ECDH.aead_encrypt(secret, ACK[msg],
							 ACK.secret_message.iv,
							 ACK.secret_message.header)
end)

-- decrypt with a secret
When("decrypt the secret message with ''", function(sec)
		ZEN.assert(ACK[sec], "Secret used to decrypt not found: secret")
		ZEN.assert(ACK.secret_message,
				   "Secret data to decrypt not found: secret message")

        local secret = KDF(ACK[sec])
        -- KDF2 sha256 on all secrets, this way the
        -- secret is always 256 bits, safe for direct aead_decrypt
        ACK.message = { header = ACK.secret_message.header }
        ACK.message.text, ACK.checksum =
           ECDH.aead_decrypt(secret,
							 ACK.secret_message.text,
							 ACK.secret_message.iv,
							 ACK.message.header)
        ZEN.assert(ACK.checksum == ACK.secret_message.checksum,
                   "Decryption error: authentication failure, checksum mismatch")
end)

-- encrypt to a single public key
When("encrypt the message for ''", function(_key)
		ZEN.assert(ACK.keypair, "Keys not found: keypair")
		ZEN.assert(ACK.keypair.private_key, "Private key not found in keypair")
		ZEN.assert(ACK.message, "Data to encrypt not found: message")
		ZEN.assert(type(ACK.public_key) == 'table',
				   "Public keys not found in keyring")
		ZEN.assert(ACK.public_key[_key], "Public key not found for: ".._key)
		local private = ACK.keypair.private_key
		local key = ECDH.session(ACK.keypair.private_key, ACK.public_key[_key])
		ACK.secret_message = { header = ACK.header or 'empty',
							   iv = O.random(32) }
		ACK.secret_message.text,
		ACK.secret_message.checksum =
		   ECDH.aead_encrypt(key,
							 ACK.message,
							 ACK.secret_message.iv,
							 ACK.secret_message.header)
end)


When("decrypt the secret message from ''", function(_key)
		ZEN.assert(ACK.keypair, "Keyring not found")
		ZEN.assert(ACK.keypair.private_key, "Private key not found in keyring")
		ZEN.assert(ACK.secret_message, "Data to decrypt not found: secret_message")
		ZEN.assert(ACK[_key],
				   "Key to decrypt not found, the public key from: ".._key)
		local session = ECDH.session(ACK.keypair.private_key, ACK[_key])
		ACK.message, checksum = ECDH.aead_decrypt(session,
												  ACK.secret_message.text,
												  ACK.secret_message.iv,
												  ACK.secret_message.header)
		ZEN.assert(checksum == ACK.secret_message.checksum,
				   "Failed verification of integrity for secret message")
end)

-- sign a message and verify
When("create the signature of ''", function(doc)
		ZEN.assert(ACK.keypair, "Keyring not found")
		ZEN.assert(ACK.keypair.private_key, "Private key not found in keyring")
		ZEN.assert(not ACK.signature, "Cannot overwrite existing object: ".."signature")
		local obj = ACK[doc]
		ZEN.assert(obj, "Object not found: "..doc)
		local t = luatype(obj)
		ACK.signature = ECDH.sign(ACK.keypair.private_key, ZEN.serialize(obj))
		ZEN.CODEC.signature = CONF.output.encoding.name
end)

When("verify the '' is signed by ''", function(msg, by)
		ZEN.assert(ACK.public_key[by], "Public key by "..by.." not found")
		local obj
		obj = ACK[msg]
		ZEN.assert(obj, "Object not found: "..msg)
		-- obj = obj[by]
		-- ZEN.assert(obj, "Object not found: "..msg.." by "..by)
		local t = luatype(obj)
		local sign
		if t == 'table' then
		   sign = obj.signature
		   ZEN.assert(sign, "Signature by "..by.." not found")
		   obj.signature = nil
		   ZEN.assert(ECDH.verify(ACK.public_key[by], ZEN.serialize(obj), sign),
					  "The signature by "..by.." is not authentic")
		else
		   sign = ACK.signature[by]
		   ZEN.assert(sign, "Signature by "..by.." not found")
		   ZEN.assert(ECDH.verify(ACK.public_key[by], obj, sign),
					  "The signature by "..by.." is not authentic")
		end
end)

When("verify the '' has a signature in '' by ''", function(msg, sig, by)
		ZEN.assert(ACK.public_key[by], "Public key by "..by.." not found")
		local obj
		obj = ACK[msg]
		ZEN.assert(obj, "Object not found: "..msg)
		local s
		s = ACK[sig]
		ZEN.assert(s, "Signature not found: "..sig)
		ZEN.assert(ECDH.verify(ACK.public_key[by], ZEN.serialize(obj), s),
				   "The signature by "..by.." is not authentic")
end)

