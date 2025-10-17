--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2025 Dyne.org foundation
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
--on Tuesday, 14th October 2025
--]]

local W3C = require_once'crypto_w3c'

local supported_credential_formats <const> = {
    jwt_vc_json = true,
    ldp_vc = true,
    mso_mdoc = true,
    ['dc+sd-jwt'] = true
}
local supported_credential_ta_types <const> = {
    aki = true,
    etsi_tl = true,
    openid_federation = true
}

local function _map_from_type(v)
    if type(v) == "number" then
        return F.new(v)
    elseif type(v) == "boolean" then
        return v
    else
        return O.from_string(v)
    end
end

local function _map_to_type(v)
    if type(v) == "zenroom.float" then
        return tonumber(tostring(v))
    elseif type(v) == "boolean" then
        return v
    else
        return O.to_string(v)
    end
end

local function is_nonempty_array(x)
    local n <const> = isarray(x)
    return type(n) == "number" and n > 0
end

local function is_nonempty_string(x)
    return type(x) == "string" and #x > 0
end

local function import_dcql_query(obj)
    zencode_assert(type(obj) == 'table', 'Invalid dcql_query: not a table')
    -- credentials: REQUIRED
    local credentials <const> = obj.credentials
    zencode_assert(
        is_nonempty_array(credentials),
        'Invalid dcql_query: missing credentials array'
    )
    local id_set = {}
    for _, cred in ipairs(credentials) do
        zencode_assert(
            isdictionary(cred),
            'Invalid dcql_query: credential is not a dictionary'
        )
        -- id: REQUIRED
        zencode_assert(
            type(cred.id) == 'string' and cred.id:match("^[%w_-]+$") and not id_set[cred.id],
            'Invalid dcql_query: missing or invalid credential id'
        )
        id_set[cred.id] = true
        -- format: REQUIRED
        zencode_assert(
            type(cred.format) == 'string' and supported_credential_formats[cred.format],
            'Invalid dcql_query: missing or invalid credential format'
        )
        -- multiple: OPTIONAL (default: false)
        if cred.multiple ~= nil then
            zencode_assert(
                type(cred.multiple) == 'boolean',
                'Invalid dcql_query: invalid multiple field, it must be a boolean'
            )
        end
        -- meta: REQUIRED
        zencode_assert(
            isdictionary(cred.meta),
            'Invalid dcql_query: missing meta object'
        )
        if cred.format == 'ldp_vc' or cred.format == 'jwt_vc_json' then
            -- type_values: REQUIRED for ldp_vc
            zencode_assert(
                is_nonempty_array(cred.meta.type_values),
                'Invalid dcql_query: missing or invalid meta.type_values array'
            )
            for _, tv_array in ipairs(cred.meta.type_values) do
                zencode_assert(
                    is_nonempty_array(tv_array),
                    'Invalid dcql_query: invalid meta.type_values element, it must be a non-empty array'
                )
                for _, tv in ipairs(tv_array) do
                    zencode_assert(
                        is_nonempty_string(tv),
                        'Invalid dcql_query: invalid meta.type_values value, it must be a non-empty string'
                    )
                end
            end
        elseif cred.format == 'dc+sd-jwt' then
            -- vct_values: REQUIRED for dc+sd-jwt
            zencode_assert(
                is_nonempty_array(cred.meta.vct_values),
                'Invalid dcql_query: missing or invalid meta.vct_values array, it must contain at least one value'
            )
            for _, vct in ipairs(cred.meta.vct_values) do
                zencode_assert(
                    is_nonempty_string(vct),
                    'Invalid dcql_query: invalid meta.vct_values value, it must be a non-empty string'
                )
            end
        elseif cred.format == 'mso_mdoc' then
            -- doctype_value: REQUIRED for mso_mdoc
            zencode_assert(
                is_nonempty_string(cred.meta.doctype_value),
                'Invalid dcql_query: missing or invalid meta.doctype_value, it must be a non-empty string'
            )
        end
        -- trusted_authorities: OPTIONAL
        if cred.trusted_authorities ~= nil then
            zencode_assert(
                is_nonempty_array(cred.trusted_authorities),
                'Invalid dcql_query: invalid trusted_authorities array'
            )
            for _, v in ipairs(cred.trusted_authorities) do
                zencode_assert(
                    v.type and type(v.type) == 'string' and supported_credential_ta_types[v.type],
                    'Invalid dcql_query: invalid trusted_authorities.type'
                )
                zencode_assert(
                    v.values and is_nonempty_array(v.values),
                    'Invalid dcql_query: invalid trusted_authorities.id'
                )
                for k, _ in ipairs(v) do
                    zencode_assert(
                        k == 'type' or k == 'values',
                        'Invalid dcql_query: unknown field in trusted_authorities: ' .. k
                    )
                end
            end
        end
        -- require_cryptographic_holder_binding: OPTIONAL (default: true)
        if cred.require_cryptographic_holder_binding ~= nil then
            zencode_assert(
                type(cred.require_cryptographic_holder_binding) == 'boolean',
                'Invalid dcql_query: invalid require_cryptographic_holder_binding field, it must be a boolean'
            )
        end
        -- claims: OPTIONAL
        local claims_id_set = {}
        if cred.claims ~= nil then
            zencode_assert(
                is_nonempty_array(cred.claims),
                'Invalid dcql_query: invalid claims array'
            )
            for _, claim in ipairs(cred.claims) do
                zencode_assert(
                    isdictionary(claim),
                    'Invalid dcql_query: claim is not a dictionary'
                )
                -- id: REQUIRED if claim_sets is present
                if cred.claim_sets ~= nil or claim.id then
                    zencode_assert(
                        type(claim.id) == 'string' and claim.id:match("^[%w_-]+$") and not claims_id_set[claim.id],
                        'Invalid dcql_query: missing or invalid claim id'
                    )
                    claims_id_set[claim.id] = true
                end
                -- path: REQUIRED
                zencode_assert(
                    is_nonempty_array(claim.path),
                    'Invalid dcql_query: invalid claim.path array'
                )
                -- values: OPTIONAL
                if claim.values ~= nil then
                    zencode_assert(
                        is_nonempty_array(claim.values),
                        'Invalid dcql_query: invalid claim.values array'
                    )
                    for _, v in ipairs(claim.values) do
                        zencode_assert(
                            type(v) == 'string' or type(v) == 'number' or type(v) == 'boolean',
                            'Invalid dcql_query: invalid claim.values value, it must be a string, number or boolean'
                        )
                    end
                end
            end
        end
        -- claim_sets: OPTIONAL
        if cred.claim_sets ~= nil then
            -- claim_sets must be abstent if claims is absent
            zencode_assert(
                cred.claims ~= nil,
                'Invalid dcql_query: claim_sets present but claims is absent'
            )
            zencode_assert(
                is_nonempty_array(cred.claim_sets),
                'Invalid dcql_query: invalid claim_sets array'
            )
            for _, claim_set in ipairs(cred.claim_sets) do
                zencode_assert(
                    is_nonempty_array(claim_set),
                    'Invalid dcql_query: claim_set is not a non-empty array'
                )
                for _, claim_id in ipairs(claim_set) do
                    zencode_assert(
                        type(claim_id) == 'string' and claims_id_set[claim_id],
                        'Invalid dcql_query: invalid claim_set claim id reference'
                    )
                end
            end
        end
    end
    -- credential_sets: OPTIONAL
    if obj.credential_sets ~= nil then
        zencode_assert(
            is_nonempty_array(obj.credential_sets),
            'Invalid dcql_query: invalid credential_sets array'
        )
        for _, credential_set in ipairs(obj.credential_sets) do
            zencode_assert(
                isdictionary(credential_set),
                'Invalid dcql_query: credential_set is not a dictionary'
            )
            -- options: REQUIRED
            zencode_assert(
                credential_set.options and is_nonempty_array(credential_set.options),
                'Invalid dcql_query: invalid credential_set.options array'
            )
            for _, option_array in ipairs(credential_set.options) do
                zencode_assert(
                    is_nonempty_array(option_array),
                    'Invalid dcql_query: invalid credential_set.options element, it must be a non-empty array'
                )
                for _, option in ipairs(option_array) do
                    zencode_assert(
                        type(option) == 'string' and id_set[option],
                        'Invalid dcql_query: invalid credential_set.options reference'
                    )
                end
            end
            -- required: OPTIONAL (default: true)
            if credential_set.required ~= nil then
                zencode_assert(
                    type(credential_set.required) == 'boolean',
                    'Invalid dcql_query: invalid credential_set.required field, it must be a boolean'
                )
            end
        end
    end
    return schema_get(obj, '.', nil, _map_from_type)
