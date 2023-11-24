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
--Last modified by Denis Roio
--on Wednesday, 14th July 2021
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
            I.spy(creds[i])
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



ZEN:add_schema(
    {
        supported_selective_disclosure = {
            import = import_supported_selective_disclosure,
            export = export_supported_selective_disclosure
        }
    }
)

