print ""
print "= ECDH and ECP session tests"
print ""

ECP = require'zenroom_ecp'

ecdh = ECDH.new('bls383')
rng = RNG.new()

g1 = ECP.generator()
o = ECP.order()

sk1 = INT.new(rng,o)
pk1 = sk1 * g1

sk2 = INT.new(rng,o)
pk2 = sk2 * g1

sp1ecp = pk1 * sk2 -- ECP only
sp2ecp = pk2 * sk1 -- ECP only
assert(sp1ecp == sp2ecp, "Fail ECP session calculation (multiplication)")

sp1ecpkdf = I.spy(ecdh:kdf(sp1ecp))
sp2ecpkdf = I.spy(ecdh:kdf(sp2ecp))
assert(sp1ecpkdf == sp2ecpkdf, "Fail KDF over ECP multiplication")

assert(ecdh:kdf(pk1 * sk2) == ecdh:kdf(pk2 * sk1), "Fail KDF+ECPmul implicit transformation")

hash = HASH.new('sha256')
assert(ECDH.kdf(hash, pk1*sk2) == ECDH.kdf(hash, pk2 * sk1), "Fail KDF+ECPmul with explicit HASH")

-- TODO: equal results by ECDH session and ECP multiplication?
-- fails perhaps because of use of PAIR_G1mul?
-- assert(sp1ecp == sp1)
-- assert(sp2ecp == sp2)

-- print(pk1)
-- print(pk1:octet())
-- print(type(pk1))
-- ses1,sp1 = ecdh:session(pk1,sk2)
-- ses2,sp2 = ecdh:session(pk2,sk1)

-- print(ses1)
-- print(ses2)
-- assert(ses1 == ses2, "Fail DH+KDF2 session calculation")
