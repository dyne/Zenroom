----- Symmetric encryption (AES-GCM/AEAD) using PBKDF2

-- This example demonstrates how to take a secret and encrypt it using
-- a single password, even a small 4 digit PIN.

secrets_schema = S.record {
   pin = S.string,
   text = S.string,
   salt = S.hex,
   iterations = S.number
}

cipher_schema = S.record {
   header = S.octet,
   iv = S.octet,
   text = S.octet,
   checksum = S.octet
}

decode_schema = S.record {
   header = S.octet,
   text = S.octet,
   checksum = S.octet
}
   
rng = RNG.new()

secrets = JSON.decode(KEYS)
validate(secrets, secrets_schema)

ecdh = ECDH.new()

hash = HASH.new("sha256")
key = ECDH.pbkdf2(hash, secrets.pin, secrets.salt, secrets.kdf_iterations, 32)

local cipher = { header = str("my header"),
				 iv = rng:octet(16) }
cipher.text, cipher.checksum =
   ECDH.aead_encrypt(key, secrets.text,
					 cipher.iv, cipher.header)
validate(cipher,cipher_schema)

-- I.print(cipher)
output = map(cipher, hex)
print(JSON.encode(output))

------- receiver's stage
-- pin in again provided, kdf is ran so secret is there

local decode = { header = cipher.header }
decode.text, decode.checksum =
   ECDH.aead_decrypt(key, cipher.text,
					 cipher.iv, cipher.header)
validate(decode, decode_schema)

-- this needs to be checked, can also be in the host application
-- if checksums are different then the data integrity is corrupted
assert(decode.checksum == cipher.checksum)

print(decode.header:str())
print(decode.text:str())

