--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2021 Dyne.org foundation
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
--on Friday, 26th November 2021
--]]

--- WHEN

-- nop to terminate IF blocks
When("done", function() end)


local function _is_found(el, t)
	if not t then
		return ACK[el] and (luatype(ACK[el]) == 'table' or #ACK[el] ~= 0)
	else
		ZEN.assert(ACK[t], "Array or dictionary not found in: "..t)
		if ZEN.CODEC[t].zentype == 'array' then
			local o_el = O.from_string(el)
			for _,v in pairs(ACK[t]) do
				if v == o_el then return true end
			end
		elseif ZEN.CODEC[t].zentype == 'dictionary' then
			return ACK[t][el] and (luatype(ACK[t][el]) == 'table' or #ACK[t][el] ~= 0)
		else
			ZEN.assert(false, "Invalid container type: "..t.." is "..ZEN.CODEC[t].zentype)
		end
	end
	return false
end

IfWhen("'' is found", function(el)
	ZEN.assert(_is_found(el), "Cannot find object: "..el)
end)
IfWhen("'' is not found", function(el)
	ZEN.assert(not _is_found(el), "Object should not be found: "..el)
end)

IfWhen("'' is found in ''", function(el, t)
	ZEN.assert(_is_found(el, t), "Cannot find object: "..el.." in "..t)
end)
IfWhen("'' is not found in ''", function(el, t)
	ZEN.assert(not _is_found(el,t), "Object: "..el.." should not be found in "..t)
end)

When("append '' to ''", function(src, dest)
		local val = have(src)
		local dst = have(dest)
		ZEN.assert(luatype(dst) ~= 'table',
				   "Cannot append to table: "..dest)
		-- if the destination is a number, fix the encoding to string
		if isnumber(dst) then
		   dst = O.from_string( tostring(dst) )
		   ZEN.CODEC[dest].encoding = "string"
		   ZEN.CODEC[dest].luatype = "string"
		   ZEN.CODEC[dest].zentype = "element"
        end
        if isnumber(val) then
		   val = O.from_string( tostring(val) )
		end
        dst = dst:octet() .. val
		ACK[dest] = dst
end)

When("append the string '' to ''", function(hstr, dest)
	local dst = have(dest)
	ZEN.assert(luatype(dst) ~= 'table', "Cannot append to table: "..dest)
	-- if the destination is a number, fix the encoding to string
	if isnumber(dst) then
	   dst = O.from_string( tostring(dst) )
	   ZEN.CODEC[dest].encoding = "string"
	   ZEN.CODEC[dest].luatype = "string"
	   ZEN.CODEC[dest].zentype = "element"
	end
	dst = dst:octet() .. O.from_string(hstr)
	ACK[dest] = dst
end)

When("append the '' of '' to ''", function(enc, src, dest)
	local from = have(src)
	local to = have(dest)
	ZEN.assert(type(to) == 'zenroom.octet', "Destination type is not octet: "..dest.." ("..type(to)..")")
	ZEN.assert(ZEN.CODEC[dest].encoding == 'string', "Destination encoding is not string: "..dest)
	local f = guess_outcast(enc)
	ZEN.assert(f, "Encoding format not found: "..enc)
	to = to .. O.from_string( f( from:octet() ) )
	ACK[dest] = to
end)

When("create the ''", function(dest)
	empty (dest)
	ACK[dest] = { }
	ZEN.CODEC[dest] = guess_conversion(ACK[dest], dest)
	ZEN.CODEC[dest].name = dest
end)
When("create the '' named ''", function(sch, name)
	empty(name)
	ACK[name] = { }
	ZEN.CODEC[name] = guess_conversion(ACK[name], sch)
	ZEN.CODEC[name].name = name
end)

-- simplified exception for I write: import encoding from_string ...
When("write string '' in ''", function(content, dest)
	empty(dest)
	ACK[dest] = O.from_string(content)
	ZEN.CODEC[dest] = new_codec(dest,
				    {encoding = 'string',
				     luatype = 'string',
				     zentype = 'element' })
end)

-- ... and from a number
When("write number '' in ''", function(content, dest)
	empty(dest)
	-- TODO: detect number base 10
	local num = tonumber(content)
	ZEN.assert(num, "Cannot convert value to number: "..content)
--	if num > 2147483647 then
--		error('Overflow of number object over 32bit signed size')
		-- TODO: maybe support unsigned native here
--	end
	ACK[dest] = F.new(content)
	ZEN.CODEC[dest] = new_codec(dest, {zentype = 'element' })
end)

When("create the number from ''", function(from)
	empty'number'
	local get = have(from)
	ACK.number = BIG.from_decimal(get:octet():string())
	ZEN.CODEC.number = new_codec('number', {zentype = 'element' })
end)

When("set '' to '' as ''", function(dest, content, format)
	empty(dest)
	local guess = input_encoding(format)
	guess.raw = content
	guess.name = dest
	ACK[dest] = operate_conversion(guess)
--	ZEN.CODEC[dest] = new_codec(dest, { luatype = luatype(ACK[dest]), zentype = 'element' })
end)

When("create the json of ''", function(src)
	local obj, codec = have(src)
	empty'json'
	local encoding = fif( codec.encoding == 'complex',
						  codec.schema or src, codec.encoding)
	ACK.json = OCTET.from_string(

	   JSON.encode(obj, encoding)
	)
	new_codec('json', {encoding = 'string',
			   zentype = 'element'})
end)

-- numericals
When("set '' to '' base ''", function(dest, content, base)
	empty(dest)
	local bas = tonumber(base)
	ZEN.assert(bas, "Invalid numerical conversion for base: "..base)
	local num = tonumber(content,bas)
	ZEN.assert(num, "Invalid numerical conversion for value: "..content)
	ACK[dest] = F.new(num)
	ZEN.CODEC[dest] = new_codec(dest,
 				    {encoding = 'number',
 				     zentype = 'element' })
end)

local function _delete_f(name)
   have(name)
   ACK[name] = nil
   ZEN.CODEC[name] = nil
end
When("delete ''", _delete_f)
When("remove ''", _delete_f)
When("delete the ''", _delete_f)
When("remove the ''", _delete_f)

When("rename the '' to ''", function(old,new)
	have(old)
	empty(new)
	ACK[new] = ACK[old]
	ACK[old] = nil
	ZEN.CODEC[new] = ZEN.CODEC[old]
	ZEN.CODEC[old] = nil
end)
When("rename '' to ''", function(old,new)
	have(old)
	empty(new)
	ACK[new] = ACK[old]
	ACK[old] = nil
	ZEN.CODEC[new] = ZEN.CODEC[old]
	ZEN.CODEC[old] = nil
end)
When("rename the object named by '' to ''", function(old,new)
	local oldo = have(old)
	local olds = oldo:octet():string()
	have(olds)
	empty(new)
	ACK[new] = ACK[olds]
	ACK[olds] = nil
	ZEN.CODEC[new] = ZEN.CODEC[olds]
	ZEN.CODEC[olds] = nil
end)
When("rename '' to named by ''", function(old,new)
	have(old)
	local newo = have(new)
	local news = newo:octet():string()
	empty(news)
	ACK[news] = ACK[old]
	ACK[old] = nil
	ZEN.CODEC[news] = ZEN.CODEC[old]
	ZEN.CODEC[old] = nil
end)
When("rename the object named by '' to named by ''", function(old,new)
	local oldo = have(old)
	local olds = oldo:octet():string()
	have(olds)
	local newo = have(new)
	local news = newo:octet():string()
	empty(news)
	ACK[news] = ACK[olds]
	ACK[olds] = nil
	ZEN.CODEC[news] = ZEN.CODEC[olds]
	ZEN.CODEC[olds] = nil
end)

When("create the '' string of ''", function(encoding, src)
		local orig = have(src)
		ZEN.assert(luatype(orig) ~= 'table', "Source element is not a table: "..src)
		empty(encoding) -- destination name is encoding name
		local f = guess_outcast(encoding)
		ZEN.assert(f, "Encoding format not found: "..encoding)
		ACK[encoding] = O.from_string( f( orig:octet() ) )
		new_codec(encoding, { zentype = 'element',
							  luatype = 'string',
							  encoding = 'string' })
end)

When("copy the '' to ''", function(old,new)
	have(old)
	empty(new)
	ACK[new] = deepcopy(ACK[old])
	new_codec(new, { }, old)
end)

local function _copy_move_in(old, new, inside, delete)
	local src = have(old)
	local dst = have(inside)
	ZEN.assert(luatype(dst) == 'table', "Destination is not a table: "..inside)
	ZEN.assert(not dst[new],
			   "Cannot overwrite destination: "..new.." inside "..inside)
	dst[new] = deepcopy(src)
	ACK[inside] = dst
	if delete then
	   ACK[old] = nil
	   ZEN.CODEC[old] = nil
	end
end
When("copy the '' to '' in ''", function(old,new,inside)
		_copy_move_in(old, new, inside, false)
end)
When("move the '' to '' in ''", function(old,new,inside)
		_copy_move_in(old, new, inside, true)
end)


When("copy '' to ''", function(old,new)
	have(old)
	empty(new)
	ACK[new] = deepcopy(ACK[old])
	new_codec(new, { }, old)
end)

When("copy contents of '' in ''", function(src,dst)
	local obj = have(src)
	have(dst)
	for k, v in pairs(obj) do
	   ACK[dst][k] = v -- no deepcopy
	   -- no new codec (using dst)
	end
end)

When("copy contents of '' named '' in ''", function(src,name,dst)
	local obj = have(src)
	have(dst)
	for k, v in pairs(obj) do
	   if k == name then
	      ACK[dst][k] = v -- no deepcopy
	   end
	   -- no new codec (using dst)
	end
end)

When("copy the '' in '' to ''", function(old,inside,new)
	ZEN.assert(ACK[inside][old], "Object not found: "..old.." inside "..inside)
	empty(new)
	ACK[new] = deepcopy(ACK[inside][old])
	new_codec(new, { }, inside)
end)

When("split the rightmost '' bytes of ''", function(len, src)
	local obj = have(src)
	empty'rightmost'
	local s = tonumber(len)
	ZEN.assert(s, "Invalid number arg #1: "..type(len))
	local l,r = OCTET.chop(obj,#obj-s)
	ACK.rightmost = r
	ACK[src] = l
	new_codec('rightmost', { }, src)
end)

When("split the leftmost '' bytes of ''", function(len, src)
	local obj = have(src)
	empty'leftmost'
	local s = tonumber(len)
	ZEN.assert(s, "Invalid number arg #1: "..type(len))
	local l,r = OCTET.chop(obj,s)
	ACK.leftmost = l
	ACK[src] = r
	new_codec('leftmost', { }, src)
end)

local function _numinput(num)
	local t = type(num)
	if not iszen(t) then
		if t == 'table' then
			local aggr = nil
			for _,v in pairs(num) do
				if aggr then
                    aggr = aggr + _numinput(v)
                else
                    aggr = _numinput(v)
                end
			end
			return aggr
		elseif t ~= 'number' then
			error('Invalid numeric type: ' .. t, 2)
		end
		return num
	end
	if t == 'zenroom.octet' then
		return BIG.new(num)
	elseif t == 'zenroom.big' or t == 'zenroom.float' then
		return num
	else
		return BIG.from_decimal(num:octet():string()) -- may give internal errors
	end
	error("Invalid number", 2)
	return nil
end

-- escape math function overloads for pointers
local function _add(l,r) return(l + r) end
local function _sub(l,r) return(l - r) end
local function _mul(l,r) return(l * r) end
local function _div(l,r) return(l / r) end
local function _mod(l,r) return(l % r) end

local function _math_op(op, l, r, bigop)
	local left  = _numinput(l)
	local right = _numinput(r)
	local lz = type(left)
	local rz = type(right)
	if lz ~= rz then error("Incompatible numeric arguments", 2) end
	local codec
	ACK.result = true -- new_codec checks existance
	if lz == "zenroom.big" then
		codec = new_codec('result',
				  {encoding = 'integer',
				   luatype = 'userdata',
				   zentype = 'element',
                   rawtype = 'zenroom.big'})
	else
		codec = new_codec('result',
				  {encoding = 'float',
				   luatype = 'userdata',
				   zentype = 'element',
                   rawtype = 'zenroom.float'})
	end
        if type(left) == 'zenroom.big'
          and type(right) == 'zenroom.big' then
          if bigop then
            op = bigop
          -- -- We should check if the operatoin is supported
          --else
          --  error("Operation not supported on big integers")
          end
        end
	return op(left, right), codec
end

When("create the result of '' inverted sign", function(left)
	local l = have(left)
	empty 'result'
        local zero = 0;
        if type(l) == "zenroom.big" then
            zero = INT.new(0)
        elseif type(l) == "zenroom.float" then
            zero = F.new(0)
        end
	ACK.result, ZEN.CODEC.result = _math_op(_sub, zero, l, BIG.zensub)
end)

When("create the result of '' + ''", function(left,right)
	local l = have(left)
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_add, l, r, BIG.zenadd)
end)

When("create the result of '' in '' + ''", function(left, dict, right)
	local d = have(dict)
	local l = d[left]
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_add, l, r, BIG.zenadd)
end)

When("create the result of '' in '' + '' in ''", function(left, ldict, right, rdict)
	local ld = have(ldict)
	local l = ld[left]
	local rd = have(rdict)
	local r = rd[right]
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_add, l, r, BIG.zenadd)
end)

