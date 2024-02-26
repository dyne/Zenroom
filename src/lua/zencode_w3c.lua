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
   local t = luatype(doc)
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

local function import_jwt(obj)
    local res = {}
    local toks = strtok(obj, '.')
    res.header = JSON.decode(schema_get(toks[1], '.', O.from_url64, tostring):string())
    res.header = deepmap(function(s)
        if type(s) == 'string' then
            return O.from_string(s)
        elseif type(s) == 'number' then
            return F.new(s)
        else
            return s
        end
    end, res.header)
    res.payload = JSON.decode(schema_get(toks[2], '.', O.from_url64, tostring):string())
    res.payload = deepmap(function(s)
        if type(s) == 'string' then
            return O.from_string(s)
        elseif type(s) == 'number' then
            return F.new(s)
        else
            return s
        end
    end, res.payload)
    res.signature = schema_get(toks[3], '.', O.from_url64, tostring)
    return res
end

local function export_jwt(obj)
    local header = O.to_url64(O.from_string(JSON.encode(obj.header, 'string')))
    local payload = O.to_url64(O.from_string(JSON.encode(obj.payload, 'string')))
    return header .. '.' .. payload .. '.' .. obj.signature:url64()
end


ZEN:add_schema(
    {
        did_document = { import = import_did_document,
                         export = export_did_document,
 						 schematype = 'open' },
        verificationMethod = { import = import_verification_method,
                               export = export_verification_method },
        verification_method = { import = import_verification_method,
								export = export_verification_method },
        -- flexible verifiable credential
        -- only internal 'jws' member has peculiar encoding
        verifiable_credential = function(obj)
            ACK.verifiable_credential = {}
            new_codec('verifiable_credential', {
                encoding = 'string',
				schema = 'verifiable_credential',
                zentype = 'e'
            })
            return (deepmap(OCTET.from_string, obj))
        end,
        json_web_token = { import = import_jwt,
                           export = export_jwt },
    }
)

-- return { r , s } table suitable for signature verification
local function jws_octet_to_signature(obj)
    local toks = strtok(OCTET.to_string(obj), '.')
    -- parse header
    local header = JSON.decode( OCTET.from_url64(toks[1]):string())
    -- possibility to have puublic key in the header?
    zencode_assert(header.alg, 'JWS header is missing alg specification')
    -- TODO: if payload is present return and verify the signature from it
    local res, verify_f, pk
    if header.alg == 'ES256K' then
        res = {}
        res.r, res.s = OCTET.chop(OCTET.from_url64(toks[3]), 32)
        verify_f = ECDH.verify
        pk = ACK.ecdh_public_key
    elseif header.alg == 'ES256' then
        res = OCTET.from_url64(toks[3])
        verify_f = ES256.verify
        pk = ACK.es256_public_key
    else
        error(header.alg .. ' algorithm not yet supported by zenroom jws verification')
    end
    return res, verify_f, pk
end

-- return octet string suitable for JWS encapsulation
local function jws_signature_to_octet(s, h, p)
    local header
    if not h then
        header = O.from_string(
            JSON.encode(
                {
                    alg = algo or 'ES256K', -- default secp256k1
                    b64 = true,
                    crit = 'b64'
                }
            )
        )
    else
        header = h
    end
    local payload = ""
    if p then
        zencode_assert(type(p) == 'zenroom.octet', "The payload should be a string")
        payload = O.to_url64(p)
    end
    local signature = s
    if luatype(signature) == 'table' then
        zencode_assert(s.r and s.s, "The signature table does not contains r and s")
        signature = s.r .. s.s
    end
    return (OCTET.to_url64(header) ..
            '.' .. payload ..
            '.' .. OCTET.to_url64(signature))
end

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

local function _json_encoding(src)
    local source, codec = have(src)
    local source_str = source
    if luatype(source) == 'table' then
        local encoding = codec.schema or codec.encoding
		   or CODEC.output.encoding.name
        source_str = O.from_string( JSON.encode(source, encoding) )
    end
    return source_str
end

