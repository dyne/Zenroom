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

-- When(deprecated(
--         "create jws signature of ''",
--         "create jws detached signature with header '' and payload ''",
--         function(src)
--             warn('raw signature of the payload, non standard jws')
--             local source_str = W3C.json_encoding(src)
--             empty'jws'
--             local sk = havekey'ecdh' -- assuming secp256k1
--             ACK.jws = O.from_string(
--                 W3C.jws_signature_to_octet(ECDH.sign(sk, source_str)) )
--             new_codec('jws', { zentype = 'e',
--                                 encoding = 'string' })
--         end
--     )
-- )

-- When(deprecated(
--         "create jws signature using ecdh signature in ''",
--         "create jws detached signature with header '' and payload ''",
--         function(sign)
--             warn('external signature can be not jws compliant')
--             local signature = have(sign)
--             empty'jws'
--             ACK.jws = O.from_string(jws_signature_to_octet(signature))
--             new_codec('jws', { zentype = 'e',
--                                 encoding = 'string' })
--         end
--     )
-- )

-- return a header for jws
-- @param alg alg in jws header
-- @param pk pk flag, is true the alg pk is set in the header in jwk format
local function _create_jws_header(alg, pk)
    ACK.jws_header = {['alg'] = O.from_string(alg)}
    if pk then
        ACK.jws_header.jwk = W3C.create_jwk(alg)
    end
    new_codec('jws_header', { zentype = 'd' })
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

When("create jws signature of header '' and payload ''", function(header, payload)
    empty'jws_signature'
    local h <const> = have(header)
    local p <const> = have(payload)
    ACK['jws_signature'] = W3C.create_jws(nil, h, p, false)
    new_codec('jws_signature', { zentype = 'e',
                                 encoding = 'string' })
end)

-- jws result will be without pyaload, signature is always perform on
-- header.payload
When("create jws detached signature of header '' and payload ''", function(header, payload)
    empty'jws_detached_signature'
    local h <const> = have(header)
    local p <const> = have(payload)
    ACK['jws_detached_signature'] = W3C.create_jws(nil, h, p, true)
    new_codec('jws_detached_signature', { zentype = 'e',
                                          encoding = 'string' })
end)

local function _verify_jws(payload, jws)
    local n_jws <const> = jws or 'jws'
    local o_jws <const> = have(n_jws)
    local o_payload = have(payload) and W3C.serialize(payload)
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
    local signature, verify_f, pub, signed = W3C.jws_octet_to_signature(o_jws, enc_payload)
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

IfWhen("verify '' has a jws signature in ''", function(n_payload, n_jws)
           local jws     <const> = have(n_jws)
           local payload <const> = have(n_payload)
           local pser    <const> = W3C.serialize(payload)
           local tjws    <const> = strtok(jws:string(), '.')
           zencode_assert( tjws[1] ~= '', "The JWS has no header")
           -- I.spy(W3C.deserialize(O.from_string(tjws[1])))
           zencode_assert( jsontok(O.from_url64(tjws[1]):string()),
                                   "The JWS header is not a valid JSON")
           zencode_assert( tjws[3] ~= '', "The JWS has no signature")
           local phead   <const> = O.from_string(tjws[1])
           local header  <const> = W3C.deserialize(phead)
           zencode_assert( luatype(header)=='table',
                           'The JWS header is not a dictionary')
           local crypto  <const> = W3C.resolve_crypto_algo(header.alg)
           -- the payload is passed as argument so we assume this to
           -- be a detached signature, in case another payload is
           -- present in the jws then we also verify it is the same as
           -- the detached one
           if tjws[2] ~= '' then
               zencode_assert(pser == O.from_string(tjws[2]),
                              "The JWS contains a different payload")
           end
           I.spy({ header = W3C.deserialize(phead),
                   payload = JSON.encode(payload) })
           local to_be_verified <const> = phead..O.from_string('.')..pser
           local psig    <const> = W3C.deserialize(O.from_string(tjws[3]))
           I.spy({len= #psig,psig = psig:hex()})

           -- if header.alg == 'ES256K' then
               -- TODO: split signature in r and s should be done in ECDH
           local pk = mayhave('jws_public_key')
           if not pk then pk = mayhave(crypto.keyname..'_public_key') end
           zencode_assert(crypto.verify(pk, to_be_verified, psig),
                          'Invalid JWS signature of: '..n_payload)
end)

IfWhen("verify jws signature in ''", function(n_jws)
           local jws     <const> = have(n_jws)
           local tjws    <const> = strtok(jws:string(), '.')
           zencode_assert( tjws[1] ~= '', "The JWS has no header")
           zencode_assert( jsontok(O.from_url64(tjws[1]):string()),
                                   "The JWS header is not a valid JSON")
           zencode_assert( tjws[2] ~= '', "The JWS has no payload")
           zencode_assert( tjws[3] ~= '', "The JWS has no signature")
           local phead   <const> = O.from_string(tjws[1])
           local header  <const> = W3C.deserialize(phead)
           zencode_assert( luatype(header)=='table',
                           'The JWS header is not a dictionary')
           local crypto  <const> = W3C.resolve_crypto_algo(header.alg)
           local to_be_verified <const> = phead..O.from_string('.')..pser
           local psig    <const> = W3C.deserialize(O.from_string(tjws[3]))
           local pk = mayhave('jws_public_key')
           if not pk then pk = mayhave(crypto.keyname..'_public_key') end
           zencode_assert(crypto.verify(pk, to_be_verified, psig),
                          'Invalid JWS signature of: '..n_payload)
end)
