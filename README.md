# DECODE lang

Restricted execution environment for LUA based blockchain language
implementation. For more information see [docs](docs).

This implementation has no threading support, so no parallel
execution: the binary produced is fully static and designed to be
executed as a new process for each new script.

## Build instructions

If you have cloned this source code from git, then do:
```
git submodule update --init --recursive
```

Then first build the static build environment (musl-libc): this needs to be done only once at the beginning of new builds:

```
make bootstrap
```

Then at last run the build command:
```
make
```

## Crypto functionalities

This interpreter includes statically the following cryptographic
primitives, extracted from the NaCl library and included via the
monocypher/luanacha implementation:

- Authenticated encryption with Chacha20 stream encryption (more precisely Xchacha20, ie. Chacha with a 24-byte nonce) and Poly1305 MAC, 
- Curve25519-based key exchange and public key encryption,
- Blake2b hash function,
- Ed25519-based signature function using Blake2b hash instead of sha512,
- Argon2i, a modern key derivation function based on Blake2b. Like scrypt, it is designed to be expensive in both CPU and memory.

### Crypto API

Here a summary of calls available.


```
randombytes(n)
	return a string containing n random bytes


--- Authenticated encryption

lock(key, nonce, plain [, prefix]) => crypted
	authenticated encryption using Xchacha20 and a Poly1305 MAC
	key must be a 32-byte string
	nonce must be a 24-byte string
	plain is the text to encrypt as a string
	prefix is an optional string. If it is provided, it is prepended 
	to the encrypted text. The prefix can be use for example to 
	store the nonce, and avoid extra string allocation and copying in 
	Lua applications. The prefix defaults to the empty string.
	Return the encrypted text as a string. The encrypted text includes 
	the 16-byte MAC. So #crypted == #plain + 16 + #prefix
	
	Note: the prefix is not an "additional data" in the AEAD sense.
	The MAC is computed over only the encrypted text. It does not include 
	the prefix.


unlock(key, nonce, crypted [, offset]) => plain
	authenticated decryption - verification of the Poly1305 MAC
	and decryption with Xcahcha20.
	key must be a 32-byte string
	nonce must be a 24-byte string
	crypted is the text to decrypt as a string
	offset is an optional integer. It is the length of the prefix used 
	by lock() if any. It defaults to 0.
	Return the decrypted text as a string or nil if the MAC 
	verification fails.
	
	Note: the responsibility of using matching prefix and offset belongs 
	to the application.
	

--- Curve25519-based key exchange

public_key(sk) => pk
	return the public key associated to a curve25519 secret key
	sk is the secret key as a 32-byte string
	pk is the associated public key as a 32-byte string

keypair() => pk, sk
	generates a pair of curve25519 keys (public key, secret key)
	pk is the public key as a 32-byte string
	sk is the secret key as a 32-byte string
	
	Note: This is a convenience function:
		pk, sk = keypair()  --is equivalent to
		sk = randombytes(32); pk = public_key(sk)

key_exchange(sk, pk) => k
	DH key exchange. Return a session key k used to encrypt 
	or decrypt a text.
	sk is the secret key of the party invoking the function 
	("our secret key"). 
	pk is the public key of the other party 
	("their public key").
	sk, pk and k are 32-byte strings


--- Blake2b cryptographic hash

blake2b_init([digest_size [, key]]) => ctx
	initialize and return a blake2b context object
	digest_size is the optional length of the expected digest. If provided,
	it must be an integer between 1 and 64. It defaults to 64.
	key is an optional key allowing to use blake2b as a MAC function.
	If provided, key is a string with a length that must be between 
	1 and 64. The default is no key.
	ctx is a pointer to the blake2b context as a light userdata.

blake2b_update(ctx, text_fragment)
	update the hash with a new text fragment
	ctx is a pointer to a blake2b context as a light userdata.

blake2b_final(ctx) => digest
	return the final value of the hash
	ctx is a pointer to a blake2b context as a light userdata.
	The digest is returned as a string. The length of the digest
	has been defined at the context creation (see blake2b_init()).
	It defaults to 64.

blake2b(text) => digest
	compute the hash of a string. 
	Returns a 64-byte digest.
	This is a convenience function which combines the init(), 
	update() and final() functions above.


--- Ed25519 signature

sign_public_key(sk) => pk
	return the public key associated to a secret key
	sk is the secret key as a 32-byte string
	pk is the associated public key as a 32-byte string

sign_keypair() => pk, sk
	generates a pair of ed25519 signature keys (public key, secret key)
	pk is the public signature key as a 32-byte string
	sk is the secret signature key as a 32-byte string

	Note: This is a convenience function:
		pk, sk = sign_keypair()  	--is equivalent to
		sk = randombytes(32); pk = sign_public_key(sk)

sign(sk, text) => sig
	sign a text with a secret key
	sk is the secret key as a 32-byte string
	text is the text to sign as a string
	Return the text signature as a 64-byte string.

check(sig, pk, text) => is_valid
	check a text signature with a public key
	sig is the signature to verify, as a 64-byte string
	pk is the public key as a 32-byte string
	text is the signed text
	Return a boolean indicating if the signature is valid or not.
	
	Note: curve25519 key pairs (generated with keypair())
	cannot be used for ed25519 signature. The signature key pairs 
	must be generated with sign_keypair().


--- Argon2i password derivation 

argon2i(pw, salt, nkb, niter) => k
	compute a key given a password and some salt
	This is a password key derivation function similar to scrypt.
	It is intended to make derivation expensive in both CPU and memory.
	pw: the password string
	salt: some entropy as a string (typically 16 bytes)
	nkb:  number of kilobytes used in RAM (as large as possible)
	niter: number of iterations (as large as possible, >= 10)
	Return k, a key string (32 bytes).

	For example: on a CPU i5 M430 @ 2.27 GHz laptop,
	with nkb=100000 (100MB) and niter=10, the derivation takes ~ 1.8 sec
	
```



## Acknowledgements

Copyright (C) 2017 by Dyne.org foundation, Amsterdam

Designed, written and maintained by Denis Roio <jaromil@dyne.org>

Includes code by:

- Mozilla foundation (lua_sandbox)
- Rich Felker, et al (musl-libc)
- IETF Trust (blake2b)
- Daniel J. Bernstein, Tanja Lange and Peter Schwabe (NaCl)
- Loup Vaillant (monocypher)
- Phil Leblanc (luanacha)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
