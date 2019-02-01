-- Zencode implementation to encrypt and decrypt AES GCM messages
-- uses random IV and sha256 by default

When("I use '' key to encrypt the text", function(keyname,dest)
		ZEN.debug()
		ZEN.assert(ACK.text,
				   "No text to encrypt found in DATA")

		ZEN.assert(ACK.whoami, "No identification provided")
		local pk = ACK[keyname].public
		ZEN.assert(pk, "Public key not found in keyring: "..keyname)
		local sk = ACK[ACK.whoami].private
		ZEN.assert(sk, "Private key not found in keyring: "..ACK.whoami)
		
		local session = ECDH.kdf2(HASH.new('sha256'), sk * pk)

		-- compose the cipher message
		local text = MSG.pack({ from = ACK.whoami,
								text = ACK.text })
		local cipher = { }
		cipher.iv = random:octet(16)
		cipher.text,cipher.checksum =
		   ECDH.aesgcm_encrypt(session, text, cipher.iv, "Zencode")
		cipher.encoding = "hex"
		cipher.curve = "bls383"
		cipher.schema = "aes_gcm"
		cipher.pubkey = pk
		OUT.aes_gcm = export(cipher, 'aes_gcm', hex)
end)

Given("I have an encrypted message", function()
		 ZEN.assert(IN.aes_gcm, "Message not found in input (AES_GCM)")
		 ACK.aes_gcm = import(IN.aes_gcm, 'aes_gcm')
end)

When("I decrypt the message", function()
		ZEN.assert(IN.aes_gcm, "No encrypted material found (AES_GCM)")
		local cipher = ACK.aes_gcm

		init_keyring()
		ZEN.assert(validate(keyring[whoami], schemas['keypair']),
				   "Keypair not found in keyring: "..whoami)
		ZEN.assert(keyring[whoami].private,
				   "Private key not found in keypair: "..whoami)

 		local sk = INT.new(keyring[whoami].private)
		local session = ECDH.kdf2(HASH.new('sha256'), sk * cipher.pubkey )
		-- local checksum = { received = cipher.checksum) }
		local decode = { }
		decode.text, decode.checksum =
		   ECDH.aead_decrypt(session, cipher.text, cipher.iv, "Zencode")
		ZEN.assert(decode.checksum == cipher.checksum,
				   "Checksum mismatch when decrypting ciphertext")
		-- I.print(decode)
		-- I.print(cipher)
		OUT.decode = MSG.unpack(decode.text:str())
		-- ZEN.debug()
end)
