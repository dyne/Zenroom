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

--[[
Example of dcql_query to eliminate before merging:
- {
  "credentials": [
    {
      "id": "my_credential",
      "format": "dc+sd-jwt",
      "meta": {
        "vct_values": [
          "discount_from_voucher"
        ]
      },
      "claims": [
        {
          "path": [
            "has_discount_from_voucher"
          ],
          "values": [
            "20",
            "30"
          ]
        }
      ]
    },
    {
      "id": "my_other_credential",
      "format": "ldp_vc",
      "meta": {
        "type_values": [
          "discountCredential"
        ]
      },
      "claims": [
        {
          "path": [
            "credentialSubject",
            "discountPercentage"
          ],
          "values": [
            "20",
            "30"
          ]
        }
      ]
    }
  ]
}
- {
  "credentials": [
    {
      "id": "my_credential",
      "format": "ldp_vc",
      "meta": {
        "type_values": [
          [
            "questionnaire"
          ]
        ]
      },
      "claims": [
        {
          "path": [
            "credentialSubject",
            "formid"
          ],
          "values": []
        },
        {
          "path": [
            "credentialSubject",
            "instanceid"
          ],
          "values": []
        },
        {
          "path": [
            "credentialSubject",
            "submissiondate"
          ],
          "values": []
        }
      ]
    }
  ]
}
--]]

-- TODO: create a schema to validate dcql_query in input


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
        dcql_query_codec.encoding == 'string' and
        dcql_query_codec.zentype == 'd',
        "Invalid dcql_query, it must be a string dictionary: "..dcql
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
