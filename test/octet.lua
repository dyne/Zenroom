print '= OCTET TESTS'

-- random and  check hash of octets
ecdh = require'ecdh'
ecc = ecdh.new()
right = ecc:random(64)
teststr = right:string()
test64 = right:base64()
testhex = right:hex()

left = octet.new()

print '== test octet copy'
left = right;
assert(left == right)
assert(ecc:hash(left) == ecc:hash(right))

print '== test string import/export'
left:string(teststr)
assert(left == right)
assert(left:string() == teststr)
assert(ecc:hash(left) == ecc:hash(right))

print '== test base64 import/export'
left:base64(test64)
assert(left == right)
assert(left:base64() == test64)
assert(ecc:hash(left) == ecc:hash(right))


print '== test hex import/export'
left:hex(testhex)
assert(left == right)
assert(left:hex() == testhex)
assert(ecc:hash(left) == ecc:hash(right))

print '= OK'