When("create the result of '' - ''", function(left,right)
	local l = have(left)
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_sub, l, r, BIG.zensub)
end)

When("create the result of '' in '' - ''", function(left, dict, right)
	local d = have(dict)
	local l = d[left]
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_sub, l, r, BIG.zensub)
end)

When("create the result of '' in '' - '' in ''", function(left, ldict, right, rdict)
	local ld = have(ldict)
	local l = ld[left]
	local rd = have(rdict)
	local r = rd[right]
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_sub, l, r, BIG.zensub)
end)

When("create the result of '' * ''", function(left,right)
	local l = have(left)
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_mul, l, r, BIG.zenmul)
end)

When("create the result of '' in '' * ''", function(left, dict, right)
	local d = have(dict)
	local l = d[left]
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_mul, l, r, BIG.zenmul)
end)

When("create the result of '' * '' in ''", function(left, right, dict)
	local l = have(left)
	local d = have(dict)
	local r = d[right]
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_mul, l, r, BIG.zenmul)
end)

When("create the result of '' in '' * '' in ''", function(left, ldict, right, rdict)
	local ld = have(ldict)
	local l = ld[left]
	local rd = have(rdict)
	local r = rd[right]
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_mul, l, r, BIG.zenmul)
end)

When("create the result of '' / ''", function(left,right)
	local l = have(left)
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_div, l, r, BIG.zendiv)
end)

