-- Zencode implementation to encrypt and decrypt AES GCM messages
-- uses random IV and sha256 by default

When("I use '' key to encrypt the text", function(keyname,dest)
		data = data or ZEN.data.load()
		ZEN.assert(data['text'],
				   "No text to encrypt found in DATA")

		init_keyring()

		ZEN.assert(keyring[keyname].public,
				   "Public key not found in keyring: "..keyname)
		local pubkey = hex(keyring[keyname].public)

		ZEN.assert(ECP.validate(pubkey),
				   "Invalid public key in keyring: "..keyname)

		ZEN.assert(validate(keyring[whoami],schemas['keypair']),
				   "Keypair not found in keyring: "..whoami)
		local privkey = hex(keyring[whoami].private)

		local pk = ECP.new(pubkey)
		local sk = INT.new(privkey)
		local session = ECDH.kdf2(HASH.new('sha256'), sk * pk )
		local text = MSG.pack({ from = whoami,
								text = data.text })
		local cipher = { }
		cipher.iv = random:octet(16)
		cipher.text,cipher.checksum =
		   ECDH.aesgcm_encrypt(session, text, cipher.iv, "Zencode")
		
		cipher = map(cipher,hex)
		cipher.encoding = "hex"
		cipher.curve = "bls383"
		cipher.zenroom = VERSION
		cipher.schema = "aes_gcm"
		cipher.pubkey = keyring[whoami].public
		ZEN.data.add(data,dest,cipher)
end)
		
When("I decrypt the '' to ''", function(src, dest)
		data = data or ZEN.data.load()		
		ZEN.assert(data[src], "Encrypted packet not found in: "..src)
		ZEN.assert(validate(data[src],schemas['aes_gcm']),
				   "Invalid AES-GCM encrypted packet in: "..src)

		init_keyring()
		ZEN.assert(validate(keyring[whoami], schemas['keypair']),
				   "Keypair not found in keyring: "..whoami)
		ZEN.assert(keyring[whoami].private,
				   "Private key not found in keypair: "..whoami)

 		local sk = INT.new(hex(keyring[whoami].private))
		local pk = ECP.new(hex(data[src].pubkey))
		local session = ECDH.kdf2(HASH.new('sha256'), sk * pk )
		local checksum = { received = hex(data[src].checksum) }

		local decode = { }
		decode.iv = hex(data[src].iv)
		decode.ciphertext = hex(data[src].text)
		decode.text, checksum.calculated =
		   ECDH.aead_decrypt(session, decode.ciphertext, decode.iv, "Zencode")
		ZEN.assert(checksum.calculated == checksum.received,
				   "Checksum mismatch when decrypting ciphertext",
				   { checksum = checksum })
		ZEN.data.add(data,dest,MSG.unpack(decode.text:str()))
end)		
