print '= OCTET TESTS'

test = 'testing the octets in zenroom'
test64 = 'dGVzdGluZyB0aGUgb2N0ZXRzIGluIHplbnJvb20='
testhex = '74657374696e6720746865206f637465747320696e207a656e726f6f6d'

left = octet.new()
right = octet.new()
right:string(test)

-- also check hash of octets
ecdh = require'ecdh'
ecc = ecdh.new()

print '== test string import/export'
print(test)
print(right:string())
assert(test == right:string())

print '== test base64 import'
left:base64(test64)
print(test64)
print(left:base64())
assert(left == right)
assert(ecc:hash(left) == ecc:hash(right))


print '== test hex import'
left:hex(testhex)
print(testhex)
print(left:hex())
assert(left == right)
assert(ecc:hash(left) == ecc:hash(right))

print '== test base64 export'
print(test64)
print(left:base64())
assert(left:base64() == test64)
assert(ecc:hash(left) == ecc:hash(right))

print '== test hex export'
print (left:hex())
print (testhex)
assert(left:hex() == testhex)
assert(ecc:hash(left) == ecc:hash(right))

print '= OK'