When("create the result of '' in '' / ''", function(left, dict, right)
	local d = have(dict)
	local l = d[left]
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_div, l, r, BIG.zendiv)
end)

When("create the result of '' / '' in ''", function(left, right, dict)
	local l = have(left)
	local d = have(dict)
	local r = d[right]
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_div, l, r, BIG.zendiv)
end)

When("create the result of '' in '' / '' in ''", function(left, ldict, right, rdict)
	local ld = have(ldict)
	local l = ld[left]
	local rd = have(rdict)
	local r = rd[right]
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_div, l, r, BIG.zendiv)
end)

When("create the result of '' % ''", function(left,right)
	local l = have(left)
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_mod, l, r, BIG.zenmod)
end)

When("create the result of '' in '' % ''", function(left, dict, right)
	local d = have(dict)
	local l = d[left]
	local r = have(right)
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_mod, l, r, BIG.zendiv)
end)

When("create the result of '' in '' % '' in ''", function(left, ldict, right, rdict)
	local ld = have(ldict)
	local l = ld[left]
	local rd = have(rdict)
	local r = rd[right]
	empty 'result'
	ACK.result, ZEN.CODEC.result = _math_op(_mod, l, r, BIG.zendiv)
end)

local function _countchar(haystack, needle)
    return select(2, string.gsub(haystack, needle, ""))
