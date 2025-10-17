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

local DCQL = require'crypto_dcql_query'

local function import_dcql_query(obj)
    DCQL.validate_query(obj)
    return deepmap(input_encoding("string").fun, obj)
end

local function export_dcql_query(obj)
    return deepmap(get_encoding_function("string"), obj)
end

ZEN:add_schema(
    {
        dcql_query = {
            import = import_dcql_query,
            export = export_dcql_query
        }
    }
)

-- credential list is a dictionary where the fields are the type of credential
-- and the values are arrays of credentials of that type (maybe a schema can be created for this)
When("create credentials from '' matching dcql_query ''", function(creds, dcql)
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
        local string_query <const> = deepmap(get_encoding_function("string"), query)
        out[string_query.id] = {}
        local matching_credentials <const> = credentials[string_query.format]
        if matching_credentials == nil then
            goto continue
        end
        local checker <const> = DCQL.check_fn[string_query.format]
        if not checker then
            error("Credential format not yet suppoerted: " .. string_query.format)
        end
        for _, cred in ipairs(matching_credentials) do
            checker(cred, string_query, out)
            -- if checker(cred, string_query) then
            --    table.insert(out[string_query.id], cred)
            -- end
        end
        ::continue::
    end
    ACK.credentials = out
    new_codec('credentials', { zentype = 'd', encoding = 'string' })
end)
