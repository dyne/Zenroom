--[[
--This file is part of zenroom
--
--Copyright (C) 2023 Dyne.org foundation
--designed, written and maintained by Rebecca Selvaggini and Luca Di Domenico
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
--Last modified by ...
--on ...
--]]

local PVSS = require'crypto_pvss'

-- TODO: decide if g, G should be fixed or they should be randomly generated using Tonelli-Shanks.

g = ECP.new(BIG.new(O.from_hex("07ef3f7f6123b2f5e1ce7c249e0a44c8b18b3671e11d5e233d15742cf538d068f94dfae3ac9966e626a3d6670d78b6ee")), BIG.new(O.from_hex("12d5c20e3ce7143c03491820a7b08c067f25bd9b724985cd95ec862f8cbb31c944f420e59f8f820bccf6e94b72236ca7")))
G = ECP.new(BIG.new(O.from_hex("0a17f5c7ea3abe3654c4b56d709efd293e17e79327e15b2a7eababd02b20edf33bba0a6ff2c801923399c3c9fd6a1718")), BIG.new(O.from_hex("12f6579b77dbc6485107e68fe181e0aeb680f665880c7ded1db5f84c0a3fdc152f299511e4e5f64f1422d21c276f848a")))

local function pvss_public_key_f(obj)
    local point = obj:zcash_topoint()
    ZEN.assert(
       point ~=  ECP.infinity(),
       'pvss public key is not valid (is infinity)'
    )
    ZEN.assert(
        point*ECP.order() == ECP.infinity(),
        'pvss public key is not valid (not in the subgroup)'
    )
    return point
end

local function pvss_enc_shares_imp_f(obj)
    -- obj is of the form {i, Y_i} where i is integer, Y_i is ECP point
    if type(obj) == "string" then
        local tonumb = tonumber(obj)
        if tonumb then
            return BIG.new(tonumb)
        else
            return O.from_base64(obj):zcash_topoint()
        end
    else
        error("Invalid type of object in encrypted share", 2)
    end
end

local function pvss_enc_shares_exp_f(obj)
    -- obj is of the form {{i_1, Y_i_1}, ..., {i_v, Y_i_v}}
    local output = {}
    for _,v in pairs(obj) do
        table.insert( output, { BIG.to_decimal( v[1] ) , v[2]:zcash_export() })
    end
    return output
end

ZEN.add_schema(
    {
        pvss_public_key = {
            import = function(obj)
                return ZEN.get(obj, '.', pvss_public_key_f)
            end,
            export = function(o) return o:zcash_export() end
        },
        pvss_encrypted_shares = {
            import = function(obj)
                return ZEN.get(obj, '.', nil, pvss_enc_shares_imp_f)
            end,
            export = pvss_enc_shares_exp_f
        }
    }
)

---------------------------------------- PVSS initialization -------------------------------------

-- generate the private key
When('create the pvss key',function()
    initkeyring'pvss'
    ACK.keyring.pvss = PVSS.keygen()
end)

-- generate the public key
When('create the pvss public key',function()
    empty'pvss public key'
    local sk = havekey'pvss'
    ACK.pvss_public_key = PVSS.sk2pk(G, sk)
    new_codec('pvss public key', { zentype = 'e'})
end)

----------------------------------------- DISTRIBUTION --------------------------------------------

-- TODO: array of public keys in schema to execute "have'pks'" ?
When("create the pvss secret shares of '' with '' quorum '' using the public keys ''", function(sec, num, thr, pubks)
    local s = have(sec)
	local n = tonumber(num)
	ZEN.assert(n, "Total shares is not a number: "..num)
	local t = tonumber(thr)
	ZEN.assert(t, "Quorum shares is not a number: "..thr)
    ZEN.assert(t <= n, "Quorum is bigger than total")
    local pks = have(pubks)
    local Cs, Yarray, challenge, responses = PVSS.create_shares(s, g, pks, t, n)

    empty'pvss cs'
    for i = 1,t do
        Cs[i] = Cs[i]:zcash_export()
    end
    ACK.pvss_cs = Cs
    new_codec('pvss cs', {zentype='a'}) -- array of points.

    empty'pvss encrypted shares'
    for i = 1, n do
        Yarray[i][1] = BIG.new(Yarray[i][1])
    end
    ACK.pvss_encrypted_shares = Yarray
    new_codec('pvss encrypted shares')

    -- pvss_proof is an array of BIGs: {challenge, r} or {challenge, r_1,..,r_n}
    empty'pvss proof'
    table.insert(responses, 1, challenge)
    ACK.pvss_proof = responses
    new_codec('pvss proof', {zentype='a'}) -- array of BIGs.

    empty'pvss quorum'
    ACK.pvss_quorum = BIG.new(t)
    new_codec('pvss quorum', {zentype = 'e'})

    empty'pvss total'
    ACK.pvss_total = BIG.new(n)
    new_codec('pvss total', {zentype = 'e'})

    -- empty'pvss participant pks'
    -- ACK.pvss_participant_pks = pks
    -- new_codec('pvss participant pks', {zentype = 'a'})
end)

When("verify the pvss encrypted shares", function()
    local commitments = have'pvss cs'
    local encrypted_shares = have'pvss encrypted shares'
    local proof = have'pvss proof'
    local t = have'pvss quorum'
    local n = have'pvss total'
    local pks = have'pvss participant pks'

    n = tonumber(BIG.to_decimal(n))
    t = tonumber(BIG.to_decimal(t))
    ZEN.assert(t <= n, "Quorum is bigger than total")

    ZEN.assert(type(pks) == 'table', "'pvss participant pks' is not a table")
    ZEN.assert(type(commitments) == 'table', "'pvss commitments' is not a table")
    ZEN.assert(type(encrypted_shares) == 'table', "'pvss encrypted shares' is not a table")
    ZEN.assert(type(proof) == 'table', "'pvss proof' is not a table")

    ZEN.assert(#pks == n, "'pvss participant pks' is of wrong length")
    ZEN.assert(#commitments == t, "'pvss commitments' is of wrong length")
    ZEN.assert(#encrypted_shares == n, "'pvss encrypted shares' is of wrong length")
    ZEN.assert(#proof == n + 1, "'pvss proof' is of wrong length")

    for i = 1,t do
        commitments[i] = pvss_public_key_f(commitments[i])
    end

    local enc_shares = {}

    for i = 1,n do
        pks[i] = pvss_public_key_f(pks[i])
        enc_shares[i] = { tonumber(BIG.to_decimal(encrypted_shares[i][1])), encrypted_shares[i][2] }
        ZEN.assert(type(proof[i]) == 'zenroom.big', 'Proof element is not big')
        ZEN.assert(proof[i] < ECP.order(), 'Proof element is not modulo CURVE_ORDER')
    end
    ZEN.assert(type(proof[n + 1]) == 'zenroom.big', 'Proof element is not big')
    ZEN.assert(proof[n + 1] < ECP.order(), 'Proof element is not modulo CURVE_ORDER')

    -- TODO: use "table.remove" ?
    local challenge = proof[1]
    local responses = { table.unpack(proof, 2, n+1) }

    ZEN.assert(
        PVSS.verify_shares(g, pks, t, n, commitments, enc_shares, challenge, responses),
        'The pvss encrypted shares are not authentic'
    )
end)

----------------------------------- RECONSTRUCTION -------------------------------------------

-- - [1] Participant decrypts its own share AND generate a proof
-- - [2] Each participant verifies the shares of the others
-- - [3] Secret reconstruction / pooling the share
