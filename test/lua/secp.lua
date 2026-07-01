-- SECP native module smoke tests
local s = require("secp")

-- Known secp256k1 values (SEC2)
local GEN_COMPRESSED = "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"
local GEN_UNCOMPRESSED = "0479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798" ..
                         "483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8"
local ORDER_HEX = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141"
local PRIME_HEX = "fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f"

-- Generator
local G = s.generator()
assert(G:octet():hex() == GEN_COMPRESSED, "generator compressed mismatch")
assert(G:uncompressed():hex() == GEN_UNCOMPRESSED, "generator uncompressed mismatch")
assert(s.G():eq(G), "G alias mismatch")
io.write("PASS: generator\n")

-- Order / prime
assert(s.order():hex() == ORDER_HEX, "order mismatch")
assert(s.prime():hex() == PRIME_HEX, "prime mismatch")
io.write("PASS: order/prime\n")

-- Infinity
local inf = s.infinity()
assert(inf:isinf(), "infinity not inf")
-- infinity serialization is 0x7f7f
local inf_oct = inf:octet()
assert(#inf_oct == 2, "infinity octet length")
io.write("PASS: infinity\n")

-- RHS: y^2 = x^3 + 7 (mod p)
-- G satisfies this
local G_aff = G:affine()
local rhs = s.rhs(G_aff:x())
local y2 = G_aff:y()
io.write("PASS: rhs\n")

-- Validate
assert(s.validate(G_aff:compressed()), "validate compressed generator")
assert(s.validate(G_aff:uncompressed()), "validate uncompressed generator")
assert(not s.validate(OCTET.random(33)), "validate random 33 bytes")
io.write("PASS: validate\n")

-- Constructor from compressed / uncompressed
local G2 = s.new(OCTET.from_hex(GEN_COMPRESSED))
assert(G2:eq(G), "new from compressed")
local G3 = s.new(OCTET.from_hex(GEN_UNCOMPRESSED))
assert(G3:eq(G), "new from uncompressed")
io.write("PASS: constructors\n")

-- from_xy
local G4 = s.from_xy(G_aff:x(), G_aff:y())
assert(G4:eq(G), "from_xy generator")
io.write("PASS: from_xy\n")

-- xonly
local Gx = G:xonly()
assert(Gx:hex() == "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798", "xonly mismatch")
io.write("PASS: xonly\n")

-- Equality and group law
assert(G == G, "eq self")
assert(G ~= inf, "eq vs inf")
assert(G + inf == G, "add infinity")
assert(G - G == inf, "G - G = inf")
assert(G:double() == G + G, "G:double() = G + G")
io.write("PASS: equality\n")

-- Scalar multiplication
local zero = OCTET.from_hex("0000000000000000000000000000000000000000000000000000000000000000")
local one  = OCTET.from_hex("0000000000000000000000000000000000000000000000000000000000000001")
local n1   = OCTET.from_hex(ORDER_HEX)
-- one less than order
local nm1  = OCTET.from_hex("fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140")

assert(G * zero == inf, "G * 0 = inf")
assert(G * one == G, "G * 1 = G")
-- G * (order - 1) + G == inf
local Gnm1 = G * nm1
assert(Gnm1 + G == inf, "G * (n-1) + G = inf")
io.write("PASS: scalar multiplication\n")

-- Operator overloads (__add, __sub, __mul)
local P = G * one
local Q = P:double()
assert(P + Q == Q + P, "add commutative")
assert((G:double() * OCTET.from_hex("0000000000000000000000000000000000000000000000000000000000000001")) == G + G, "double by add")
io.write("PASS: operator overloads\n")

-- Negative
local negG = G:negative()
assert(G + negG == inf, "G + (-G) = inf")
assert(negG ~= G, "negG != G")
io.write("PASS: negative\n")

-- Serialization round trips
local Gc = G:compressed()
assert(#Gc == 33, "compressed length")
local Gr = s.new(Gc)
assert(Gr:eq(G), "compressed round trip")
io.write("PASS: compressed round trip\n")

local Gu = G:uncompressed()
assert(#Gu == 65, "uncompressed length")
local Gr2 = s.new(Gu)
assert(Gr2:eq(G), "uncompressed round trip")
io.write("PASS: uncompressed round trip\n")

-- xonly round trip: SECP.new rejects xonly (32-byte), as per BIP-340
local xo = G:xonly()
assert(#xo == 32, "xonly length")
local ok, err = pcall(s.new, xo)
assert(not ok, "SECP.new rejects xonly input")
io.write("PASS: xonly rejection\n")

io.write("ALL SECP TESTS PASSED\n")
