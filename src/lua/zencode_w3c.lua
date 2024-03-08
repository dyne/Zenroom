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

local function decode_jwt_parts(s)
    if type(s) == 'string' then
        return O.from_string(s)
    elseif type(s) == 'number' then
        if s==math.floor(s) and s >= 1500000000 and s < 2000000000 then
            return U.new(s)
        else
            return FLOAT.new(s)
        end
    else
        return s
    end
end

local function import_jwt(obj)
    local res = {}
    local toks = strtok(obj, '.')
    res.header = JSON.decode(schema_get(toks[1], '.', O.from_url64, tostring):string())
    res.header = deepmap(decode_jwt_parts, res.header)
    res.payload = JSON.decode(schema_get(toks[2], '.', O.from_url64, tostring):string())
    res.payload = deepmap(decode_jwt_parts, res.payload)
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

--[[
--    Json Web Key
--]]

-- create a jwk encoded key starting from the realtive sk/pk
-- @param alg alg in jwk
-- @param sk_falg sk flag, if true the alg sk will be inserted in the jwk
-- @param pk a specific public key to be used
-- @return jwk as a string dictionary (need to be transformed in octet before store in ACK)
local function _create_string_jwk(alg, sk_flag, pk)
    if sk_flag and pk then error('JWK can not be created with zenroom sk and custom pk', 2) end
    if alg ~= 'ES256K' and alg ~= 'ES256' then error(alg.. ' not yet supported by zenroom jwk', 2) end
    local alg_to_pk = {['ES256K']= 'ecdh_public_key', ['ES256']= 'es256_public_key'}
    local jwk = {}
    jwk.kty = 'EC'
    jwk.crv = fif(alg == 'ES256K', 'secp256k1', 'P-256')
    local pub
    -- explicit pk
    if pk then
        local pub_codec
        pub, pub_codec = have(pk)
        if alg_to_pk[alg] ~= pub_codec.schema then
            error('The '..alg..' algorithm does not match the public key schema '..pub_codec.schema, 2)
        end
    else
        local sk, pub_f
        if alg == 'ES256K' then
            sk = ACK.keyring and ACK.keyring.ecdh
            pub_f = ECDH.pubgen
        else
            local ES256 = require_once 'es256'
            sk = ACK.keyring and ACK.keyring.es256
            pub_f = ES256.pubgen
        end
        -- sk found
        if sk then
            if sk_flag then jwk.d = O.to_url64(sk) end
            pub = pub_f(sk)
        -- sk not found search for default public key
        else
            if sk_flag then error('Private key for '..alg..' algorithm not found in the keyring', 2) end
            local pub_codec
            pub, pub_codec = have(alg_to_pk[alg])
            if alg_to_pk[alg] ~= pub_codec.schema then
                error('The '..alg..' algorithm does not match the public key schema '..pub_codec.schema, 2)
            end
        end
    end
    local x, y = O.chop(pub, 32)
    jwk.x = O.to_url64(x)
    jwk.y = O.to_url64(y)
    return jwk
end

local function _create_jwk(alg, sk_flag, pk)
    empty 'jwk'
    ACK.jwk = deepmap(O.from_string, _create_string_jwk(alg, sk_flag, pk))
    new_codec('jwk', { zentype = 'd',
                       encoding = 'string' })
end

When("create jwk of p256 public key", function() _create_jwk('ES256') end)
When("create jwk of es256 public key", function() _create_jwk('ES256') end)
When("create jwk of secp256r1 public key", function() _create_jwk('ES256') end)
When("create jwk of p256 public key with private key", function() _create_jwk('ES256', true) end)
When("create jwk of es256 public key with private key", function() _create_jwk('ES256', true) end)
When("create jwk of secp256r1 public key with private key", function() _create_jwk('ES256', true) end)
When("create jwk of p256 public key ''", function(pk) _create_jwk('ES256', false, pk) end)
When("create jwk of es256 public key ''", function(pk) _create_jwk('ES256', false, pk) end)
When("create jwk of secp256r1 public key ''", function(pk) _create_jwk('ES256', false, pk) end)

