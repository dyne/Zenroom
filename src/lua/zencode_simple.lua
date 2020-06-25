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

-- make sure relevant defaults are there
CONF.encoding = CONF.encoding or url64
CONF.encoding_prefix = CONF.encoding_prefix or 'u64'

ZEN.add_schema({
	  -- keypair (ECDH)
	  public_key = function(obj)
		 local o = obj.public_key or obj -- fix recursive schema check
		 if type(o) == "string" then o = ZEN.decode(o) end
		 ZEN.assert(ECDH.pubcheck(o),
					"Public key is not a valid point on curve")
		 return o
	  end,
      keypair = function(obj)
         return { public_key  = ZEN:validate_recur(obj, 'public_key'),
                  private_key = ZEN.get(obj, 'private_key') }
	  end,
	  secret_message = function(obj)
		 return { checksum = ZEN.get(obj, 'checksum'),
				  header   = ZEN.get(obj, 'header'),
				  iv       = ZEN.get(obj, 'iv'),
				  text     = ZEN.get(obj, 'text') }
	  end,
	  signature = function(obj)
		 return { r = ZEN.get(obj, 'r', INT.new),
				  s = ZEN.get(obj, 's', INT.new) }
--				  text = ZEN.get(obj, 'text') }
	  end
})

-- generate keypair
local function f_keygen()
   local kp = ECDH.keygen()
   ACK.keypair = { public_key = kp.public,
				   private_key = kp.private }
end
When("I create the keypair", f_keygen)

-- encrypt with a header and secret
When("I encrypt the secret message '' with ''", function(msg, sec)
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
When("I decrypt the secret message with ''", function(sec)
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
When("I encrypt the message for ''", function(_key)
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


When("I decrypt the secret message from ''", function(_key)
		ZEN.assert(ACK.keypair, "Keyring not found")
		ZEN.assert(ACK.keypair.private_key, "Private key not found in keyring")
		ZEN.assert(ACK.secret_message, "Data to decrypt not found: secret_message")
		ZEN.assert(ACK.public_key[_key],
				   "Key to decrypt not found: public key[".._key.."])")
		local session = ECDH.session(ACK.keypair.private_key, ACK.public_key[_key])
		ACK.message, checksum = ECDH.aead_decrypt(session,
												  ACK.secret_message.text,
												  ACK.secret_message.iv,
												  ACK.secret_message.header)
		ZEN.assert(checksum == ACK.secret_message.checksum,
				   "Failed verification of integrity for secret message")
end)

-- sign a message and verify
When("I create the signature of ''", function(doc)
		ZEN.assert(ACK.keypair, "Keyring not found")
		ZEN.assert(ACK.keypair.private_key, "Private key not found in keyring")
		local obj = ACK[doc]
		ZEN.assert(obj, "Object not found: "..doc)
		local t = type(obj)
		if t == 'table' then
		   local s = ECDH.sign(ACK.keypair.private_key, OCTET.serialize(obj))
		   ACK[doc].signature = s
		else
		   ACK.signature = ECDH.sign(ACK.keypair.private_key, obj)
		end
		-- include contextual information
end)

When("I verify the '' is signed by ''", function(msg, by)
		ZEN.assert(ACK.public_key[by], "Public key by "..by.." not found")
		local obj = ACK[msg]
		ZEN.assert(obj, "Object not found: "..msg)
		local t = type(obj)
		local sign
		if t == 'table' then
		   sign = obj.signature
		   ZEN.assert(sign, "Signature by "..by.." not found")
		   obj.signature = nil
		   ZEN.assert(ECDH.verify(ACK.public_key[by], OCTET.serialize(obj), sign),
					  "The signature is not authentic")
		else
		   sign = ACK.signature[by]
		   ZEN.assert(sign, "Signature by "..by.." not found")
		   ZEN.assert(ECDH.verify(ACK.public_key[by], obj, sign),
					  "The signature is not authentic")
		end
end)
