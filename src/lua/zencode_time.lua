--[[
--This file is part of zenroom
--
--Copyright (C) 2021-2025 Dyne.org foundation
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
    new_codec('date_table', { zentype = 'e', encoding = 'complex', schema = 'date_table'})
end)

local function _timestamp2UTC(t_name, dest)
    zencode_assert(os, 'Could not find os')
    local d <const> = dest or 'UTC_timestamp'
    empty(d)
    local t <const> = tonumber((t_name and have(t_name)) or os.time(os.date("!*t")))
    if t_name and CODEC[t_name] and CODEC[t_name].encoding ~= 'time' then
        error('Invalid time encoding: ' .. timestamp_codec.encoding, 2)
    end
    ACK[d] = O.from_string(os.date("!%Y-%m-%dT%H:%M:%SZ", t))
    new_codec(d, { zentype = 'e', encoding = 'string'})
end

When("create UTC timestamp of now", _timestamp2UTC)
When("create UTC timestamp of ''", _timestamp2UTC)
When("create ZULU timestamp of now", function() _timestamp2UTC(nil, 'ZULU_timestamp') end)
When("create ZULU timestamp of ''", function(t_name) _timestamp2UTC(t_name, 'ZULU_timestamp') end)

local function _UTC2timestamp(t_name)
    if not os then error('Could not find os', 2) end
    local utc_timestamp, utc_timestamp_codec <const> = have(t_name)
    if utc_timestamp_codec.encoding ~= 'string' then
        error('Invalid UTC timestamp encoding: ' .. utc_timestamp_codec.encoding, 2)
    end
    local year, month, day, hour, min, sec <const> = utc_timestamp:string():match("(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)Z")
    local utc_table <const> = {
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(min),
        sec = tonumber(sec),
        isdst = false
    }
    local offset <const> = math.floor(os.difftime(os.time(), os.time(os.date("!*t"))))
    ACK.timestamp = TIME.new(os.time(utc_table) + offset)
    new_codec('timestamp', { zentype = 'e', encoding = 'time'})
end

When("create timestamp of UTC timestamp ''", _UTC2timestamp)
When("create timestamp of ZULU timestamp ''", _UTC2timestamp)
