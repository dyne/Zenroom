print ""
print "= ECDH and ECP session tests"
print ""

rng = RNG.new()
g1 = ECP.generator()
o = ECP.order()

sk1 = INT.new(rng,o)
pk1 = sk1 * g1

sk2 = INT.new(rng,o)
pk2 = sk2 * g1

ecdh = ECDH.new('bls383')
ses1,sp1 = ecdh:session(pk1,sk2)
ses2,sp2 = ecdh:session(pk2,sk1)

assert(ses1 == ses2, "Fail DH+KDF2 session calculation")
assert(sp1 == sp2, "Fail DH session calculation")


-- print(ses1)
-- print(ses2)
-- print(sp1)
-- print(sp2)

sp1ecp = pk1 * sk2 -- ECP only
sp2ecp = pk2 * sk1 -- ECP only
-- print(sp1ecp)
-- print(sp2ecp)
assert(sp1ecp == sp2ecp, "Fail ECP session calculation (multiplication)")
-- TODO: equal results by ECDH session and ECP multiplication?
-- fails perhaps because of use of PAIR_G1mul?
-- assert(sp1ecp == sp1)
-- assert(sp2ecp == sp2)
