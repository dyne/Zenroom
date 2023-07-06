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

local CURVE_ORDER = ECP.order()

--------------------------------------- NIZKP ------------------------------------------------------

-- This function implements the creation of a non-interactive zero knwoledge proof
-- of the discrete logarithm equality.
-- Section 3 of https://link.springer.com/chapter/10.1007/3-540-48071-4_7
-- Section 3 of https://www.win.tue.nl/~berry/papers/crypto99.pdf
function PVSS.create_proof_DLEQ(points_tables, alpha_array, hash, is_det)
    -- points_tables is an array where each component is {g1, h1, g2, h2}.
    -- alpha is such that g1^alpha = h1 and g2^alpha = h2

    local hash_function = hash or sha256
    local w_array = {}
    local r_array = {}
    local concat = O.empty()
    for k,v in pairs(points_tables) do
        local g1, h1, g2, h2 = table.unpack(v)
        local w
        if(is_det) then
            w = BIG.new(k+3)
        else
            w = BIG.modrand(CURVE_ORDER)
        end
        w_array[k] = w
        local a1 = g1 * w
        local a2 = g2 * w
        if(is_det) then
            -- TODO: decide if it is best to use our element order in the concatenation
            -- or the one seen in the Sage implementation.
            concat = concat .. O.from_string(h1:x():decimal()) .. O.from_string(h1:y():decimal())
            concat = concat .. O.from_string(h2:x():decimal()) .. O.from_string(h2:y():decimal())
            concat = concat .. O.from_string(a1:x():decimal()) .. O.from_string(a1:y():decimal())
            concat = concat .. O.from_string(a2:x():decimal()) .. O.from_string(a2:y():decimal())
        else
            concat = concat .. h1:zcash_export() .. h2:zcash_export() .. a1:zcash_export() .. a2:zcash_export()
        end
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
    -- c is the challenge, r_array contains the responses

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


---------------------------------------- PVSS initialization -------------------------------------

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
-- K_array is the coefficients table
local function pol_evaluation(x, K_array)
    local len = #K_array
    local y = K_array[len]
    for i = len-1, 1, -1 do
        y = (K_array[i] + y:modmul(x, CURVE_ORDER)) % CURVE_ORDER
    end
    return y
end

----------------------------------------- DISTRIBUTION --------------------------------------------
-- See 'Distribution' in Section 3.1 of https://www.win.tue.nl/~berry/papers/crypto99.pdf

-- Given the secret, the public keys, the values t and n compute the shares 
-- det_pol_coefs = polynomial coefficients array needed only for deretministic tests
function PVSS.create_shares(s, g, pks, t, n, det_pol_coefs)
    -- We assume that s is a BIG modulo CURVE_ORDER.
    local is_det = nil
    local coefficients = {s}
    local commitments = {g * s}
    if(not det_pol_coefs) then
        for i = 2,t do
            coefficients[i] = BIG.modrand(CURVE_ORDER)
            commitments[i] = g * coefficients[i]
        end
    else
        is_det = true
        for i = 2,t do
            coefficients[i] = det_pol_coefs[i]
            commitments[i] = g * coefficients[i]
        end
    end

    local encrypted_shares = {}
    local Xs = {}
    local evals = {}
    local proof_points = {}
    for i = 1,n do
        evals[i] = pol_evaluation(BIG.new(i), coefficients)
        encrypted_shares[i] = {i, pks[i] * evals[i]}
        Xs[i] = g * evals[i]
        proof_points[i] = {g, Xs[i], pks[i], encrypted_shares[i][2]}
    end

    local challenge, responses = PVSS.create_proof_DLEQ(proof_points, evals, nil, is_det)

    return commitments, encrypted_shares, challenge, responses, Xs, evals
end

-- Given the proofs of the encrypted shares, verify their validity
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
        proof_points[i] = {g, Xs[i], pks[i], encrypted_shares[i][2]}
    end

    return PVSS.verify_proof_DLEQ(proof_points, challenge, responses)
end

-----------------------------------RECONSTRUCTION-------------------------------------------
-- See 'Reconstruction' in Section 3.1 of https://www.win.tue.nl/~berry/papers/crypto99.pdf


-- Given the private key x, the encrypted share Y, the public key y, the generator G, the partecipant index 'index'
-- the participant decrypt the share and compute a ZKP of the correctness of the operation
-- is_det is a boolean used for tests
function PVSS.decrypt_share(x, Y, y, G, index, is_det)
    local S = Y * BIG.modinv(x, CURVE_ORDER)
    local point_array = {G, y, S, Y}
    local challenge, responses = PVSS.create_proof_DLEQ({point_array}, {x}, nil, is_det)
    return {S, challenge, responses[1], point_array, index}
end

--Given as input a table containing the output tables of PVSS.decrypt_shares, verify the validity of the shares
-- return the list of valid decrypted shares
function PVSS.verify_decrypted_shares(shares_proof)
    local valid_shares = {}
    local valid_indexes = {}
    for i = 1, #shares_proof do
        if PVSS.verify_proof_DLEQ({shares_proof[i][4]}, shares_proof[i][2], {shares_proof[i][3]}) then
            table.insert(valid_shares, shares_proof[i][1])
            table.insert(valid_indexes, shares_proof[i][5])
        end
    end
    return valid_shares, valid_indexes
end

-- Given as input a table containing the decrypted shares and the threshold retrive the secret.
-- Here we are assuming that the shares have been already verified.
function PVSS.pooling_shares(shares, indexes, threshold)
    if #shares >= threshold then
        local secret = ECP.infinity()
        for k = 1, threshold do
            local i = indexes[k]
            local lagrange_coeff = BIG.new(1)
            for m = 1, threshold do
                local j = indexes[m]
                local factor = BIG.new(1)
                if j ~= i then
                    local big_j = BIG.new(j)
                    factor = BIG.moddiv(big_j, BIG.modsub(big_j, BIG.new(i), CURVE_ORDER), CURVE_ORDER)
                    lagrange_coeff = BIG.modmul(lagrange_coeff,factor, CURVE_ORDER)
                end
            end
            secret = secret + (shares[k]*lagrange_coeff)
        end
        return secret
    else
        -- TODO: throw error or return nil or something?
        error("The number of shares is less then the threshold", 2)
    end
end

return PVSS
