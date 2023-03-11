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
    -- id and @context must be always present in DID-documents
    ZEN.assert(doc.id and #doc.id < 256, 'Invalid DID document: id not found')
    ZEN.assert(doc['@context'], 'Invalid DID document: @context not found')
    ZEN.assert(#JSON.encode(doc, 'string') < 4096, 'DID document too large')
    local did_components = strtok(doc.id, ':')
    -- schme: did
    ZEN.assert(did_components[1] == 'did',
	       'Invalid DID document: invalid scheme')
    -- method name: a-z/0-9
    ZEN.assert(not did_components[2]:match('[^%l%d]'),
	       'Invalid DID document: invalid method-name')
    -- mathod specific identifier: a-z/A-Z/0-9/"."/"-"/"_"/"%" HEXDIG HEXDIG
    local error_msg = 'Invalid DID document: invalid method specific identifier'
    for i=3,#did_components do
	first = true
	for chars in did_components[i]:gmatch('[^%%]*') do
	    if first then
		ZEN.assert(not chars:match('[^%w%.%-%_]'),
			   error_msg)
		first = nil
	    else
		-- checks %%
		ZEN.assert(chars, error_msg)
		-- checks %hexhex...
		ZEN.assert(chars:match('%x%x[%w%.%-%_]*') == chars,
			   error_msg)
	    end
	end
    end
    return ZEN.get(doc, '.', O.from_string, tostring)
end

local function export_did_document(doc)
   local t = luatype(doc)
   if t == 'table' then
	  return deepmap(O.to_string, doc)
   else
	  return O.to_string(doc)
   end
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
    local toks = strtok(OCTET.to_string(obj), '.')
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

local function _json_encoding(src)
    local source, codec = have(src)
    local source_str = source
    if luatype(source) == 'table' then
        local encoding = fif( codec.encoding == 'complex',
                              codec.schema or src, codec.encoding)
        source_str = O.from_string( JSON.encode(source, encoding) )
    end
    return source_str
end

When(
    "create the jws signature of ''", function(src)
        local source_str = _json_encoding(src)
        empty'jws'
        local sk = havekey'ecdh' -- assuming secp256k1
        ACK.jws = O.from_string(
            jws_signature_to_octet(ECDH.sign(sk, source_str)) )
        new_codec('jws', { zentype = 'element',
                           encoding = 'string' })
    end
)

When(
    "create the jws signature using the ecdh signature in ''", function(sign)
        local signature = have(sign)
        empty'jws'
        ACK.jws = O.from_string(jws_signature_to_octet(signature))
        new_codec('jws', { zentype = 'element',
                           encoding = 'string' })
    end
)

IfWhen(
    "verify the jws signature of ''",
    function(src)
        local jws = have'jws'
        local pub = have 'ecdh public key'
        local source_str = _json_encoding(src)
        local signature = jws_octet_to_signature(jws)
        ZEN.assert(
            ECDH.verify(pub, source_str, signature),
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
        local cred_str = _json_encoding(vc)
        proof.jws =
            jws_signature_to_octet(
              ECDH.sign(sk, cred_str)
        )
        ACK[vc].proof = deepmap(OCTET.from_string, proof)
    end
)

local function _verification_f(src, document, public_key)
    local signature = jws_octet_to_signature(document.proof.jws)

    -- omit the proof subtable from verification
    local proof = document.proof
    document.proof = nil
    local document_str = _json_encoding(src)
    document.proof = proof
    ZEN.assert(
        ECDH.verify(public_key, document_str, signature),
        'The signature does not validate: ' .. src
    )
end

IfWhen(
    "verify the verifiable credential named ''",
    function(src)
        local document = have(src)
        ZEN.assert(document.proof and document.proof.jws,
                    'The object has no signature: ' .. src)
        _verification_f(src, document, have('ecdh public key'))
    end
)

IfWhen(
    "verify the did document named ''",
    function(src)
        local document = have(src)
        ZEN.assert(document.proof and document.proof.jws,
                    'The object has no signature: ' .. src)
        _verification_f(src, document, have('ecdh public key'))
    end
)

IfWhen(
    "verify the did document named '' is signed by ''",
    function(src, signer_did_doc)
        local document = have(src)
        local signer_document = have(signer_did_doc)
        ZEN.assert(document.proof and document.proof.jws,
                    'The object has no signature: ' .. src)
        ZEN.assert(document.proof.verificationMethod,
                    'The proof inside '..src..' has no verificationMethod')
        local data = strtok(O.to_string(document.proof.verificationMethod), '#' )
        local signer_id = O.from_string(data[1])
        ZEN.assert(signer_id == signer_document.id,
                    'The signer id in proof is different from the one in '..signer_did_doc)
        local i = 1
        local pk = nil
        repeat
            if signer_document.verificationMethod[i].id == document.proof.verificationMethod then
                pk = O.from_base58(
                    O.to_string( signer_document.verificationMethod[i].publicKeyBase58 ))
            end
            i = i+1
        until( ( not signer_document.verificationMethod[i] ) or pk )
        ZEN.assert(pk , data[2]..' used to sign '..src..' not found in the did document '..signer_did_doc)
        _verification_f(src, document, pk)
    end
)
-- operations on the did-document
When(
    "create the serviceEndpoint of ''",
    function(did_doc)
        local doc = have(did_doc)
        ZEN.assert(doc.service, 'service not found')
        ACK.serviceEndpoint = {}
        for _, service in pairs(doc.service) do
            local name = strtok(O.to_string(service.id), '#')[2]
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
            local pub_key_name = strtok(O.to_string(ver_method.id), '#')[2]
            if pub_key_name == ETHEREUM_ADDRESS then
                local address = strtok(
                    O.to_string(ver_method.blockchainAccountId), ':' )[3]
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

When(
    "create the '' public key from did document ''",
    function(algo, did_doc)
        local doc = have (did_doc)
        local pk_name = algo..'_public_key'
        empty (pk_name)
        ZEN.assert(doc.verificationMethod, 'verificationMethod not found in '..did_doc)
        local id = doc.id..O.from_string('#'..pk_name)
        local i = 1
        repeat
            if doc.verificationMethod[i].id == id then
                ACK[pk_name] = O.from_base58(O.to_string((doc.verificationMethod[i].publicKeyBase58)))
            end
            i = i+1
        until( ( not doc.verificationMethod[i] ) or ACK[pk_name] )
        ZEN.assert(ACK[pk_name], pk_name..' not found in the did document '..did_doc)
        ZEN.CODEC[pk_name] = guess_conversion(ACK[pk_name], pk_name)
        ZEN.CODEC[pk_name].name = pk_name
    end
)
