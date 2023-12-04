--[[
--This file is part of Zenroom
--
--Copyright (C) 2023 Dyne.org foundation
--
--designed, written and maintained by:
--Rebecca Selvaggini, Alberto Lerda, Denis Roio and Andrea D'Intino
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

local SD_JWT = require'crypto_sd_jwt'

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


    local creds = obj.credentials_supported
    for i=1,#creds do
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

local function import_str_dict(obj)
    return deepmap(function(o)
        if type(o) == 'string' then
            return O.from_str(o)
        elseif type(o) == 'number' then
            return F.new(o)
        else
            return o
        end
    end, obj)
end

local function export_str_dict(obj)
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

local function import_selective_disclosure_request(obj)
    zencode_assert(obj.fields, "Input object should have a key 'fields'")
    zencode_assert(obj.object, "Input object should have a key 'object'")

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
        object = import_str_dict(obj.object),
    }
end

local function export_selective_disclosure_request(obj)
    return {
        fields = deepmap(function(o) return o:str() end, obj.fields),
        object = export_str_dict(obj.object),
    }
end

local function import_selective_disclosure_payload(obj)
    return {
        payload = import_str_dict(obj.payload),
        disclosures = import_str_dict(obj.disclosures),
    }
end

local function export_selective_disclosure_payload(obj)
    return {
        disclosures = export_str_dict(obj.disclosures),
        payload = export_str_dict(obj.payload),
    }
end

local function import_signed_selective_disclosure(obj)
    -- export the whole obj as string dictionary but the signature
    local signature = obj.jwt.signature
    obj.jwt.signature = nil
    local jwt = import_str_dict(obj.jwt)
    obj.jwt.signature = signature

    jwt.signature = O.from_base64(signature)
    return {
        jwt = jwt,
        disclosures = import_str_dict(obj.disclosures),
    }
end

local function export_signed_selective_disclosure(obj)
    -- export the whole obj as string dictionary but the signature
    local signature = obj.jwt.signature
    obj.jwt.signature = nil
    local jwt = export_str_dict(obj.jwt)
    obj.jwt.signature = signature

    jwt.signature = signature:base64()
    return {
        jwt = jwt,
        disclosures = export_str_dict(obj.disclosures),
    }
end

local function import_jwt(obj)
    local toks = strtok(obj, ".")
    -- TODO: verify this is a valid jwt
    return import_str_dict{
        header = JSON.raw_decode(O.from_url64(toks[1]):str()),
        payload = JSON.raw_decode(O.from_url64(toks[2]):str()),
        signature = O.from_url64(toks[3]),
    }
end

local function import_sd_jwt(obj)
    zencode_assert(obj:sub(#obj, #obj) == '~', "JWT binding not implemented")
    local toks = strtok(obj, "~")
    disclosures = {}
    for i=2,#toks do
        disclosures[#disclosures+1] = JSON.raw_decode(O.from_url64(toks[i]):str())
    end
    return import_str_dict{
        jwt = import_jwt(toks[1]),
        disclosures = disclosures,
    }
end

local function export_jwt(obj)
    return table.concat({
        O.from_string(JSON.raw_encode(export_str_dict(obj.header))):url64(),
        O.from_string(JSON.raw_encode(export_str_dict(obj.payload))):url64(),
        obj.signature:url64(),
    }, ".")
end

local function export_sd_jwt(obj)
    local records = {
        export_jwt(obj.jwt)
    }
    for _, d in pairs(export_str_dict(obj.disclosures)) do
        records[#records+1] = O.from_string(JSON.raw_encode(d, true)):url64()
    end
    records[#records+1] = ""
    return table.concat(records, "~")
end

ZEN:add_schema(
    {
        supported_selective_disclosure = {
            import = import_supported_selective_disclosure,
            export = export_supported_selective_disclosure
        },
        es256_public_jwk = {
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
        selective_disclosure_payload = {
            import = import_selective_disclosure_payload,
            export = export_selective_disclosure_payload,
        },
        signed_selective_disclosure = {
            import = import_signed_selective_disclosure,
            export = export_signed_selective_disclosure,
        },
        sd_jwt = {
            import = import_sd_jwt,
            export = export_sd_jwt,
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
When("create es256 public jwk with ''", function(pk)
    local pubk = load_pubkey_compat(pk, 'es256')
    zencode_assert(#pubk == 64, "Invalid es256 public key: expected length is 64, given is "..#pubk)
    local jwk = {
        kty = O.from_string("EC"),
        crv = O.from_string("P-256"),
        alg = O.from_string("ES256"),
        use = O.from_string("sig"),
        x = pubk:sub(1,32),
        y = pubk:sub(33,64)
    }
    empty'es256_public_jwk'
    ACK.es256_public_jwk = jwk
    new_codec("es256_public_jwk")
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

When("create selective disclosure request from '' with id '' for ''", function(ssd_name, id_name, object_name)
    local ssd = have(ssd_name)
    local id = have(id_name)
    local object = have(object_name)

    local creds = ssd.credentials_supported
    local pos = 0
    for i=1,#creds do
        if creds[i].id == id then
	    pos = i
	    break
	end
    end
    zencode_assert(pos > 0, "Unknown credential id")

    ACK.selective_disclosure_request = {
        fields = creds[pos].order,
        object = object,
    }
    new_codec("selective_disclosure_request")
end)

When("create selective disclosure payload of ''", function(sdr_name)
    local sdr = have(sdr_name)
    local sdp = SD_JWT.create_sd(sdr)
    sdp.payload = import_str_dict(sdp.payload)
    ACK.selective_disclosure_payload = sdp
    new_codec('selective_disclosure_payload')
end)

When("create signed selective disclosure of '' with key es256", function(sdp_name)
    local p256 = havekey'es256'
    local sdp = have(sdp_name)

    ACK.signed_selective_disclosure = {
        jwt=SD_JWT.create_jwt_es256(sdp.payload, p256),
        disclosures=sdp.disclosures,
    }
    new_codec('signed_selective_disclosure')
end)

-- for reference see Section 8.1 of https://datatracker.ietf.org/doc/draft-ietf-oauth-selective-disclosure-jwt/
When("verify sd jwt '' issued by '' is valid", function(obj, by)
    local signed_sd = have(obj)
    local iss_pk = load_pubkey_compat(by, 'es256')
    local jwt = signed_sd.jwt
    local disclosures = signed_sd.disclosures
-- Ensure that a signing algorithm was used that was deemed secure for the application.
    zencode_assert(SD_JWT.verify_jws_header(jwt), "The JWT header is not valid")
-- Check that the _sd_alg claim value is understood and the hash algorithm is deemed secure.
    zencode_assert(SD_JWT.verify_sd_alg(jwt), "The hash algorithm is not supported")

-- Check that the sd-jwt contains all the mandatory claims
    zencode_assert(SD_JWT.check_mandatory_claim_names(jwt.payload), "The JWT payload does not contain the mandatory claims")

-- Validate the signature over the Issuer-signed JWT.
    zencode_assert(SD_JWT.verify_jws_signature(jwt, iss_pk), "The issuer signature is not valid")

-- TODO?: Validate the Issuer and that the signing key belongs to this Issuer.

-- Process the Disclosures and embedded digests in the Issuersigned JWT and compare the value with the digests calculated
    zencode_assert(SD_JWT.verify_sd_fields(jwt.payload, disclosures), "The disclosure is not valid")

-- TODO: Check that the SD-JWT is valid using claims such as nbf, iat and exp in the processed payload.
end)
