-- to be executed using -S or _rng_ functions

ECP = require_once'zenroom_ecp'
ELGAMAL = require_once'crypto_elgamal'

print("Checks for deterministic operations")

rng = RNG.new()

first = rng:octet(16)
second = rng:octet(16)

-- subsequent executions lead to different results
assert( first ~= second )
I.print({ first = first })
I.print({ second = second })

-- new initialization doesn't resets from first
rng = RNG.new()
third = rng:octet(16)
assert( first ~= third )
I.print({ third = third })

i = INT.new(rng, ECP.order())
I.print({big_random = i})

-- ECDH
ecdh = ECDH.keygen()
I.print({ ecdh_keys = { sec = ecdh:private(),
						pub = ecdh:public() } })
ecdh2 = ECDH.new()
ecdh2:keygen()
I.print({ ecdh_keys = { sec = ecdh2:private(),
						pub = ecdh2:public() } })
assert(ecdh2:private() ~= ecdh:private())
assert(ecdh2:public() ~= ecdh:public())
c, d = ecdh:sign("Hello World!")
I.print({ ecdh_sign = { c = c, d = d } })
-- will check if same on next execution

-- ElGamal
-- d = INT.new(rng, ECP.order())
-- g = d * ECP.generator()
d, g = ELGAMAL.keygen()
I.print({ elg_keys = { d = d,
					   g = g }})
