--[[
--This file is part of zenroom
--
--Copyright (C) 2021 Dyne.org foundation
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
--Last modified by Denis Roio
--on Wednesday, 14th July 2021
--]]
local ETHEREUM_ADDRESS = "ethereum_address"
local EDDSA_PUBLIC_KEY = "eddsa_public_key"

local function import_did_document(doc)
    -- id must be always present in DID-documents
    ZEN.assert(doc.id, 'Invalid DID document: id not found')
    -- all the other fields are optional and imported as a string
    return ZEN.get(doc, '.', O.from_string, tostring)
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
        res[key] = ZEN.get(doc[key], '.',
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

ZEN.add_schema(
    {
        did_document = { import = import_did_document,
                         export = export_did_document },
        verificationMethod = { import = import_verification_method,
                               export = export_verification_method },
        -- flexible verifiable credential
        -- only internal 'jws' member has peculiar encoding
        verifiable_credential = function(obj)
            ACK.verifiable_credential = {}
            new_codec('verifiable_credential', {
                name = 'verifiable_credential',
                encoding = 'string',
                zentype = 'schema',
                luatype = 'table'
            })
            return (deepmap(OCTET.from_string, obj))
        end
    }
)

-- return { r , s } table suitable for signature verification
local function jws_octet_to_signature(obj)
    local toks = strtok(OCTET.to_string(obj), '[^.]*')
    -- header parsing may be skipped
    -- local header = JSON.decode( OCTET.from_url64(toks[1]):to_string() )
    local res = {}
    res.r, res.s = OCTET.chop(OCTET.from_url64(toks[3]), 32)
    return (res)
end

-- return octet string suitable for JWS encapsulation
local function jws_signature_to_octet(obj, algo)
    local header =
        OCTET.from_string(
        JSON.encode(
            {
                alg = algo or 'ES256K', -- default secp256k1
                b64 = true,
                crit = 'b64'
            }
        )
    )
    return (OCTET.to_url64(header) ..
        '..' .. OCTET.to_url64(obj.r .. obj.s))
end

When(
    "set the verification method in '' to ''",
    function(vc, meth)
        local cred = have(vc)
        ZEN.assert(cred.proof, 'The object is not signed: ' .. vc)
        local m = have(meth)
        ACK[vc].proof.verificationMethod = m
    end
)

When(
    "get the verification method in ''",
    function(vc)
        empty 'verification_method'
        local cred = have(vc)
        ZEN.assert(cred.proof, 'The object is not signed: ' .. vc)
        ACK.verification_method = cred.proof.verificationMethod
        new_codec('verification_method', {
            schema="verificationMethod",
            name="verification_method",
            encoding="complex",
            zentype="schema"
        })
    end
)


When(
    "create the jws signature of ''", function(src)
        local source = have(src)
        empty'jws'
        local sk = havekey'ecdh' -- assuming secp256k1
        local source_str
        if luatype(source) == 'table' then
           source_str = O.from_string( JSON.encode(source) )
        else
           source_str = source
        end
        ACK.jws = O.from_string(
            jws_signature_to_octet(ECDH.sign(sk, source_str)) )
        new_codec('jws', { zentype = 'element',
                           encoding = 'string' })
    end
)

IfWhen(
    "verify the jws signature of ''",
    function(src)
        local jws = have'jws'
        local signed = have(src)
        if luatype(signed) == 'table' then
           signed = JSON.encode(signed)
        end
        local pub = have 'ecdh public key'
        local signature = jws_octet_to_signature(jws)
        -- omit the proof subtable from verification
        ZEN.assert(
            ECDH.verify(pub, signed, signature),
            'The signature does not validate: ' .. src
        )
    end
)

When(
    "sign the verifiable credential named ''",
    function(vc)
        local credential = have(vc)
        local sk = havekey'ecdh' -- assuming secp256k1
        ZEN.assert(not credential.proof,'The object is already signed: ' .. vc)
        local proof = {
            type = 'Zenroom v'.._G.ZENROOM_VERSION.original,
            -- "Signature", -- TODO: check what to write here for secp256k1
            -- created = "2018-06-18T21:19:10Z",
            proofPurpose = 'authenticate' -- assertionMethod", -- TODO: check
        }
        local cred_str
        if luatype(credential) == 'table' then
           cred_str = JSON.encode(credential)
        else
           cred_str = credential
        end
        proof.jws =
            jws_signature_to_octet(
              ECDH.sign(sk, OCTET.from_string(cred_str))
        )
        ACK[vc].proof = deepmap(OCTET.from_string, proof)
    end
)

local function _verification_f(doc)
    local document = have(doc)
    ZEN.assert(document.proof and document.proof.jws,
               'The object has no signature: ' .. doc)
    local signature = jws_octet_to_signature(document.proof.jws)
    local public_key = have 'ecdh public key'

    -- omit the proof subtable from verification
    local proof = document.proof
    document.proof = nil
    local signed = JSON.encode(document)
    document.proof = proof
    ZEN.assert(
        ECDH.verify(public_key, signed, signature),
        'The signature does not validate: ' .. doc
    )
end

IfWhen(
    "verify the verifiable credential named ''", _verification_f
)

IfWhen(
    "verify the did document named ''", _verification_f
)

-- operations on the did-document
When(
    "create the serviceEndpoint of ''",
    function(did_doc)
        local doc = have(did_doc)
        ZEN.assert(doc.service, 'service not found')
        ACK.serviceEndpoint = {}
        for _, service in pairs(doc.service) do
            local name = strtok(O.to_string(service.id), '[^#]*')[2]
            ACK.serviceEndpoint[name] = service.serviceEndpoint
        end
        new_codec('serviceEndpoint', { encoding = 'string',
                                       luatype = 'table',
                                       zentype = 'dictionary' })
    end
)

When(
    "create the verificationMethod of ''",
    function(did_doc)
        local doc = have(did_doc)
        ZEN.assert(doc.verificationMethod, 'verificationMethod not found')
        empty 'verificationMethod'
        ACK.verificationMethod = {}

        for _, ver_method in pairs(doc.verificationMethod) do
            local pub_key_name = strtok(O.to_string(ver_method.id), '[^#]*')[2]
            if pub_key_name == ETHEREUM_ADDRESS then
                local address = strtok(
                    O.to_string(ver_method.blockchainAccountId), '[^:]*' )[3]
                ACK.verificationMethod[pub_key_name] = O.from_hex(address)
            else
                local pub_key = O.to_string(ver_method.publicKeyBase58)
                ACK.verificationMethod[pub_key_name] = O.from_base58(pub_key)
            end
        end
        new_codec('verificationMethod', { zentype = 'schema',
                                          encoding = 'complex' })
    end
)