When("create jwk of ecdh public key", function() _create_jwk('ES256K') end)
When("create jwk of es256k public key", function() _create_jwk('ES256K') end)
When("create jwk of secp256k1 public key", function() _create_jwk('ES256K') end)
When("create jwk of ecdh public key with private key", function() _create_jwk('ES256K', true) end)
When("create jwk of es256k public key with private key", function() _create_jwk('ES256K', true) end)
When("create jwk of secp256k1 public key with private key", function() _create_jwk('ES256K', true) end)
When("create jwk of ecdh public key ''", function(pk) _create_jwk('ES256K', false, pk) end)
When("create jwk of es256k public key ''", function(pk) _create_jwk('ES256K', false, pk) end)
When("create jwk of secp256k1 public key ''", function(pk) _create_jwk('ES256K', false, pk) end)

--[[
--    Json Web Signature
--]]

-- parse JWS string
-- @param o_jws the jws as octet (from string)
-- @param o_payload the payload as octet, to verify detached signature
-- @return signature (table {r,s} in case of ecdsa on secp256k1)
-- @return verifification function to verify the signature based on the algorithm present in the header
-- @return public key, tsake the one in the header (if present) or the correct key in zenroom memory
-- @return header.payload, if payload is differenet from the empty string
local function jws_octet_to_signature(o_jws, o_payload)
    local toks = strtok(OCTET.to_string(o_jws), '.')
    -- parse header
    local pk
    local header = JSON.decode( OCTET.from_url64(toks[1]):string())
    local alg = header.alg
    if not alg then error('JWS header is missing alg specification', 2) end
    if header.jwk then
        -- kty MUST be present
        if header.jwk.kty ~= 'EC' then
            error('JWS public key type supported by zenroom is only EC', 2)
        end
        -- if kty == EC, crv MUST be present
        local alg_table = {['P-256'] = 'ES256', ['secp256k1'] = 'ES256K'}
        local alg_from_crv = alg_table[header.jwk.crv]
        if not alg_from_crv then
            error('JWS public key curve supported by zenroom are only P-256 or secp256k1, found: '..header.jwk.crv, 2)
        elseif alg ~= alg_from_crv then
            error('JWS public key curve '..header.jwk.crv..' does not match the alg '..alg, 2)
        end
        pk = O.from_url64(header.jwk.x) .. O.from_url64(header.jwk.y)
    end
    -- header.payload is what should be signed
    if not o_payload and toks[2] == "" then
        error('No payload provided during jws verification', 2)
    end
    if o_payload and toks[2] ~= "" then
        if toks[2] ~= O.to_string(o_payload) then
            error('JWS payload does not match the payload in input', 2)
        end
    end
    local signed = O.from_string(toks[1]..'.')..(o_payload or O.from_string(toks[2]))
    -- signature
    local signature, verify_f
    if alg == 'ES256K' then
        signature = {}
        signature.r, signature.s = OCTET.chop(OCTET.from_url64(toks[3]), 32)
        verify_f = ECDH.verify
        pk = pk or ACK.ecdh_public_key
    elseif alg == 'ES256' then
        local ES256 = require_once 'es256'
        signature = OCTET.from_url64(toks[3])
        verify_f = ES256.verify
        pk = pk or ACK.es256_public_key
    else
        error(alg .. ' algorithm not yet supported by zenroom jws verification', 2)
    end
    return signature, verify_f, pk, signed
end

