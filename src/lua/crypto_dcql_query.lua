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
--on Friday, 17th October 2025
--]]

local W3C = require_once'crypto_w3c'

local DCQL = {
    check_fn = {}
}

-----------------------------------
-- Validation of dcql_query objects

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
-- utility functions
local function is_nonempty_array(x)
    local n <const> = isarray(x)
    return type(n) == "number" and n > 0
end

local function is_nonempty_string(x)
    return type(x) == "string" and #x > 0
end

-- check correctness of a dcql_query object
function DCQL.validate_query(obj)
    if type(obj) ~= 'table' then
        error('Invalid dcql_query: not a table', 3)
    end
    -- credentials: REQUIRED
    local credentials <const> = obj.credentials
    if is_nonempty_array(credentials) == false then
        error('Invalid dcql_query: missing credentials array', 3)
    end
    local id_set = {}
    for _, cred in ipairs(credentials) do
        if not isdictionary(cred) then
            error('Invalid dcql_query: credential is not a dictionary', 3)
        end
        -- id: REQUIRED
        if type(cred.id) ~= 'string' or not cred.id:match("^[%w_-]+$") or id_set[cred.id] then
            error('Invalid dcql_query: missing or invalid credential id', 3)
        end
        id_set[cred.id] = true
        -- format: REQUIRED
        if type(cred.format) ~= 'string' or not supported_credential_formats[cred.format] then
            error('Invalid dcql_query: missing or invalid credential format', 3)
        end
        -- multiple: OPTIONAL (default: false)
        if cred.multiple ~= nil then
            if type(cred.multiple) ~= 'boolean' then
                error('Invalid dcql_query: invalid multiple field, it must be a boolean', 3)
            end
        end
        -- meta: REQUIRED
        if not isdictionary(cred.meta) then
            error('Invalid dcql_query: missing meta object', 3)
        end
        if cred.format == 'ldp_vc' or cred.format == 'jwt_vc_json' then
            -- type_values: REQUIRED for ldp_vc
            if not is_nonempty_array(cred.meta.type_values) then
                error('Invalid dcql_query: missing or invalid meta.type_values array', 3)
            end
            for _, tv_array in ipairs(cred.meta.type_values) do
                if not is_nonempty_array(tv_array) then
                    error('Invalid dcql_query: invalid meta.type_values element, it must be a non-empty array', 3)
                end
                for _, tv in ipairs(tv_array) do
                    if not is_nonempty_string(tv) then
                        error('Invalid dcql_query: invalid meta.type_values value, it must be a non-empty string', 3)
                    end
                end
            end
        elseif cred.format == 'dc+sd-jwt' then
            -- vct_values: REQUIRED for dc+sd-jwt
            if not is_nonempty_array(cred.meta.vct_values) then
                error('Invalid dcql_query: missing or invalid meta.vct_values array, it must be a non-empty array', 3)
            end
            for _, vct in ipairs(cred.meta.vct_values) do
                if not is_nonempty_string(vct) then
                    error('Invalid dcql_query: invalid meta.vct_values element, it must be a non-empty string', 3)
                end
            end
        elseif cred.format == 'mso_mdoc' then
            -- doctype_value: REQUIRED for mso_mdoc
            if not is_nonempty_string(cred.meta.doctype_value) then
                error('Invalid dcql_query: missing or invalid meta.doctype_value, it must be a non-empty string', 3)
            end
        end
        -- trusted_authorities: OPTIONAL
        if cred.trusted_authorities ~= nil then
            if not is_nonempty_array(cred.trusted_authorities) then
                error('Invalid dcql_query: invalid trusted_authorities array', 3)
            end
            for _, v in ipairs(cred.trusted_authorities) do
                if not isdictionary(v) then
                    error('Invalid dcql_query: trusted_authorities element is not a dictionary', 3)
                end
                if not v.type or type(v.type) ~= 'string' or not supported_credential_ta_types[v.type] then
                    error('Invalid dcql_query: missing or invalid trusted_authorities.type', 3)
                end
                if not v.values or not is_nonempty_array(v.values) then
                    error('Invalid dcql_query: missing or invalid trusted_authorities.values array', 3)
                end
                for k, _ in ipairs(v) do
                    if k ~= 'type' and k ~= 'values' then
                        error('Invalid dcql_query: unknown field in trusted_authorities: ' .. k, 3)
                    end
                end
            end
        end
        -- require_cryptographic_holder_binding: OPTIONAL (default: true)
        if cred.require_cryptographic_holder_binding ~= nil then
            if type(cred.require_cryptographic_holder_binding) ~= 'boolean' then
                error('Invalid dcql_query: invalid require_cryptographic_holder_binding field, it must be a boolean', 3)
            end
        end
        -- claims: OPTIONAL
        local claims_id_set = {}
        if cred.claims ~= nil then
            if not is_nonempty_array(cred.claims) then
                error('Invalid dcql_query: invalid claims array', 3)
            end
            for _, claim in ipairs(cred.claims) do
                if not isdictionary(claim) then
                    error('Invalid dcql_query: claim is not a dictionary', 3)
                end
                -- id: REQUIRED if claim_sets is present
                if cred.claim_sets ~= nil or claim.id then
                    if type(claim.id) ~= 'string' or not claim.id:match("^[%w_-]+$") or claims_id_set[claim.id] then
                         error('Invalid dcql_query: missing or invalid claim id', 3)
                    end
                    claims_id_set[claim.id] = true
                end
                -- path: REQUIRED
                if not is_nonempty_array(claim.path) then
                    error('Invalid dcql_query: missing or invalid claim.path array', 3)
                end
                -- values: OPTIONAL
                if claim.values ~= nil then
                    if not is_nonempty_array(claim.values) then
                        error('Invalid dcql_query: invalid claim.values array', 3)
                    end
                    for _, v in ipairs(claim.values) do
                        if not (type(v) == 'string' or type(v) == 'number' or type(v) == 'boolean') then
                             error('Invalid dcql_query: invalid claim.values value, it must be a string, number or boolean', 3)
                        end
                    end
                end
            end
        end
        -- claim_sets: OPTIONAL
        if cred.claim_sets ~= nil then
            -- claim_sets must be abstent if claims is absent
            if cred.claims == nil then
                error('Invalid dcql_query: claim_sets present but claims is absent', 3)
            end
            if not is_nonempty_array(cred.claim_sets) then
                error('Invalid dcql_query: invalid claim_sets array', 3)
            end
            for _, claim_set in ipairs(cred.claim_sets) do
                if not is_nonempty_array(claim_set) then
                    error('Invalid dcql_query: claim_set is not a non-empty array', 3)
                end
                for _, claim_id in ipairs(claim_set) do
                    if type(claim_id) ~= 'string' or not claims_id_set[claim_id] then
                        error('Invalid dcql_query: claim_set element is not a string', 3)
                    end
                end
            end
        end
    end
    -- credential_sets: OPTIONAL
    if obj.credential_sets ~= nil then
        if not is_nonempty_array(obj.credential_sets) then
            error('Invalid dcql_query: invalid credential_sets array', 3)
        end
        for _, credential_set in ipairs(obj.credential_sets) do
            if not isdictionary(credential_set) then
                error('Invalid dcql_query: credential_set is not a dictionary', 3)
            end
            -- options: REQUIRED
            if not is_nonempty_array(credential_set.options) then
                error('Invalid dcql_query: missing or invalid credential_set.options array', 3)
            end
            for _, option_array in ipairs(credential_set.options) do
                if not is_nonempty_array(option_array) then
                    error('Invalid dcql_query: invalid credential_set.options element, it must be a non-empty array', 3)
                end
                for _, option in ipairs(option_array) do
                    if type(option) ~= 'string' or not id_set[option] then
                        error('Invalid dcql_query: invalid credential_set.options element, it must be a string', 3)
                    end
                end
            end
            -- required: OPTIONAL (default: true)
            if credential_set.required ~= nil then
                if type(credential_set.required) ~= 'boolean' then
                    error('Invalid dcql_query: invalid credential_set.required field, it must be a boolean', 3)
                end
            end
        end
    end
