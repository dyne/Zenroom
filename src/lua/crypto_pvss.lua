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

local GENERATORS = {["g"] = ECP.new(BIG.new(O.from_hex("07ef3f7f6123b2f5e1ce7c249e0a44c8b18b3671e11d5e233d15742cf538d068f94dfae3ac9966e626a3d6670d78b6ee")), BIG.new(O.from_hex("12d5c20e3ce7143c03491820a7b08c067f25bd9b724985cd95ec862f8cbb31c944f420e59f8f820bccf6e94b72236ca7"))),
    ["G"] = ECP.new(BIG.new(O.from_hex("0a17f5c7ea3abe3654c4b56d709efd293e17e79327e15b2a7eababd02b20edf33bba0a6ff2c801923399c3c9fd6a1718")), BIG.new(O.from_hex("12f6579b77dbc6485107e68fe181e0aeb680f665880c7ded1db5f84c0a3fdc152f299511e4e5f64f1422d21c276f848a")))}

--------------------------------------- NIZKP ------------------------------------------------------

-- NOTE: the inputs of the following 2 functions are points on the curve.
function PVSS.det_concatenation(h1, h2, a1, a2)
    local concat = O.from_string(h1:x():decimal()) .. O.from_string(h1:y():decimal())
    concat = concat .. O.from_string(h2:x():decimal()) .. O.from_string(h2:y():decimal())
    concat = concat .. O.from_string(a1:x():decimal()) .. O.from_string(a1:y():decimal())
    concat = concat .. O.from_string(a2:x():decimal()) .. O.from_string(a2:y():decimal())
    return concat
end

function PVSS.concatenation(h1, h2, a1, a2)
    return h1:to_zcash() .. h2:to_zcash() .. a1:to_zcash() .. a2:to_zcash()
end

-- This function implements the creation of a non-interactive zero knwoledge proof
-- of the discrete logarithm equality.
-- Section 3 of https://link.springer.com/chapter/10.1007/3-540-48071-4_7
-- Section 3 of https://www.win.tue.nl/~berry/papers/crypto99.pdf
-- points_tables is an array where each component is {g1, h1, g2, h2}.
-- alpha = alpha_array[i] is such that g1^alpha = h1 and g2^alpha = h2
-- det_chall: array for deterministic challenges w, used just for testing
-- concat_f: optional (defualt PVSS.concatenation), function that specifies the order and encoding used for the output
-- hash: optional parameter, if not provided default to SHA-256
function PVSS.create_proof_DLEQ(points_tables, alpha_array, hash, concat_f, det_chall)
    local hash_function = hash or sha256
    local concat_function = concat_f or PVSS.concatenation
    local w_array = {}
    local r_array = {}
    local concat = O.empty()
    for k,v in pairs(points_tables) do
        local g1, h1, g2, h2 = table.unpack(v)
        local w
        if(det_chall) then
            w = det_chall[k]
        else
            w = BIG.modrand(CURVE_ORDER)
        end
        w_array[k] = w
        local a1 = g1 * w
        local a2 = g2 * w
        concat = concat .. concat_function(h1, h2, a1, a2)
    end
    local c = hash_function(concat)
    c = BIG.mod( BIG.new(c) , CURVE_ORDER)

    for k,alpha in pairs(alpha_array) do
        local r = alpha:modmul(c, CURVE_ORDER)
        r_array[k] = BIG.modsub(w_array[k], r, CURVE_ORDER)
    end
    table.insert(r_array, 1, c)
    return r_array
end

-- This function implements the verification of a non-interactive zero knwoledge proof
-- of the discrete logarithm equality.
-- Section 3 of https://link.springer.com/chapter/10.1007/3-540-48071-4_7
-- Section 3 of https://www.win.tue.nl/~berry/papers/crypto99.pdf
-- points_tables: see PVSS.create_proof_DLEQ
-- proof: table containing, in order, the challenge and the response(s).
-- hash and concat_f: see PVSS.create_proof_DLEQ
function PVSS.verify_proof_DLEQ(points_tables, proof, hash, concat_f)
    local hash_function = hash or sha256
    local concat_function = concat_f or PVSS.concatenation
    local concat = O.empty()
    local c = table.remove(proof, 1)
    for k,v in pairs(points_tables) do
        local g1, h1, g2, h2 = table.unpack(v)
        local r = proof[k]
        local a1 = (g1 * r) + (h1 * c)
        local a2 = (g2 * r) + (h2 * c)
        concat = concat..concat_function(h1, h2, a1, a2)
    end
    table.insert(proof,1,c)
    local digest = hash_function(concat)

    return ((BIG.mod(BIG.new(digest), CURVE_ORDER)) == c)
end

---------------------------------------- PVSS initialization -------------------------------------

-- Given a number n and a prime p, it returns a table containing n different generators of the curve.
-- NOTE that for BLS12-381 p is ECP.prime() and r is ECP.order().
local function create_generators(n, p, r)
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

