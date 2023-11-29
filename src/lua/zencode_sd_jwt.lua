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

local function import_url_f(obj)
    -- TODO: validation URL
    return O.from_str(obj)
end

local URLS_METADATA = {
    "issuer",
    "credential_issuer",
    "authorization_endpoint",
    "token_endpoint",
    "pushed_authorization_request_endpoint",
    "credential_endpoint",
    "jwks_uri",
}

local DICTS_METADATA = {
    "grant_types_supported",
    "code_challenge_methods_supported",
    "response_modes_supported",
    "response_types_supported",
    "scopes_supported",
    "subject_types_supported",
    "token_endpoint_auth_methods_supported",
    "id_token_signing_alg_values_supported",
    "request_object_signing_alg_values_supported",
    "claim_types_supported",
}

local BOOLS_METADATA = {
    "claims_parameter_supported",
    "authorization_response_iss_parameter_supported",
    "request_parameter_supported",
    "request_uri_parameter_supported",
}

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

local function check_display(display)
    return display.name and display.locale
end

local function import_supported_selective_disclosure(obj)
    local check_support = function(what, needed)
        found = false
        for i=1,#obj[what] do
            if obj[what][i] == needed then
                found = true
                break
            end
        end
        assert(found, needed .. " not supported in " .. what)
    end

    local res = {}
    for i=1,#URLS_METADATA do
        res[URLS_METADATA[i]] =
            schema_get(obj, URLS_METADATA[i], import_url_f, tostring)
    end


    local pattern_id = "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x"
    local creds = obj.credentials_supported
    for i=1,#creds do
        assert(creds[i].id:match(pattern_id))
        check_display(creds[i].display)
        local count = 0
        for j=1,#creds[i].order do
            local display = creds[i].credentialSubject[creds[i].order[j]]
            if display then
                check_display(display)
                count = count + 1
            end
        end
        assert(count == #creds[i].order)
    end

    res.credentials_supported =
        schema_get(obj, 'credentials_supported', O.from_str, tostring)
    -- we support authroization_code
    check_support('grant_types_supported', "authorization_code")
    -- we support ES256
    check_support('request_object_signing_alg_values_supported', "ES256")
    check_support('id_token_signing_alg_values_supported', "ES256")
    -- TODO: claims_parameter_supported is a boolean
    -- res.claims_parameter_supported =
    --     schema_get(obj, 'claims_parameter_supported', , tostring)

    for i=1,#DICTS_METADATA do
        res[DICTS_METADATA[i]] =
            schema_get(obj, DICTS_METADATA[i], O.from_str, tostring)
    end

    for i=1,#BOOLS_METADATA do
        res[BOOLS_METADATA[i]] = schema_get(obj, BOOLS_METADATA[i])
    end
    return res
end

local function export_supported_selective_disclosure(obj)
    local res = {}
    res.issuer = obj.issuer:str()
    for i=1,#URLS_METADATA do
        res[URLS_METADATA[i]] = obj[URLS_METADATA[i]]:str()
    end
    res.credentials_supported =
        deepmap(function(obj) return obj:str() end,
            obj.credentials_supported)
    for i=1,#DICTS_METADATA do
        res[DICTS_METADATA[i]] =
            deepmap(function(obj) return obj:str() end,
                obj[DICTS_METADATA[i]])
    end
    for i=1,#BOOLS_METADATA do
        res[BOOLS_METADATA[i]] = obj[BOOLS_METADATA[i]]
    end
    return res
end

--for reference on JSON Web Key see RFC7517
local function import_jwk(obj)
    zencode_assert(obj.kty, "The input is not a valid JSON Web Key, missing kty")
    zencode_assert(obj.kty == "EC", "kty must be EC, given is "..obj.kty)
    zencode_assert(obj.crv, "The input is not a valid JSON Web Key, missing crv")
    zencode_assert(obj.crv == "P-256", "crv must be P-256, given is "..obj.crv)
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
        zencode_assert(obj.alg == "ES256", "alg must be ES256, given is "..obj.alg)
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
    local key = {
        kty = O.to_string(obj.kty),
        crv = O.to_string(obj.crv),
        x = O.to_url64(obj.x),
        y = O.to_url64(obj.y)
    }
    if obj.use then
        key.use = O.to_string(obj.use)
    end
    if obj.alg then
        key.alg = O.to_string(obj.alg)
    end
    if obj.kid then
        key.kid = O.to_url64(obj.kid)
    end

    return key
end
local function export_jwk_key_binding(obj)
    return {
        cnf = {
            jwk = export_jwk(obj.cnf.jwk)
        }
    }
end

local function import_jwk_key_binding(obj)
    return {
        cnf = {
            jwk = import_jwk(obj.cnf.jwk)
        }
    }
end

local function import_selective_disclosure_request(obj)
    zencode_assert(obj.fields, "Input object should have a key 'fields'")
    zencode_assert(obj.object, "Input object should have a key 'object'")

    for k,v in pairs(obj.object) do
        for _,key in  pairs(JWT_RESERVED_CLAIMS) do
            zencode_assert(k ~= key, "SD request can not contain a claim with key "..k)
        end
    end

    for i=1, #obj.fields do
        zencode_assert(type(obj.fields[i]) == 'string', "The object with key fields must be a string array")
        found = false
        for k,v in pairs(obj.object) do
            if k == obj.fields[i] then
                found = true
                break
            end
        end
        zencode_assert(found, "The field "..obj.fields[i].." is not a key in the object")
    end

    return {
        fields = deepmap(function(o) return O.from_str(o) end, obj.fields),
        object = deepmap(function(o)
            if type(o) == 'string' then
                return O.from_str(o)
            elseif type(o) == 'number' then
                return F.new(o)
            else
                return o
            end
        end, obj.object),
    }
end

local function export_selective_disclosure_request(obj)
    return {
        fields = deepmap(function(o) return o:str() end, obj.fields),
        object = deepmap(function(o)
            if type(o) == 'zenroom.octet' then
                return o:string()
            elseif type(o) == 'zenroom.float' then
                return tonumber(o)
            else
                return o
            end
        end, obj.object),
    }
end

ZEN:add_schema(
    {
        supported_selective_disclosure = {
            import = import_supported_selective_disclosure,
            export = export_supported_selective_disclosure
        },
        p256_public_jwk = {
            import = import_jwk,
            export = export_jwk
        },
        jwk_key_binding = {
            import = import_jwk_key_binding,
            export = export_jwk_key_binding,
        },
        selective_disclosure_request = {
            import = import_selective_disclosure_request,
            export = export_selective_disclosure_request,
        },
    }
)

When("use supported selective disclosure to disclose '' named '' with id ''", function(disp_name, named, id_name)
    local ssd = have'supported selective disclosure'
    local disp = have(disp_name)
    local name = have(named)
    local id = have(id_name)
    check_display(disp)

    local credential = nil

    -- search for credentials supported id
    for i=1,#ssd.credentials_supported do
        if ssd.credentials_supported[i].id == id then
            credential = ssd.credentials_supported[i]
            break
        end
    end

    zencode_assert(credential ~= nil, "Credential not supported (unknown id)")

    found = false
    for i =1,#credential.order do
        if credential.order[i] == name then
            found = true
        end
    end

    if not found then
        credential.order[#credential.order+1] = name
        credential.credentialSubject[name:string()] = {
            display = {
                disp
            }
        }
    else
        curr = credential.credentialSubject[name].display
        curr[#curr+1] = disp
    end
end)

----for reference on JSON Web Key see RFC7517
When("create p256 public jwk with ''", function(pk)
    local pubk = load_pubkey_compat(pk, 'p256')
    zencode_assert(#pubk == 64, "Invalid p256 public key: expected length is 64, given is "..#pubk)
    local jwk = {
        kty = O.from_string("EC"),
        crv = O.from_string("P-256"),
        alg = O.from_string("ES256"),
        use = O.from_string("sig"),
        x = pubk:sub(1,32),
        y = pubk:sub(33,64)
    }
    empty'p256_public_jwk'
    ACK.p256_public_jwk = jwk
    new_codec("p256_public_jwk")
end)

When("set kid in jwk '' to ''", function(jw, kid)
    local jwk = have(jw)
    local k_id = O.to_url64(have(kid))
    zencode_assert(not jwk.kid, "The given JWK already has a field 'kid'")
    ACK[jw].kid = O.from_url64(k_id)
end)

When("create jwt key binding with jwk ''", function(jwk_name)
    local jwk = have(jwk_name)
    empty'jwk key binding'
    ACK.jwk_key_binding = {
        cnf = {
            jwk = jwk
        }
    }
    new_codec("jwk_key_binding")
end)

local function verify_cred_match(cred, sdr)
    local all = true
    for i=1,#cred.order do
        -- I have to verify that each item of order is inside sdr.fields
        local found = false
        for j=1,#sdr.fields do
            if sdr.fields[j] == cred.order[i] then
                found = true
                break
            end
        end
        if not found then
            all = false
            break
        end
    end

    return all
end

local function verify_ssd_match(ssd, sdr)
    for i=1,#ssd.credentials_supported do
        if verify_cred_match(ssd.credentials_supported[i], sdr) then
            return true
        end
    end
    return false
end

IfWhen("verify '' matches ''", function(sdr_name, ssd_name)
    local sdr = have(sdr_name)
    local ssd = have(ssd_name)

    zencode_assert(verify_ssd_match(ssd, sdr), "No credential supported matches")
end)

local function create_sd(sdr)
    local disclosures = {}
    local jwt_payload = deepcopy(sdr.object)
    jwt_payload._sd = {}
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
        local disclosure = {
            O.random(16):url64(),
            f,
            encode
        }
        disclosures[#disclosures+1] = disclosure
        jwt_payload[f] = nil
        jwt_payload._sd[#jwt_payload._sd+1] = sha256(
            O.from_string(JSON.raw_encode(disclosure)):url64())
    end
    return I.spy({
        payload=jwt_payload,
        disclosures=disclosures,
    })
end

When("create selective disclosure payload of ''", function(sdr_name)
    local sdr = have(sdr_name)
    ACK.selective_disclosure_payload = create_sd(sdr)
    new_codec('selective_disclosure_payload')
end)
