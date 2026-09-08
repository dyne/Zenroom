local ED = require('ed')
local P256 = require('es256')

assert(OCTET.random(8):hex() == 'ae5a0eeaccdb66df',
       'OCTET.random stream changed')
assert(ED.secgen():hex() ==
       '8d547d3fcbec6c3df77dd4a78633e29d5d5564e3069b4597796568b19c2f17fe',
       'EdDSA key generation stream changed')
assert(P256.keygen():hex() ==
       '4666cd0285a3bce367f5f0545fed7340725f45cc880e1780e9e28438ec5d1034',
       'P-256 key generation stream changed')

local original = OCTET.from_hex('000102030405060708090a0b0c0d0e0f')
assert(original:fuzz_byte_xor():hex() ==
       '00fe02030405060708090a0b0c0d0e0f',
       'byte fuzzer stream changed')
assert(original:fuzz_bit():hex() ==
       '000102030405060708090a0b0c0d0e1f',
       'bit fuzzer stream changed')
