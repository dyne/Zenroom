--[[
--This file is part of zenroom
--
--Copyright (C) 2023 Dyne.org foundation
--
--designed, written and maintained by:
--Rebecca Selvaggini, Alberto Lerda and Denis Roio
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
--]]

local ES256 = require'es256'
local sd_jwt = {}

-- Given as input a "disclosure array" of the form {salt, key, value}
-- Return: disclosure = the array in octet form
--         hashed = the sha256 digest of the encoded array (for _sd)
--         encoded_dis = the url64+json encoding of the input array (used just for testing)
function sd_jwt.create_disclosure(dis_arr)
    -- TODO: disclosure of disctionary
    -- TODO: problems sub, updated_at
    local encoded_dis = O.from_string(JSON.raw_encode(dis_arr, true)):url64()
    local disclosure = {}
    for i = 1, #dis_arr do
        if type(dis_arr[i]) == 'table' then
            disclosure[i] = deepmap(function(o) return O.from_string(o) end, dis_arr[i])
        elseif type(dis_arr[i]) == 'string' then
            disclosure[i] = O.from_string(dis_arr[i])
        end
    end
    local hashed = O.from_string(sha256(encoded_dis):url64())
    return  disclosure, hashed, encoded_dis
end


--[[ JWT reserved claim names (see Section 4.1 and Section 5 of RFC7519)
"iss" (Issuer) Claim
"sub" (Subject) Claim
"aud" (Audience) Claim
"exp" (Expiration Time) Claim
"nbf" (Not Before) Claim
"iat" (Issued At) Claim
"jti" (JWT ID) Claim
"typ" (Type) Header Parameter
"cty" (Content Type) Header Parameter
]]
local JWT_RESERVED_CLAIMS = {"iss", "sub", "aud", "exp", "nbf", "iat", "jti", "typ", "cty"}

-- Given as input a selective disclosure request
-- Return a table containing two keys:
--        payload = the jwt containing disclosable object (the credential to be signed by the issuer)
--        disclosures = the list of disclosure arrays
function sd_jwt.create_sd(sdr)
    local disclosures = {}
    local jwt_payload = {
        _sd = {}
    }
    for _, f in pairs(sdr.fields) do
        local f = f:str()
        local encode = nil
        if type(sdr.object[f]) == 'table' then
            encode = deepmap(function(o) return o:str() end, sdr.object[f])
        elseif type(sdr.object[f]) == 'zenroom.octet' then
            encode = sdr.object[f]:str()
        else
            encode = sdr.object[f]
        end
        local disclosure_arr = {
            O.random(16):url64(),
            f,
            encode
        }
        local disclosure, hashed = sd_jwt.create_disclosure(disclosure_arr)

        disclosures[#disclosures+1] = disclosure
        jwt_payload._sd[#jwt_payload._sd+1] = hashed
    end
    for _, rc in pairs(JWT_RESERVED_CLAIMS) do
        jwt_payload[rc] = deepcopy(sdr.object[rc])
    end

    return {
        payload=jwt_payload,
        disclosures=disclosures,
    }
end

function sd_jwt.export_str_dict(obj)
    return deepmap(function(o)
        if type(o) == 'zenroom.octet' then
            return o:string()
        elseif type(o) == 'zenroom.float' then
            return tonumber(o)
        else
            return o
        end
    end, obj)
end
-- TODO: add test from section A.3 of
-- https://www.rfc-editor.org/rfc/rfc7515.html
-- WARNING: the JSON encode is not unique, so I should
-- return the base64 encoding to be sure to be able to verify it,
-- but we are in zenroom and if I print the same object I obtain the
-- same representation, thus I can keep the object and print it only
-- on export, yay!
function sd_jwt.create_jwt_es256(payload, sk)
    local header, b64header, b64payload, hmac
    header = {
        alg=O.from_string("ES256"),
        typ=O.from_string("JWT")
    }
    payload_str = sd_jwt.export_str_dict(payload)
    I.spy(payload_str)
    b64payload = O.from_string(JSON.raw_encode(payload_str)):url64()
    I.spy(b64payload)

    local signature = ES256.sign(sk, b64payload)
    return {
        header=header,
        payload=payload,
        signature=signature,
    }
end

return sd_jwt
