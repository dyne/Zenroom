------------
--- <h1>Cryptographic primitives</h1>
--
-- The main goal of Zenroom is to provide a compact VM for controlled
-- execution of cryptographic functions. This section lists all the
-- cryptographic data transformations that are available in Zenroom.
--
-- @author Denis "Jaromil" Roio
-- @license LGPLv3
-- @copyright Dyne.org foundation 2017-2018


--- Random Generation
-- @section random

--- Generates a string of random bytes.
--
-- @int length must be 256 or less
-- @treturn string result
-- @return[2] nil
-- @return[2] string error message
-- @usage random = randombytes(32);
function randombytes(length)
end


--- Symmetric Encryption
-- @section encryption
--
-- The following functions all use a "<b>secret</b>" which is
-- basically the password of the encryption and then a "<b>nonce</b>"
-- which is also known to participants and is usually a number that
-- can be incremented at every communication.
--
-- All function names start with the <b>encrytp_</b> or
-- <b>decrypt_</b> prefixes followed by the name of the encryption
-- algorithm.

--- Symmetric NORX encryption of a message.
--
-- @string secret a "session secret", 32 bytes long
-- @string nonce must also be 32 bytes long
-- @string message in plain text
-- @treturn string encrypted text
-- @see exchange_session_x25519
-- @usage
-- nonce = randombytes(32)
-- pass = randombytes(32) -- should be a "shared secret"
-- cryptomsg = encrypt_norx(secret, nonce, "Secret Text")
-- -- eventually, encode in base64 and print out
-- print(encode_b64(cryptomsg))
function encrypt_norx(secret, nonce, message)
end


--- Symmetric NORX decryption of a message.
--
-- @string secret a "session secret", 32 bytes long
-- @string nonce must be 32 bytes long
-- @string message encrypted text
-- @treturn string plain text message
-- @return[2] nil
-- @return[2] string error message
-- @see exchange_session_x25519
-- @usage
-- nonce = randombytes(32)
-- pass = randombytes(32)
-- -- here we receive the encrypted message, assuming its base64 encoded
-- cryptomsg = decode_b64(DATA)
-- message = decrypt_norx(secret, nonce, cryptomsg)
-- -- print out the result
-- print(message)
function decrypt_norx(secret, nonce, message)
end

--- Asymmetric Session Keys
-- @section session

--- Generate a keypair based on EC25519.
--
-- Keys can be used in asymmetric cryptographic schemes where
-- participants share only their public keys and a nonce to generate a
-- shared "session secret" for each exchange.
--
-- @treturn[1] string secret key (sk)
-- @treturn[1] string public key (pk)
function keygen_session_x25519()
end

--- Get the public key associated to a secret EC25519 key.
--
-- @string pk secret key generated using keygen_session_x25519()
-- @treturn string public key (pk)
-- @see keygen_session_x25519
function pubkey_session_x25519(pk)
end

--- Compute a DH session key from different keypairs.
--
-- Having received a public key from someone else, we can compute a
-- "session secret" by combining it with our own secret key. The same
-- "session secret" can be known by the other person using his/her own
-- secret key and our public key. The "shared secret" can be then used
-- in encrypt/decrypt functions in each message exchange.
--
-- @string sk our secret key
-- @string pk public key from someone else
-- @treturn string shared session key
-- @see keygen_session_x25519
-- @see encrypt_norx
-- @see decrypt_norx
function exchange_session_x25519(sk,pk)


