--[[
--This file is part of zenroom
--
--Copyright (C) 2021-2026 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
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
--Last modified by Matteo Cristino
--on Thursday, 26th September 2024
--]]

-- local W3C = require_once "crypto_w3c"

local ETHEREUM_ADDRESS = "ethereum_address"
local EDDSA_PUBLIC_KEY = "eddsa_public_key"

local function import_verification_method(doc)
    local res = {}
    local import_functions = {
        [ETHEREUM_ADDRESS] = O.from_hex,
        [EDDSA_PUBLIC_KEY] = O.from_base58
    }
    for key, _ in pairs(doc) do
        res[key] = schema_get(doc[key], '.',
                           import_functions[key] or O.from_base64,
                           tostring)
    end
    return res
end

local function export_verification_method(doc)
    local res = {}
    local export_functions = {
        [ETHEREUM_ADDRESS] = O.to_hex,
        [EDDSA_PUBLIC_KEY] = O.to_base58
    }
    for key, ver_method in pairs(doc) do
        res[key] = (export_functions[key] or O.to_base64)(ver_method)
    end
    return res
end

ZEN:add_schema(
    {
        verification_method = {
            import = import_verification_method,
			export = export_verification_method
        },
        verifiable_credential = function(obj)
            return schema_get(obj, '.', O.from_string, tostring)
        end,
        
    }
)

When("set verification method in '' to ''", function(vc, meth)
    local cred = have(vc)
    zencode_assert(cred.proof, 'The object is not signed: ' .. vc)
    local m = have(meth)
    ACK[vc].proof.verificationMethod = m
end)

When("get verification method in ''", function(vc)
    empty 'verification_method'
    local cred = have(vc)
    zencode_assert(cred.proof, 'The object is not signed: ' .. vc)
    ACK.verification_method = cred.proof.verificationMethod
    new_codec('verification_method')
end)

When("sign verifiable credential named ''", function(vc)
    local credential = have(vc)
    zencode_assert(not credential.proof,
                   'The object is already signed: ' .. vc)
    ACK[vc].proof = {
        ['type'] = O.from_string('Zenroom '.._G.ZENROOM_VERSION.original),
        -- "Signature", -- TODO: check what to write here for secp256k1
        -- created = "2018-06-18T21:19:10Z",

        -- create a JWS detached signature of the payload, default alg
        jws = JOSE.create_jws(false, nil, credential, true),
        proofPurpose = O.from_string'authenticate' -- assertionMethod", -- TODO: check
    }
end)

IfWhen("verify verifiable credential named ''", function(src)
    local document = have(src)
    if not zencode_assert(document.proof and document.proof.jws,
        'The object has no signature: ' .. src) then return end
    local proof <const> = document.proof
    document.proof = nil
    local jws <const> = JOSE.parse_jws(proof.jws)
    if jws.payload then
        if not zencode_assert(JSON.serialize(document) == jws.payload_enc,
                       "The JWS proof contains a different payload") then return end
    end
    local crypto  <const> = CRYPTO.load(jws.header.alg)
    local pk = mayhave('jws_public_key')
    if not pk then pk = have(crypto.keyname..'_public_key') end
    local to_be_verified <const> =
        jws.header_enc..O.from_string('.')..JSON.serialize(document)
    if not zencode_assert(crypto.verify(pk, to_be_verified, jws.signature),
                   'Invalid verifiable credential signature of: '..src) then return end
end)