end
When("create the count of char '' found in ''", function(needle, haystack)
	local h = have(haystack)
	empty'count'
--	ACK.count = _countchar(O.to_string(h), needle)
	ACK.count = F.new(h:octet():charcount(tostring(needle)))
	new_codec('count',
		  {encoding = 'number',
		   zentype = 'element' })
end)

-- TODO:
-- When("set '' as '' with ''", function(dest, format, content) end)
-- When("append '' as '' to ''", function(content, format, dest) end)
-- When("write '' as '' in ''", function(content, dest) end)
-- implicit conversion as string

-- https://github.com/dyne/Zenroom/issues/175
When("remove zero values in ''", function(target)
    local types = {"number", "zenroom.float", "zenroom.big"}
    local zeros = {0, F.new(0), BIG.new(0)}
	have(target)
	ACK[target] = deepmap(function(v)
        for i =1,#types do
            if type(v) == types[i] then
                if v == zeros[i] then
                    return nil
                else
                    return v
                end
            end
            i = i + 1
        end
        return v
	end, ACK[target])
end)

When("remove spaces in ''", function(target)
    local src = have(target)
    ZEN.assert(not isnumber(src), "Invalid number object: "..target)
    ZEN.assert(luatype(src) ~= 'table', "Invalid table object: "..target)
    ACK[target] = src:octet():rmchar( O.from_hex('20') )
end)

