# Zenroom cheatsheet
## V0.4

### Symmetric Encryption
- encrypt_norx args(key_32B,nonce_32B,message) return(encrypted_message)
- decrypt_norx args(key_32B,nonce_32B,message) return(encrypted_message)

### Asymmetric Key Session
- keygen_session_ return(secret_key,public_key)
- pubkey_session_ args(secret_key) return(public_key)
- exchange_session_ args(secret_key,public_key) return(session_key)

### Unique Hashing
- hash_blake2b args(message) return(digest_64B)
- hash_init_blake2b args(len=64,key=nil) return(ctx)
- hash_update_ args(ctx,message)
- hash_final_ args(ctx) return(hash)

### Signing and Checking
- keygen_sign_ed25519 return(secret_key_32B,public_key_32B)
- pubkey_sign_ed25519 args(secret_key_32B) return(public_key_32B)
- sign_ed25519 args(secret_key_32B,public_key_32B,message) return(signature_64B)
- check_ed25519 args(signature_64B,public_key_32B,message) return(true|false)

### Key Derivation
- kdf_argon2i args(password,salt_16B,RAM_KB,iterations_10min) return(password_32B)

### Compression
- compress_ args(string) return(compressed_string)
- decompress_ args(compressed_string) return(string)

### String de/coding
- decode_ args(encoded) return(message)
- encode_b64 args(message,linelen=72) return
- encode_b58 args(message<256B) return(encoded)