-- generate a JWS signature
-- @param s the signature, if not present payload can not be empty string
-- @param h the header (optional), default is ecdsa on secp256k1
-- @param p the payload (optional), default is empty string
-- @param d the detached falg, if set to true and payload is present, remove payload from jws
-- @return octet string containing the jws
local function jws_signature_to_octet(s, h, p, d)
    local header = h or
        O.from_string(JSON.encode(
                          {
                              alg = 'ES256K',
                              b64 = true,
                              crit = {'b64'}
                          }
        ))
    local payload = (p and O.to_url64(p)) or ""
    local signature = s
    if not signature then
        local header_json = JSON.decode(header:string())
        if not header_json.alg then
            error('Algorithm not specified in jws header', 2)
        end
        if not payload or payload == "" then
            error('Can not create a jws signature without the payload', 2)
        end
        local to_be_signed = O.from_string(O.to_url64(header)..'.'..payload)
        if header_json.alg == 'ES256K' then
            local sk = havekey'ecdh'
            local signature_table = ECDH.sign(sk, to_be_signed)
            signature = signature_table.r .. signature_table.s
        elseif header_json.alg == 'ES256' then
            local ES256 = require_once 'es256'
            local sk = havekey'es256'
            signature = ES256.sign(sk, to_be_signed)
        else
            error(header_json.alg .. ' algorithm not yet supported by zenroom jws signature', 2)
        end
    end
    payload = (d and "") or payload
    if luatype(signature) == 'table' then
        if not(s.r and s.s) then
            error('The signature table does not contains r and s', 2)
        end
        signature = s.r .. s.s
    end
    return (OCTET.to_url64(header) ..
            '.' .. payload ..
            '.' .. OCTET.to_url64(signature))
end

-- utlity to encode a JSON as octet string based on its original encoding
-- if octet are passed as input it will check that the original string was
-- a json or a json encoded in url64
-- @param src the json to encode
-- @return octet string containg the encoded json
local function _json_encoding(src)
    local source, codec = have(src)
    local source_str = source
    if luatype(source) == 'table' then
        local encoding = codec.schema or codec.encoding
		   or CODEC.output.encoding.name
        source_str = O.from_string( JSON.encode(source, encoding) )
    else
        -- check that before encoding it was a table
        -- this should ensure that we are signing only json
        local input = get_encoding_function(codec.encoding)(source)
        if O.is_url64(input) then
            input = O.from_url64(input):string()
        end
        if not JSON.validate(input) then
            error(src..' is not a json or an encoded json', 2)
        end
    end
    return source_str
end

When(deprecated("create jws signature of ''",
                "create jws detached signature with header '' and payload ''",
                function(src)
                    warn('raw signature of the payload, non standard jws')
                    local source_str = _json_encoding(src)
                    empty'jws'
                    local sk = havekey'ecdh' -- assuming secp256k1
                    ACK.jws = O.from_string(
                        jws_signature_to_octet(ECDH.sign(sk, source_str)) )
                    new_codec('jws', { zentype = 'e',
                                       encoding = 'string' })
               end)
)

When(deprecated("create jws signature using ecdh signature in ''",
                "create jws detached signature with header '' and payload ''",
                function(sign)
                    warn('external signature can be not jws compliant')
                    local signature = have(sign)
                    empty'jws'
                    ACK.jws = O.from_string(jws_signature_to_octet(signature))
                    new_codec('jws', { zentype = 'e',
                                       encoding = 'string' })
end))

-- return a header for jws
-- @param alg alg in jws header
-- @param pk pk flag, is true the alg pk is set in the header in jwk format
local function _create_jws_header(alg, pk)
    local header = {['alg'] = alg}
    if pk then
        header.jwk = _create_string_jwk(alg)
    end
    ACK.jws_header = deepmap(O.from_string, header)
    new_codec('jws_header', { zentype = 'd',
                              encoding = 'string' })
end

When("create jws header for p256 signature", function() _create_jws_header('ES256') end)
When("create jws header for es256 signature", function() _create_jws_header('ES256') end)
When("create jws header for secp256r1 signature", function() _create_jws_header('ES256') end)
When("create jws header for p256 signature with public key", function() _create_jws_header('ES256', true) end)
When("create jws header for es256 signature with public key", function() _create_jws_header('ES256', true) end)
When("create jws header for secp256r1 signature with public key", function() _create_jws_header('ES256', true) end)

