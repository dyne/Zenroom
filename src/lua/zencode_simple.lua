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
CONF.curve = CONF.curve or 'goldilocks'
CONF.encoding = CONF.encoding or url64
CONF.encoding_prefix = CONF.encoding_prefix or 'u64'

local _ecdh = ECDH.new(CONF.curve) -- used for validation

ZEN.add_schema({
	  -- keypair (ECDH)
	  public_key = function(obj)
		 local o = obj.public_key or obj -- fix recursive schema check
		 if type(o) == "string" then o = ZEN:import(o) end
		 ZEN.assert(_ecdh:checkpub(o),
					"Public key is not a valid point on curve: "..CONF.curve)
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
	  signed_message = function(obj)
		 return { r = ZEN.get(obj, 'r'),
				  s = ZEN.get(obj, 's'),
				  text = ZEN.get(obj, 'text') }
	  end
})

-- generate keypair
local function f_keygen()
   local kp
   local ecdh = ECDH.new(CONF.curve)
   kp = ecdh:keygen()
   ZEN:pick('keypair', { public_key = kp.public,
						 private_key = kp.private })
   ZEN:validate('keypair')
   ZEN:ack('keypair')
end
When("I create my new keypair", f_keygen)
When("I generate my keys", f_keygen)

-- encrypt with a header and secret
When("I encrypt the '' and '' to '' with ''", function(what, hdr, msg, sec)
		ZEN.assert(ACK[what], "Data to encrypt not found in "..what)
		local secret = ACK[sec]
		ZEN.assert(secret, "Secret to encrypt not found in "..sec)
		secret = ECDH.kdf2(HASH.new('sha256'),secret) -- KDF2 sha256 on all secrets
		-- secret is always 32 bytes long, safe for direct aead_decrypt
		ZEN.assert(ACK[hdr], "Header not found in "..hdr)
		ACK[msg] = { header = ACK[hdr],
					 iv = O.random(16) }
		ACK[msg].text, ACK[msg].checksum = 
		   ECDH.aead_encrypt(secret, ACK[what], ACK[msg].iv, ACK[hdr])
		-- include contextual information
end)

-- decrypt with a secret
When("I decrypt the '' to '' with ''", function(what, msg, sec)
		local enc = ACK[what]
		ZEN.assert(enc, "Data to decrypt not found in "..what)
		local secret = ACK[sec]
		ZEN.assert(secret, "Secret to decrypt not found in "..sec)
		secret = ECDH.kdf2(HASH.new('sha256'),secret) -- KDF2 sha256 on all secrets
		-- secret is always 32 bytes long, safe for direct aead_decrypt
		ACK[msg] = { header = enc.header }
		local checksum
		ACK[msg].text, checksum = 
		   ECDH.aead_decrypt(secret, enc.text, enc.iv, enc.header)
		ZEN.assert(checksum == enc.checksum,
				   "Decryption error: authentication failure, checksum mismatch")
end)

-- encrypt to a single public key
When("I encrypt the '' to '' for ''", function(what, msg, recpt)
		ZEN.assert(ACK.keypair, "Keyring not found")
		ZEN.assert(ACK.keypair.private_key, "Private key not found in keyring")
		ZEN.assert(ACK[what], "Data to encrypt not found in "..what)
		ZEN.assert(type(ACK.public_key) == 'table', "Public keys not found in keyring")
		local from = ECDH.new(CONF.curve)
		from:private(ACK.keypair.private_key)
		local to = ECDH.new(CONF.curve)
		ZEN.assert(ACK.public_key[recpt], "Public key not found for: "..recpt)
		to:public(ACK.public_key[recpt])
		ACK[msg] = from:encrypt(to, ACK[what], str('empty'))
end)

When("I decrypt the '' from '' to ''", function(src,frm,dst)
		ZEN.assert(ACK.keypair, "Keyring not found")
		ZEN.assert(ACK.keypair.private_key, "Private key not found in keyring")
		ZEN.assert(ACK.public_key[frm], "Public key not found: "..frm)
		ZEN.assert(ACK[src], "Ciphertext not found")
		local recpt = ECDH.new(CONF.curve)
		recpt:private(ACK.keypair.private_key)
		ACK[src].pubkey = ACK.public_key[frm]
		ACK[dst] = recpt:decrypt(ACK[src])
end)

-- sign a message and verify
When("I sign the '' as ''", function(doc, dst)
		ZEN.assert(ACK.keypair, "Keyring not found")
		ZEN.assert(ACK.keypair.private_key, "Private key not found in keyring")
		local dsa = ECDH.new(CONF.curve)
		dsa:private(ACK.keypair.private_key)
		ACK[dst] = dsa:sign(I.spy(ACK[doc]))
		-- include contextual information
		ACK[dst].text = ACK[doc]
end)

When("I verify the '' is authentic", function(msg)
		ZEN.assert(ACK.public_key, "Public key not found")
		local dsa = ECDH.new(CONF.curve)
		dsa:public(ACK.public_key)
		local sm = ACK[msg]
		ZEN.assert(sm, "Signed message not found: "..msg)
		ZEN.assert(dsa:verify(sm.text,{ r = sm.r, s = sm.s }),
				   "The signature is not authentic")
end)
