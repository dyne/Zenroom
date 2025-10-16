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
        local copy_cred = cred
        local path <const> = claim.path
        local values <const> = claim.values
        -- path exists
        for _, p in ipairs(path) do
            if copy_cred[p] == nil then
                warn("Credential does not have the required path: " .. table.concat(path, '.'))
                return false
            end
            copy_cred = copy_cred[p]
        end
        -- if values is specified, check that the value under the path matches one of them
        if values and (#values > 0) then
            local value_found = false
            local string_cred_value <const> = O.to_string(copy_cred)
            for _, v in ipairs(values) do
                if string_cred_value == v then
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

local function _check_dcsdjwt(cred)
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
        local string_query <const> = deepmap(O.to_string, query)
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
