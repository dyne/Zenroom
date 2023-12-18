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

local function export_str_dict(obj)
    return deepmap(get_encoding_function("string"), obj)
end

-- Given as input a "disclosure array" of the form {salt, key, value}
-- Return: disclosure = the array in octet form
--         hashed = the sha256 digest of the encoded array (for _sd)
--         encoded_dis = the url64+json encoding of the input array (used just for testing)
function sd_jwt.create_disclosure(dis_arr)
    -- TODO: disclosure of disctionary

    local encoded_dis = O.from_string(JSON.raw_encode(export_str_dict(dis_arr), true)):url64()
    local disclosure = {}
    for i = 1, #dis_arr do
        if type(dis_arr[i]) == 'table' then
            disclosure[i] = deepmap(function(o) return O.from_string(o) end, dis_arr[i])
        elseif type(dis_arr[i]) == 'string' then
            disclosure[i] = O.from_string(dis_arr[i])
        else
            disclosure[i] = dis_arr[i]
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
local JWT_RESERVED_CLAIMS = {"iss", "sub", "aud", "exp", "nbf", "iat", "jti", "typ", "type", "cty", "cnf"}

local NON_SELECTIVELY_DISCLOSABLE_CLAIMS = {"iss", "iat", "exp", "cnf", "type", "_sd", "_sd_alg"}

-- Given as input a selective disclosure request
-- Return a table containing two keys:
--        payload = the jwt containing disclosable object (the credential to be signed by the issuer)
--        disclosures = the list of disclosure arrays
function sd_jwt.create_sd(sdr)
    local disclosures = {}
    local jwt_payload = {
        _sd_alg = O.from_string("sha-256"),
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
    local payload_str = export_str_dict(payload)
    b64payload = O.from_string(JSON.raw_encode(payload_str)):url64()

    local signature = ES256.sign(sk, b64payload)
    return {
        header=header,
        payload=payload,
        signature=signature,
    }
end

-- Given as input a signed selective disclosure 'ssd' and a list of strings 'disclosed_keys'
-- Return the list of disclosure array with keys in 'disclosed_keys'
function sd_jwt.retrive_disclosures(ssd, disclosed_keys)
    local disclosures = {}
    local all_dis = ssd.disclosures
    for _,k in pairs(disclosed_keys) do
        for ind, arr in pairs(all_dis) do
            if arr[2] == k then
                table.insert(disclosures, arr)
                break
            end
        end
    end
    return disclosures
end

-- for reference see Section 8.1 of https://datatracker.ietf.org/doc/draft-ietf-oauth-selective-disclosure-jwt/

function sd_jwt.verify_jws_signature(jws, pk)
    local payload_str = export_str_dict(jws.payload)
    local b64payload = O.from_string(JSON.raw_encode(payload_str)):url64()
    return ES256.verify(pk, jws.signature, b64payload)
end

function sd_jwt.verify_jws_header(jws)
    return jws.header.alg == O.from_string("ES256") and jws.header.typ == O.from_string("JWT")
end

function sd_jwt.verify_sd_alg(jwt)
    return jwt.payload._sd_alg == O.from_string("sha-256")
end

local function is_in(list, elem)
    local found = false
    for i = 1, #list do
        if list[i] == elem then
            found = true
            break
        end
    end
    return found
end

-- TODO: In the final version we should check that the sd-jwt payload contains all the mandatory claims below
-- "iss", "iat", "cnf", "type", if "_sd" => "_sd_alg"
function sd_jwt.check_mandatory_claim_names(jwt)
    local found = true
    if jwt._sd then
        if not jwt._sd_alg then
            found = false
        end
    end
    if not jwt.iss then
        found = false
    end
    return found
end

-- Check that the input is a table of three elements, where the first two object are string
-- the input should be of the form {salt, key, value}
-- we also check that the key is not in NON_SELECTIVELY_DISCLOSABLE_CLAIMS
local function disclosure_array_is_valid(arr)
    if type(arr) ~= 'table' or #arr ~= 3 then
        return false
    end
    if type(arr[1]) ~= 'string' or type(arr[2]) ~= 'string' then
        return false
    end
    if is_in(NON_SELECTIVELY_DISCLOSABLE_CLAIMS, arr[2]) then
        return false
    end
    return true
end

function sd_jwt.verify_sd_fields(jwt, disclosures)
    local match = true
    local digest_arr = jwt._sd
    local disclosures_arr = export_str_dict(disclosures)
    local claim_names = {}
    for i = 1, #disclosures_arr do
        if not disclosure_array_is_valid(disclosures_arr[i]) then
            return false
        end
        if is_in(claim_names, disclosures_arr[i][2]) then
            return false
        else
            table.insert(claim_names, disclosures_arr[i][2])
        end
        local _, hashed = sd_jwt.create_disclosure(disclosures_arr[i])
        if not is_in(digest_arr, hashed) then
            match = false
            break
        end
    end
    return match
end

return sd_jwt