When("create jws signature of ''", function(src)
    local source_str = _json_encoding(src)
    empty'jws'
    local sk = havekey'ecdh' -- assuming secp256k1
    ACK.jws = O.from_string(
        jws_signature_to_octet(ECDH.sign(sk, source_str)) )
    new_codec('jws', { zentype = 'e',
                        encoding = 'string' })
end)

When("create jws signature using ecdh signature in ''", function(sign)
    local signature = have(sign)
    empty'jws'
    ACK.jws = O.from_string(jws_signature_to_octet(signature))
    new_codec('jws', { zentype = 'e',
                        encoding = 'string' })
end)

When("create jws signature with header '' payload '' and signature ''", function(header, payload, signature)
    local o_header = _json_encoding(header)
    local o_payload = have(payload)
    local o_signature = have(signature)
    empty 'jws'
    ACK.jws = O.from_string(
        jws_signature_to_octet(o_signature, o_header, o_payload)
    )
    new_codec('jws', { zentype = 'e',
                       encoding = 'string' })
end)

IfWhen("verify jws signature of ''", function(src)
    local jws = have'jws'
    local source_str = _json_encoding(src)
    local signature, verify_f, pub = jws_octet_to_signature(jws)
    zencode_assert(pub, "Public key to verify the jws signature not found")
    zencode_assert(
        verify_f(pub, source_str, signature),
        'The signature does not validate: ' .. src
    )
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
    local cred_str = _json_encoding(vc)
    proof.jws =
        jws_signature_to_octet(
            ECDH.sign(sk, cred_str)
    )
    ACK[vc].proof = deepmap(OCTET.from_string, proof)
end)

local function _verification_f(src, document, public_key)
    local signature, verify_f = jws_octet_to_signature(document.proof.jws)

    -- omit proof subtable from verification
    local proof = document.proof
    document.proof = nil
    local document_str = _json_encoding(src)
    document.proof = proof
    zencode_assert(
        verify_f(public_key, document_str, signature),
        'The signature does not validate: ' .. src
    )
end

IfWhen("verify verifiable credential named ''", function(src)
    local document = have(src)
    zencode_assert(document.proof and document.proof.jws,
                'The object has no signature: ' .. src)
    _verification_f(src, document, have('ecdh public key'))
end)

IfWhen("verify did document named ''", function(src)
    local document = have(src)
    zencode_assert(document.proof and document.proof.jws,
                'The object has no signature: ' .. src)
    _verification_f(src, document, have('ecdh public key'))
end)

IfWhen("verify did document named '' is signed by ''", function(src, signer_did_doc)
    local document = have(src)
    local signer_document = have(signer_did_doc)
    zencode_assert(document.proof and document.proof.jws,
                'The object has no signature: ' .. src)
    zencode_assert(document.proof.verificationMethod,
                'The proof inside '..src..' has no verificationMethod')
    local data = strtok(O.to_string(document.proof.verificationMethod), '#' )
    local signer_id = O.from_string(data[1])
    zencode_assert(signer_id == signer_document.id,
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
    zencode_assert(pk , data[2]..' used to sign '..src..' not found in the did document '..signer_did_doc)
    _verification_f(src, document, pk)
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

function create_jwt_hs256(payload, password)
    local header, b64header, b64payload, hmac
    header = {
        alg=O.from_string("HS256"),
        typ=O.from_string("JWT")
    }
    b64header = O.from_string(JSON.encode(header, 'string')):url64()
    b64payload = O.from_string(JSON.encode(payload, 'string')):url64()
    hash = HASH.new("sha256")

    local signature = hash:hmac(
        password,
        b64header .. '.' .. b64payload)
    return {
        header=header,
        payload=payload,
        signature=signature,
    }
end

When("create json web token of '' using ''", function(payload_name, password_name)
    local payload = have(payload_name)
    local password = mayhave(password_name) or password_name
    empty'json_web_token'
    ACK.json_web_token = create_jwt_hs256(payload, password)
    new_codec("json_web_token")
end)

IfWhen("verify json web token in '' using ''", function(hmac_name, password_name)
    local hmac = have(hmac_name)
    local password = mayhave(password_name) or password_name
    local jwt_hs256 = create_jwt_hs256(hmac.payload, password)
    zencode_assert(jwt_hs256.signature == hmac.signature, "Could not re-create HMAC")
end)

