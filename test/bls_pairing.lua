-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2019-2020 Dyne.org foundation
-- Written by Denis Roio
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

print''
print '= TEST BLS CURVE PAIRING OPERATIONS'
print''

G1 = ECP.generator()
G2 = ECP2.generator()
O = ECP.order()

-- return a random big number modulus curve order
function R() return INT.random() end

print("G1 size:  "..#(G1*R()):octet())
print("G2 size:  "..#(G2*R()):octet())
print("Ate size: "..#PAIR.ate( G2*R(), G1*R()):octet())

print("Multiplication of ECP1 generator and curve order is infinite")
inf = G1 * O
assert(inf:isinf())

print("Test miller(rQ,P) == miller(Q,rP) == miller(Q,P)^r")
Q = G2 * R()
P = G1 * R()
r = R()
g1 = PAIR.ate( Q*r, P)
g2 = PAIR.ate( Q,   P*r)
assert(g1 == g2)
g2 = PAIR.ate( Q, P)^r
assert(g1 == g2)

print("Test that miller(Q,P1+P2+P3) = miller(Q,P1).e(Q,P2).e(Q,P3)")
Q  = G2 * R()
P1 = G1 * R()
P2 = G1 * R()
P3 = G1 * R()
assert( PAIR.ate( Q, P1 + P2 + P3)
		   ==
		   PAIR.ate( Q, P1) * PAIR.ate( Q, P2) * PAIR.ate(Q, P3) )
-- check failures
assert( PAIR.ate( Q, P1 + P2 + P3)
		   ~=
		   PAIR.ate( Q, P1) * PAIR.ate( Q, P1) * PAIR.ate(Q, P1) )
assert( PAIR.ate( Q, P1 + P2 + P3)
		   ~=
		   PAIR.ate( Q, P2) * PAIR.ate( Q, P2) * PAIR.ate(Q, P2) )
assert( PAIR.ate( Q, P1 + P2 + P3)
		   ~=
		   PAIR.ate( Q, P3) * PAIR.ate( Q, P3) * PAIR.ate(Q, P3) )
--

print("Test that miller(Q1+Q2+Q3,P1) = miller(Q1,P1).e(Q2,P1).e(Q3,P1)")
P  = G1 * R()
q1 = R()
Q1 = G2 * q1
q2 = R()
Q2 = G2 * q2
q3 = R()
Q3 = G2 * q3
g1 = PAIR.ate(Q1+Q2+Q3,P)
g2 = PAIR.ate(Q1,P) * PAIR.ate(Q2,P) * PAIR.ate(Q3,P)
assert(g1 == g2)

print("Test that miller(Q1+Q2,P) != miller(Q1+Q2,R)")
assert(PAIR.ate(Q1+Q2,P) ~= PAIR.ate(Q1+Q2,G1*R()))




print("Test BLS Signatures")
-- δ = r.O
-- γ = δ.G2
-- σ = δ * ( H(m)*G1 )
-- assume: ε(δ*G2, H(m)) == ε(G2, δ*H(m))
-- check:  ε(γ, H(m))    == ε(G2, σ)

msg = str("This is the authenticated message")

-- keygen
-- δ = r.O
-- γ = δ.G2
sk = INT.random()
pk = G2 * sk

-- sign
-- σ = δ * ( H(m)*G1 )
sm = ECP.hashtopoint(msg) * sk

-- verify
-- e(γ,H(m)) == e(G2,σ)
hm = ECP.hashtopoint(msg)
assert( PAIR.ate(pk, hm) == PAIR.ate(G2, sm),
        "BLS Signature doesn't validates")

-- check verify fails on wrong sig
hmwrong = ECP.hashtopoint(msg..str("!!"))
assert( PAIR.ate(pk, hmwrong) ~= PAIR.ate(G2, sm),
        "BLS Signature validates incorrectly")

print'Test BLS aggregated signatures'
sk2 = INT.random()
pk2 = G2 * sk2
sm2 = ECP.hashtopoint(msg) * sk2
assert( PAIR.ate(pk2, hm) == PAIR.ate(G2, sm2),
        "BLS Signature 2 doesn't validates")
assert( PAIR.ate(pk + pk2, hm) == PAIR.ate(G2, sm + sm2),
        "BLS Signature aggregation doesn't validates")


print("Test tripartite shared secret")
-- Parties A,B,C generate random a,b,c ∈ Zr
-- Parties A,B,C broadcast to all aG, bG, cG
-- A computes KA = e(bG, cG)^a
-- B computes KB = e(aG, cG)^b
-- C computes KC = e(aG, bG)^c
-- Shared key is K = KA = KB = KC = e(G, G)^abc

a = INT.random()
b = INT.random()
c = INT.random()
aG1 = G1 * a
aG2 = G2 * a
bG1 = G1 * b
bG2 = G2 * b
cG1 = G1 * c
cG2 = G2 * c
K  = PAIR.ate(G2, G1)   ^( a * b * c )
KA =         PAIR.ate(bG2, cG1) ^a
assert(KA == PAIR.ate(cG2, bG1) ^a)
KB =         PAIR.ate(aG2, cG1) ^b
assert(KB == PAIR.ate(cG2, aG1) ^b)
KC =         PAIR.ate(aG2, bG1) ^c
assert(KC == PAIR.ate(bG2, aG1) ^c)
assert(K == KA, "BLS tripartite shared secret fails (A)")
assert(K == KB, "BLS tripartite shared secret fails (B)")
assert(K == KC, "BLS tripartite shared secret fails (C)")


print''
print('PAIRING OK')
print''
