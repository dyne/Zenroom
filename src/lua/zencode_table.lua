--[[
--This file is part of zenroom
--
--Copyright (C) 2020-2021 Dyne.org foundation
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
--on Monday, 28th August 2023
--]]

local function move_or_copy_in(src_value, src_name, dest, new)
    local d = have(dest)
    if luatype(d) ~= 'table' then error("Object is not a table: "..dest, 2) end
    local new_name = new or src_name
    local cdest = CODEC[dest]
    if cdest.zentype == 'e' and cdest.schema then
        local sdest = ZEN.schemas[cdest.schema]
        if luatype(sdest) ~= 'table' then -- old schema types are not open
            error("Schema is not open to accept extra objects: "..dest)
        elseif not sdest.schematype or sdest.schematype ~= 'open' then
            error("Schema is not open to accept extra objects: "..dest)
        end
        if d[new_name] then
            error("Cannot overwrite: "..new_name.." in "..dest,2)
        end
        d[new_name] = src_value
        ACK[dest] = d
    elseif cdest.zentype == 'd' then
        if d[new_name] then
            error("Cannot overwrite: "..new_name.." in "..dest,2)
        end
        d[new_name] = src_value
        ACK[dest] = d
    elseif cdest.zentype == 'a' then
        table.insert(ACK[dest], src_value)
    else
        error("Invalid destination type: "..cdest.zentype,2)
    end
end

When("move named by '' in ''", function(src_name, dest)
    local src = have(src_name):string()
    move_or_copy_in(have(src), src, dest)
    ACK[src] = nil
    CODEC[src] = nil
end)

When("move '' in ''", function(src, dest)
    move_or_copy_in(have(src), src, dest)
    ACK[src] = nil
    CODEC[src] = nil
end)

When("move '' to '' in ''", function(src, new, dest)
    move_or_copy_in(have(src), src, dest, new) ---old, new, inside, true)
    ACK[src] = nil
    CODEC[src] = nil
end)

When("move '' from '' in ''", function(name, src, dest)
    move_or_copy_in(have({src, name}), name, dest)
    ACK[src][name] = nil
end)

When("copy named by '' in ''", function(src_name, dest)
    local src = have(src_name):string()
    move_or_copy_in(deepcopy(have(src)), src, dest)
end)

When("copy '' in ''", function(src, dest)
    move_or_copy_in(deepcopy(have(src)), src, dest)
end)

When("copy '' to '' in ''", function(src, new, dest)
    move_or_copy_in(have(src), src, dest, new)
end)

When("copy '' from '' in ''", function(name, src, dest)
    move_or_copy_in(have({src, name}), name, dest)
end)

local function _when_remove_dictionary(ele, from)
    -- ele is just the name (key) of object to remove
    local dict = have(from)
    zencode_assert(dict, "Dictionary not found: "..from)
    if dict[ele] then
        ACK[from][ele] = nil -- remove from dictionary
    elseif CODEC[ele].name ~= ele and dict[CODEC[ele].name] then
        -- it may be a copy or random object with different name
        ACK[from][CODEC[ele].name] = nil
    else
        error("Object not found in dictionary: "..ele.." in "..from)
    end
end

local function _when_remove_array(ele, from)
    local obj = have(ele)
    local arr = have(from)
    local found = false
    local newdest = { }
    if luatype(obj) == 'table' then
        -- overload __eq for tables
        local m_obj = {}
        local m_arr = {}
        setmetatable(arr, m_arr)
        setmetatable(obj, m_obj)
        local fun = function(l, r) return zencode_serialize(l) == zencode_serialize(r) end
        m_arr.__eq = fun
        m_obj.__eq = fun
    end
    for _,v in next,arr,nil do
        if not (v == obj) then
            table.insert(newdest,v)
        else
            found = true
        end
    end
    zencode_assert(found, "Element to be removed not found in array")
    ACK[from] = newdest
end

When("remove '' from ''", function(ele,from)
    local codec = CODEC[from]
    zencode_assert(codec, "No codec registration for target: "..from)
    if codec.zentype == 'd'
        or codec.schema then
        _when_remove_dictionary(ele, from)
    elseif codec.zentype == 'a' then
        _when_remove_array(ele, from)
    else
        I.warn({ CODEC = codec})
        error("Invalid codec registration for target: "..from)
    end
end)

