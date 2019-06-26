-- to be executed using -S or _rng_ functions

rng = RNG.new()

first = rng:octet(16)
second = rng:octet(16)

-- subsequent executions lead to different results
assert( first ~= second )
print(first)
print(second)

-- new initialization doesn't resets from first
rng = RNG.new()
third = rng:octet(16)
assert( first ~= third )
print(third)

print("ECP checks for deterministic operations")
print(ECP.order())
i = INT.new(rng, ECP.order())
I.print({i})

-- ECDH
ecdh = ECDH.keygen()
print(ecdh:private())
print(ecdh:public())
I.print(ecdh:sign("Hello World!"))
ecdh2 = ECDH.new()
ecdh2:keygen()
print(ecdh2:private())
print(ecdh2:public())

-- ElGamal
-- d = INT.new(rng, ECP.order())
-- g = d * ECP.generator()
d, g = ELGAMAL.keygen()
I.print({ d, g })
