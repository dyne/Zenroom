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
local JOSE = require_once "crypto_jose"

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
    local crypto <const> = CRYPTO.load(alg)
    ACK.jws_header = {['alg'] = O.from_string(crypto.IANA)}
    if pk then
        local jwk = JOSE.create_jwk(crypto.IANA)
        jwk.x = O.from_string(jwk.x:to_url64())
        jwk.y = O.from_string(jwk.y:to_url64())
        ACK.jws_header.jwk = jwk
    end
    new_codec('jws_header', { zentype = 'd', encoding = 'string' })
end

When("create jws header for '' signature", function(algo_name)
         local crypto <const> = CRYPTO.load(algo_name)
         empty'jws_header'
         ACK.jws_header = { alg = O.from_string(crypto.IANA) }
         -- TODO: generate UID
         new_codec('jws_header', { zentype = 'd', encoding = 'string' })
end)

When("create jws header for '' signature with public key", function(algo_name)
         local crypto <const> = CRYPTO.load(algo_name)
         empty'jws_header'
         ACK.jws_header = { alg = O.from_string(crypto.IANA) }
         local jwk = JOSE.create_jwk(crypto.IANA)
         jwk.x = O.from_string(jwk.x:to_url64())
         jwk.y = O.from_string(jwk.y:to_url64())
         ACK.jws_header.jwk = jwk
         -- TODO: generate UID
         new_codec('jws_header', { zentype = 'd', encoding = 'string' })
end)

When(deprecated("create jws header for p256 signature",
                "create jws header for '' signature", function() _create_jws_header('ES256') end))
When(deprecated("create jws header for es256 signature",
                "create jws header for '' signature", function() _create_jws_header('ES256') end))
When(deprecated("create jws header for secp256r1 signature",
                "create jws header for '' signature", function() _create_jws_header('ES256') end))
When(deprecated("create jws header for ecdh signature",
                "create jws header for '' signature", function() _create_jws_header('ES256K') end))
When(deprecated("create jws header for es256k signature",
                "create jws header for '' signature", function() _create_jws_header('ES256K') end))
When(deprecated("create jws header for secp256k1 signature",
                "create jws header for '' signature", function() _create_jws_header('ES256K') end))

When(deprecated("create jws header for p256 signature with public key",
                "create jws header for '' signature with public key", function() _create_jws_header('ES256', true) end))
When(deprecated("create jws header for es256 signature with public key",
                "create jws header for '' signature with public key", function() _create_jws_header('ES256', true) end))
When(deprecated("create jws header for secp256r1 signature with public key",
                "create jws header for '' signature with public key", function() _create_jws_header('ES256', true) end))
When(deprecated("create jws header for ecdh signature with public key",
                "create jws header for '' signature with public key", function() _create_jws_header('ES256K', true) end))
When(deprecated("create jws header for es256k signature with public key",
                "create jws header for '' signature with public key", function() _create_jws_header('ES256K', true) end))
When(deprecated("create jws header for secp256k1 signature with public key",
                "create jws header for '' signature with public key", function() _create_jws_header('ES256K', true) end))

When("create jws signature of header '' and payload ''", function(header, payload)
    empty'jws_signature'
    local h <const> = have(header)
    local p <const> = have(payload)
    ACK['jws_signature'] = JOSE.create_jws(nil, h, p, false)
    new_codec('jws_signature', { zentype = 'e',
                                 encoding = 'string' })
end)

-- jws result will be without pyaload, signature is always perform on
-- header.payload
When("create jws detached signature of header '' and payload ''", function(header, payload)
    empty'jws_detached_signature'
    local h <const> = have(header)
    local p <const> = have(payload)
    ACK['jws_detached_signature'] = JOSE.create_jws(nil, h, p, true)
    new_codec('jws_detached_signature', { zentype = 'e',
                                          encoding = 'string' })
end)

local function _verify_jws(n_payload, n_jws)
    local jws_enc <const> = have(n_jws or 'jws')
    local payload <const> = have(n_payload)
    local pser    <const> = JSON.serialize(payload)
    local jws     <const> = JOSE.parse_jws(jws_enc)
    local crypto  <const> = CRYPTO.load(jws.header.alg)
    -- the payload is passed as argument so we assume this to
    -- be a detached signature, in case another payload is
    -- present in the jws then we also verify it is the same as
    -- the detached one
    if jws.payload then
        zencode_assert(pser == jws.payload_enc,
                       "The JWS contains a different payload")
    end
    local to_be_verified <const> =
        jws.header_enc..O.from_string('.')..pser
    -- if header.alg == 'ES256K' then
    -- TODO: split signature in r and s should be done in ECDH
    local pk = mayhave('jws_public_key')
    if not pk then pk = have(crypto.keyname..'_public_key') end
    zencode_assert(crypto.verify(pk, to_be_verified, jws.signature),
                   'Invalid JWS signature of: '..n_payload)
end
IfWhen(deprecated("verify jws signature of ''",
                  "verify '' has a jws signature in ''",
                  _verify_jws))
IfWhen("verify '' has a jws signature in ''", _verify_jws)

IfWhen("verify jws signature in ''", function(n_jws)
           local jws_enc <const> = have(n_jws)
           local jws     <const> = JOSE.parse_jws(jws_enc)
           zencode_assert( jws.payload, "The JWS has no payload")
           local crypto  <const> = CRYPTO.load(jws.header.alg)
           local to_be_verified <const> = jws.header_enc..O.from_string('.')..jws.payload_enc
           local pk = mayhave('jws_public_key')
           if not pk then pk = mayhave(crypto.keyname..'_public_key') end
           if not pk then pk = JOSE.jwk_to_pk(jws.header, crypto) end
           zencode_assert(pk, 'Public key not found for JWS signature')
           zencode_assert(crypto.verify(pk, to_be_verified, jws.signature),
                          'Invalid JWS signature in: '..n_jws)
end)
