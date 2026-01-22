--[[
--This file is part of Zenroom
--
--Copyright (C) 2023-2026 Dyne.org foundation
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

local SD_JWT = require_once'crypto_sd_jwt'
local W3C = require_once'crypto_w3c'

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
    local check_support = function(o, what, needed)
        local found = false
        if(type(o[what]) == 'table') then
            for k,v in pairs(o[what]) do
               if v == needed[k] then
                    found = true
                    break
               end 
            end
        else
            if (type(needed) == 'table') then
                for _,v in pairs(needed) do
                    if o[what] == v then
                        found = true
                        break
                    end
                end
            else
                found = o[what] == needed
            end
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
        check_support(v, 'format', {'ldp_vc','dc+sd-jwt'})
        if v.format == 'dc+sd-jwt' then
            check_support(v, 'credential_signing_alg_values_supported', {'ES256','EDDSA','MLDSA44','SECP256K1'})
            if (not v.vct) then
                error("Invalid supported selective disclosure: missing parameter vct", 2)
            end
        end
        if v.format == 'ldp_vc' then check_support(v, 'credential_signing_alg_values_supported', {'Ed25519Signature2018'}) end
        check_support(v, 'cryptographic_binding_methods_supported', {"jwk", "did:dyne:sandbox.signroom"})
        -- check_support(creds[i], 'proof_types_supported', {jwt = { proof_signing_alg_values_supported = {"ES256"}}})
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
        deepmap(function(o) return o:str() end,
            obj.credential_configurations_supported)
    return res
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
        local found = false
        for k in pairs(obj.object) do
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

local function import_signed_selective_disclosure(obj)
    zencode_assert(obj:sub(#obj, #obj) == '~', "JWT binding not implemented")
    local toks = strtok(obj, "~")
    local disclosures = {}
    for i=2,#toks do
        disclosures[#disclosures+1] = JSON.raw_decode(O.from_url64(toks[i]):str())
    end
    return {
        jwt = W3C.import_jwt(toks[1]),
        disclosures = import_str_dict(disclosures),
    }
end

local function export_signed_selective_disclosure(obj)
    local records = {
        table.concat(
            {O.from_string(JSON.raw_encode(export_str_dict(obj.jwt.header), true)):url64(),
             O.from_string(JSON.raw_encode(export_str_dict(obj.jwt.payload), true)):url64(),
             O.to_url64(obj.jwt.signature),
            }, ".")
    }
    for _, d in pairs(export_str_dict(obj.disclosures)) do
        table.insert(records, O.from_string(JSON.raw_encode(d, true)):url64())
    end
    return table.concat(records, "~") .. "~"
end

local function import_signed_selective_disclosure_wiht_kb(obj)
    local last_pos = obj:match(".*()~")
    if not last_pos then
        error("Invalid signed selective disclosure with key binding: " .. obj, 2)
    end
    local res = import_signed_selective_disclosure(obj:sub(1, last_pos))
    res.key_binding = W3C.import_jwt(obj:sub(last_pos+1))
    return res
end

local function export_signed_selective_disclosure_wiht_kb(obj)
    local ssd = export_signed_selective_disclosure(obj)
    local kb = W3C.export_jwt(obj.key_binding)
    return ssd .. kb
end

ZEN:add_schema(
    {
        supported_selective_disclosure = {
            import = import_supported_selective_disclosure,
            export = export_supported_selective_disclosure
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
        },
        signed_selective_disclosure_with_key_binding = {
            import = import_signed_selective_disclosure_wiht_kb,
            export = export_signed_selective_disclosure_wiht_kb,
        }
    }
)

When("create selective disclosure request from '' with id '' for ''", function(ssd_name, id_name, object_name)
    local ssd = have(ssd_name)
    local id = have(id_name)
    local object = have(object_name)

    local credential
    for _,v in pairs(ssd.credential_configurations_supported) do
        if v.vct == id then
            credential = v
            break
        end
    end
    zencode_assert(credential, "Unknown credential id: " .. id)
    local claims = credential.claims
    local fields = {}
    local already_included_fields = {}
    for _,v in pairs(claims) do
        local field = v.path[1]
        local field_string = field:string()
        if not already_included_fields[field_string] then
            table.insert(fields, field)
            already_included_fields[field_string] = true
        end
    end
    ACK.selective_disclosure_request = {
        fields = fields,
        object = object,
    }
    new_codec("selective_disclosure_request")
end)

When("create selective disclosure of ''", function(sdr_name)
    local sdr = have(sdr_name)
    local sdp = SD_JWT.create_sd(sdr) -- TODO: hash algo as arg
    ACK.selective_disclosure = sdp
    new_codec('selective_disclosure')
end)


When("create signed selective disclosure of ''", function(sdp_name)
    local sdp <const> = have(sdp_name)
    ACK.signed_selective_disclosure = {
        jwt = SD_JWT.create_jwt(sdp.payload,
                                havekey('es256'),
                                CRYPTO.load('es256')),
        disclosures = sdp.disclosures,
    }
    new_codec('signed_selective_disclosure')
end)

When("create signed selective disclosure of '' with ''",
     function(sdp_name, algo)
    local sdp <const> = have(sdp_name)
    local alg <const> = mayhave(algo)
    local crypto <const> = CRYPTO.load(alg or algo)
    ACK.signed_selective_disclosure = {
        jwt = SD_JWT.create_jwt(sdp.payload, havekey(crypto.keyname), crypto),
        disclosures = sdp.disclosures,
    }
    new_codec('signed_selective_disclosure')
end)

When("use signed selective disclosure '' only with disclosures ''", function(ssd_name, lis)
    local ssd = have(ssd_name)
    local disclosed_keys = have(lis)
    local all_dis <const> = ssd.disclosures
    local new_disclosures = { }
    for _,k in pairs(disclosed_keys) do
        for _, arr in pairs(all_dis) do
            if arr[2] == k then
                table.insert(new_disclosures, arr)
                break
            end
        end
    end
    ssd.disclosures = new_disclosures
end)

IfWhen("verify disclosures '' are found in signed selective disclosure ''", function(lis, ssd_name)
    local ssd = have(ssd_name)
    local disclosed_keys, c_disclosed_keys = have(lis)
    if not zencode_assert(c_disclosed_keys.zentype ~= 'd', "Disclosures must be a single value or an array") then return end
    if c_disclosed_keys.zentype == 'e' then
        if not zencode_assert(type(disclosed_keys) == 'zenroom.octet', "Disclosures must a single value or an array") then return end
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
        if not zencode_assert(found, "Disclosure key not found: "..k:octet():string()) then return end
    end
end)

-- for reference see Section 8.1 of https://datatracker.ietf.org/doc/draft-ietf-oauth-selective-disclosure-jwt/
IfWhen("verify signed selective disclosure '' issued by '' is valid", function(obj, by)
    local signed_sd <const> = have(obj)
    local jwt <const> = signed_sd.jwt
    local disclosures <const> = signed_sd.disclosures
    local algo <const> = jwt.header.alg:string()
    local crypto <const> = CRYPTO.load(algo)
    -- if jwt.header.alg == O.from_string("ES256") then
    local iss_pk <const> = load_pubkey_compat(by, algo:lower())
    local payload_str <const> = SD_JWT.prepare_dictionary(jwt.payload)
    local b64payload <const> = O.from_string(JSON.raw_encode(payload_str, true)):url64()
    local header_str <const> = SD_JWT.prepare_dictionary(jwt.header)
    local b64header <const> = O.from_string(JSON.raw_encode(header_str, true)):url64()

    -- jwt.payload._sd_alg == O.from_string("sha-256")

    -- Check that the sd-jwt contains all the mandatory claims
    -- TODO: break due to non-alphabetic sorting of string dictionary
    -- elements when re-encoded to JSON. The payload may be a nested
    -- dictionary at 3 or more depth.
    if not zencode_assert(
        SD_JWT.check_mandatory_claim_names(jwt.payload),
        "The JWT payload does not contain the mandatory claims") then return end

    -- Process the Disclosures and embedded digests in the Issuersigned JWT and compare the value with the digests calculated
    -- Disclosures are an array and sorting is kept so this validation passes.
    if not zencode_assert(
        SD_JWT.verify_sd_fields(jwt.payload, disclosures),
        "The disclosure is not valid") then return end

    if not zencode_assert(os, 'Could not find os to check timestamps') then return end
    local time_now = TIME.new(os.time())
    if(jwt.payload.iat) then
        if not zencode_assert(jwt.payload.iat < time_now, 'The iat claim is not valid') then return end
    end
    if(jwt.payload.exp) then
        if not zencode_assert(jwt.payload.exp > time_now, 'The exp claim is not valid') then return end
    end
    if(jwt.payload.nbf) then
        if not zencode_assert(jwt.payload.nbf < time_now, 'The nbf claim is not valid') then return end
    end

    if not zencode_assert(
        -- TODO?: Validate the Issuer and that the signing key belongs
        -- to this Issuer
        crypto.verify(iss_pk, O.from_string(b64header .. "." .. b64payload),
                      jwt.signature)
        ,
        "The issuer signature is not valid"
    ) then return end

    --TODO: check that issued at is not expired
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
