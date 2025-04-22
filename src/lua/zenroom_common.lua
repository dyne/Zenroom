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
--]]

-- override type to recognize zenroom's types
local _luatype <const> = _G['type']
_G['luatype'] = _luatype

local _type <const> = function(var)
    local simple = luatype(var)
    if simple == "userdata" then
        local meta = getmetatable(var)
        if meta then return(meta.__name)
        else return("unknown") end
    else return(simple) end
end
_G['type'] = _type

-- TODO: optimise in C
local _iszen <const> = function(n)
    if not n then
        error("Cannot parse null zenroom type",2) end
    for _ in n:gmatch("zenroom") do
        return true
    end
    return false
end
_G['iszen'] = _iszen

-- workaround for a ternary conditional operator
function fif(condition, if_true, if_false)
    if condition then return if_true else return if_false end
end

-- reliable table size measurement
_G['table_size'] = function(t)
    if not t then return 0 end
    if luatype(t) ~= 'table' then
        error("table_size argument is not a table: "..type(t),2)
    end
    local c = 0
    for _ in pairs(t) do
        c = c + 1
    end
    return c
end

_G['uscore'] = function(input)
    local it = luatype(input)
    if it == 'string' then
        return string.gsub(input, ' ', '_')
    elseif it == 'number' then
        return input
    else
        error("Underscore transform not a string or number: "..it, 3)
    end
end
_G['space'] = function(input)
    local it = luatype(input)
    if it == 'string' then
        return string.gsub(input, '_', ' ')
    elseif it == 'number' then
        return input
    else
        error("Whitespace transform not a string or number: "..it, 3)
    end
end

_G['strtok'] = function(str, delimiter)
    delimiter = delimiter or ' '
    local result = {}
    local start = 1
    local delimiterPos = string.find(str, delimiter, start, true)

    while delimiterPos do
        local token = string.sub(str, start, delimiterPos - 1)
        table.insert(result, token)
        start = delimiterPos + 1
        delimiterPos = string.find(str, delimiter, start, true)
    end

    local lastToken = string.sub(str, start)
    if lastToken ~= "" then
        table.insert(result, lastToken)
    end

    return result
end

-- sorted iterator for deterministic ordering of tables
-- from: https://www.lua.org/pil/19.3.html
_G["lua_pairs"]  = _G["pairs"]
_G["lua_ipairs"] = _G["ipairs"]
local function _pairs(t)
    local a = {}
    for n in lua_pairs(t) do table.insert(a, n) end
    QSORT(a) -- TODO: cannot sort over zenroom types
    local i = 0      -- iterator variable
    return function ()   -- iterator function
        i = i + 1
        -- if a[i] == nil then return nil
        return a[i], t[a[i]]
    end
end
local function _ipairs(t)
    local a = {}
    for n in lua_ipairs(t) do table.insert(a, n) end
    QSORT(a)
    local i = 0      -- iterator variable
    return function ()   -- iterator function
        i = i + 1
        -- if a[i] == nil then return nil
        return a[i]
    end
end
-- Switch to deterministic (sorted) table iterators: this breaks lua
-- tests in particular those stressing i/pairs and pack/unpack, which
-- are anyway unnecessary corner cases in zenroom, which exits cleanly
-- and signaling a stack overflow. Please report back if this
-- generates problems leading to the pairs for loop in function above.
_G["sort_pairs"]  = _pairs
_G["sort_ipairs"] = _pairs

