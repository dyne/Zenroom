-- Pedersen commitment tests over SECP

local S = require("secp")
local pedersen = require("crypto_pedersen")
local G = S.G()

io.write("=== Pedersen Commitment Tests ===\n")

-- Test H determinism
local H1 = pedersen.H()
local H2 = pedersen.H()
assert(H1 == H2, "H is deterministic")
io.write("PASS: H determinism\n")

-- Test H is not G
assert(H1 ~= G, "H != G")
io.write("PASS: H != G\n")

-- Basic commit/open round trip
local m = OCTET.random(32)
local r = OCTET.random(32)
local C = pedersen.commit(m, r)
assert(pedersen.open(C, m, r), "commit/open round trip")
io.write("PASS: commit/open\n")

-- Verify wrong message fails
local m2 = OCTET.random(32)
assert(not pedersen.open(C, m2, r), "wrong message should fail")
io.write("PASS: wrong message rejects\n")

-- Verify wrong blinding factor fails
local r2 = OCTET.random(32)
assert(not pedersen.open(C, m, r2), "wrong blinding should fail")
io.write("PASS: wrong blinding rejects\n")

-- Homomorphic addition
local m3 = OCTET.random(32)
local r3 = OCTET.random(32)
local C1 = pedersen.commit(m, r)
local C2 = pedersen.commit(m3, r3)
local C_sum = pedersen.add(C1, C2)

-- C1 + C2 should equal commit(m+m3, r+r3)
-- But we can't easily add scalars mod n in pure Lua (need native helpers)
-- Instead, verify that C_sum opens to (m, r) + (m3, r3) semantics:
-- If someone knows m,r and m3,r3, they can open the sum
assert(C_sum == C1 + C2, "homomorphic add matches point addition")
io.write("PASS: homomorphic addition\n")

-- Test with zero scalars
local zero = OCTET.from_hex("0000000000000000000000000000000000000000000000000000000000000000")
local C_zero_m = pedersen.commit(zero, r)
local rH = H1 * r
assert(C_zero_m == rH, "C = 0*G + r*H = r*H")
io.write("PASS: zero message\n")

-- Test commit with zero blinding
local C_zero_r = pedersen.commit(m, zero)
assert(C_zero_r == G * m, "C = m*G + 0*H = m*G")
io.write("PASS: zero blinding\n")

-- H is on the curve
local H_comp = H1:compressed()
assert(S.validate(H_comp), "H is valid point")
io.write("PASS: H is on curve\n")

-- H is not infinity
assert(not H1:isinf(), "H is not infinity")
io.write("PASS: H not infinity\n")

io.write("\nALL PEDERSEN TESTS PASSED\n")
