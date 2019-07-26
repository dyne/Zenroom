----- Symmetric encryption (AES-GCM/AEAD) using PBKDF2

-- This example demonstrates how to take a secret and encrypt it using
-- a single password, even a small 4 digit PIN.
   
rng = RNG.new()

secrets = JSON.decode(KEYS)

ecdh = ECDH.new()

hash = HASH.new("sha256")
key = ECDH.pbkdf2(hash, secrets.pin, secrets.salt, secrets.kdf_iterations, 32)

local cipher = { header = str("my header"),
				 iv = rng:octet(16) }
cipher.text, cipher.checksum =
   ECDH.aead_encrypt(key, secrets.text,
					 cipher.iv, cipher.header)

-- I.print(cipher)
-- output = map(cipher, hex)
print(JSON.encode(cipher))

------- receiver's stage
-- pin in again provided, kdf is ran so secret is there

local decode = { header = cipher.header }
decode.text, decode.checksum =
   ECDH.aead_decrypt(key, cipher.text,
					 cipher.iv, cipher.header)

-- this needs to be checked, can also be in the host application
-- if checksums are different then the data integrity is corrupted
assert(decode.checksum == cipher.checksum)

print(decode.header:str())
print(decode.text:str())