end

local function export_dcql_query(obj)
    return deepmap(_map_to_type, obj)
end

ZEN:add_schema(
    {
        dcql_query = {
            import = import_dcql_query,
            export = export_dcql_query
        }
    }
)

-- helper functions
local function _parse_dcsdjwt(string_cred)
    local toks <const> = strtok(string_cred, "~")
    local disclosures = {}
    for i=2, #toks do
        disclosures[#disclosures + 1] = JSON.raw_decode(O.from_url64(toks[i]):str())
    end
    local jwt <const> = W3C.import_jwt(toks[1])
    return {
        header = jwt.header,
        payload = jwt.payload,
        signature = jwt.signature,
        disclosures = disclosures,
    }
end

local function _check_path(path, root)
    for i = 2, #path do
        if type(root) ~= "table" or root[path[i]] == nil then
            return nil
        end
        root = root[path[i]]
    end
    return root
end

local function _map_to_type(v)
    if type(v) == "zenroom.float" then
        return tonumber(tostring(v))
    elseif type(v) == "boolean" then
        return v
    else
        return O.to_string(v)
    end
end

-- ldp_vc checker
local function _check_ldp_vc(cred, string_query)
    if cred['@context'] == nil or
       cred['type'] == nil or
       cred['credentialSubject'] == nil then
        warn("Invalid credential, missing @context or type or credentialSubject")
        return false
    end
    -- match type_values
    local cred_type <const> = cred.type
    local type_values <const> = string_query.meta.type_values
    local c_set = {}
    for _, v in ipairs(cred_type) do c_set[v:string()] = true end
    local type_found = false
    for _, tv_array in ipairs(type_values) do
        local all_match = true
        for _, tv in ipairs(tv_array) do
            if not c_set[tv] then
                all_match = false
                break
            end
        end
        if all_match then
            type_found = true
            break
        end
    end
    if not type_found then
        warn("Credential type does not match any of the required type_values")
        return false
    end
    -- not expired
    local cred_validUntil <const> = zulu2timestamp(cred.validUntil)
    local now <const> = TIME.new(os.time())
    if (now > cred_validUntil) then
        warn("Credential is expired")
        return false
    end
    -- match claims
    for _, claim in ipairs(string_query.claims) do
        local root = cred
        local path <const> = claim.path
        local values <const> = claim.values
        -- path exists
        local root = _map_to_type(_check_path(path, root[path[1]]));
        if root == nil then
            warn("Credential does not have the required path: " .. table.concat(path, '.'))
            return false
        end
        -- if values is specified, check that the value under the path matches one of them
        if values and (#values > 0) then
            local value_found = false
            for _, v in ipairs(values) do
                if root == v then
                    value_found = true
                    break
                end
            end
            if not value_found then
                warn("Credential value does not match any of the required values for path: " .. table.concat(path, '.'))
                return false
            end
        end
    end
    return true
end

-- dc+sd-jwt checker
local function _check_dcsdjwt(cred, string_query)
    local parsed_cred <const> = _parse_dcsdjwt(cred:string())
    -- match vct_values
    local cred_vct <const> = (parsed_cred.payload.vct or parsed_cred.payload.type):string()
    local vct_values <const> = string_query.meta.vct_values
    if cred_vct ~= vct_values[1] then
        warn("Invalid credential, vct does not match: " .. cred_vct .. " != " .. vct_values[1])
        return false
    end
    -- not expired
    local cred_exp <const> = TIME.new(parsed_cred.payload.exp)
    local now <const> = TIME.new(os.time())
    if (now > cred_exp) then
        warn("Credential is expired")
        return false
    end
    -- match claims
    for _, claim in ipairs(string_query.claims) do
        local path <const> = claim.path
        local values <const> = claim.values
        local claim_path_found = false
        -- path exists
        for _, d in ipairs(parsed_cred.disclosures) do
            if path[1] == d[2] then
                local root = _check_path(path, d[3])
                if root == nil then goto continue end
                if values and (#values > 0) then
                    local value_found = false
                    for _, v in ipairs(values) do
                        if root == v then
                            value_found = true
                            break
                        end
                    end
                    if not value_found then
                        warn("Credential value does not match any of the required values for path: " .. table.concat(path, '.'))
                        return false
                    end
                end
                claim_path_found = true
                break
            end
            ::continue::
        end
        if not claim_path_found then
            local root = _map_to_type(_check_path(path, parsed_cred.payload[path[1]]));
            if root ~= nil then
                if values and (#values > 0) then
                    local value_found = false
                    for _, v in ipairs(values) do
                        if root == v then
                            value_found = true
                            break
                        end
                    end
                    if value_found then
                        claim_path_found = true
                    end
                else
                    claim_path_found = true
                end
            end
        end
        if not claim_path_found then
            warn("Credential does not have the required path: " .. table.concat(path, '.'))
            return false
        end
    end
    return true
end

local checkers = {
    ldp_vc = _check_ldp_vc,
    ['dc+sd-jwt'] = _check_dcsdjwt
}

-- credential list is a dictionary where the fields are the type of credential
-- and the values are arrays of credentials of that type (maybe a schema can be created for this)
When("create matching credentials from '' matching dcql_query ''", function(creds, dcql)
    empty('matching credentials')
    local credentials, credentials_codec <const> = have(creds)
    zencode_assert(
        credentials_codec.zentype == 'd',
        "Invalid credential list, it must be an dictionary: "..creds
    )
    local dcql_query, dcql_query_codec <const> = have(dcql)
    zencode_assert(
        dcql_query_codec.schema == 'dcql_query' and dcql_query_codec.zentype == 'e', 
        "Invalid dcql_query: "..dcql
    )
    local out = {}
    for _, query in pairs(dcql_query.credentials) do
        local string_query <const> = deepmap(_map_to_type, query)
        out[string_query.id] = {}
        local matching_credentials <const> = credentials[string_query.format]
        if matching_credentials == nil then
            goto continue
        end
        local checker <const> = checkers[string_query.format]
        if not checker then
            error("Credential format not yet suppoerted: " .. string_query.format)
        end
        for _, cred in ipairs(matching_credentials) do
            if checker(cred, string_query) then
                table.insert(out[string_query.id], cred)
            end
        end
        ::continue::
    end
    ACK.matching_credentials = out
    new_codec('matching_credentials', { zentype = 'd', encoding = 'string' })
end)
