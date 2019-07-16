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

-- Zencode implementation to encrypt and decrypt AES GCM messages
-- uses random IV and sha256 by default

local order = ECP.order()
local G = ECP.generator()
local KDF_rounds = 10000
local get = ZEN.get


ZEN.add_schema(
   {
	  aes_gcm =
		{ import = function(obj)
			 return { checksum = get(O.from_hex, obj, 'checksum'),
					  iv = get(O.from_hex, obj, 'iv'),
					  text = get(O.from_hex, obj, 'text'), -- may be MSGpack
					  encoding = obj.encoding,
					  curve = obj.curve,
					  pubkey = get(ECP.new, obj, 'pubkey') } end,
		  export = function(obj,conv)
			 return { checksum = conv(obj.checksum),
					  iv = conv(obj.iv),
					  text = conv(obj.text),
					  encoding = obj.encoding,
					  curve = obj.curve,
					  pubkey = conv(obj.pubkey) } end,
		},

	 ecdh_keypair =
		{ import = function(obj)
			 return { private = get(INT.new, obj, 'private'),
					  public = get(ECP.new, obj, 'public') } end,
		  export = function(obj, conv)
			 return map(obj, conv) end
		},

	 encryption_draft =
		{ import = function(obj)
			 return { from = get(O.from_string, obj, 'from'),
					  text = get(O.from_string, obj, 'text'),
					  data = get(O.from_hex, obj, 'data') }
			 end,
		  export = function(obj, conv)
			 return { from = str(obj.from),
					  text = str(obj.text),
					  data = conv(obj.data) }
			 end
		}
})

Given("I have the public key by ''", function(who)
		 if not ACK.keys then ACK.keys = { } end
		 if IN.KEYS[who] then
			ACK.keys[who] = get(ECP.new, IN.KEYS, who)
		 elseif IN[who] then
			ACK.keys[who] = get(ECP.new, IN, who)
		 else
			ZEN.assert(false, "Public key not found: "..who)
		 end
end)

Given("I have my public key", function()
         ZEN.assert(type(IN.KEYS[ACK.whoami]) == "table",
					"Public key not found for: "..ACK.whoami)
         ACK.pubkey = get(ECP.new, IN.KEYS[ACK.whoami], 'public')
end)

Given("I have my private key", function()
         ZEN.assert(type(IN.KEYS[ACK.whoami]) == "table",
					"Private key not found for: "..ACK.whoami)
         ACK.privkey = get(O.from_hex, IN.KEYS[ACK.whoami], 'private')
end)

Given("I have my keypair", function()
         ZEN.assert(type(IN.KEYS[ACK.whoami]) == "table",
					"Keypair not found for: "..ACK.whoami)
		 local kp = ZEN:valid('ecdh_keypair', IN.KEYS[ACK.whoami])
         ACK.pubkey = kp.public
         ACK.privkey = kp.private
end)

When("I create my new keypair", function()
		ZEN.assert(ACK.whoami, "No identity specified for own keypair")
		local key = INT.new(RNG.new(),order)
		local kp = { public = key * G,
					 private = key }
		OUT[ACK.whoami] = export(kp, 'ecdh_keypair', hex)
end)

When("I export my public key", function()
		ZEN.assert(ACK.whoami, "No identity specified")
		OUT[ACK.whoami] = hex(ACK.pubkey)
end)

When("I export all keys", function()
		OUT[ACK.whoami] = { }
		if ACK.pubkey then OUT[ACK.whoami].public = hex(ACK.pubkey) end
		if ACK.privkey then OUT[ACK.whoami].private = hex(ACK.privkey) end
		if type(ACK.keys) == 'table' then
		   for k,v in ipairs(ACK.keys) do
			  OUT[k] = hex(v)
		   end
		end
end)	  
		   

When("I use '' key to encrypt the output", function(keyname)
		ZEN.assert(ACK.draft, "No draft to encrypt found")
		ZEN.assert(ACK.whoami, "No identity specified")
		local pk = ACK.keys[keyname]
		ZEN.assert(pk, "Public key not found in keyring: "..keyname)
		local sk = ACK.privkey
		ZEN.assert(sk, "Private key not found for: "..ACK.whoami)
		
		local session = ECDH.kdf2(HASH.new('sha256'), pk * sk)

		-- compose the cipher message
		local message = MSG.pack({ from = ACK.draft.from,
								   text = ACK.draft.text,
								   data = hex(ACK.draft.data) })
		local cipher = { }
		cipher.iv = RNG.new():octet(16)
		cipher.text, cipher.checksum =
		   ECDH.aesgcm_encrypt(session, message, cipher.iv, "Zencode")
		cipher.encoding = "hex"
		cipher.curve = "bls383"
		cipher.schema = "aes_gcm"
		cipher.pubkey = ACK.pubkey
		OUT.aes_gcm = export(cipher, 'aes_gcm', hex)
end)

Given("I receive an encrypted message", function()
		 ZEN.assert(IN.aes_gcm, "No encrypted message found in input")
		 ACK.aes_gcm = ZEN:valid('aes_gcm', IN.aes_gcm)
end)

When("I decrypt the message", function()
		ZEN.assert(ACK.aes_gcm, "No encrypted message received")
		local cipher = ACK.aes_gcm

		ZEN.assert(ACK.privkey, "No private key found in keyring")
		local sk = ACK.privkey

		local session = ECDH.kdf2(HASH.new('sha256'), cipher.pubkey * sk)
		-- local checksum = { received = cipher.checksum) }
		local decode = { }
		decode.text, decode.checksum =
		   ECDH.aead_decrypt(session, cipher.text, cipher.iv, "Zencode")
		ZEN.assert(decode.checksum == cipher.checksum,
				   "Checksum mismatch when decrypting ciphertext")
		OUT = MSG.unpack(decode.text:str())
end)
