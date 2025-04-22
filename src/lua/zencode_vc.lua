--[[
--This file is part of zenroom
--
--Copyright (C) 2021-2025 Dyne.org foundation
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

local W3C = require_once "crypto_w3c"

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
    local sk = havekey'ecdh' -- assuming secp256k1
    zencode_assert(not credential.proof,'The object is already signed: ' .. vc)
    local proof = {
        type = 'Zenroom v'.._G.ZENROOM_VERSION.original,
        -- "Signature", -- TODO: check what to write here for secp256k1
        -- created = "2018-06-18T21:19:10Z",
        proofPurpose = 'authenticate' -- assertionMethod", -- TODO: check
    }
    local cred_str = W3C.json_encoding(vc)
    proof.jws = W3C.jws_signature_to_octet(ECDH.sign(sk, cred_str))
    ACK[vc].proof = deepmap(OCTET.from_string, proof)
end)

IfWhen("verify verifiable credential named ''", function(src)
    local document = have(src)
    zencode_assert(document.proof and document.proof.jws,
        'The object has no signature: ' .. src)
    W3C.verify_jws_from_proof(src, document)
end)
