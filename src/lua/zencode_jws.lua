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

When(deprecated(
        "create jws signature of ''",
        "create jws detached signature with header '' and payload ''",
        function(src)
            warn('raw signature of the payload, non standard jws')
            local source_str = W3C.json_encoding(src)
            empty'jws'
            local sk = havekey'ecdh' -- assuming secp256k1
            ACK.jws = O.from_string(
                W3C.jws_signature_to_octet(ECDH.sign(sk, source_str)) )
            new_codec('jws', { zentype = 'e',
                                encoding = 'string' })
        end
    )
)

When(deprecated(
        "create jws signature using ecdh signature in ''",
        "create jws detached signature with header '' and payload ''",
        function(sign)
            warn('external signature can be not jws compliant')
            local signature = have(sign)
            empty'jws'
            ACK.jws = O.from_string(jws_signature_to_octet(signature))
            new_codec('jws', { zentype = 'e',
                                encoding = 'string' })
        end
    )
)

-- return a header for jws
-- @param alg alg in jws header
-- @param pk pk flag, is true the alg pk is set in the header in jwk format
local function _create_jws_header(alg, pk)
    local header = {['alg'] = alg}
    if pk then
        header.jwk = W3C.create_string_jwk(alg)
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
    local o_header = W3C.json_encoding(header)
    local o_payload = W3C.json_encoding(payload)
    empty(n_output)
    ACK[n_output] = O.from_string(
        W3C.jws_signature_to_octet(nil, o_header, o_payload, detached)
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
    local o_payload = payload and W3C.json_encoding(payload)
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

IfWhen("verify '' has a jws signature in ''", _verify_jws)

IfWhen("verify jws signature in ''", function(jws) _verify_jws(nil, jws) end)
