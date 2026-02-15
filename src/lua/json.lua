--
-- zenroom's json encoder and decoder
--
-- Copyright (c) 2019 rxi
-- Copyright (c) 2020-2026 Dyne.org foundation
--
-- Permission is hereby granted, free of charge, to any person
-- obtaining a copy of this software and associated documentation
-- files (the "Software"), to deal in the Software without
-- restriction, including without limitation the rights to use, copy,
-- modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
-- BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
-- ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
-- CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--

local json = { _version = "1.1.0" }

------------
-- Encode --
------------

local encode

local escape_char_map = {
  [ "\\" ] = "\\\\",
  [ "\"" ] = "\\\"",
  [ "\b" ] = "\\b",
  [ "\f" ] = "\\f",
  [ "\n" ] = "\\n",
  [ "\r" ] = "\\r",
  [ "\t" ] = "\\t",
}

local escape_char_map_inv = { [ "\\/" ] = "/" }
for k, v in pairs(escape_char_map) do
  escape_char_map_inv[v] = k
end


local function escape_char(c)
  return escape_char_map[c] or string.format("\\u%04x", c:byte())
end


local function encode_nil(val)
  return "null"
end


local function encode_table(val, stack, whitespaces)
  local res = {}
  stack = stack or {}
  local separator = ","
  if whitespaces then
      separator = ", "
  end
  -- Circular reference?
  if stack[val] then error("circular reference") end

  stack[val] = true

  local _ipairs <const> = fif(CONF.output.sorting,sort_ipairs,ipairs)
  local _pairs <const> = fif(CONF.output.sorting,sort_pairs,pairs)

  if rawget(val, 1) ~= nil or next(val) == nil then
    -- Treat as array -- check keys are valid and it is not sparse
    local n = 0
    for k in pairs(val) do
      if type(k) ~= "number" then
        error("invalid table: mixed or invalid key types")
      end
      n = n + 1
    end
    if n ~= #val then
      warn("JSON encoding error: "..type(val))
      error("invalid table: sparse array (n="..n..", #val="..#val..")")
    end
    -- Encode
	for i, v in _ipairs(val) do
	   res[#res+1] = encode(v, stack, whitespaces)
	end
    stack[val] = nil
    return "[" .. table.concat(res, separator) .. "]"

  else
    -- Treat as an object
    for k, v in _pairs(val) do
      if type(k) ~= "string" then
        error("invalid table: mixed or invalid key types")
      end
      local val = encode(v, stack, whitespaces)
      if type(val) == 'zenroom.big' then val = val:decimal() end
      local cln = ":"
      if whitespaces then
        cln = ": "
      end
      table.insert(res, encode(k, stack, whitespaces) .. cln .. val)
    end
    stack[val] = nil
    return "{" .. table.concat(res, separator) .. "}"
  end
end


local function encode_string(val)
  return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val)
  -- Check for NaN, -inf and inf
  -- if val ~= val or val <= -math.huge or val >= math.huge then
  --   error("unexpected number value '" .. tostring(val) .. "'")
  -- end
  -- return string.format("%.14g", val)
  local s = tostring(val)
  local n = tonumber(s)
  if not n then error("Not a number: "..val, 2) end
  return n
end

local function encode_function(val)
   -- return hex function address as string
   return '"' .. strtok(tostring(val))[2] .. '"'
end

local type_func_map = {
  [ "nil"     ] = encode_nil,
  [ "table"   ] = encode_table,
  [ "string"  ] = encode_string,
  [ "number"  ] = encode_number,
  [ "function"] = encode_function,
  [ "boolean" ] = tostring,
}


encode = function(val, stack, whitespaces)
  local t = type(val)
  local f = type_func_map[t]
  if f then
    return f(val, stack, whitespaces)
  end
  error("unexpected type '" .. t .. "'")
end


function json.raw_encode(val, whitespaces)
   return(encode(val, nil, whitespaces))
   -- sort
   -- local out = "{ "
   -- for k,v in sort_pairs(val) do
   -- 	  out = out .. '"'..k..'": '
   -- 	  out = out .. encode(v)..","
   -- end
   -- return(out:sub(1,-2) .. "}")
end


------------
-- Decode --
------------

local parse
local byte = string.byte

local function create_set(...)
  local res = {}
  for i = 1, select("#", ...) do
    res[ select(i, ...) ] = true
  end
  return res
end

local function create_byte_set(...)
  local res = {}
  for i = 1, select("#", ...) do
    local ch = select(i, ...)
    res[byte(ch)] = true
  end
  return res
end

local space_chars   = create_byte_set(" ", "\t", "\r", "\n")
local delim_chars   = create_byte_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars  = create_byte_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals      = create_set("true", "false", "null")

local literal_map = {
  [ "true"  ] = true,
  [ "false" ] = false,
  [ "null"  ] = nil,
}

local default_limits = {
  max_input_bytes = 16 * 1024 * 1024,
  max_depth = 256,
  max_array_length = 200000,
  max_object_members = 200000,
}

local function get_json_limits()
  local conf = rawget(_G, "CONF")
  local parser = conf and conf.parser
  local json = parser and parser.json
  local limits = {}
  for k, v in pairs(default_limits) do
    local cur = json and json[k]
    if type(cur) == "number" and cur > 0 then
      limits[k] = math.floor(cur)
    else
      limits[k] = v
    end
  end
  return limits
end

local function is_valid_json_number(s)
  return s:match("^%-?(0|[1-9]%d*)(%.%d+)?([eE][%+%-]?%d+)?$") ~= nil
end


local function next_char(str, idx, set, negate)
  local len = #str
  for i = idx, len do
    if set[byte(str, i)] ~= negate then
      return i
    end
  end
  return len + 1
end


local function decode_error(str, idx, msg)
  local line_count = 1
  local col_count = 1
  for i = 1, idx - 1 do
    col_count = col_count + 1
    if byte(str, i) == 10 then -- "\n"
      line_count = line_count + 1
      col_count = 1
    end
  end
  error( string.format("The JSON input is not valid: %s at line %d col %d", msg, line_count, col_count) )
end


local function codepoint_to_utf8(n)
  -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
  local f = math.floor
  if n <= 0x7f then
    return string.char(n)
  elseif n <= 0x7ff then
    return string.char(f(n / 64) + 192, n % 64 + 128)
  elseif n <= 0xffff then
    return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
  elseif n <= 0x10ffff then
    return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
                       f(n % 4096 / 64) + 128, n % 64 + 128)
  end
  error( string.format("invalid unicode codepoint '%x'", n) )
