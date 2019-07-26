print''
print '= CURVE PAIRING OPERATIONS TESTS FOR BLS383'
print''

ECP = require_once('zenroom_ecp')
ECP2 = require_once('zenroom_ecp2')

G1 = ECP.generator()
G2 = ECP2.generator()
r = ECP.order()

rng = RNG.new()
-- return a random big number modulus curve order
function R() return rng:modbig(r) end

print("Multiplication of ECP1 generator and curve order is infinite")
inf = G1 * r
assert(inf:isinf())

print("Pick a random point in G1")
P1 = G1 * R()

print("Pick a random point in G2 (ECP2 multuplication)")
Q1 = G2 * R()

print("Test that miller(sQ,P) = miller(Q,sP), s random")
s = R()
g1 = ECP2.miller( Q1*s, P1)
g2 = ECP2.miller( Q1,   P1*s)
assert(g1 == g2)

print("Test that miller(sQ,P) = miller(Q,P)^s, s random")
g2 = ECP2.miller( Q1, P1)^s
assert(g1 == g2)

print("Test that miller(Q,P1+P2) = miller(Q,P1).e(Q,P2)")
P2 = P1 * s
g1 = ECP2.miller( Q1, P1 + P2 )
g2 = ECP2.miller( Q1, P1) * ECP2.miller( Q1, P2)
assert(g1 == g2)

print''
print('PAIRING OK')
print''