end


-----------------------------------
-- check functions for dcql_query matching

local _map_to_type <const> = get_encoding_function("string")

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

local function _encode_dcsdjwt(obj_cred)
    local records = {
        table.concat(
            {O.from_string(JSON.raw_encode(deepmap(_map_to_type, obj_cred.header), true)):url64(),
             O.from_string(JSON.raw_encode(deepmap(_map_to_type, obj_cred.payload), true)):url64(),
             O.to_url64(obj_cred.signature),
            }, ".")
    }
    for _, d in pairs(obj_cred.disclosures) do
        table.insert(records, O.from_string(JSON.raw_encode(d, true)):url64())
    end
    return O.from_string(table.concat(records, "~") .. "~")
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

local function _validate_claim_ldp_vc(claim, cred)
    local path <const> = claim.path
    local values <const> = claim.values

    local root = _map_to_type(_check_path(path, cred[path[1]]))
    if root == nil then
        warn("Credential does not have the required path: " .. table.concat(path, '.'))
        return false
    end
    if values and #values > 0 then
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
    return true
end

local function _build_claim_path_sets(claims, cred, stop_on_fail)
    local claim_path_sets = {}
    for _, claim in ipairs(claims) do
        if not _validate_claim_ldp_vc(claim, cred) then
            if stop_on_fail then
                return nil, false
            else
                return nil, true
            end
        end
        table.insert(claim_path_sets, claim.path)
    end
    return claim_path_sets, true