When("create jws header for ecdh signature", function() _create_jws_header('ES256K') end)
When("create jws header for es256k signature", function() _create_jws_header('ES256K') end)
When("create jws header for secp256k1 signature", function() _create_jws_header('ES256K') end)
When("create jws header for ecdh signature with public key", function() _create_jws_header('ES256K', true) end)
When("create jws header for es256k signature with public key", function() _create_jws_header('ES256K', true) end)
When("create jws header for secp256k1 signature with public key", function() _create_jws_header('ES256K', true) end)

local function _create_jws(header, payload, detached)
    local n_output = (detached and 'jws_detached_signature') or 'jws_signature'
    local o_header = _json_encoding(header)
    local o_payload = _json_encoding(payload)
    empty(n_output)
    ACK[n_output] = O.from_string(
        jws_signature_to_octet(nil, o_header, o_payload, detached)
    )
    new_codec(n_output, { zentype = 'e',
                          encoding = 'string' })
end

When("create jws signature of header '' and payload ''", function(header, payload)
    _create_jws(header, payload, false)
end)

-- jws result will be without pyaload, signature is always perform on header.payload
When("create jws detached signature of header '' and payload ''", function(header, payload)
    _create_jws(header, payload, true)
end)

local function _verify_jws(payload, jws)
    local n_jws = jws or 'jws'
    local o_jws = have(n_jws)
    local o_payload = payload and _json_encoding(payload)
    local enc_payload
    if o_payload then
        local c_payload = CODEC[payload].encoding
        if c_payload == 'url64' or luatype(ACK[payload]) == 'table' then
            enc_payload = O.from_string(O.to_url64(o_payload)) 
        elseif c_payload == 'string' then
            enc_payload = o_payload
        else
            error('encoding for payload not accpeted: '..c_payload, 2)
        end
    end
    local signature, verify_f, pub, signed = jws_octet_to_signature(o_jws, enc_payload)
    if not pub then
        error('Public key to verify the jws signature not found', 2)
    end
    if not verify_f(pub, signed, signature) then
        -- retro compatibility, but non jws compliant signature
        if o_payload and verify_f(pub, o_payload, signature) then
            warn('Raw signature of the payload verified, but is non standard jws')
        else
            error('The signature does not validate: ' .. n_jws, 2)
        end
    end
end

IfWhen(deprecated("verify jws signature of ''",
                  "verify '' has a jws signature in ''",
                  _verify_jws
))

IfWhen("verify '' has a jws signature in ''", _verify_jws)

IfWhen("verify jws signature in ''", function(jws) _verify_jws(nil, jws) end)

--[[
--    Verifiable Cerdential
--]]

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
    local cred_str = _json_encoding(vc)
    proof.jws =
        jws_signature_to_octet(
            ECDH.sign(sk, cred_str)
    )
    ACK[vc].proof = deepmap(OCTET.from_string, proof)
end)

local function _verify_jws_from_proof(src, document, public_key)
    -- omit proof subtable from verification
    local proof = document.proof
    document.proof = nil
    local document_str = _json_encoding(src)
    local document_enc = O.from_string(O.to_url64(document_str))
    document.proof = proof

    local signature, verify_f, pub, signed = jws_octet_to_signature(document.proof.jws, document_enc)

    local pk = public_key or pub
    if not verify_f(pk, signed, signature) then
        -- retro compatibility, but non jws compliant signature
        if verify_f(pk, document_str, signature) then
            warn('Raw signature of the payload verified, but is non standard jws')
        else
            error('The signature does not validate: ' .. src, 2)
        end
    end
end

IfWhen("verify verifiable credential named ''", function(src)
    local document = have(src)
    zencode_assert(document.proof and document.proof.jws,
                'The object has no signature: ' .. src)
    _verify_jws_from_proof(src, document)
end)

--[[
--    Did document
--]]

IfWhen("verify did document named ''", function(src)
    local document = have(src)
    zencode_assert(document.proof and document.proof.jws,
                'The object has no signature: ' .. src)
    _verify_jws_from_proof(src, document)
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
    _verify_jws_from_proof(src, document, pk)
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

--[[
--    Json Web Toekn
--]]

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

