
-- Initialisation

rng = RNG.new() -- initialise a new random number generator
g = ECP.G() -- get the curve's generator coordinates
h = g * 2 -- hashtopoint "h0"
order = ECP.order() -- get the curves order in a big

-- ElGamal Key Generation
private = rng:big()
public = g * private
print "== private key:"
print(private)
print "== public key:"
print(public)

-- Encrypt a msg with 1
k = rng:big()
a = g * k
b = (public * k) + h * BIG.new(1)
print "== encrypted with 1"
print(b)

-- Encrypt a msg with 2
k2 = rng:big()
a2 = g * k2
b2 = (public * k2) + h * BIG.new(2)
print "== encrypted with 2"
print(b2)

-- Sum both messages
sum_k = k + k2
sum_a = a + a2
sum_b = b + b2

-- Decrypt
x = (sum_a * private):negative()
y = sum_b + x
assert(y == h * BIG.new(3)) -- this should yeld the sum of the two encrypted messages
print("Decrypted succesfully! x and y:")
print(x)
print(y)
