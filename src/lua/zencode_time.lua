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
--Last modified by Matteo Cristino
--on Thursday, 29th February 2024
--]]

When("create timestamp", function()
    zencode_assert(os, 'Could not find os')
    ACK.timestamp = TIME.new(os.time())
    new_codec('timestamp', { zentype = 'e', encoding = 'time'})
end)

When("create integer '' cast of timestamp ''", function(dest, source)
    empty(dest)
    local src = have(source)
    if type(src) ~= 'zenroom.time' then
        src = TIME.new(src)
    end
    ACK[dest] = BIG.from_decimal(tostring(src))
    new_codec(dest, { zentype = 'e', encoding = 'integer'})
end)

When("create timestamp in future cast of date table ''", function(dt)
    zencode_assert(os, 'Could not find os')
    local now = os.date("*t", os.time())
    local date_table = have(dt)
    local date_table_fields = {
        year = true,
        month = true,
        day = true,
        hour = true,
        min = true,
        sec = true
    }
    for k, v in pairs(date_table) do
        if not date_table_fields[k] then
            error("Invalid date table field: " .. k)
        end
        now[k] = now[k] + ((v and tonumber(v)) or 0)
    end
    ACK.timestamp = TIME.new(os.time(now))
    new_codec('timestamp', { zentype = 'e', encoding = 'time'})
end)
