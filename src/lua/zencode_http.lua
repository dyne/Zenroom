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

When("create the url from ''", function(src)
	local obj = have(src)
	local url = obj:str():lower()
	empty'url'
	local proto
	if url:sub(1,7)=='http://' then proto = 'http://' end
	if url:sub(1,8)=='https://' then proto = 'https://' end
	ZEN.assert(proto, "Invalid http prefix in url: "..obj:str())
	local toks = strtok(url, '[^/]+') -- second is the host
	local res = _is_valid_host(toks[2])
	ZEN.assert(not res, res)
	ACK.url = obj
	new_codec('url',{zentype='element',content='url', encoding='string'})
end)

When("append '' as http request to ''", function(ele, dst)
	local arg = have(ele):str():lower()
	local url = have(dst):str():lower()
	local codec = ZEN.CODEC[dst]
	ZEN.assert(codec.content=='url',
		   "Cannot append http request to invalid url: "..dst)
	local separator = fif( url:find('?'), '&', '?' )
	ACK[dst] = O.from_string( url .. separator ..
				  _normalize_percent_encoding(ele)
				  .. '=' ..
				  _normalize_percent_encoding(arg) )
end)
