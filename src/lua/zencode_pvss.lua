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
--]]

local PVSS = require'crypto_pvss'

local GENERATORS = PVSS.set_generators()

local function pvss_public_key_f(obj)
    local point = ECP.from_zcash(obj)
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

local function import_public_shares_f(obj)
    local res = {}
    res.public_keys = ZEN.get(obj, 'public_keys', pvss_public_key_f)
    res.proof = ZEN.get(obj, 'proof', BIG.new, O.from_base64)
    res.commitments = ZEN.get(obj, 'commitments', ECP.from_zcash, O.from_base64)
    res.encrypted_shares = ZEN.get(obj, 'encrypted_shares', ECP.from_zcash, O.from_base64)
    return res
end

local function export_public_shares_f(obj)
    local res = {["public_keys"] = {}, ["proof"] = {}, ["encrypted_shares"] = {}, ["commitments"] = {}}
    for k,v in pairs(obj.commitments) do
        res.commitments[k] = v:to_zcash()
    end
    local n = #obj.public_keys
    for i=1,n do
        res.public_keys[i] = obj.public_keys[i]:to_zcash()
        res.proof[i] = obj.proof[i]:octet():base64()
        res.encrypted_shares[i] = obj.encrypted_shares[i]:to_zcash()
    end
    res.proof[n+1] = obj.proof[n+1]:octet():base64()
    return res
end

local function import_secret_share_f(obj)
    local res = {}
    res.index = ZEN.get(obj, 'index', INT.from_decimal, tostring)
    res.proof = ZEN.get(obj, 'proof', BIG.new, O.from_base64)
    res.dec_share = ZEN.get(obj, 'dec_share', ECP.from_zcash, O.from_base64)
    res.enc_share = ZEN.get(obj, 'enc_share', ECP.from_zcash, O.from_base64)
    res.pub_key = ZEN.get(obj, 'pub_key', pvss_public_key_f)
    return res
end

local function export_secret_share_f(obj)
    local res = {["proof"]={}}
    res.index = obj.index:decimal()
    res.enc_share = obj.enc_share:to_zcash()
    res.dec_share = obj.dec_share:to_zcash()
    res.pub_key = obj.pub_key:to_zcash()
    for k,v in pairs(obj.proof) do
        res.proof[k] = v:octet():base64()
    end
    return res
end

local function import_verified_shares_f(obj)
    local res = {}
    res.valid_indexes = ZEN.get(obj, 'valid_indexes', INT.from_decimal, tostring)
    res.valid_shares = ZEN.get(obj, 'valid_shares', ECP.from_zcash, O.from_base64)
    return res
end

local function export_verified_shares_f(obj)
    local res = {["valid_indexes"] = {}, ["valid_shares"] = {}}
    for i = 1, #obj.valid_indexes do
        res.valid_shares[i] = obj.valid_shares[i]:to_zcash()
        res.valid_indexes[i] = obj.valid_indexes[i]:decimal()
    end
    return res
end

local function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

ZEN.add_schema(
    {
        pvss_public_key = {
            import = function(obj)
                return ZEN.get(obj, '.', pvss_public_key_f)
            end,
            export = ECP.to_zcash
        },
        pvss_public_shares = { import = import_public_shares_f,
            export = export_public_shares_f},
        pvss_secret_share = { import = import_secret_share_f,
            export = export_secret_share_f
        },
        pvss_verified_shares = { import = import_verified_shares_f,
            export = export_verified_shares_f
        }
    }
)

---------------------------------------- PVSS initialization -------------------------------------

-- Participant generates the private key
When('create the pvss key',function()
    initkeyring'pvss'
    ACK.keyring.pvss = PVSS.keygen()
end)

-- Participant generates the public key
When('create the pvss public key',function()
    empty'pvss public key'
    local sk = havekey'pvss'
    ACK.pvss_public_key = PVSS.sk2pk(GENERATORS, sk)
    new_codec('pvss public key', { zentype = 'e'})
end)

----------------------------------------- DISTRIBUTION --------------------------------------------

