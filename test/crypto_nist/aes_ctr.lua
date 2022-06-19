print('AES-CTR vector tests (NIST)')
-- vectors from https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-38a.pdf


print(' F.5.1 CTR-AES128.Encrypt')
Key     = O.from_hex('2b7e151628aed2a6abf7158809cf4f3c')
Counter = O.from_hex('f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff')

-- Block #1 
Input      = O.from_hex('f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff')
Output     = O.from_hex('ec8cdf7398607cb0f2d21675ea9ea1e4')
Plaintext  = O.from_hex('6bc1bee22e409f96e93d7e117393172a')
Ciphertext = O.from_hex('874d6191b620e3261bef6864990db6ce')
assert( AES.ctr(Key, Plaintext, Input) == Ciphertext, "Error in block #1" )

-- Block #2 
Input      = O.from_hex('f0f1f2f3f4f5f6f7f8f9fafbfcfdff00')
Output     = O.from_hex('362b7c3c6773516318a077d7fc5073ae')
Plaintext  = O.from_hex('ae2d8a571e03ac9c9eb76fac45af8e51')
Ciphertext = O.from_hex('9806f66b7970fdff8617187bb9fffdff')
assert( AES.ctr(Key, Plaintext, Input) == Ciphertext, "Error in block #2" )

-- Block #3 
Input      = O.from_hex('f0f1f2f3f4f5f6f7f8f9fafbfcfdff01')
Output     = O.from_hex('6a2cc3787889374fbeb4c81b17ba6c44')
Plaintext  = O.from_hex('30c81c46a35ce411e5fbc1191a0a52ef')
Ciphertext = O.from_hex('5ae4df3edbd5d35e5b4f09020db03eab')
assert( AES.ctr(Key, Plaintext, Input) == Ciphertext, "Error in block #3" )

-- Block #4 
Input      = O.from_hex('f0f1f2f3f4f5f6f7f8f9fafbfcfdff02')
Output     = O.from_hex('e89c399ff0f198c6d40a31db156cabfe')
Plaintext  = O.from_hex('f69f2445df4f9b17ad2b417be66c3710')
Ciphertext = O.from_hex('1e031dda2fbe03d1792170a0f3009cee')
assert( AES.ctr(Key, Plaintext, Input) == Ciphertext, "Error in block #4" )


Key     = O.from_hex('2b7e151628aed2a6abf7158809cf4f3c')
Counter = O.from_hex('f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff')

print(' F.5.2 CTR-AES128.Decrypt')
-- Block #1 
Input      = O.from_hex('f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff')
Output     = O.from_hex('ec8cdf7398607cb0f2d21675ea9ea1e4')
Ciphertext = O.from_hex('874d6191b620e3261bef6864990db6ce')
Plaintext  = O.from_hex('6bc1bee22e409f96e93d7e117393172a')
assert( AES.ctr(Key, Ciphertext, Input) == Plaintext, "Error in block #4" )

-- Block #2 
Input      = O.from_hex('f0f1f2f3f4f5f6f7f8f9fafbfcfdff00')
Output     = O.from_hex('362b7c3c6773516318a077d7fc5073ae')
Ciphertext = O.from_hex('9806f66b7970fdff8617187bb9fffdff')
Plaintext  = O.from_hex('ae2d8a571e03ac9c9eb76fac45af8e51')
assert( AES.ctr(Key, Ciphertext, Input) == Plaintext, "Error in block #4" )

-- Block #3 
Input      = O.from_hex('f0f1f2f3f4f5f6f7f8f9fafbfcfdff01')
Output     = O.from_hex('6a2cc3787889374fbeb4c81b17ba6c44')
Ciphertext = O.from_hex('5ae4df3edbd5d35e5b4f09020db03eab')
Plaintext  = O.from_hex('30c81c46a35ce411e5fbc1191a0a52ef')
assert( AES.ctr(Key, Ciphertext, Input) == Plaintext, "Error in block #4" )

-- Block #4 
Input      = O.from_hex('f0f1f2f3f4f5f6f7f8f9fafbfcfdff02')
Output     = O.from_hex('e89c399ff0f198c6d40a31db156cabfe')
Ciphertext = O.from_hex('1e031dda2fbe03d1792170a0f3009cee')
Plaintext  = O.from_hex('f69f2445df4f9b17ad2b417be66c3710')
assert( AES.ctr(Key, Ciphertext, Input) == Plaintext, "Error in block #4" )

print('OK')