local function _deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[_deepcopy(orig_key)] = _deepcopy(orig_value)
        end
        setmetatable(copy, _deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
_G['deepcopy'] = _deepcopy

-- compare two tables
local function _deepcmp(left, right)
    if not ( luatype(left) == "table" ) then
        error("Internal error: deepcmp 1st argument is not a table")
    end
    if not ( luatype(right) == "table" ) then
        error("Internal error: deepcmp 2nd argument is not a table")
    end
    if left == right then return true end
    for key1, value1 in pairs(left) do
        local value2 = right[key1]
        if value2 == nil then return false
        elseif value1 ~= value2 then
            if type(value1) == "table" and type(value2) == "table" then
                if not _deepcmp(value1, value2) then
                    return false
                end
            else
                return false
            end
        end
    end
    -- check for missing keys in tbl1
    for key2, _ in pairs(right) do
        if left[key2] == nil then
            return false
        end
    end
    return true
end
_G['deepcmp'] = _deepcmp

-- deep recursive map on a tree structure
-- for usage see test/deepmap.lua
-- operates only on strings, passes numbers through
local function _deepmap(fun,t,...)
    local luatype = luatype
    if luatype(fun) ~= 'function' then
        error("Internal error: deepmap 1st argument is not a function", 3)
        return nil end
    -- if luatype(t) == 'number' then
    --     return t end
    if luatype(t) ~= 'table' then
        return fun(t) end
    -- error("Internal error: deepmap 2nd argument is not a table", 3)
    -- return nil end
    local res = {}
    for k,v in pairs(t) do
        if luatype(v) == 'table' then
            res[k] = _deepmap(fun,v,...) -- recursion
        else
            res[k] = fun(v,k,...)
        end
    end
    return setmetatable(res, getmetatable(t))
end
_G['deepmap'] = _deepmap

local function _deepsortmap(fun,t,...)
    local luatype = luatype
    if luatype(fun) ~= 'function' then
        error("Internal error: deepmap 1st argument is not a function", 3)
        return nil end
    -- if luatype(t) == 'number' then
    --     return t end
    if luatype(t) ~= 'table' then
        return fun(t) end
    -- error("Internal error: deepmap 2nd argument is not a table", 3)
    -- return nil end
    local res = {}
    for k,v in sort_pairs(t) do
        if luatype(v) == 'table' then
            res[k] = _deepsortmap(fun,v,...) -- recursion
        else
            res[k] = fun(v,k,...)
        end
    end
    return setmetatable(res, getmetatable(t))
end
_G['deepsortmap'] = _deepsortmap

-- function to be used when converting codecs with complex trees
-- mask is a dictionary of functions to be applied in place
local function _deepmask(fun, t, mask)
    local luatype = luatype
    if luatype(fun) ~= 'function' then
        error("Internal error: deepmask 1st argument is not a function", 3)
    end
    if not mask then
        error("Internal error: deepmask 3rd argument is nil", 2)
    end
    if luatype(t) ~= 'table' then
        error("Internal error: deepmask 2nd argument is not a table", 3)
    end
    if mask and luatype(mask) ~= 'table' then
        error("Internal error: deepmask 3rd argument is not a table", 3)
    end
    local res = {}
    for k, v in pairs(t) do
        local maskp <const> = mask[k]
        if not maskp then
            res[k] = fun(v, k)
            goto continue
        end
        if luatype(v) == 'table' then
            res[k] = _deepmask(fun, v, maskp)
            goto continue
        end
        if not maskp then
            res[k] = fun(v, k)
            goto continue
        end
        local encoder
        if luatype(maskp) == 'function' then
            encoder = maskp
        else
            encoder = get_encoding_function(maskp)
        end
        if not encoder then
            error("Invalid encoding found in "..k
                  ..": "..encoder,2)
        end
        res[k] = encoder(v, k)
        ::continue::
    end
    return setmetatable(res, getmetatable(t))
end
_G['deepmask'] = _deepmask

local function _mask_set(t, path, value)
    local current = t
    local nump <const> = #path
    for i = 1, nump - 1 do
        local key = path[i]
        if not current[key] then current[key] = {} end
        current = current[key]
    end
    current[path[nump]] = value
    return t
end
_G['deepmask_set'] = _mask_set

function isarray(obj)
    if not obj then
        warn("Argument of isarray() is nil")
        return false
    end
    if luatype(obj) == 'string' then
        -- seach HEAD for ACK[obj] and check its CODEC
        local o = ACK[obj]
        if not o then return false end
        if luatype(o) ~= 'table' then return false end
        if CODEC[obj].zentype == 'a' then return true end
        return false
    end
    if luatype(obj) ~= 'table' then
        -- warn("Argument of isarray() is not a table")
        return false
    end
    local count = 0
    for k, v in pairs(obj) do
        -- check that all keys are numbers
        -- don't check sparse ratio (cjson's lua_array_length)
        if luatype(k) ~= "number" then return false end
        count = count + 1
    end
    return count
end

