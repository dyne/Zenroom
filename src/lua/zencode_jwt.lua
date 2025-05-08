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

local W3C = require_once'crypto_w3c'

ZEN:add_schema(
    {
        json_web_token = {
            import = W3C.import_jwt,
            export = W3C.export_jwt
        },
        jwt = {
            import = W3C.import_jwt,
            export = W3C.export_jwt
        }
    }
)

function create_jwt_hs256(payload, password)
    local header <const> = {
        alg = O.from_string'HS256',
        typ = O.from_string'JWT'
    }
    local b64header <const> = O.from_string(
        JSON.encode(header,'string')):url64()
    local b64payload <const> = O.from_string(
        JSON.encode(payload,'string')):url64()
    local hash = HASH.new("sha256")

    local signature <const> = hash:hmac(
        password,
        b64header .. '.' .. b64payload)
    return {
        header=header,
        payload=payload,
        signature=signature,
    }
end

When("create json web token of '' using ''", function(payload_name, password_name)
    local payload <const> = have(payload_name)
    local password <const> = mayhave(password_name) or password_name
    empty'json_web_token'
    ACK.json_web_token = create_jwt_hs256(payload, password)
    new_codec("json_web_token")
end)

IfWhen("verify json web token in '' using ''", function(hmac_name, password_name)
    local hmac <const> = have(hmac_name)
    local password <const> = mayhave(password_name) or password_name
    local jwt_hs256 <const> = create_jwt_hs256(hmac.payload, password)
    zencode_assert(jwt_hs256.signature == hmac.signature, "Could not re-create HMAC")
end)
