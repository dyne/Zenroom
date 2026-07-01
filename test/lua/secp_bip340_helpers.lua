-- BIP-340 native helper tests
local s = require("secp")

-- Tagged hash tests
-- Test vector: BIP0340/aux tag with known data
local tag_hash = s.bip340_tagged_hash("BIP0340/aux", OCTET.from_hex("0000000000000000000000000000000000000000000000000000000000000000"))
assert(#tag_hash == 32, "tagged hash length")
io.write("PASS: tagged_hash\n")

-- Secret key validation
local zero = OCTET.from_hex("0000000000000000000000000000000000000000000000000000000000000000")
local order_hex = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
local order = OCTET.from_hex(order_hex)
local one = OCTET.from_hex("0000000000000000000000000000000000000000000000000000000000000001")

assert(not s.bip340_seckey_valid(zero), "zero is invalid")
assert(not s.bip340_seckey_valid(order), "order is invalid")
assert(s.bip340_seckey_valid(one), "one is valid")
assert(s.bip340_seckey_valid(OCTET.random(32)), "random 32 bytes is valid")
io.write("PASS: seckey_valid\n")

-- lift_x
local G = s.G():xonly()
local P = s.bip340_lift_x(G)
assert(P ~= nil, "lift_x generator")
assert(P:xonly():hex() == G:hex(), "lift_x x matches")
-- Even y check: compressed prefix is 02
assert(P:compressed():hex():sub(1,2) == "02", "lift_x gives even y")
io.write("PASS: lift_x\n")

io.write("ALL BIP340 HELPER TESTS PASSED\n")
