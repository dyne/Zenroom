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
--Last modified by Matteo Cristino
--on Thursday, 26th September 2024
--]]

local W3C = require_once "crypto_w3c"

local function _create_jwk(alg, sk_flag, pk)
    empty 'jwk'
    ACK.jwk = deepmap(O.from_string, W3C.create_string_jwk(alg, sk_flag, pk))
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
