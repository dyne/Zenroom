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

--for reference on JSON Web Key see RFC7517
-- TODO: implement jwk for other private/public keys
local function import_jwk(obj)
    zencode_assert(obj.kty, "The input is not a valid JSON Web Key, missing kty")
    -- zencode_assert(obj.kty == "EC", "kty must be EC, given is "..obj.kty)
    -- zencode_assert(obj.crv, "The input is not a valid JSON Web Key, missing crv")
    -- zencode_assert(obj.crv == "P-256", "crv must be P-256, given is "..obj.crv)
    zencode_assert(obj.x, "The input is not a valid JSON Web Key, missing x")
    zencode_assert(#O.from_url64(obj.x) == 32, "Wrong length in field 'x', expected 32 given is ".. #O.from_url64(obj.x))
    zencode_assert(obj.y, "The input is not a valid JSON Web Key, missing y")
    zencode_assert(#O.from_url64(obj.y) == 32, "Wrong length in field 'y', expected 32 given is ".. #O.from_url64(obj.y))

    local res = {
        kty = O.from_string(obj.kty),
        crv = O.from_string(obj.crv),
        x = O.from_url64(obj.x),
        y = O.from_url64(obj.y)
    }
    if obj.alg then
        -- zencode_assert(obj.alg == "ES256", "alg must be ES256, given is "..obj.alg)
        res.alg = O.from_string(obj.alg)
    end
    if obj.use then
        zencode_assert(obj.use == "sig", "use must be sig, given is "..obj.use)
        res.use = O.from_string(obj.use)
    end
    if obj.kid then
        res.kid = O.from_url64(obj.kid)
    end
    return res
end

local function export_jwk(obj)
    local key = { }
    if obj.d   then key.d =   O.to_string(obj.d) end
    if obj.kty then key.kty = O.to_string(obj.kty) end
    if obj.crv then key.crv = O.to_string(obj.crv) end
    if obj.x   then key.x =   O.to_string(obj.x) end
    if obj.y   then key.y =   O.to_string(obj.y) end
    if obj.use then key.use = O.to_string(obj.use) end
    if obj.alg then key.alg = O.to_string(obj.alg) end
    if obj.kid then key.kid = O.to_string(obj.kid) end
    return key
end

ZEN:add_schema(
    {
        jwk = {
            import = import_jwk,
            export = export_jwk
        }
    }
)

local function _create_jwk(alg, sk_flag, pk)
    empty 'jwk'
    ACK.jwk = deepmap(O.from_string, W3C.create_string_jwk(alg, sk_flag, pk))
    new_codec('jwk') -- { schemazentype = 'd',
                      -- encoding = 'string' })
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
