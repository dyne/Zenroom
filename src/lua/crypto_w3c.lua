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

-- generate a serialized url64(JSON) encoded  octet string of any object
-- @param any the object to serialize
-- @return octet which should be printed as string
function W3C.serialize(any)
    if luatype(any) == 'table' then
        return (
            O.from_string
            (O.to_url64
             (O.from_string
              (JSON.encode
               (deepmap
                (function(o)
                        local t <const> = type(o)
                        if t == 'boolean' then
                            return(o)
                        elseif iszen(t) then
                            return O.to_string(o:octet())
                        else
                            return(tostring(o))
                        end
                end,any))
              )
             )
            )
        )
    else
        if not iszen(type(any)) then
            error("W3C serialize called with wrong argument type: "
                  ..type(any),2)
        end
        if #any == 0 then return O.from_string('') end
        return O.from_string(O.to_url64(any:octet()))
    end
end

-- generate a de-serialized object from
-- any serialized octet
-- @param jws the object to serialize
-- @return object which can be also a table
function W3C.deserialize(any)
    if not iszen(type(any)) then
        error("W3C deserialize called with wrong argument type: "
              ..type(any),2)
    end
    local u <const> = O.from_url64(O.to_string(any))
    local s <const> = O.to_string(u)
    if JSON.validate(s) then
        return JSON.decode(s)
    else
        return(u)
    end
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
-- @param d the detached flag, if set to true and payload is present, remove payload from jws
-- @return octet string containing the jws
function W3C.create_jws(s, h, p, d)
    if h and luatype(h) ~= 'table' then
        error('W3C create JWS wrong argument type for header: '
              ..type(h),2)
    end
    local function _headers_from_octets(ho)
        local t <const> = type(ho)
        if iszen(t) then
            return ho:octet():to_string()
        end
        if t == 'bool' then return ho end
        return tostring(t)
    end
    local header = { -- default
        alg = 'ES256K',
        b64 = true,
        crit = {'b64'}
    }
    if h then header = deepmap(_headers_from_octets,h) end
    local dot <const> = O.from_string('.')
    local payload = p -- may be changed by detached flag
    local signature = s
    if not signature then
        if not payload then
            error('Can not create a jws signature without the payload', 2)
        end
        if not header.alg then
            error('Algorithm not specified in jws header', 2)
        end
        local to_be_signed <const> =
            W3C.serialize(header)
            ..
            O.from_string('.')
            ..
            W3C.serialize(payload)
        local crypto <const> =
            W3C.resolve_crypto_algo(O.to_string(header.alg))
        local sk <const> = havekey(crypto.keyname)
        signature = crypto.sign(sk, to_be_signed)

    end
    payload = (d and O.from_string('')) or payload
    if luatype(signature) == 'table' then
        if not(signature.r and signature.s) then
            error('The signature table does not contains r and s', 2)
        end
        signature = signature.r .. signature.s
    end
    return (W3C.serialize(header)
            ..dot..
            W3C.serialize(payload)
            ..dot..
            W3C.serialize(signature))
end

-- Parse a JWS string and return a structure with header, payload and
-- signature in a dictionary:
-- { header, header_enc, payload, payload_enc, signature, signature_enc }
function W3C.parse_jws(jws_enc)
    local tjws    <const> = strtok(O.to_string(jws_enc), '.')
    if tjws[1] == '' then error("The JWS has no header", 2) end
    if not JSON.validate(O.from_url64(tjws[1]):string()) then
        error("The JWS header is not a valid JSON",2) end
    if tjws[3] == '' then error("The JWS has no signature", 2) end
    local ho <const> = O.from_string(tjws[1])
    local res = {
        header_enc = ho,
        header = W3C.deserialize(ho)
    }
    if luatype(res.header) ~= 'table' then
        error('The JWS header is not a dictionary', 2) end
    if tjws[2] ~= '' then
        local po <const> = O.from_string(tjws[2])
        res.payload_enc = po
        res.payload = W3C.deserialize(po)
    end
    local so <const> = O.from_string(tjws[3])
    res.signature_enc = so
    res.signature = W3C.deserialize(so)
    return res
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


-- require and return crypto class according to:
-- https://www.iana.org/assignments/jose/jose.xhtml
-- use procedural branching to instantiate only when needed
function W3C.resolve_crypto_algo(algo)
    if type(algo) ~= 'string' then
        error('W3C resolve crypto algo called with wrong argument type: '
        ..type(algo),2)
    end
    local alg <const> = algo:upper()
    if alg == 'ES256' then
        -- ECDSA using P-256 and SHA-256 [RFC7518, Section 3.4]
        return({ name = 'ES256',
                 sign = ES256.sign,
                 verify = ES256.verify,
                 pubgen = ES256.pubgen,
                 public_xy = ES256.public_xy,
                 keyname = 'es256'
        })
    elseif alg == 'EDDSA' then
        -- EdDSA signature algorithms [RFC8037, Section 3.1]
        return({name = 'EDDSA',
                sign = ED.sign,
                verify = ED.verify,
                pubgen = ED.pubgen,
                keyname = 'eddsa'
        })
    elseif alg == 'ML-DSA-44' or alg == 'MLDSA44' then
        return({name = 'ML-DSA-44',
                sign = PQ.mldsa44_signature,
                verify = PQ.mldsa44_verify,
                pubgen = PQ.mldsa44_pubgen,
                keyname = 'mldsa44'
        })
    elseif alg == 'ES256K' or alg == 'ECDH' then
        -- ECDSA using secp256k1 curve and SHA-256 [RFC8812, Section 3.2]
        return({name = 'ES256K',
                sign = ECDH.sign,
                verify = ECDH.verify,
                pubgen = ECDH.pubgen,
                public_xy = ECDH.public_xy,
                keyname = 'ecdh'
        })
    end
    error("Unsupported JOSE crypto algorithm: "..alg,2)
