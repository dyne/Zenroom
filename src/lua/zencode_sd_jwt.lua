--[[
--This file is part of Zenroom
--
--Copyright (C) 2023-2025 Dyne.org foundation
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
    "credential_issuer",
    "credential_endpoint"
}
--"authorization_servers",

-- local DICTS_METADATA = {
--     "grant_types_supported",
--     "code_challenge_methods_supported",
--     "response_modes_supported",
--     "response_types_supported",
--     "scopes_supported",
--     "subject_types_supported",
--     "token_endpoint_auth_methods_supported",
--     "id_token_signing_alg_values_supported",
--     "request_object_signing_alg_values_supported",
--     "claim_types_supported",
-- }

-- local BOOLS_METADATA = {
--     "claims_parameter_supported",
--     "authorization_response_iss_parameter_supported",
--     "request_parameter_supported",
--     "request_uri_parameter_supported",
-- }

local function check_display(display)
    return display.name and display.locale
end

local function import_supported_selective_disclosure(obj)
    local check_support = function(obj, what, needed)
        found = false
        if(type(obj[what]) == 'table') then
            for k,v in pairs(obj[what]) do
               if v == needed[k] then
                    found = true
                    break
               end 
            end
        else 
            found = obj[what] == needed
        end
        if(not found) then
            error("Found parameter not supported in " .. what, 3)
        end
    end

    local res = {}
    for i=1,#URLS_METADATA do
        res[URLS_METADATA[i]] =
            schema_get(obj, URLS_METADATA[i], import_url_f, tostring)
    end
    res.authorization_servers = schema_get(obj, 'authorization_servers', import_url_f, tostring)
    local creds = obj.credential_configurations_supported
    for _,v in pairs(creds) do
        check_display(v.display)
        check_support(v, 'format', 'vc+sd-jwt')
        check_support(v, 'credential_signing_alg_values_supported', {'ES256'})
        check_support(v, 'cryptographic_binding_methods_supported', {"jwk", "did:dyne:sandbox.signroom"})
        -- check_support(creds[i], 'proof_types_supported', {jwt = { proof_signing_alg_values_supported = {"ES256"}}})
        if (not v.vct) then
            error("Invalid supported selective disclosure: missing parameter vct", 2)
        end
        -- claims and everything in it are optional
    end

    res.credential_configurations_supported =
        schema_get(obj, 'credential_configurations_supported', O.from_str, tostring)

    return res
end

local function export_supported_selective_disclosure(obj)
    local res = {}
    for i=1,#URLS_METADATA do
        res[URLS_METADATA[i]] = obj[URLS_METADATA[i]]:str()
    end
    res.authorization_servers = {}
    for k,v in pairs(obj.authorization_servers) do
        res.authorization_servers[k] = v:str()
    end
    res.credential_configurations_supported =
        deepmap(function(obj) return obj:str() end,
            obj.credential_configurations_supported)
    return res
end

--for reference on JSON Web Key see RFC7517
-- TODO: implement jwk for other private/public keys
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
    return deepmap(input_encoding("str").fun, obj)
end

local function export_str_dict(obj)
    return deepmap(get_encoding_function("string"), obj)
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

local function import_selective_disclosure(obj)
    return {
        payload = import_str_dict(obj.payload),
        disclosures = import_str_dict(obj.disclosures),
    }
end

local function export_selective_disclosure(obj)
    return {
        disclosures = export_str_dict(obj.disclosures),
        payload = export_str_dict(obj.payload),
    }
end

local function import_decoded_selective_disclosure(obj)
    -- export the whole obj as string dictionary but the signature
    local signature = obj.jwt.signature
    obj.jwt.signature = nil
    local jwt = import_str_dict(obj.jwt)
    obj.jwt.signature = signature

    jwt.signature = O.from_url64(signature)
    return {
        jwt = jwt,
        disclosures = import_str_dict(obj.disclosures),
    }
end

local function export_decoded_selective_disclosure(obj)
    -- export the whole obj as string dictionary but the signature
    local signature = obj.jwt.signature
    obj.jwt.signature = nil
    local jwt = export_str_dict(obj.jwt)
    obj.jwt.signature = signature
    jwt.signature = O.to_url64(signature)
    return {
        jwt = jwt,
        disclosures = export_str_dict(obj.disclosures),
    }
end

local function import_jwt(obj)
    local function import_jwt_dict(d)
        return import_str_dict(
            JSON.raw_decode(O.from_url64(d):str()))
    end
    local toks = strtok(obj, ".")
    -- TODO: verify this is a valid jwt
    return {
        header = import_jwt_dict(toks[1]),
        payload = import_jwt_dict(toks[2]),
        signature = O.from_url64(toks[3]),
    }
end

local function import_signed_selective_disclosure(obj)
    zencode_assert(obj:sub(#obj, #obj) == '~', "JWT binding not implemented")
    local toks = strtok(obj, "~")
    disclosures = {}
    for i=2,#toks do
        disclosures[#disclosures+1] = JSON.raw_decode(O.from_url64(toks[i]):str())
    end
    return {
        jwt = import_jwt(toks[1]),
        disclosures = import_str_dict(disclosures),
    }
end

local function export_jwt(obj)
    return table.concat({
        O.from_string(JSON.raw_encode(export_str_dict(obj.header), true)):url64(),
        O.from_string(JSON.raw_encode(export_str_dict(obj.payload), true)):url64(),
        O.to_url64(obj.signature),
    }, ".")
end

local function export_signed_selective_disclosure(obj)
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
        jwk = {
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
        selective_disclosure = {
            import = import_selective_disclosure,
            export = export_selective_disclosure,
        },
        decoded_selective_disclosure = {
            import = import_decoded_selective_disclosure,
            export = export_decoded_selective_disclosure,
        },
        signed_selective_disclosure = {
            import = import_signed_selective_disclosure,
            export = export_signed_selective_disclosure,
        }
    }
)


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

    local credential
    for _,v in pairs(ssd.credential_configurations_supported) do
        if v.vct == id then credential = v end
    end
    zencode_assert(credential, "Unknown credential id")
    local claims = credential.claims
    local fields = {}
    for k,_ in pairs(claims) do
        table.insert(fields, O.from_str(k))
    end
    ACK.selective_disclosure_request = {
        fields = fields,
        object = object,
    }
    new_codec("selective_disclosure_request")
end)

When("create selective disclosure of ''", function(sdr_name)
    local sdr = have(sdr_name)
    local sdp = SD_JWT.create_sd(sdr)
    ACK.selective_disclosure = sdp
    new_codec('selective_disclosure')
end)

When("create signed selective disclosure of ''", function(sdp_name)
    local p256 <const> = havekey'es256'
    local sdp <const> = have(sdp_name)
    ACK.signed_selective_disclosure =
        {
            jwt = SD_JWT.create_jwt(
                sdp.payload, p256,
                { sign = ES256.sign,
                  name = 'ES256' }),
            disclosures = sdp.disclosures,
        }
    new_codec('signed_selective_disclosure')
end)

When("create signed selective disclosure of '' with ''",
     function(sdp_name, algo)
    local sk <const> = havekey(algo:lower())
    local sdp <const> = have(sdp_name)
    local alg <const> = algo:upper()
    local crypto = { }
    if alg == 'ES256' then
        crypto.sign = ES256.sign
    elseif alg == 'EDDSA' then
        crypto.sign = ED.sign
    elseif alg == 'MLDSA44' then
        crypto.sign = QP.mldsa44_signature
    elseif alg == 'SECP256K1' then
        crypto.sign = ECDH.sign
    end
    if not crypto.sign then
        error("Unsupported SD-JWT signature: "..algo)
    end
    crypto.name = alg
    ACK.signed_selective_disclosure =
        {
            jwt = SD_JWT.create_jwt(sdp.payload, sk, crypto),
            disclosures = sdp.disclosures,
        }
    new_codec('signed_selective_disclosure')
end)

When("use signed selective disclosure '' only with disclosures ''", function(ssd_name, lis)
    local ssd = have(ssd_name)
    local disclosed_keys = have(lis)
    local disclosure = SD_JWT.retrive_disclosures(ssd, disclosed_keys)
    ssd.disclosures = disclosure
end)

IfWhen("verify disclosures '' are found in signed selective disclosure ''", function(lis, ssd_name)
    local ssd = have(ssd_name)
    local disclosed_keys, c_disclosed_keys = have(lis)
    zencode_assert(c_disclosed_keys.zentype ~= 'd', "Disclosures must be a single value or an array")
    if c_disclosed_keys.zentype == 'e' then
        zencode_assert(type(disclosed_keys) == 'zenroom.octet', "Disclosures must a single value or an array")
        disclosed_keys = {disclosed_keys}
    end
    for _,k in pairs(disclosed_keys) do
        local found = false
        for _, v in pairs(ssd.disclosures) do
            if v[2] == k then
                found = true
                break
            end
        end
        zencode_assert(found, "Disclosure key not found: "..k:octet():string())
    end
end)

-- for reference see Section 8.1 of https://datatracker.ietf.org/doc/draft-ietf-oauth-selective-disclosure-jwt/
IfWhen("verify signed selective disclosure '' issued by '' is valid", function(obj, by)
    local signed_sd = have(obj)
    local iss_pk = load_pubkey_compat(by, 'es256')
    local jwt = signed_sd.jwt
    local disclosures = signed_sd.disclosures
-- Ensure that a signing algorithm was used that was deemed secure for the application.
-- TODO: may break due to non-alphabetic sorting of header elements
    zencode_assert(SD_JWT.verify_jws_header(jwt), "The JWT header is not valid")

-- Check that the _sd_alg claim value is understood and the hash algorithm is deemed secure.
    zencode_assert(SD_JWT.verify_sd_alg(jwt), "The hash algorithm is not supported")

-- Check that the sd-jwt contains all the mandatory claims
-- TODO: break due to non-alphabetic sorting of string dictionary
-- elements when re-encoded to JSON. The payload may be a nested
-- dictionary at 3 or more depth.
    zencode_assert(SD_JWT.check_mandatory_claim_names(jwt.payload), "The JWT payload does not contain the mandatory claims")

-- Process the Disclosures and embedded digests in the Issuersigned JWT and compare the value with the digests calculated
-- Disclosures are an array and sorting is kept so this validation passes.
    zencode_assert(SD_JWT.verify_sd_fields(jwt.payload, disclosures), "The disclosure is not valid")

-- Validate the signature over the Issuer-signed JWT.
-- TODO: break due to non-alphabetic sorting of objects mentioned above in this function
    zencode_assert(SD_JWT.verify_jws_signature(jwt, iss_pk), "The issuer signature is not valid")

-- TODO?: Validate the Issuer and that the signing key belongs to this Issuer.

    zencode_assert(os, 'Could not find os to check timestamps')
    local time_now = TIME.new(os.time())
    if(jwt.payload.iat) then
        zencode_assert(jwt.payload.iat < time_now, 'The iat claim is not valid')
    end
    if(jwt.payload.exp) then
        zencode_assert(jwt.payload.exp > time_now, 'The exp claim is not valid')
    end
    if(jwt.payload.nbf) then
        zencode_assert(jwt.payload.nbf < time_now, 'The nbf claim is not valid')
    end

end)

When("create disclosed kv from signed selective disclosure ''", function(ssd_name)
    local ssd, ssd_c = have(ssd_name)
    zencode_assert(ssd_c.schema and ssd_c.schema == "signed_selective_disclosure",
        "Object is not a signed selective disclosure: " .. ssd_name)
    local disclosed_kv = {}
    for _, v in pairs(ssd.disclosures) do
        disclosed_kv[v[2]:str()] = v[3]
    end
    ACK.disclosed_kv = disclosed_kv
    new_codec('disclosed kv', {
        encoding = 'string',
        luatype = 'table',
        zentype = 'd'
    })
end)
