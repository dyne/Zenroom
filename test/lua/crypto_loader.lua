local loader = require'crypto_loader'

local from_string = loader.load('es256k')
assert(from_string.IANA == 'ES256K', 'string identifiers should resolve to ES256K')
assert(from_string.keyname == 'ecdh', 'ES256K should use the ECDH keyring')

local from_octet = loader.load(O.from_string('es256k'))
assert(from_octet.IANA == from_string.IANA, 'octet identifiers should resolve to the same algorithm')
assert(from_octet.keyname == from_string.keyname, 'octet identifiers should resolve to the same keyring')
assert(from_octet.sign == from_string.sign, 'octet identifiers should expose the same sign function')
assert(from_octet.verify == from_string.verify, 'octet identifiers should expose the same verify function')
assert(from_octet.pubgen == from_string.pubgen, 'octet identifiers should expose the same pubgen function')

print('crypto loader regressions OK')