end


local function parse_surrogate_unicode_escape(s)
  local n1 = tonumber(s:sub(3, 6), 16)
  local n2 = tonumber(s:sub(9, 12), 16)
  return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
end


local function parse_unicode_escape(s)
  local n = tonumber(s:sub(3, 6), 16)
  if n >= 0xd800 and n <= 0xdfff then
    error(string.format("invalid unicode surrogate '%x'", n))
  end
  return codepoint_to_utf8(n)
end


local function parse_string(str, i)
  local has_unicode_escape = false
  local has_surrogate_escape = false
  local has_escape = false
  local skip_next_low_surrogate = false
  local last
  local len = #str
  for j = i + 1, len do
    local x = byte(str, j)

    if x < 32 then
      decode_error(str, j, "control character in string")
    end

    if last == 92 then -- "\\" (escape char)
      if x == 117 then -- "u" (unicode escape sequence)
        local hex = str:sub(j + 1, j + 4)
        if not hex:find("^%x%x%x%x$") then
          decode_error(str, j, "invalid unicode escape in string")
        end
        local n1 = tonumber(hex, 16)
        if skip_next_low_surrogate then
          if n1 < 0xdc00 or n1 > 0xdfff then
            decode_error(str, j, "invalid unicode surrogate pair in string")
          end
          skip_next_low_surrogate = false
        elseif n1 >= 0xd800 and n1 <= 0xdbff then
          local b1 = byte(str, j + 5)
          local b2 = byte(str, j + 6)
          local hex2 = str:sub(j + 7, j + 10)
          local n2 = tonumber(hex2, 16)
          if b1 ~= 92 or b2 ~= 117 or not n2 or n2 < 0xdc00 or n2 > 0xdfff then
            decode_error(str, j, "invalid unicode surrogate pair in string")
          end
          skip_next_low_surrogate = true
          has_surrogate_escape = true
        elseif n1 >= 0xdc00 and n1 <= 0xdfff then
          decode_error(str, j, "invalid unicode surrogate pair in string")
        else
          has_unicode_escape = true
        end
      else
        if not escape_chars[x] then
          local c = string.char(x)
          decode_error(str, j, "invalid escape char '" .. c .. "' in string")
        end
        has_escape = true
      end
      last = nil

    elseif x == 34 then -- '"' (end of string)
      local s = str:sub(i + 1, j - 1)
      if has_surrogate_escape then
        s = s:gsub("\\u[dD][89aAbB]%x%x\\u[dD][cdefCDEF]%x%x", parse_surrogate_unicode_escape)
      end
      if has_unicode_escape then
        s = s:gsub("\\u%x%x%x%x", parse_unicode_escape)
      end
      if has_escape then
        s = s:gsub("\\.", escape_char_map_inv)
      end
      return s, j + 1

    else
      last = x
    end
  end
  decode_error(str, i, "expected closing quote for string")
