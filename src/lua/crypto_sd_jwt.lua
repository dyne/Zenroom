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

local sd_jwt = {}

-- Given as input a "disclosure array" of the form {salt, key, value}
-- Return: disclosure = the array in octet form
--         hashed = the sha256 digest of the encoded array (for _sd)
--         encoded_dis = the url64+json encoding of the input array (used just for testing)
function sd_jwt.create_disclosure(dis_arr)
    -- TODO: disclosure of disctionary
    -- TODO: problems sub, updated_at
    local encoded_dis = O.from_string(JSON.raw_encode(dis_arr, true)):url64()
    local disclosure = {}
    for i = 1, #dis_arr do
        if type(dis_arr[i]) == 'table' then
            disclosure[i] = deepmap(function(o) return O.from_string(o) end, dis_arr[i])
        elseif type(dis_arr[i]) == 'string' then
            disclosure[i] = O.from_string(dis_arr[i])
        end
    end
    local hashed = O.from_string(sha256(encoded_dis):url64())
    return  disclosure, hashed, encoded_dis
end

-- Given as input a selective disclosure request
-- Return a table containing two keys:
--        payload = the jwt containing disclosable object (the credential to be signed by the issuer)
--        disclosures = the list of disclosure arrays
function sd_jwt.create_sd(sdr)
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
        local disclosure_arr = {
            O.random(16):url64(),
            f,
            encode
        }
        local disclosure, hashed = sd_jwt.create_disclosure(disclosure_arr)

        disclosures[#disclosures+1] = disclosure
        jwt_payload[f] = nil
        jwt_payload._sd[#jwt_payload._sd+1] = hashed
    end

    return {
        payload=jwt_payload,
        disclosures=disclosures,
    }
end

return sd_jwt