-- The issuer generates the encrypted shares for n participants with quorum t
When("create the pvss public shares of '' with '' quorum '' using the public keys ''", function(sec, num, thr, pubks)
    local s = have(sec)
	local n = tonumber(have(num):decimal())
	ZEN.assert(n, "Total shares is not a number: "..num)
	local t = tonumber(have(thr):decimal())
	ZEN.assert(t, "Quorum shares is not a number: "..thr)
    ZEN.assert(t <= n, "Quorum is bigger than total")
    local pks = have(pubks)
    local pvss_public_shares = PVSS.create_shares(GENERATORS, s, pks, t, n)

    empty'pvss public shares'
    ACK.pvss_public_shares = pvss_public_shares
    new_codec('pvss public shares')

end)

-- Anyone verifies the encrypted shares created by the issuer
When("verify the pvss public shares with '' quorum ''", function(num,thr)
    local pvss_public_shares = have'pvss public shares'
    local t = tonumber(have(thr):decimal())
    local n = tonumber(have(num):decimal())

    ZEN.assert(t <= n, "Quorum is bigger than total")

    ZEN.assert(type(pvss_public_shares.public_keys) == 'table', "'pvss participant pks' is not a table")
    ZEN.assert(type(pvss_public_shares.commitments) == 'table', "'pvss commitments' is not a table")
    ZEN.assert(type(pvss_public_shares.encrypted_shares) == 'table', "'pvss encrypted shares' is not a table")
    ZEN.assert(type(pvss_public_shares.proof) == 'table', "'pvss proof' is not a table")

    ZEN.assert(tablelength(pvss_public_shares.public_keys) == n, "'pvss participant pks' is of wrong length")
    ZEN.assert(tablelength(pvss_public_shares.commitments) == t, "'pvss commitments' is of wrong length")
    ZEN.assert(tablelength(pvss_public_shares.encrypted_shares) == n, "'pvss encrypted shares' is of wrong length")
    ZEN.assert(tablelength(pvss_public_shares.proof) == n + 1, "'pvss proof' is of wrong length")

    for _,v in pairs(pvss_public_shares.proof) do
        ZEN.assert(type(v) == 'zenroom.big', 'Proof element is not big')
        ZEN.assert(v < ECP.order(), 'Proof element is not modulo CURVE_ORDER')
    end

    ZEN.assert(
        PVSS.verify_shares(GENERATORS, t, n, pvss_public_shares),
        'The pvss public shares are not authentic'
    )
end)

----------------------------------- RECONSTRUCTION -------------------------------------------

-- Participant decrypts its own share AND generate a proof
When("create the secret share with public key ''", function(pk)
    local x = havekey'pvss'
    local y = have(pk)
    ZEN.assert(y == PVSS.sk2pk(GENERATORS, x))
    local issuer_shares = have'pvss public shares'
    local output = PVSS.decrypt_share(GENERATORS, x, y, issuer_shares)
    output["index"] = BIG.new(output["index"])

    empty'pvss secret share'
    ACK.pvss_secret_share = output
    new_codec('pvss secret share')
end)

-- Each participant verifies the shares of the others
When("create the pvss verified shares from ''", function(list)
    local dec_shares = have(list)
    local valid_shares, valid_indexes = PVSS.verify_decrypted_shares(GENERATORS, dec_shares)
    for k,v in pairs(valid_indexes) do
        valid_indexes[k] = BIG.new(v)
    end

    empty'pvss verified shares'
    ACK.pvss_verified_shares = {["valid_shares"] = valid_shares, ["valid_indexes"] = valid_indexes}
    new_codec('pvss verified shares')

end)

-- Secret reconstruction / pooling the share
When("compose the pvss secret using '' with quorum ''", function(shrs, thr)
    local threshold = tonumber(BIG.to_decimal(have(thr)))
    local verified_shares = have(shrs)

    local secret_point = PVSS.pooling_shares(verified_shares.valid_shares, verified_shares.valid_indexes, threshold)

    empty'pvss secret'
    ACK.pvss_secret = secret_point:to_zcash()
    new_codec('pvss secret', {zentype = 'e'})
end)