-- This function returns the defualt fixed generators if no input is provided;
-- otherwise it returns random generators.
function PVSS.set_generators(is_random)
    if is_random then
        local table = create_generators(2, ECP.prime(), CURVE_ORDER)
        return {g = table[1], G = table[2]}
    else
        return GENERATORS
    end
end

--Create the secret and public keys of a partecipant using the generator G
function PVSS.keygen()
    return BIG.modrand(CURVE_ORDER)
end

function PVSS.sk2pk(generators, sk)
    return generators.G*sk
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

-- Given the secret s, the public keys pks, the quorum/threshold t and the total participants n,
-- the issuer computes the shares.
-- We assume that s is a BIG modulo CURVE_ORDER.
-- det_values (USED ONLY FOR TESTING) = table containing the polynomial coefficients array
-- AND the array of the "verifier challenges" used in the create_proof.
function PVSS.create_shares(generators, s, pks, t, n, det_values)
    local det_chall = nil
    local conc_f = nil
    local coefficients = {s}
    local commitments = {generators.g * s}
    if(not det_values) then
        for i = 2,t do
            coefficients[i] = BIG.modrand(CURVE_ORDER)
            commitments[i] = generators.g * coefficients[i]
        end
    else
        det_chall = det_values[2]
        conc_f = PVSS.det_concatenation
        for i = 2,t do
            coefficients[i] = det_values[1][i]
            commitments[i] = generators.g * coefficients[i]
        end
    end

    local encrypted_shares = {}
    local Xs = {}
    local evals = {}
    local proof_points = {}
    for i = 1,n do
        evals[i] = pol_evaluation(BIG.new(i), coefficients)
        encrypted_shares[i] = pks[i] * evals[i]
        Xs[i] = generators.g * evals[i]
        proof_points[i] = {generators.g, Xs[i], pks[i], encrypted_shares[i]}
    end

    local proof = PVSS.create_proof_DLEQ(proof_points, evals, nil, conc_f, det_chall)

    return {["commitments"] = commitments, ["public_keys"] = pks, ["encrypted_shares"] = encrypted_shares, ["proof"] = proof}, Xs, evals
end

-- Given the proofs of the encrypted shares, verify their validity.
-- issuer_shares: dictionary outputted from PVSS.create_shares.
function PVSS.verify_shares(generators, t, n, issuer_shares, concat_f)
    local concatentation_function = concat_f or PVSS.concatenation
    local Xs = {}
    local proof_points = {}
    for i=1,n do
        local value = ECP.infinity()
        for j = 0, (t-1) do
            local pow = BIG.new(i):modpower(BIG.new(j), CURVE_ORDER)
            value = value + (issuer_shares.commitments[j+1] * pow)
        end
        Xs[i] = value
        proof_points[i] = {generators.g, Xs[i], issuer_shares.public_keys[i], issuer_shares.encrypted_shares[i]}
    end

    return PVSS.verify_proof_DLEQ(proof_points, issuer_shares.proof, nil, concatentation_function)
end

-----------------------------------RECONSTRUCTION-------------------------------------------
-- See 'Reconstruction' in Section 3.1 of https://www.win.tue.nl/~berry/papers/crypto99.pdf

-- Given the private key x, the public key y and the dictionary outputted from PVSS.create_shares,
-- the participant decrypts the share and computes a ZKP of the correctness of the operation.
-- det_chall (USED ONLY FOR TESTING): array containing fixed "verifier challenges".
function PVSS.decrypt_share(generators, x, y, issuer_shares, det_chall)
    local index = 0
    for k,v in pairs(issuer_shares.public_keys) do
        if y == v then
            index = k
            break
        end
    end
    local Y = issuer_shares.encrypted_shares[index]
    local S = Y * BIG.modinv(x, CURVE_ORDER)
    local point_array = {generators.G, y, S, Y}
    local conc_f = nil
    if(det_chall) then
        conc_f = PVSS.det_concatenation
    end
    local proof = PVSS.create_proof_DLEQ({point_array}, {x}, nil, conc_f, det_chall)
    return {["dec_share"] = S, ["proof"] = proof, ["index"] = index, ["enc_share"] = Y, ["pub_key"] = y}
end

--Given as input an array of dictionaries outputted from PVSS.decrypt_shares,
-- verify the validity of the shares and return the list of valid decrypted shares
function PVSS.verify_decrypted_shares(generators, partecipants_shares, concat_f)
    local concatenation_function = concat_f or PVSS.concatenation
    local valid_shares = {}
    local valid_indexes = {}
    for i = 1, #partecipants_shares do
        if PVSS.verify_proof_DLEQ({{generators.G, partecipants_shares[i].pub_key, partecipants_shares[i].dec_share, partecipants_shares[i].enc_share}}, partecipants_shares[i].proof, nil, concatenation_function) then
            table.insert(valid_shares, partecipants_shares[i].dec_share)
            table.insert(valid_indexes, partecipants_shares[i].index)
        end
    end
    return valid_shares, valid_indexes
end

-- Given as input a table containing the decrypted shares, the indexes and the threshold, retrive the secret.
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
        error("The number of shares "..#shares.." is less then the threshold "..threshold, 2)
    end
end

return PVSS
