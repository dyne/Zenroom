print("Checks for deterministic operations")

first = O.random(16)
second = O.random(16)

-- subsequent executions lead to different results
assert( first ~= second )
I.print({ first = first })
I.print({ second = second })

-- new initialization doesn't resets from first
third = O.random(16)
assert( first ~= third )
I.print({ third = third })

i = INT.random()
I.print({big_random = i})

-- ECDH
ecdh = ECDH.keygen()
I.print({ ecdh_keys = { sec = ecdh.private,
						pub = ecdh.public } })
ecdh2 = ECDH.keygen()
I.print({ ecdh_keys = { sec = ecdh2.private,
						pub = ecdh2.public } })
assert(ecdh2.private ~= ecdh.private)
assert(ecdh2.public ~= ecdh.public)
c, d = ECDH.sign(ecdh.private, "Hello World!")
I.print({ ecdh_sign = { c = c, d = d } })
-- will check if same on next execution
