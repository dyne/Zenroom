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

local W3C = {}

local function require_once_fun(scenario, fun_name)
    local S = require_once(scenario)
    local f = S[fun_name]
    if not f then error("Method "..fun_name.." not found in "..scenario, 2) end
    return f
end

-- utlity to encode a JSON as octet string based on its original encoding
-- if octet are passed as input it will check that the original string was
-- a json or a json encoded in url64
-- @param src the json to encode
-- @return octet string containg the encoded json
function W3C.json_encoding(src)
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

-- parse JWS string
-- @param o_jws the jws as octet (from string)
-- @param o_payload the payload as octet, to verify detached signature
-- @return signature (table {r,s} in case of ecdsa on secp256k1)
-- @return verifification function to verify the signature based on the algorithm present in the header
-- @return public key, tsake the one in the header (if present) or the correct key in zenroom memory
-- @return header.payload, if payload is differenet from the empty string
function W3C.jws_octet_to_signature(o_jws, o_payload)
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
        if header.jwk.x and header.jwk.y then
            pk = O.from_url64(header.jwk.x) .. O.from_url64(header.jwk.y)
        end
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
        verify_f = require_once_fun('ecdh', 'verify')
        pk = pk or ACK.ecdh_public_key
    elseif alg == 'ES256' then
        signature = OCTET.from_url64(toks[3])
        verify_f = require_once_fun('es256', 'verify')
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
function W3C.jws_signature_to_octet(s, h, p, d)
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
            local signature_table = require_once_fun('ecdh', 'sign')(sk, to_be_signed)
            signature = signature_table.r .. signature_table.s
        elseif header_json.alg == 'ES256' then
            local sk = havekey'es256'
            signature = require_once_fun('es256', 'sign')(sk, to_be_signed)
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


-- Verify a jws signature from a document proof
-- @param src the name of the object containing the document
-- @param document the document to be verified
-- @param public_key the public key to be used for verification, if not present the public key in the header will be used
function W3C.verify_jws_from_proof(src, document, public_key)
    -- omit proof subtable from verification
    local proof = document.proof
    document.proof = nil
    local document_str = W3C.json_encoding(src)
    local document_enc = O.from_string(O.to_url64(document_str))
    document.proof = proof

    local signature, verify_f, pub, signed = W3C.jws_octet_to_signature(document.proof.jws, document_enc)

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

-- create a jwk encoded key starting from the realtive sk/pk
-- @param alg alg in jwk
-- @param sk_falg sk flag, if true the alg sk will be inserted in the jwk
-- @param pk a specific public key to be used
-- @return jwk as a string dictionary (need to be transformed in octet before store in ACK)
function W3C.create_string_jwk(alg, sk_flag, pk)
    if sk_flag and pk then error('JWK can not be created with zenroom sk and custom pk', 2) end
    if alg ~= 'ES256K' and alg ~= 'ES256' then error(alg.. ' not yet supported by zenroom jwk', 2) end
    local alg_to_pk = {['ES256K']= 'ecdh_public_key', ['ES256']= 'es256_public_key'}
    local jwk = {}
    jwk.kty = 'EC'
    jwk.crv = fif(alg == 'ES256K', 'secp256k1', 'P-256')
    local pub_xy_f
    if alg == 'ES256K' then
        pub_xy_f = require_once_fun('ecdh', 'public_xy')
    else
        pub_xy_f = require_once_fun('es256', 'public_xy')
    end
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
            pub_f = require_once_fun('ecdh', 'pubgen')
        else
            sk = ACK.keyring and ACK.keyring.es256
            pub_f = require_once_fun('es256', 'pubgen')
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
    local x, y = pub_xy_f(pub)
    jwk.x = O.to_url64(x)
    jwk.y = O.to_url64(y)
    return jwk
end

return W3C