local function count_f(obj_name)
    local obj, obj_codec = have(obj_name)
    local count = 0
    if obj_codec.zentype == 'd' then
        for _, _ in pairs(t) do
            count = count + 1
        end
    else
        count = #obj
    end
    return count
end

When("create size of ''", function(arr)
    ACK.size = F.new(count_f(arr))
    new_codec('size', {zentype='e', encoding='float'})
end)

local function _is_found_in(ele_name, obj_name)
    local ele = mayhave(ele_name) or O.from_string(ele_name)
    local obj, obj_codec = have(obj_name)
    if obj_codec.zentype == 'a' then
        for _,v in pairs(obj) do
            if v == ele then return true end
        end
    elseif obj_codec.zentype == 'd' then
        local el = O.to_string(ele)
        return obj[el] and (luatype(obj[el]) == 'table' or tonumber(obj[el]) or #obj[el] ~= 0)
    else
        zencode_assert(false, "Invalid container type: "..obj.." is "..obj_codec)
    end
end

IfWhen("verify '' is not found in ''", function(ele_name, obj_name)
           zencode_assert(not _is_found_in(ele_name, obj_name),
                          "Object should not be found: "..ele_name.." in "..obj_name)
end)

IfWhen("verify '' is found in ''", function(ele_name, obj_name)
           zencode_assert(_is_found_in(ele_name, obj_name),
                          "Cannot find object: "..ele_name.." in "..obj_name)
end)

IfWhen("verify '' is found in '' at least '' times", function(ele_name, obj_name, times)
    local ele, ele_codec = have(ele_name)
    zencode_assert( luatype(ele) ~= 'table',
                "Invalid use of table in object comparison: "..ele_name)
    local num = have(times)
    local obj, obj_codec = have(obj_name)
    zencode_assert( luatype(obj) == 'table',
                "Not a table: "..obj_name)
    zencode_assert( obj_codec.zentype == 'a', "Not an array: "..obj_name)
    local constructor = fif(type(num) == "zenroom.big", BIG.new, F.new)
    local found = constructor(0)
    local one = constructor(1)
    for _,v in pairs(obj) do
        if type(v) == type(ele) and v == ele then found = found + one end
    end
    if type(num) == "zenroom.big" then
        zencode_assert(found >= num, "Object "..ele_name.." found only "..found:decimal().." times instead of "..num:decimal().." in array "..obj_name)
    else
        zencode_assert(found >= num, "Object "..ele_name.." found only "..tostring(found).." times instead of "..tostring(num).." in array "..obj_name)
    end
end)

When("create copy of last element from ''", function(obj_name)
    local obj, obj_codec = have(obj_name)
    if type(obj) ~= 'table' then
        error("Can only index tables")
    end
    if obj_codec.zentype == 'a' then
        if #obj == 0 then
            error("Last element doesn't exist for empty array")
        end
        ACK.copy_of_last_element = obj[#obj]
    elseif obj_codec.zentype == 'd' then
        local elem = nil
        for _, v in sort_pairs(obj) do
            elem = v
        end
        if not elem then
            error("Last element doesn't exist for empty dictionary")
        end
        ACK.copy_of_last_element = elem
    else
        error("Cannot find last element in " .. obj_codec.zentype)
    end
    local n_codec = {encoding = obj_codec.encoding}
    -- if copying from table of schema
    if obj_codec.schema then
        n_codec.schema = obj_codec.schema
        n_codec.zentype = "e"
    end
    new_codec('copy_of_last_element', n_codec)
end)

local function take_out_f(path, dest, format)
    if dest then path = path..CONF.path.separator..dest end
    local ele, dest = pick_from_path(path)
    ACK[dest] = ele
    if format then
        new_codec(dest, guess_conversion(ACK[dest], format))
    else
        local root = strtok(uscore(path), CONF.path.separator)[1]
        new_codec(dest, { encoding = CODEC[root].encoding })
    end
end

When("pickup from path ''", function(path)
    take_out_f(path, nil, nil)
end)

When("pickup a '' from path ''", function(format, path)
    take_out_f(path, nil, format)
end)

When("take '' from path ''", function(target, path)
    take_out_f(path, uscore(target), nil)
end)
