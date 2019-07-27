print()
print "= ELLIPTIC CURVE ARITHMETIC OPERATIONS TESTS FOR GENERIC TRANSFORMATIONS"
print()

ECP = require_once('zenroom_ecp')

g1 = ECP.generator()
o = ECP.order()

-- octet serialization back and forth
a = ECP.hashtopoint(O.random(64))
print("ECP serialized length: "..#a:octet().." bytes")
print(a:octet())
b = ECP.new(a:octet())
assert(a == b)

-- learned from Coconut
wk = INT.modrand(o)
k = INT.modrand(o)
c = INT.modrand(o)
rk = wk:modsub(c * k, o)
-- rk = (wk - c*k) % o -- error when not using modsub
Aw1 = g1 * wk
Aw2 = (g1*k) * c + g1 * rk

assert(Aw1 == Aw2, 'Error in subtraction / modsub()')

-- mod_inverse
i = INT.modrand(ECP.order())
inv = i:modinv(ECP.order())
assert(i:modmul(inv, ECP.order()) == BIG.new(1), 'Error in mod_inverse (gcd based)')

print "OK"
