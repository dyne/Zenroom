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

local function decode_jwt_parts(s)
    if type(s) == 'string' then
        return O.from_string(s)
    elseif type(s) == 'number' then
        return fif(TIME.detect_time_value(s), TIME.new, FLOAT.new)(s)
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

-- bearer tokens to access OAuth 2.0-protected resources (RFC 6750)
local function import_bearer_jwt(obj)
    local toks = strtok(obj)
    if toks[1] ~= 'BEARER' then error("Bearer json web token is missing 'BEARER ' prefix", 2) end
    return import_jwt(toks[2])
end

local function export_bearer_jwt(obj)
    return 'BEARER ' .. export_jwt(obj)
end

ZEN:add_schema(
    {
        json_web_token = {
            import = import_jwt,
            export = export_jwt
        },
        bearer_json_web_token = {
            import = import_bearer_jwt,
            export = export_bearer_jwt
        }
    }
)

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