function isdictionary(obj)
    if not obj then
        warn("Argument of isdictionary() is nil")
        return false
    end
    if luatype(obj) == 'string' then
        -- seach HEAD for ACK[obj] and check its CODEC
        local o = ACK[obj]
        if not o then return false end
        if luatype(o) ~= 'table' then return false end
        if CODEC[obj].zentype == 'd'
            or CODEC[obj].zentype == 'schema' then
            return true end -- TRUE
        return false
    end
    -- check the object itself
    if luatype(obj) ~= 'table' then return false end
    -- error("Argument is not a table: "..type(obj)
    local count = 0
    for k, v in pairs(obj) do
        -- check that all keys are not numbers
        -- don't check sparse ratio (cjson's lua_array_length)
        if luatype(k) ~= "string" then return false end
        count = count + 1
    end
    return count
end

function array_contains(arr, obj)
    if luatype(arr) ~= 'table' then error("Internal error: array_contains argument is not a table",2) end
    for k, v in pairs(arr) do
        if luatype(k) ~= 'number' then error("Internal error: array_contains argument is not an array", 2) end
        if v == obj then return true end
    end
    return false
end


function help(module)
    if module == nil then
        print("usage: help(module)")
        print("example > help(octet)")
        print("example > help(ecdh)")
        print("example > help(ecp)")
        return
    end
    for k,v in pairs(module) do
        if type(v)~='table' and string.sub(k,1,1)~='_' then
            print("class method: "..k)
        end
    end
    -- local inst = module.new()
    -- if inst == nil then return end
    -- for s,f in pairs(getmetatable(inst)) do
    --     if(string.sub(s,1,2)~='__') then print("object method: "..s) end
    -- end
end

local oldtonumber = tonumber
function tonumber(obj, ...)
    if type(obj) == "zenroom.float" or type(obj) == "zenroom.time" then
        obj = tostring(obj)
    end
    return oldtonumber(obj, ...)
end

function isnumber(n)
    local t = type(n)
    return t == 'number' or t == 'zenroom.float' or t == 'zenroom.big'
end

function deprecated(old, new, func)
    local warn_func = function(...)
        warn(table.concat({"DEPRECATED:\n", old, "\nuse instead\n", new}))
        func(...)
    end
    return old, warn_func
end

function zip(...)
    local arrays = {...}
    local ans = {}
    local index = 0
    for k, v in pairs(arrays) do
        zencode_assert(isarray(v), "zip input are not arrays")
    end
    return function()
        index = index + 1
        for k, v in pairs(arrays) do
            ans[k] = v[index]
            -- stop iteration at the first nil value in one of the array
            if ans[k] == nil then return end
        end
        return table.unpack(ans)
    end
end

-- extract an element from deep down
-- works both in IN and ACK memory
-- @param path path to variable separated by points
-- @return element found following the path
-- @return name of the destination
function pick_from_path(path, no_dest)
    local path_array = strtok(uscore(path), CONF.path.separator)
    local root = path_array[1]
    table.remove(path_array, 1)
    local dest = path_array[#path_array]
    if not no_dest then empty(dest) end
    -- should works both in given and when phase
    -- IN is checked firstly since in the When phase IN will be empty
    local res = IN[root] or ACK[root]
    for _,v in pairs(path_array) do
        zencode_assert(luatype(res) == 'table', "Object is not a table: "..root)
        if res[v] == nil then
            local v_number = tonumber(v)
            zencode_assert(v_number and res[v_number] ~= nil, "Key "..v.." not found in "..root)
            res = res[v_number]
        else
            res = res[v]
        end
        root = v
    end
    return res, dest
end

-- -- MULTIBASE

-- Unicode, character, encoding, description, status
-- U+0030, 0, base2, Binary (01010101), experimental
-- U+0066, f, base16, Hexadecimal (lowercase), final
-- U+0046, F, base16upper, Hexadecimal (uppercase), final
-- U+0052, R, base45, Base45 RFC9285, draft
-- U+007a, z, base58btc, Base58 Bitcoin, final
-- U+006d, m, base64, RFC4648 no padding, final
-- U+004d, M, base64pad, RFC4648 with padding, experimental
-- U+0075, u, base64url, RFC4648 no padding, final
-- U+0055, U, base64urlpad, RFC4648 with padding, final

function multibase_decode(src)
    local pfx <const> = string.sub(src,1,1):lower()
    local val <const> = string.sub(src,2)
    local trans <const> = {
        f = O.from_hex,
        r = O.from_base45,
        z = O.from_base58,
        m = O.from_base64,
        u = O.from_url64
    }
    return trans[pfx](val)
end
