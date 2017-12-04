# Crypto API

Here a summary of calls available. This API is subject to change and more functions will be added according to requirements for the implementation of attribute based cryptographi in DECODE.

## Compression functions

```
blz(str)
	compress string str (BriefLZ algorithm)
	return the compressed string or (nil, error message)

unblz(cstr)
	uncompress string cstr
	return the uncompressed string or (nil, error message)

lzf(str)
	compress string str (LZF algorithm)
	return the compressed string or (nil, error message)

unlzf(cstr)
	uncompress string cstr
	return the uncompressed string or (nil, error message)
```

## Encoding functions

```
b64encode(str [, n])
	base64 encode string str. n is an optional integer
	if n > 0, a newline is inserted every n character in the encoded string
	if n == 0, no newline is inserted.
	if not provided, n defaults to 72.
	return the encoded string

b64decode(bstr)
	decode base64-encoded string bstr. Even non well-formed encoded strings (ie.
	strings with no "=" padding) are decoded.
	all whitespace characters in bstr are ignored.
	return the encoded string or nil if the string cannot be decoded

b58encode(str)
	base58 encode string str
	this uses the same alphabet as bitcoin addresses:
	"123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
	contrary to base64, base58 encodes a string as a long number 
	written in base58. 
	Base58 is not intended to be used for long strings, 
	if #str > 256, str is not encoded and the function raises an error.
	No newline is inserted in the encoded string.
	return the encoded string.

b58decode(bstr)
	decode base58-encoded string bstr
	return the decoded string or (nil, error message) in case of an 
	invalid base58 string or if the decoded string is longer than
	256 bytes.

xor(str, key)
	return the byte-to-byte xor of string str with string key.
	the returned string is always the same length as str.
	if key is longer than str, extra key bytes are ignored.
	if key is shorter than str, it is repeated as much as necessary.
```

## Authenticated encryption functions (Norx encryption algorithm)

```
aead_encrypt(encrypt(k, n, m [, ninc [, aad [, zad]]]) return c
	k: key string (32 bytes)
	n: nonce string (32 bytes)
	m: message (plain text) string 
	ninc: optional nonce increment (useful when encrypting a long message
	     as a sequence of block). The same parameter n can be used for 
	     the sequence. ninc is added to n for each block, so the actual
	     nonce used for each block encryption is distinct.
	     ninc defaults to 0 (the nonce n is used as-is)
	aad: prefix additional data (AD) (not encrypted, prepended to the 
	     encrypted message). default to the empty string
	zad: suffix additional data (not encrypted, appended to the 
	     encrypted message). default to the empty string
	return encrypted text string c with aad prefix and zad suffix
	(c includes the 32-byte MAC, so #c = #aad + #m + 32 + #zad)

aead_decrypt(k, n, c [, ninc [, aadln [, zadln]]]) 
	    return (m, aad, zad) | (nil, msg)
	k: key string (32 bytes)
	n: nonce string (32 bytes)
	c: encrypted message string 
	ninc: optional nonce increment (see above. defaults to 0)
	aadln: length of the AD prefix (default to 0)
	zadln: length of the AD suffix  (default to 0)
	return (plain text, aad, zad) or (nil, errmsg) if MAC is not valid
```

## Curve25519-based key exchange

```
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
```

## Blake2b cryptographic hash

```
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
```

## Ed25519 signature

```
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
```

## Argon2i password derivation 

```
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
	
	Note: this implementation has no threading support, so no parallel 
	execution.
```

## Legacy cryptographic functions

```
rc4raw(str, key) => encrypted (or decrypted) string
	encrypt (or decrypt, as rc4 is symmetric) string str with string key
	key length must be 16 (or an error is raised)
	return the encrypted string
	see http://en.wikipedia.org/wiki/RC4 for raw rc4 weaknesses
	rc4(), a rc4-drop implementation, should be used instead for most uses

rc4(str, key) => encrypted (or decrypted) string
	this is a rc4-drop encryption function with a 256-byte drop
	(ie. the rc4 state is initialized by "encrypting" a 256-byte block of
	zero bytes before starting the encyption of the string)
	arguments and return are the same as rc4raw()
	key length must be 16 (or an error is raised)

md5(str) => digest
	return the md5 hash of string str as a 16-byte binary string
	(no hex encoding)
```

## Misc functions

```
randombytes(n)
	return a random string of length n generated by the OS RNG 
	(/dev/urandom on Linux, or CryptGenRandom() on Windows)
```
