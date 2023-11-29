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
        local disclosure = {
            O.random(16):url64(),
            f,
            encode
        }
        disclosures[#disclosures+1] = disclosure

        jwt_payload[f] = nil
        jwt_payload._sd[#jwt_payload._sd+1] = sha256(
            O.from_string(JSON.raw_encode(disclosure, true)):url64())
    end

    return {
        payload=jwt_payload,
        disclosures=disclosures,
    }
end

function sd_jwt.create_disclosure(dis)
    local disclosure = O.from_string(JSON.raw_encode(dis, true)):url64()
    local hashed = O.from_string(sha256(disclosure):url64())
    return disclosure, hashed
end

return sd_jwt
