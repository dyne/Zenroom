--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2026 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License as
--published by the Free Software Foundation, either version 3 of the
--License, or (at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--You should have received a copy of the GNU Affero General Public License 
--along with this program.  If not, see <https://www.gnu.org/licenses/>.
--
--Last modified by Denis Roio
--on Friday, 26th November 2021
--]]

--- WHEN

-- nop to terminate IF blocks
When("done", function() end)


local function _is_found(el)
    return ACK[el] and (luatype(ACK[el]) == 'table' or tonumber(ACK[el]) or #ACK[el] ~= 0)
end

IfWhen("verify '' is found", function(el)
    zencode_assert(_is_found(el), "Cannot find object: "..el)
end)

IfWhen("verify '' is not found", function(el)
    zencode_assert(not _is_found(el), "Object should not be found: "..el)
end)

When("append '' to ''", function(src, dest)
		local val = have(src)
		local dst = have(dest)
		zencode_assert(luatype(dst) ~= 'table',
				   "Cannot append to table: "..dest)
		-- if the destination is a number, fix the encoding to string
		if isnumber(dst) then
		   dst = O.from_string( tostring(dst) )
		   CODEC[dest].encoding = "string"
		   CODEC[dest].zentype = 'e'
        end
        if isnumber(val) then
		   val = O.from_string( tostring(val) )
		end
        dst = dst:octet() .. val
		ACK[dest] = dst
end)

When("append string '' to ''", function(hstr, dest)
	local dst = have(dest)
	zencode_assert(luatype(dst) ~= 'table', "Cannot append to table: "..dest)
	-- if the destination is a number, fix encoding to string
	if isnumber(dst) then
	   dst = O.from_string( tostring(dst) )
	   CODEC[dest].encoding = "string"
	   CODEC[dest].zentype = 'e'
	end
	dst = dst:octet() .. O.from_string(hstr)
	ACK[dest] = dst
end)

When("prepend string '' to ''", function(hstr, dest)
	local dst = have(dest)
	zencode_assert(luatype(dst) ~= 'table', "Cannot append to table: "..dest)
	-- if the destination is a number, fix encoding to string
	if isnumber(dst) then
	   dst = O.from_string( tostring(dst) )
	   CODEC[dest].encoding = "string"
	   CODEC[dest].zentype = 'e'
	end
	dst = O.from_string(hstr) .. dst:octet()
	ACK[dest] = dst
end)

When("append '' of '' to ''", function(enc, src, dest)
	local from = have(src)
	local to = have(dest)
	zencode_assert(type(to) == 'zenroom.octet', "Destination type is not octet: "..dest.." ("..type(to)..")")
	zencode_assert(CODEC[dest].encoding == 'string', "Destination encoding is not string: "..dest)
	local f = get_encoding_function(enc)
	zencode_assert(f, "Encoding format not found: "..enc)
	to = to .. O.from_string( f( from:octet() ) )
	ACK[dest] = to
end)

When("create ''", function(dest)
	empty (dest)
	ACK[dest] = { }
	CODEC[dest] = guess_conversion(ACK[dest], dest)
	CODEC[dest].name = dest
end)
When("create '' named ''", function(sch, name)
	empty(name)
	ACK[name] = { }
	CODEC[name] = guess_conversion(ACK[name], sch)
	CODEC[name].name = name
end)

-- simplified exception for I write: import encoding from_string ...
When("write string '' in ''", function(content, dest)
	empty(dest)
	ACK[dest] = O.from_string(content)
	new_codec(dest,
			  {encoding = 'string',
			   luatype = 'string',
			   zentype = 'e' })
end)

-- ... and from a number
When("write number '' in ''", function(content, dest)
	empty(dest)
	-- TODO: detect number base 10
	local num = tonumber(content)
	zencode_assert(num, "Cannot convert value to number: "..content)
--	if num > 2147483647 then
--		error('Overflow of number object over 32bit signed size')
		-- TODO: maybe support unsigned native here
--	end

    --- simulate input from Given to add a new number
    --- in order to make it distinguish float and time
	ACK[dest] = input_encoding('float').fun(num)
    new_codec(dest, {zentype = 'e', encoding = 'number'})
end)

When("create number from ''", function(from)
	empty'number'
	local get = have(from)
	ACK.number = BIG.from_decimal(get:octet():string())
	new_codec('number', {zentype = 'e' })
end)

When("set '' to '' as ''", function(dest, content, format)
	empty(dest)
	local guess = input_encoding(format)
	guess.raw = content
	guess.name = dest
	ACK[dest] = operate_conversion(guess)
--	new_codec(dest, { luatype = luatype(ACK[dest]), zentype = 'e' })
end)

IfWhen("verify '' is a json", function(src)
    local obj, obj_c = have(src)
    if not zencode_assert(obj_c.zentype == 'e', "Encoded JSON is not an element: "..src) then return end
    if not zencode_assert(obj_c.encoding == 'string', "Encoded JSON is not an string: "..src) then return end
    zencode_assert(JSON.validate(O.to_string(obj)), "Invalid JSON object: "..src)
end)

When("create json escaped string of ''", function(src)
    local obj, codec = have(src)
    empty 'json_escaped_string'
    local encoding = codec.schema or codec.encoding
        or CODEC.output.encoding.name
    ACK.json_escaped_string = OCTET.from_string( JSON.encode(obj, encoding) )
    new_codec('json_escaped_string', {encoding = 'string', zentype = 'e'})
end)

When("create json unescaped object of ''", function(src)
    local obj <const> = have(src)
    empty'json_unescaped_object'
    local json_value_parse <const> = function(v)
        local v_type <const> = type(v)  
        if v_type == "boolean" then return v
        elseif v_type == "number" then return F.new(v)
        else return O.from_string(v)
        end
    end
    ACK.json_unescaped_object = deepmap(
        json_value_parse,
        JSON.decode(O.to_string(obj))
    )
    new_codec('json_unescaped_object', {encoding = 'string'})
end)

-- numericals
When("set '' to '' base ''", function(dest, content, base)
	empty(dest)
	local bas = tonumber(base)
	zencode_assert(bas, "Invalid numerical conversion for base: "..base)
	local num = tonumber(content,bas)
	zencode_assert(num, "Invalid numerical conversion for value: "..content)
	ACK[dest] = F.new(num)
	new_codec(dest, {encoding = 'number', zentype = 'e' })
end)

local function _delete_f(name)
   have(name)
   ACK[name] = nil
   CODEC[name] = nil
end
When("delete ''", _delete_f)
When("remove ''", _delete_f)

When("rename '' to ''", function(old,new)
	have(old)
	empty(new)
	ACK[new] = ACK[old]
	ACK[old] = nil
	CODEC[new] = CODEC[old]
	CODEC[old] = nil
end)
When("rename object named by '' to ''", function(old,new)
	local oldo = have(old)
	local olds = oldo:octet():string()
	have(olds)
	empty(new)
	ACK[new] = ACK[olds]
	ACK[olds] = nil
	CODEC[new] = CODEC[olds]
	CODEC[olds] = nil
end)
When("rename '' to named by ''", function(old,new)
	have(old)
	local newo = have(new)
	local news = newo:octet():string()
	empty(news)
	ACK[news] = ACK[old]
	ACK[old] = nil
	CODEC[news] = CODEC[old]
	CODEC[old] = nil
end)
When("rename object named by '' to named by ''", function(old,new)
	local oldo = have(old)
	local olds = oldo:octet():string()
	have(olds)
	local newo = have(new)
	local news = newo:octet():string()
	empty(news)
	ACK[news] = ACK[olds]
	ACK[olds] = nil
	CODEC[news] = CODEC[olds]
	CODEC[olds] = nil
end)

-- create '' from '' as ''
When("create '' string of ''", function(encoding, src)
		local orig = have(src)
		zencode_assert(luatype(orig) ~= 'table', "Source element is not a table: "..src)
		empty(encoding) -- destination name is encoding name
		local f = get_encoding_function(encoding)
		zencode_assert(f, "Encoding format not found: "..encoding)
		ACK[encoding] = O.from_string( f( orig:octet() ) )
		new_codec(encoding, { zentype = 'e',
							  luatype = 'string',
							  encoding = 'string' })
end)

local function move_or_copy_to(src, dest, enc)
    empty(dest)
    if not enc then
        ACK[dest] = deepcopy(have(src))
        new_codec(dest, { }, src)
    else
        ACK[dest] = apply_encoding(src, enc, "string")
        new_codec(dest, { encoding = 'string' })
    end
end

When("copy '' to ''", move_or_copy_to)

When("copy '' as '' to ''", function(src, enc, dest)
    move_or_copy_to(src, dest, enc)
end)

When("move '' to ''", function(src, dest)
    move_or_copy_to(src, dest)
    ACK[src] = nil
    CODEC[src] = nil
end)

When("move '' as '' to ''", function(src, enc, dest)
    move_or_copy_to(src, dest, enc)
    ACK[src] = nil
    CODEC[src] = nil
end)

When("copy contents of '' in ''", function(src,dst)
    local obj, obj_codec = have(src)
    zencode_assert(luatype(obj) == 'table', "Object is not a table: "..src)
    local dest, dest_codec = have(dst)
    zencode_assert(luatype(dest) == 'table', "Object is not a table: "..src)
    if dest_codec.zentype == 'a' then
        for _, v in pairs(obj) do
            table.insert(ACK[dst], v)
        end
    elseif dest_codec.zentype == 'd' then
        zencode_assert(obj_codec.zentype == 'd', "Can not copy contents of an array into a dictionary")
        for k, v in pairs(obj) do
            if ACK[dst][k] then error("Cannot overwrite: "..k.." in "..dst) end
            ACK[dst][k] = v
        end
    elseif dest_codec.zentype == 'e' and dest_codec.schema then
        local dest_schema = ZEN.schemas[dest_codec.schema]
        if luatype(dest_schema) ~= 'table' then -- old schema types are not open
            error("Schema is not open to accept extra objects: "..dst)
        elseif not dest_schema.schematype or dest_schema.schematype ~= 'open' then
            error("Schema is not open to accept extra objects: "..dst)
        end
        for k, v in pairs(obj) do
            if ACK[dst][k] then error("Cannot overwrite: "..k.." in "..dst) end
            ACK[dst][k] = v
        end
    end
end)

When("copy contents of '' named '' in ''", function(src,name,dst)
    local obj, obj_codec = have(src)
    zencode_assert(luatype(obj) == 'table', "Object is not a table: "..src)
    zencode_assert(obj_codec.zentype == 'd', "Object is not a dictionary: "..src)
    zencode_assert(obj[name], "Object not found: "..name.." inside ".. src)
    local dest, dest_codec = have(dst)
    zencode_assert(luatype(dest) == 'table', "Object is not a table: "..src)
    if dest_codec.zentype == 'a' then
        table.insert(ACK[dst], obj[name])
    elseif dest_codec.zentype == 'd' then
        zencode_assert(not dest[name], "Cannot overwrite: "..name.." in "..dst)
        ACK[dst][name] = obj[name]
    elseif dest_codec.zentype == 'e' and dest_codec.schema then
        local dest_schema = ZEN.schemas[dest_codec.schema]
        if luatype(dest_schema) ~= 'table' then -- old schema types are not open
            error("Schema is not open to accept extra objects: "..dst)
        elseif not dest_schema.schematype or dest_schema.schematype ~= 'open' then
            error("Schema is not open to accept extra objects: "..dst)
        end
        zencode_assert(dest[name], "Cannot overwrite: "..name.." in "..dst)
        ACK[dst][name] = obj[name]
    end
end)

local function move_or_copy_from_to(key_name, source, new)
    local src, src_codec = have(source)
    local key, key_enc = mayhave(key_name)
    if src_codec.zentype == 'a' then
        if key then
            if key_enc.encoding == "string" then
                key = key:str()
            elseif key_enc.encoding == "integer" then
                key = key:decimal()
            elseif key_enc.encoding == "float" then
                key = key:__tostring()
            else
                error("Invalid array key encoding: "..key_enc.encoding, 2)
            end
        else
            key = key_name
        end
        local pos = tonumber(key)
        if not pos then error("Invalid array index: "..key, 2) end
        key = pos
    else
        if key then
            if key_enc.encoding == "string" then
                key = key:str()
            else
                error("Invalid dictionary key encoding: "..key_enc.encoding, 2)
            end
        else
            key = key_name
        end
    end
    if not src[key] then error("Object not found: "..key.." inside "..source, 2) end
    if ACK[new] then
        error("Cannot overwrite existing object: "..new.."\n"..
              "To copy/move element in existing element use:\n"..
              "When I move/copy '' from '' in ''", 2)
    end
    ACK[new] = deepcopy(src[key])
    local n_codec = { encoding = src_codec.encoding }
    -- table of schemas can only contain elements
    if src_codec.schema then
        n_codec.schema = src_codec.schema
        n_codec.zentype = "e"
    end
    new_codec(new, n_codec)
    return src_codec.zentype == 'a', key
end

When("copy '' from '' to ''", move_or_copy_from_to)

When("move '' from '' to ''", function(ele, source, new)
    local is_array, to_remove = move_or_copy_from_to(ele, source, new)
    if is_array then
        table.remove(ACK[source], to_remove)
    else
        ACK[source][to_remove] = nil
    end
end)

When("split rightmost '' bytes of ''", function(len, src)
	local obj = have(src)
	empty'rightmost'
	local s = tonumber(len)
	zencode_assert(s, "Invalid number arg #1: "..type(len))
	local l,r = OCTET.chop(obj,#obj-s)
	ACK.rightmost = r
	ACK[src] = l
	new_codec('rightmost', { }, src)
end)

When("split leftmost '' bytes of ''", function(len, src)
	local obj = have(src)
	empty'leftmost'
	local s = tonumber(len)
	zencode_assert(s, "Invalid number arg #1: "..type(len))
	local l,r = OCTET.chop(obj,s)
	ACK.leftmost = l
	ACK[src] = r
	new_codec('leftmost', { }, src)
end)

local function _countchar(haystack, needle)
    return select(2, string.gsub(haystack, needle, ""))
end
When("create count of char '' found in ''", function(needle, haystack)
	local h = have(haystack)
	empty'count'
--	ACK.count = _countchar(O.to_string(h), needle)
	ACK.count = F.new(h:octet():charcount(tostring(needle)))
	new_codec('count',
		  {encoding = 'number',
		   zentype = 'e' })
end)

-- TODO:
-- When("set '' as '' with ''", function(dest, format, content) end)
-- When("append '' as '' to ''", function(content, format, dest) end)
-- When("write '' as '' in ''", function(content, dest) end)
-- implicit conversion as string

local function _rm_zeros_in(t)
    local zeros <const> = {
        number = 0,
        ['zenroom.float'] = F.new(0),
        ['zenroom.big'] = BIG.new(0)
    }
    if isarray(t) then
        local arr = {}
        for _, v in pairs(t) do
            if type(v) == 'table' then
                table.insert(arr, _rm_zeros_in(v))
            else
                local z = zeros[type(v)]
                if not z or ( z and v ~= z) then
                    table.insert(arr, v)
                end
            end
        end
        return arr
    else
        for k,v in pairs(t) do
            if type(v) == 'table' then
                t[k] = _rm_zeros_in(v)
            else
                local z = zeros[type(v)]
                if z and v == z then
                    t[k] = nil
                end
            end
        end
        return t
    end
end
-- https://github.com/dyne/Zenroom/issues/175
When("remove zero values in ''", function(target)
    local t = have(target)
    zencode_assert(luatype(t) == 'table', "Invalid table object: "..target)
    ACK[target] = _rm_zeros_in(t)
end)

When("remove spaces in ''", function(target)
    local src = have(target)
    zencode_assert(not isnumber(src), "Invalid number object: "..target)
    zencode_assert(luatype(src) ~= 'table', "Invalid table object: "..target)
    ACK[target] = src:octet():rmchar( O.from_hex('20') )
end)

When("remove newlines in ''", function(target)
    local src = have(target)
    zencode_assert(not isnumber(src), "Invalid number object: "..target)
    zencode_assert(luatype(src) ~= 'table', "Invalid table object: "..target)
    ACK[target] = src:octet():rmchar( O.from_hex('0A') )
end)

When("remove occurrences of character '' in ''",
     function(char, target)
    local src = have(target)
    local ch = have(char)
    zencode_assert(not isnumber(src), "Invalid number object: "..target)
    zencode_assert(luatype(src) ~= 'table', "Invalid table object: "..target)
    zencode_assert(not isnumber(ch), "Invalid number object: "..char)
    zencode_assert(luatype(ch) ~= 'table', "Invalid table object: "..char)
    ACK[target] = src:octet():rmchar( ch:octet() )
end)

When("compact ascii strings in ''",
     function(target)
	local src = have(target)
	zencode_assert(not isnumber(src), "Invalid number object: "..target)
	zencode_assert(luatype(src) ~= 'table', "Invalid table object: "..target)
    ACK[target] = src:octet():compact_ascii()
end)

-- When("remove all empty strings in ''", function(target)
-- 	have(target)
-- 	ACK[target] = deepmap(function(v) if trim(v) == '' then return nil end, ACK[target])
-- end)

When("create '' cast of strings in ''", function(conv, source)
	zencode_assert(CODEC[source], "Object has no codec: "..source)
	zencode_assert(CODEC[source].encoding == 'string', "Object has no string encoding: "..source)
	empty(conv)
	local src = have(source)
	local enc = input_encoding(conv)
	if luatype(src) == 'table' then
	   ACK[conv] = deepmap(function(v)
		 local s = OCTET.to_string(v)
		 zencode_assert(enc.check(s), "Object value is not a "..conv..": "..source)
		 return enc.fun( s )
	   end, src)
	else
	   local s = OCTET.to_string(src)
	   zencode_assert(enc.check(s), "Object value is not a "..conv..": "..source)
	   ACK[conv] = enc.fun(s)
	end
	new_codec(conv, {encoding = conv})
end)

When("create float '' cast of integer in ''", function(dest, source)
	empty(dest)
	local src = have(source)
    if type(src) ~= 'zenroom.big' then
        src = BIG.new(src)
    end
    ACK[dest] = F.new(BIG.to_decimal(src))
	new_codec(dest, {encoding = 'float'})
end)

When("exit with error message ''", function(err)
    local e, e_codec = mayhave(err)
    if e then
        zencode_assert(luatype(e) ~= 'table', "Error message can not be a table "..err)
        zencode_assert(e_codec.encoding == 'string', "Error message must be a string "..err)
        e = O.to_string(e)
    else
        e = err
    end
    error(space(e))
    ZEN.OK = false
end)
