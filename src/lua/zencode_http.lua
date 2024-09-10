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
--Last modified by Denis Roio
--on Saturday, 27th November 2021
--]]
local _UNRESERVED = "A-Za-z0-9%-._~"
local _GEN_DELIMS = ":/?#%[%]@"
local _SUB_DELIMS = "!$&'()*+,;="
local _RESERVED = _GEN_DELIMS .. _SUB_DELIMS
local _REG_NAME = "^[" .. _UNRESERVED .. "%%" .. _SUB_DELIMS .. "]*$"
local _IP_FUTURE_LITERAL = "^v[0-9A-Fa-f]+%." ..
                           "[" .. _UNRESERVED .. _SUB_DELIMS .. "]+$"

local function _normalize_percent_encoding (s)
    if s:find("%%$") or s:find("%%.$") then
        error("unfinished percent encoding at end of URI '" .. s .. "'")
    end
    return s:gsub("%%(..)", function (hex)
        if not hex:find("^[0-9A-Fa-f][0-9A-Fa-f]$") then
            error("invalid percent encoding '%" .. hex ..
                  "' in URI '" .. s .. "'")
        end
        -- Never percent-encode unreserved characters, and always use uppercase
        -- hexadecimal for percent encoding.  RFC 3986 section 6.2.2.2.
        local char = string.char(tonumber("0x" .. hex))
        return char:find("^[" .. _UNRESERVED .. "]") and char or "%" .. hex:upper()
    end)
end

local function _to_percent_encoding(s)
    -- percent-encode all non-unreserved characters (except spaces)
    local str = s:gsub("([^%w%-%.%_%~ ])", function (char)
                             return string.format("%%%02X", string.byte(char))
    end)
    -- spaces to plus signs
    return str:gsub(" ", "+")
end

local function _is_ip4_literal (s)
    if not s:find("^[0-9]+%.[0-9]+%.[0-9]+%.[0-9]+$") then return false end

    for dec_octet in s:gmatch("[0-9]+") do
        if dec_octet:len() > 3 or dec_octet:find("^0.") or
           tonumber(dec_octet) > 255 then
            return false
        end
    end

    return true
end

local function _is_ip6_literal (s)
    local had_elipsis = false       -- true when '::' found
    local num_chunks = 0
    while s ~= "" do
        num_chunks = num_chunks + 1
        local p1, p2 = s:find("::?")
        local chunk
        if p1 then
            chunk = s:sub(1, p1 - 1)
            s = s:sub(p2 + 1)
            if p2 ~= p1 then    -- found '::'
                if had_elipsis then return false end    -- two of '::'
                had_elipsis = true
                if chunk == "" then num_chunks = num_chunks - 1 end
            else
                if chunk == "" then return false end    -- ':' at start
                if s == "" then return false end        -- ':' at end
            end
        else
            chunk = s
            s = ""
        end

        -- Chunk is neither 4-digit hex num, nor IPv4address in last chunk.
        if (not chunk:find("^[0-9a-f]+$") or chunk:len() > 4) and
           (s ~= "" or not _is_ip4_literal(chunk)) and
           chunk ~= "" then
            return false
        end

        -- IPv4address in last position counts for two chunks of hex digits.
        if chunk:len() > 4 then num_chunks = num_chunks + 1 end
    end

    if had_elipsis then
        if num_chunks > 7 then return false end
    else
        if num_chunks ~= 8 then return false end
    end

    return true
end

local function _is_valid_host (host)
   if string.find(host,"^%[.*%]$") then
      local ip_literal = host:sub(2, -2)
      if ip_literal:find("^v") then
	 if not ip_literal:find(_IP_FUTURE_LITERAL) then
	    return "invalid IPvFuture literal '" .. ip_literal .. "'"
	 end
      else
	 if not _is_ip6_literal(ip_literal) then
	    return "invalid IPv6 address '" .. ip_literal .. "'"
	 end
      end
   elseif not _is_ip4_literal(host) and not host:find(_REG_NAME) then
      return "invalid host value '" .. host .. "'"
   end
   return nil
end

When("create url from ''", function(src)
	local obj = have(src)
	local url = obj:str():lower()
	empty'url'
	local proto
	if url:sub(1,7)=='http://' then proto = 'http://' end
	if url:sub(1,8)=='https://' then proto = 'https://' end
	zencode_assert(proto, "Invalid http prefix in url: "..obj:str())
	local toks = strtok(url, '/') -- second is the host
	local res = _is_valid_host(toks[2])
	zencode_assert(not res, res)
	ACK.url = obj
	new_codec('url',{zentype='e',content='url', encoding='string'})
end)

local function _append_to_url(ele, dst, encoding_f)
    local arg, arg_c = have(ele)
    local url, url_c = have(dst)
    zencode_assert(arg_c.encoding == 'string' and luatype(arg) ~= 'table', 
        "Cannot append http request that are not strings: "..ele)
    zencode_assert(url_c.content == 'url',
        "Cannot append http request to invalid url: "..dst)
    local separator = fif( url:str():find('?'), '&', '?' )
    local tv = type(arg)
    if tv == 'zenroom.time' or tv == 'zenroom.big' then
        arg = tostring(arg)
    elseif tv == 'zenroom.octet' then
        arg = arg:str()
    else
        error("Unexpected value type '"..tv.."' for "..ele, 2)
    end
    ACK[dst] = O.from_string(url:str() .. separator ..
                             encoding_f(ele)
                             .. '=' ..
                             encoding_f(arg)
    )
end

When("append '' as http request to ''", function(ele, dst)
    _append_to_url(ele, dst, _normalize_percent_encoding)
end)

When("append percent encoding of '' as http request to ''", function(ele, dst)
    _append_to_url(ele, dst, _to_percent_encoding)
end)

local function _get_parameters_from_table(table_params, encoding_f)
    empty('http_get_parameters')
    local params, params_c = have(table_params)
    if(params_c.zentype ~= 'd') then
        error("Expected dictionary, found "..params_c.zentype.." for "..table_params, 2)
    end
    if(params_c.encoding ~= 'string') then
        error("Parameters in "..table_params.." must be strings", 2)
    end
    local res = ""
    for k,v in pairs(params) do
        local tv = type(v)
        if tv == 'zenroom.time' or tv == 'zenroom.big' then
            v = tostring(v)
        elseif tv == 'zenroom.octet' then
            v = v:str()
        else
            error("Unexpected value type '"..tv.."' in "..table_params, 2)
        end
        res = res..encoding_f(k).."="..encoding_f(v).."&"
    end
    if #res > 1 then res = res:sub(1, -2) end
    ACK.http_get_parameters = O.from_string(res)
    new_codec('http_get_parameters', { zentype = 'e', encoding = 'string' })
end

When("create http get parameters from ''", function(table_params)
    _get_parameters_from_table(table_params, _normalize_percent_encoding)
end)

When("create http get parameters from '' using percent encoding", function(table_params)
    _get_parameters_from_table(table_params, _to_percent_encoding)
end)
