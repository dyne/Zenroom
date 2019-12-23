-- Simple tests for BLS pairing applications

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


-- BLS Signatures
-- δ = r.O
-- γ = δ.G2
-- σ = δ * ( H(m)*G1 )
-- assume: ε(δ*G2, H(m)) == ε(G2, δ*H(m))
-- check:  ε(γ, H(m))    == ε(G2, σ)

ECP = require'zenroom_ecp'
ECP2 = require'zenroom_ecp2'

msg = str("This is the authenticated message")

local G1 = ECP.generator()
local G2 = ECP2.generator() -- return value
local O  = ECP.order() -- return value

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
        "Signature doesn't validates")

-- check verify fails on wrong sig
hm = ECP.hashtopoint(msg..str("!!"))
assert( ECP2.miller(pk, hm) ~= ECP2.miller(G2, sm),
        "Signature validates incorrectly")

-- Joux’s one-round Tripartite Diffie-Hellman
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
assert(K == KA)
assert(K == KB)
assert(K == KC)