When("remove newlines in ''", function(target)
    local src = have(target)
    ZEN.assert(not isnumber(src), "Invalid number object: "..target)
    ZEN.assert(luatype(src) ~= 'table', "Invalid table object: "..target)
    ACK[target] = src:octet():rmchar( O.from_hex('0A') )
end)

When("remove all occurrences of character '' in ''",
     function(char, target)
    local src = have(target)
    local ch = have(char)
    ZEN.assert(not isnumber(src), "Invalid number object: "..target)
    ZEN.assert(luatype(src) ~= 'table', "Invalid table object: "..target)
    ZEN.assert(not isnumber(ch), "Invalid number object: "..char)
    ZEN.assert(luatype(ch) ~= 'table', "Invalid table object: "..char)
    ACK[target] = src:octet():rmchar( ch:octet() )
end)

When("compact ascii strings in ''",
     function(target)
	local src = have(target)
	ZEN.assert(not isnumber(src), "Invalid number object: "..target)
	ZEN.assert(luatype(src) ~= 'table', "Invalid table object: "..target)
    ACK[target] = src:octet():compact_ascii()
end)

local function utrim(s)
  s = string.gsub(s, "^[%s_]+", "")
  s = string.gsub(s, "[%s_]+$", "")
  return s
end

-- When("remove all empty strings in ''", function(target)
-- 	have(target)
-- 	ACK[target] = deepmap(function(v) if trim(v) == '' then return nil end, ACK[target])
-- end)

When("create the '' cast of strings in ''", function(conv, source)
	ZEN.assert(ZEN.CODEC[source], "Object has no codec: "..source)
	ZEN.assert(ZEN.CODEC[source].encoding == 'string', "Object has no string encoding: "..source)
	empty(conv)
	local src = have(source)
	local enc = input_encoding(conv)
	if luatype(src) == 'table' then
	   ACK[conv] = deepmap(function(v)
		 local s = OCTET.to_string(v)
		 ZEN.assert(enc.check(s), "Object value is not a "..conv..": "..source)
		 return enc.fun( s )
	   end, src)
	else
	   local s = OCTET.to_string(src)
	   ZEN.assert(enc.check(s), "Object value is not a "..conv..": "..source)
	   ACK[conv] = enc.fun(s)
	end
	new_codec(conv, {encoding = conv})
end)

When("create the float '' cast of integer in ''", function(dest, source)
	empty(dest)
	local src = have(source)
    if type(src) ~= 'zenroom.big' then
        src = BIG.new(src)
    end
    ACK[dest] = F.new(BIG.to_decimal(src))
	new_codec(dest, {encoding = 'float'})
end)

