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

local W3C = require_once "crypto_w3c"

local ETHEREUM_ADDRESS = "ethereum_address"
local EDDSA_PUBLIC_KEY = "eddsa_public_key"

local function import_did_document(doc)
    -- id and @context must be always present in DID-documents
    zencode_assert(doc.id and #doc.id < 256, 'Invalid DID document: id not found')
    zencode_assert(doc['@context'], 'Invalid DID document: @context not found')
    zencode_assert(#JSON.encode(doc, 'string') < 8192, 'DID document too large')
    local did_components = strtok(doc.id, ':')
    -- schme: did
    zencode_assert(did_components[1] == 'did',
            'Invalid DID document: invalid scheme')
    -- method name: a-z/0-9
    zencode_assert(not did_components[2]:match('[^%l%d]'),
            'Invalid DID document: invalid method-name')
    -- mathod specific identifier: a-z/A-Z/0-9/"."/"-"/"_"/"%" HEXDIG HEXDIG
    local error_msg = 'Invalid DID document: invalid method specific identifier'
    for i=3,#did_components do
        first = true
        for chars in did_components[i]:gmatch('[^%%]*') do
            if first then
                zencode_assert(not chars:match('[^%w%.%-%_]'),
                    error_msg)
                first = nil
            else
            -- checks %%
            zencode_assert(chars, error_msg)
            -- checks %hexhex...
            zencode_assert(chars:match('%x%x[%w%.%-%_]*') == chars,
                error_msg)
            end
        end
    end
    return schema_get(doc, '.', O.from_string, tostring)
end

local function export_did_document(doc)
    return deepmap(O.to_string, doc)
end

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
        did_document = { 
            import = import_did_document,
            export = export_did_document,
            schematype = 'open'
        },
        verificationMethod = {
            import = import_verification_method,
            export = export_verification_method
        }
    }
)

IfWhen("verify did document named ''", function(src)
    local document = have(src)
    if not zencode_assert(document.proof and document.proof.jws,
        'The object has no signature: ' .. src) then return end
    W3C.verify_jws_from_proof(src, document)
end)

IfWhen("verify did document named '' is signed by ''", function(src, signer_did_doc)
    local document = have(src)
    local signer_document = have(signer_did_doc)
    if not zencode_assert(document.proof and document.proof.jws,
        'The object has no signature: ' .. src) then return end
    if not zencode_assert(document.proof.verificationMethod,
        'The proof inside '..src..' has no verificationMethod') then return end
    local data = strtok(O.to_string(document.proof.verificationMethod), '#' )
    local signer_id = O.from_string(data[1])
    if not zencode_assert(signer_id == signer_document.id,
                'The signer id in proof is different from the one in '..signer_did_doc) then return end
    local i = 1
    local pk = nil
    repeat
        if signer_document.verificationMethod[i].id == document.proof.verificationMethod then
            pk = O.from_base58(
                O.to_string( signer_document.verificationMethod[i].publicKeyBase58 ))
        end
        i = i+1
    until( ( not signer_document.verificationMethod[i] ) or pk )
    if not zencode_assert(pk , data[2]..' used to sign '..src..' not found in the did document '..signer_did_doc) then return end
    W3C.verify_jws_from_proof(src, document, pk)
end)

-- operations on the did-document
When("create serviceEndpoint of ''", function(did_doc)
    local doc = have(did_doc)
    zencode_assert(doc.service, 'service not found')
    ACK.serviceEndpoint = {}
    for _, service in pairs(doc.service) do
        local name = strtok(O.to_string(service.id), '#')[2]
        ACK.serviceEndpoint[name] = service.serviceEndpoint
    end
    new_codec('serviceEndpoint', { encoding = 'string',
                                    zentype = 'd' })
end)

local function _import_pk_f(pk_name, pk_value, dest)
    local issuer_pk = 'issuer_public_key'
    local res = O.from_base58(O.to_string(pk_value))
    if string.sub(pk_name, 1, #issuer_pk) == issuer_pk then
        res = {
            alpha = ECP2.from_zcash(res:sub(1, 96)),
            beta = ECP2.from_zcash(res:sub(97, 192))
        }
    end
    dest[pk_name] = res
end

When("create verificationMethod of ''", function(did_doc)
    local doc = have(did_doc)
    zencode_assert(doc.verificationMethod, 'verificationMethod not found')
    empty 'verificationMethod'
    ACK.verificationMethod = {}
    for _, ver_method in pairs(doc.verificationMethod) do
        local pub_key_name = strtok(O.to_string(ver_method.id), '#')[2]
        if pub_key_name == ETHEREUM_ADDRESS then
            local address = strtok(
                O.to_string(ver_method.blockchainAccountId), ':' )[3]
            ACK.verificationMethod[pub_key_name] = O.from_hex(address)
        else
            _import_pk_f(pub_key_name, ver_method.publicKeyBase58, ACK.verificationMethod)
        end
    end
    new_codec('verificationMethod')
end)

When("create '' public key from did document ''", function(algo, did_doc)
    local doc = have (did_doc)
    local pk_name = algo..'_public_key'
    empty (pk_name)
    zencode_assert(doc.verificationMethod, 'verificationMethod not found in '..did_doc)
    local id = doc.id..O.from_string('#'..pk_name)
    local i = 1
    repeat
        if doc.verificationMethod[i].id == id then
            _import_pk_f(pk_name, doc.verificationMethod[i].publicKeyBase58, ACK)
        end
        i = i+1
    until( ( not doc.verificationMethod[i] ) or ACK[pk_name] )
    zencode_assert(ACK[pk_name], pk_name..' not found in the did document '..did_doc)
    CODEC[pk_name] = guess_conversion(ACK[pk_name], pk_name)
    CODEC[pk_name].name = pk_name
end)
