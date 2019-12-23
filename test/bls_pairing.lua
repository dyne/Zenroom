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
function R() return INT.modrand(O) end

print("Multiplication of ECP1 generator and curve order is infinite")
inf = G1 * O
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
-- print("rand: " .. bin(s))
assert(g1 == g2)

print("Test that miller(Q,P1+P2) = miller(Q,P1).e(Q,P2)")
P2 = P1 * s
g1 = ECP2.miller( Q1, P1 + P2 )
g2 = ECP2.miller( Q1, P1) * ECP2.miller( Q1, P2)
assert(g1 == g2)

print("Test that miller(Q1+Q2,P1) = miller(Q1,P1).e(Q2,P1)")
Q2 = G2 * s
g1 = ECP2.miller(Q1+Q2,P1)
g2 = ECP2.miller(Q1,P1) * ECP2.miller(Q2,P1)
assert(g1 == g2)




print("Test BLS Signatures")
-- δ = r.O
-- γ = δ.G2
-- σ = δ * ( H(m)*G1 )
-- assume: ε(δ*G2, H(m)) == ε(G2, δ*H(m))
-- check:  ε(γ, H(m))    == ε(G2, σ)

msg = str("This is the secret message")

-- keygen
-- δ = r.O
-- γ = δ.G2
sk = INT.modrand(O)
pk = G2 * sk

-- sign
-- σ = δ * ( H(m)*G1 )
sm = ECP.hashtopoint(msg) * sk

-- verify
-- e(γ,H(m)) == e(G2,σ)
hm = ECP.hashtopoint(msg)
assert( ECP2.miller(pk, hm) == ECP2.miller(G2, sm),
        "BLS Signature doesn't validates")

-- check verify fails on wrong sig
hm = ECP.hashtopoint(msg..str("!!"))
assert( ECP2.miller(pk, hm) ~= ECP2.miller(G2, sm),
        "BLS Signature validates incorrectly")

print("Test tripartite shared secret")
-- Parties A,B,C generate random a,b,c ∈ Zr
-- Parties A,B,C broadcast to all aG, bG, cG
-- A computes KA = e(bG, cG)^a
-- B computes KB = e(aG, cG)^b
-- C computes KC = e(aG, bG)^c
-- Shared key is K = KA = KB = KC = e(G, G)^abc

a = INT.modrand(O)
b = INT.modrand(O)
c = INT.modrand(O)
aG1 = G1 * a
aG2 = G2 * a
bG1 = G1 * b
bG2 = G2 * b
cG1 = G1 * c
cG2 = G2 * c
K  = ECP2.miller(G2, G1)   ^( a:modmul(b,O):modmul(c,O) )
KA = ECP2.miller(bG2, cG1) ^a
KB = ECP2.miller(aG2, cG1) ^b
KC = ECP2.miller(aG2, bG1) ^c
assert(K == KA, "BLS tripartite shared secret fails (A)")
assert(K == KB, "BLS tripartite shared secret fails (B)")
assert(K == KC, "BLS tripartite shared secret fails (C)")


print''
print('PAIRING OK')
print''