end


local function parse_number(str, i)
  local x = next_char(str, i, delim_chars)
  local s = str:sub(i, x - 1)
  if not is_valid_json_number(s) then
    decode_error(str, i, "invalid number '" .. s .. "'")
  end
  local n = tonumber(s)
  if not n then
    decode_error(str, i, "invalid number '" .. s .. "'")
  end
  if n ~= n or n <= -math.huge or n >= math.huge then
    if type(warn) == "function" then
      warn("JSON numeric overflow: " .. s)
    end
    decode_error(str, i, "number overflow '" .. s .. "'")
  end
  -- -- float detection
  -- if s:find('%.') then return(n), x end
  -- return BIG.from_decimal(s), x
   return n, x
end

local function parse_literal(str, i)
  local x = next_char(str, i, delim_chars)
  local word = str:sub(i, x - 1)
  if not literals[word] then
    decode_error(str, i, "invalid literal '" .. word .. "'")
  end
  return literal_map[word], x
end


local function parse_array(str, i, state, depth)
  local res = {}
  local n = 0
  i = i + 1
  while 1 do
    local x
    i = next_char(str, i, space_chars, true)
    -- Empty / end of array?
    if byte(str, i) == 93 then -- "]"
      i = i + 1
      break
    end
    -- Read token
    x, i = parse(str, i, state, depth + 1)
    n = n + 1
    if n > state.max_array_length then
      decode_error(str, i, "max array length exceeded")
    end
    res[n] = x
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = byte(str, i)
    i = i + 1
    if chr == 93 then break end -- "]"
    if chr ~= 44 then decode_error(str, i, "expected ']' or ','") end -- ","
  end
  return res, i
end


local function parse_object(str, i, state, depth)
  local res = {}
  local seen = {}
  local members = 0
  i = i + 1
  while 1 do
    local key, val
    i = next_char(str, i, space_chars, true)
    -- Empty / end of object?
    if byte(str, i) == 125 then -- "}"
      i = i + 1
      break
    end
    -- Read key
    if byte(str, i) ~= 34 then -- '"'
      decode_error(str, i, "expected string for key")
    end
    key, i = parse(str, i, state, depth + 1)
    if seen[key] then
      decode_error(str, i, "duplicate key '" .. key .. "'")
    end
    seen[key] = true
    -- Read ':' delimiter
    i = next_char(str, i, space_chars, true)
    if byte(str, i) ~= 58 then -- ":"
      decode_error(str, i, "expected ':' after key")
    end
    i = next_char(str, i + 1, space_chars, true)
    -- Read value
    val, i = parse(str, i, state, depth + 1)
    members = members + 1
    if members > state.max_object_members then
      decode_error(str, i, "max object members exceeded")
    end
    -- Set
    res[key] = val
    -- Next token
    i = next_char(str, i, space_chars, true)
    local chr = byte(str, i)
    i = i + 1
    if chr == 125 then break end -- "}"
    if chr ~= 44 then decode_error(str, i, "expected '}' or ','") end -- ","
  end
  return res, i
end


local char_func_map = {
  [34] = parse_string,   -- '"'
  [48] = parse_number,   -- "0"
  [49] = parse_number,   -- "1"
  [50] = parse_number,   -- "2"
  [51] = parse_number,   -- "3"
  [52] = parse_number,   -- "4"
  [53] = parse_number,   -- "5"
  [54] = parse_number,   -- "6"
  [55] = parse_number,   -- "7"
  [56] = parse_number,   -- "8"
  [57] = parse_number,   -- "9"
  [45] = parse_number,   -- "-"
  [116] = parse_literal, -- "t"
  [102] = parse_literal, -- "f"
  [110] = parse_literal, -- "n"
  [91] = parse_array,    -- "["
  [123] = parse_object,  -- "{"
}


parse = function(str, idx, state, depth)
  depth = depth or 0
  if depth > state.max_depth then
    decode_error(str, idx, "max depth exceeded")
  end
  local b = byte(str, idx)
  local f = char_func_map[b]
  if f then
    return f(str, idx, state, depth)
  end
  local chr = str:sub(idx, idx)
  decode_error(str, idx, "unexpected character '" .. chr .. "'")
end


function json.raw_decode(str)
  if type(str) ~= "string" then
    error("expected argument of type string, got " .. type(str))
  end
  local limits = get_json_limits()
  if #str > limits.max_input_bytes then
    decode_error(str, 1, "max input size exceeded")
  end
  local res, idx = parse(str, next_char(str, 1, space_chars, true), limits, 0)
  idx = next_char(str, idx, space_chars, true)
  if idx <= #str then
    decode_error(str, idx, "trailing garbage")
  end
  return res
end


return json
