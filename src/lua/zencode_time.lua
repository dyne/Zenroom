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

local function import_date_table(obj)
    local res = {}
    res.year = TIME.new(obj.year or 0)
    res.month = TIME.new(obj.month or 0)
    res.day = TIME.new(obj.day or 0)
    res.hour = TIME.new(obj.hour or 0)
    res.min = TIME.new(obj.min or 0)
    res.sec = TIME.new(obj.sec or 0)
    res.isdst = obj.isdst or false
    return res
end

local function export_date_table(obj)
    if type(obj) == 'zenroom.time' then
        return os.date("*t", tonumber(obj))
    end
    local res = {}
    res.year = tonumber(obj.year)
    res.month = tonumber(obj.month)
    res.day = tonumber(obj.day)
    res.hour = tonumber(obj.hour)
    res.min = tonumber(obj.min)
    res.sec = tonumber(obj.sec)
    res.isdst = obj.isdst
    return res
end

ZEN:add_schema(
    {
        date_table = {
            import = import_date_table,
            export = export_date_table
        }
    }
)

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

When("create timestamp of date table ''", function(dt)
    zencode_assert(os, 'Could not find os')
    local date_table, date_table_codec = have(dt)
    zencode_assert(
        date_table_codec.encoding == 'complex' and date_table_codec.schema == 'date_table',
        'Invalid date table encoding: ' .. date_table_codec.schema)
    zencode_assert(date_table.year >= TIME.new(1970),
        'Date table ' .. dt .. ' can not be converted to timestamp, ' .. tostring(date_table.year) .. ' < 1970')
    local t = os.time(export_date_table(date_table))
    ACK.timestamp = TIME.new(t)
    new_codec('timestamp', { zentype = 'e', encoding = 'time'})
end)

When("create date table of timestamp ''", function(t)
    zencode_assert(os, 'Could not find os')
    local timestamp, timestamp_codec = have(t)
    zencode_assert(timestamp_codec.encoding == 'time',
        'Invalid time encoding: ' .. timestamp_codec.encoding)
    ACK.date_table = import_date_table(os.date("*t", tonumber(timestamp)))
    new_codec('date_table', { zentype = 'e', encoding = 'date_table'})
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