When("seed the random with ''",
     function(seed)
	local s = have(seed)
	ZEN.assert(iszen(type(s)), "New random seed is not a valid zenroom type: "..seed)
	local fingerprint = random_seed(s) -- pass the seed for srand init
	act("New random seed of "..#s.." bytes") 
	xxx("New random fingerprint: "..fingerprint:hex())
     end
)

local int_ops2 = {['+'] = BIG.zenadd, ['-'] = BIG.zensub, ['*'] = BIG.zenmul, ['/'] = BIG.zendiv}
local float_ops2 = {['+'] = F.add, ['-'] = F.sub, ['*'] = F.mul, ['/'] = F.div}

local function apply_op2(op, a, b)
  local fop = nil
  if type(a) == 'zenroom.big' and type(b) == 'zenroom.big' then
    fop = int_ops2[op]
  elseif type(a) == 'zenroom.float' and type(b) == 'zenroom.float' then
    fop = float_ops2[op]
  end
  ZEN.assert(fop, "Unknown types to do arithmetics on", 2)
  return fop(a, b)
end

local int_ops1 = {['~'] = BIG.zenopposite}
local float_ops1 = {['~'] = F.opposite}

local function apply_op1(op, a)
  local fop = nil
  if type(a) == 'zenroom.big' then
    fop = int_ops1[op]
  elseif type(a) == 'zenroom.float' then
    fop = float_ops1[op]
  end
  ZEN.assert(fop, "Unknown type to do arithmetics on", 2)
  return fop(a)
end


-- ~ is unary minus
local priorities = {['+'] = 0, ['-'] = 0, ['*'] = 1, ['/'] = 1, ['~'] = 2}
When("create the result of ''", function(expr)
  local specials = {'(', ')'}
  local i, j
  empty 'result'
  for k, v in pairs(priorities) do
    table.insert(specials, k)
  end
  -- tokenizations
  local re = '[()*%-%/+]'
  local tokens = {}
  i = 1
  repeat
    j = expr:find(re, i)
    if j then
      if i < j then
        local val = utrim(expr:sub(i, j-1))
        if val ~= "" then table.insert(tokens, val) end
      end
      table.insert(tokens, expr:sub(j, j))
      i = j+1
    end
  until not j
  if i <= #expr then
    local val = utrim(expr:sub(i))
    if val ~= "" then table.insert(tokens, val) end
  end

  -- infix to RPN
  local rpn = {}
  local operators = {}
  for k, v in pairs(tokens) do
    if v == '-' and (#rpn == 0 or operators[#operators] == '(') then
        table.insert(operators, '~') -- unary minus (change sign)
    elseif priorities[v] then
      while #operators > 0 and operators[#operators] ~= '('
           and priorities[operators[#operators]]>=priorities[v] do
        table.insert(rpn, operators[#operators])
        operators[#operators] = nil
      end
      table.insert(operators, v)
    elseif v == '(' then
      table.insert(operators, v)
    elseif v == ')' then
      -- put every operator in rpn until I don't see the open parens
      while #operators > 0 and operators[#operators] ~= '(' do
        table.insert(rpn, operators[#operators])
        operators[#operators] = nil
      end
      ZEN.assert(#operators > 0, "Paranthesis not balanced", 2)
      operators[#operators] = nil -- remove open parens
    else
      table.insert(rpn, v)
    end
  end

  -- all remaining operators have to be applied
  for i = #operators, 1, -1 do
    if operators[i] == '(' then
      ZEN.assert(false, "Paranthesis not balanced", 2)
    end
    table.insert(rpn, operators[i])
  end

  local values = {}
  -- evaluate the expression
  for k, v in pairs(rpn) do
    if v == '~' then
      local op = values[#values]; values[#values] = nil
      table.insert(values, apply_op1(v, op))
    elseif priorities[v] then
      ZEN.assert(#values >= 2)
      local op1 = values[#values]; values[#values] = nil
      local op2 = values[#values]; values[#values] = nil
      local res = apply_op2(v, op2, op1)
      table.insert(values, res)
    else
      local val
      -- is the current number a integer?
      if BIG.is_integer(v) then
        val = BIG.from_decimal(v)
      elseif F.is_float(v) then
        val = F.new(v)
      else
        val = have(v)
      end
      table.insert(values, val)
    end
  end

  ZEN.assert(#values == 1, "Invalid arithmetical expression", 2)
  ACK.result = values[1]
  if type(values[1]) == 'zenroom.big' then
    ZEN.CODEC['result'] = new_codec('result',
   		                    {encoding = 'integer',
                                    luatype = 'userdata',
                                    rawtype = 'zenroom.big',
                                    zentype = 'element' })
  elseif type(values[1]) == 'zenroom.float' then
    ZEN.CODEC['result'] = new_codec('result',
   		                    {encoding = 'number',
                                    luatype = 'userdata',
                                    rawtype = 'zenroom.float',
                                    zentype = 'element' })
  end
end)
