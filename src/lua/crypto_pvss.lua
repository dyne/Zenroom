--[[
--This file is part of zenroom
--
--Copyright (C) 2023 Dyne.org foundation
--designed, written and maintained by Rebecca Selvaggini, Luca Di Domenico
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License v3.0
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--Along with this program you should have received a copy of the
--GNU Affero General Public License v3.0
--If not, see http://www.gnu.org/licenses/agpl.txt
--
--]]

local PVSS = {}

-- TODO: use secp256k1 (apparently ECDH, but ECDH.generator() does NOT exists,
-- and in the ECDH files only ECP_ZZZ_generator is called)
local CURVE_ORDER = ECP.order()

-- This function implements the creation of a non-interactive zero knwoledge proof
-- of the discrete logarithm equality.
-- Section 3 of https://link.springer.com/chapter/10.1007/3-540-48071-4_7
-- Section 3 of https://www.win.tue.nl/~berry/papers/crypto99.pdf
function PVSS.create_proof_DLEQ(points_tables, alpha_array, hash)
    -- points_tables is an array where each component is {g1, h1, g2, h2}.
    -- alpha is such that g1^alpha = h1 and g2^alpha = h2

    local hash_function = hash or sha256
    local w_array = {}
    local r_array = {}
    local concat = O.empty()
    for k,v in pairs(points_tables) do
        local g1, h1, g2, h2 = table.unpack(v)
        local w = BIG.modrand(CURVE_ORDER)
        w_array[k] = w
        local a1 = g1 * w
        local a2 = g2 * w
        concat = concat .. h1:zcash_export() .. h2:zcash_export() .. a1:zcash_export() .. a2:zcash_export()
    end

    local c = hash_function(concat)
    c = BIG.mod( BIG.new(c) , CURVE_ORDER)

    for k,alpha in pairs(alpha_array) do
        local r = alpha:modmul(c, CURVE_ORDER)
        r_array[k] = BIG.modsub(w_array[k], r, CURVE_ORDER)
    end

    return c, r_array
end

-- This function implements the verification of a non-interactive zero knwoledge proof
-- of the discrete logarithm equality.
-- Section 3 of https://link.springer.com/chapter/10.1007/3-540-48071-4_7
-- Section 3 of https://www.win.tue.nl/~berry/papers/crypto99.pdf
function PVSS.verify_proof_DLEQ(points_tables, c, r_array, hash)

    local hash_function = hash or sha256
    local concat = O.empty()
    for k,v in pairs(points_tables) do
        local g1, h1, g2, h2 = table.unpack(v)
        local r = r_array[k]
        local a1 = (g1 * r) + (h1 * c)
        local a2 = (g2 * r) + (h2 * c)
        concat = concat .. h1:zcash_export() .. h2:zcash_export() .. a1:zcash_export() .. a2:zcash_export()
    end

    local digest = hash_function(concat)

    if ( (BIG.mod( BIG.new(digest) , CURVE_ORDER)) == c) then
        return true
    end
    return false
end

--[[
    Given a number n and a prime p return a table containing n different generators of the curve.
    NOTE that for us p is ECP.prime() and r is ECP.order() 
--]] 
function PVSS.create_generators(n, p, r)
    local generators = {}
    while #generators < n do
        local x = BIG.modrand(p)
        local rhs = ECP.rhs(x)
        while BIG.jacobi(rhs, p) ~= 1 do
            x = BIG.modrand(p)
            rhs = ECP.rhs(x)
        end
        local y = BIG.modsqrt(rhs, p)
        local point = ECP.new(x,y)
        -- see function clear cofactor in src/lua/crypto_bbs.lua
        -- NOTE that this works only on BLS12-381 curve
        local h_eff = BIG.new(O.from_hex('d201000000010001'))
        point = point * h_eff
        if (point*r == ECP.infinity()) then
            local flag = true
            for _,k in pairs(generators) do
                if point == k then
                    flag = false
                end
            end
            if flag then 
                table.insert(generators, point)
            end
        end
    end
    return generators
end

--Create the secret and public keys of a partecipant using the generator G
function PVSS.keygen()
    return  BIG.modrand(CURVE_ORDER)
end

function PVSS.sk2pk(G, sk)
    return G*sk
end

-- polynomial evaluation using Horner's rule.
local function pol_evaluation(x, K_array)
    local len = #K_array
    local y = K_array[len]
    for i = len-1, 1, -1 do
        y = (K_array[i] + y:modmul(x, CURVE_ORDER)) % CURVE_ORDER
    end
    return y
end

function PVSS.create_shares(s, g, pks, t, n)
    -- We assume that s is a BIG modulo CURVE_ORDER.
    local coefficients = {s}
    local commitments = {g * s}
    for i = 2,t do
        coefficients[i] = BIG.modrand(CURVE_ORDER)
        commitments[i] = g * coefficients[i]
    end

    local encrypted_shares = {}
    -- local xs = {}
    local evals = {}
    local proof_points = {}
    for i = 1,n do
        evals[i] = pol_evaluation(BIG.new(i), coefficients)
        encrypted_shares[i] = pks[i] * evals[i]
        proof_points[i] = {g, g * evals[i], pks[i], encrypted_shares[i]}
    end

    local challenge, responses = PVSS.create_proof_DLEQ(proof_points, evals)

    return commitments, encrypted_shares, challenge, responses
end

function PVSS.verify_shares(g, pks, t, n, commitments, encrypted_shares, challenge, responses)
    local Xs = {}
    local proof_points = {}
    for i=1,n do
        local value = ECP.infinity()
        for j = 0, (t-1) do
            local pow = BIG.new(i):modpower(BIG.new(j), CURVE_ORDER)
            value = value + (commitments[j+1] * pow)
        end
        Xs[i] = value
        proof_points[i] = {g, Xs[i], pks[i], encrypted_shares[i]}
    end

    return PVSS.verify_proof_DLEQ(proof_points, challenge, responses)
end

return PVSS