end

-- ldp_vc checker
DCQL.check_fn.ldp_vc = function(cred, string_query, out)
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
    if string_query.claim_sets ~= nil then
        for _, sets in ipairs(string_query.claim_sets) do
            local claims = {}
            for _, claim_id in ipairs(sets) do
                local found
                for _, c in ipairs(string_query.claims) do
                    if c.id == claim_id then
                        found = c
                        break
                    end
                end
                if found == nil then
                    warn("Claim id in claim_sets not found in claims: " .. claim_id)
                    goto continue_set
                end
                table.insert(claims, found)
            end
            local claim_path_sets, valid <const> = _build_claim_path_sets(claims, cred, false)
            if valid and claim_path_sets then
                table.insert(out[string_query.id], {
                    credential = cred,
                    claim_path_sets = deepmap(O.from_string, claim_path_sets)
                })
            end
            ::continue_set::
        end
    else
        local claim_path_sets, valid = build_claim_path_sets(string_query.claims, cred, true)
        if not valid or not claim_path_sets then return false end
        table.insert(out[string_query.id], {
            credential = cred,
            claim_path_sets = deepmap(O.from_string, claim_path_sets)
        })
    end
end

local function _validate_claim_dcsdjwt(parsed, claim, selected_disclosures, stop_on_fail)
    local path <const> = claim.path
    local values <const> = claim.values
    -- Try matching in disclosures first
    for _, d in ipairs(parsed.disclosures) do
        if path[1] == d[2] then
            local root = _check_path(path, d[3])
            if root ~= nil then
                if values and #values > 0 then
                    local ok = false
                    for _, v in ipairs(values) do
                        if root == v then
                            ok = true
                            break
                        end
                    end
                    if not ok then
                        warn("Credential value does not match required values for path: " .. table.concat(path, '.'))
                        return false
                    end
                end
                table.insert(selected_disclosures, d)
                return true
            end
        end
    end
    -- Try matching in payload
    local root = _map_to_type(_check_path(path, parsed.payload[path[1]]))
    if root == nil then
        warn("Credential does not have the required path: " .. table.concat(path, '.'))
        return false
    end
    if values and #values > 0 then
        for _, v in ipairs(values) do
            if root == v then
                return true
            end
        end
        warn("Credential value does not match required values for path: " .. table.concat(path, '.'))
        return false
    end
    return true
end

local function _build_claim_path_sets_and_disclosures(parsed, claims, stop_on_fail)
    local claim_path_sets = {}
    local selected_disclosures = {}
    for _, claim in ipairs(claims) do
        if not _validate_claim_dcsdjwt(parsed, claim, selected_disclosures, stop_on_fail) then
            if stop_on_fail then
                return nil, nil, false
            else
                return nil, nil, true  -- skip set
            end
        end
        table.insert(claim_path_sets, claim.path)
    end
    return claim_path_sets, selected_disclosures, true
end

-- dc+sd-jwt checker
DCQL.check_fn['dc+sd-jwt'] = function(cred, string_query, out)
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
    if string_query.claim_sets ~= nil then
        for _, sets in ipairs(string_query.claim_sets) do
            local claims = {}
            for _, claim_id in ipairs(sets) do
                local found
                for _, c in ipairs(string_query.claims) do
                    if c.id == claim_id then
                        found = c
                        break
                    end
                end
                if found == nil then
                    warn("Claim id in claim_sets not found in claims: " .. claim_id)
                    goto continue_set
                end
                table.insert(claims, found)
            end
            local claim_path_sets, selected_disclosures, valid <const> = _build_claim_path_sets_and_disclosures(parsed_cred, claims, false)
            if valid and claim_path_sets then
                parsed_cred.disclosures = selected_disclosures
                table.insert(out[string_query.id], {
                    credential = _encode_dcsdjwt(parsed_cred),
                    claim_path_sets = deepmap(O.from_string, claim_path_sets)
                })
            end
            ::continue_set::
        end
    else
        local claim_path_sets, selected_disclosures, valid <const> = _build_claim_path_sets_and_disclosures(parsed_cred, string_query.claims, true)
        if not valid or not claim_path_sets then return false end
        parsed_cred.disclosures = selected_disclosures
        table.insert(out[string_query.id], {
            credential = _encode_dcsdjwt(parsed_cred),
            claim_path_sets = deepmap(O.from_string, claim_path_sets)
        })
    end
end

return DCQL
