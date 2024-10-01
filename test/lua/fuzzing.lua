print 'test octet fuzzing functions'

r = OCTET.random(200)
l = r:fuzz_byte()
assert(l ~= r)

r = OCTET.random(2000)
l = r:fuzz_byte()
assert(l ~= r)

r = OCTET.random(700000)
l = r:fuzz_byte()
assert(l ~= r)


r = OCTET.random(200)
l = r:fuzz_byte_xor()
assert(r:hamming(l)==8)

r = OCTET.random(2000)
l = r:fuzz_byte_xor()
assert(r:hamming(l)==8)

r = OCTET.random(700000)
l = r:fuzz_byte_xor()
assert(r:hamming(l)==8)

r = OCTET.random(200)
l = r:fuzz_bit()
assert(r:hamming(l)==1)

r = OCTET.random(2000)
l = r:fuzz_bit()
assert(r:hamming(l)==1)

r = OCTET.random(700000)
l = r:fuzz_bit()
assert(r:hamming(l)==1)

r = OCTET.random(200)
l = r:fuzz_byte_circular_shift()
assert(l ~= r)

r = OCTET.random(2000)
l = r:fuzz_byte_circular_shift()
assert(l ~= r)

r = OCTET.random(700000)
l = r:fuzz_byte_circular_shift()
assert(l ~= r)

r = OCTET.random(200)
l = r:fuzz_bit_circular_shift()
assert(l ~= r)

r = OCTET.random(2000)
l = r:fuzz_bit_circular_shift()
assert(l ~= r)

r = OCTET.random(700000)
l = r:fuzz_bit_circular_shift()
assert(l ~= r)