end

-- take a IANA registered string about the crypto algo and return the
-- secret key if found in keyring using havekey
function W3C.resolve_secret_key(algo)
    local alg <const> = algo:lower()
    if alg == 'es256' then return(havekey(alg)) end
    if alg == 'eddsa' then return(havekey(alg)) end
    if alg == 'ml-dsa-44' or alg == 'mldsa44'
    then return(havekey'mldsa44') end
    if alg == 'es256k' or alg == 'ecdh' or alg == 'secp256k1'
    then return(havekey'ecdh') end
    error("Unsupported secret key: "..alg,2)
end

-- create a jwk encoded key starting from the realtive sk/pk
-- @param alg alg in jwk
-- @param sk_flag sk flag, if true the alg sk will be inserted in the jwk
-- @param pk a specific public key to be used
-- @return jwk
function W3C.create_jwk(alg, sk_flag, pk)
    if sk_flag and pk then
        error('JWK can not be created with zenroom sk and custom pk', 2)
    end
    local crypto <const> = W3C.resolve_crypto_algo(alg)
    local jwk = { alg = O.from_string(crypto.name) }
    local sk
    if sk_flag then
        sk = W3C.resolve_secret_key(alg)
    end
    local pub = pk or mayhave'es256 public key'
    if not pub and crypto.pubgen then
        if not sk then
            sk = W3C.resolve_secret_key(alg)
        end
        pub = crypto.pubgen(sk)
    end
    if crypto.name == 'ES256' then
        jwk.kty = O.from_string'EC'
        jwk.crv = O.from_string'P-256'
        if pub then
            jwk.x, jwk.y = crypto.public_xy(pub)
        end
        if sk_flag then
            jwk.d = sk
        end
        return jwk
    end
    if crypto.name == 'EDDSA' then
        jwk.kty = O.from_string'EC'
        jwk.crv = O.from_string'P-256'
        if pub then
            jwk.x = pub
        end
        if sk_flag then
            jwk.d = sk
        end
        return jwk
    end
    if crypto.name == 'ES256K' then
        jwk.kty = O.from_string'EC'
        jwk.crv = O.from_string'secp256k1'
        if pub then
            jwk.x, jwk.y = crypto.public_xy(pub)
        end
        if sk_flag then
            jwk.d = sk
        end
        return jwk
    end
    if crypto.name == 'ML-DSA-44' then
        if pub then
            jwk.x = pub
        end
        if sk_flag then
            jwk.d = sk
        end
        return jwk
    end
    error('Unsupported JWK crypto algorithm: '..alg,2)
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

function W3C.import_jwt(obj)
    local function decode_jwt_parts(s)
        if type(s) == 'string' then
            return O.from_string(s)
        elseif type(s) == 'number' then
            return fif(TIME.detect_time_value(s), TIME.new, FLOAT.new)(s)
        else
            return s
        end
    end
    local function import_jwt_dict(d)
        return JSON.decode(
            schema_get(
                trim(d),
                '.', O.from_url64, tostring):string())
        -- return deepmap(input_encoding("str").fun,
        --                JSON.raw_decode(O.from_url64(trim(d)):str()))
    end
    local toks = strtok(obj, ".")
    -- TODO: verify this is a valid jwt
    return {
        header = deepmap(decode_jwt_parts,import_jwt_dict(toks[1])),
        payload = deepmap(decode_jwt_parts,import_jwt_dict(toks[2])),
        signature = O.from_url64(toks[3]),
    }
end

function W3C.export_jwt(obj)
    local header = O.to_url64(O.from_string(JSON.encode(obj.header, 'string')))
    local payload = O.to_url64(O.from_string(JSON.encode(obj.payload, 'string')))
    return header .. '.' .. payload .. '.' .. obj.signature:url64()
end
--     local encstr <const> = get_encoding_function("string")
--     return table.concat({
--         O.from_string
--         (JSON.raw_encode
--          (deepmap(encstr, obj.header),true)):url64(),
--         O.from_string
--         (JSON.raw_encode
--          (deepmap(encstr,obj.payload),true)):url64(),
--         O.to_url64(obj.signature),
--     }, ".")
-- end

return W3C
