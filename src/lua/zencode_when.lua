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
    zencode_assert(obj_c.zentype == 'e', "Encoded JSON is not an element: "..src)
    zencode_assert(obj_c.encoding == 'string', "Encoded JSON is not an string: "..src)
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
    local obj = have(src)
    empty'json_unescaped_object'
    ACK.json_unescaped_object = deepmap(
        OCTET.from_string,
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

When("copy '' to ''", function(old,new)
	have(old)
	empty(new)
	ACK[new] = deepcopy(ACK[old])
	new_codec(new, { }, old)
end)

local function _copy_move_in(old, new, inside, delete)
	local src = have(old)
	local dst = have(inside)
	zencode_assert(luatype(dst) == 'table', "Destination is not a table: "..inside)
	zencode_assert(not dst[new],
			   "Cannot overwrite destination: "..new.." inside "..inside)
	dst[new] = deepcopy(src)
	ACK[inside] = dst
	if delete then
	   ACK[old] = nil
	   CODEC[old] = nil
	end
end
When("copy '' to '' in ''", function(old,new,inside)
		_copy_move_in(old, new, inside, false)
end)
When("move '' to '' in ''", function(old,new,inside)
		_copy_move_in(old, new, inside, true)
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

When("copy '' from '' to ''", function(old,inside,new)
    zencode_assert(ACK[inside][old], "Object not found: "..old.." inside "..inside)
    empty(new)
    ACK[new] = deepcopy(ACK[inside][old])
    local o_codec = CODEC[inside]
    local n_codec = { encoding = o_codec.encoding }
	-- table of schemas can only contain elements
	if o_codec.schema then
		n_codec.schema = o_codec.schema
		n_codec.zentype = "e"
	end
    new_codec(new, n_codec)
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

local function _numinput(num, codec)
	local t = type(num)
	if not iszen(t) then
		if t == 'table' then
            if codec
            and codec.encoding == 'complex'
            and codec.schema == 'date_table' then
                return num
            end
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
	elseif t == 'zenroom.big' or t == 'zenroom.float' or t == 'zenroom.time' then
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
local big_ops = {
    [_add] = BIG.zenadd,
    [_sub] = BIG.zensub,
    [_mul] = BIG.zenmul,
    [_div] = BIG.zendiv,
    [_mod] = BIG.zenmod
}
local function date_ops(op)
    return function(l, r)
        local res = {}
        local lc = type(l) == 'zenroom.time' and os.date("*t", tonumber(l)) or l
        local rc = type(r) == 'zenroom.time' and os.date("*t", tonumber(r)) or r
        local fields = { 'year', 'month', 'day', 'hour', 'min', 'sec' }
        for _, v in pairs(fields) do
            res[v] = TIME.new(op(tonumber(lc[v]) or 0, tonumber(rc[v]) or 0))
        end
        return res
    end
end
local date_ops = {
    [_add] = date_ops(_add),
    [_sub] = date_ops(_sub)
}

local function _math_op(op, la, ra, res)
    empty(res)
    local left  = _numinput(la[1], la[2])
    local right = _numinput(ra[1], ra[2])
	local lz = type(left)
	local rz = type(right)
    if lz ~= rz and not(
        (lz == 'zenroom.time' and rz == 'table') or
        (rz == 'zenroom.time' and lz == 'table')
    ) then
        error("Incompatible numeric arguments " .. lz .. " and " .. rz, 2)
    end
    local n_codec = {zentype = 'e'}
	if lz == "zenroom.big" then
        n_codec.encoding = 'integer'
        op = big_ops[op]
        if not op then error("Operation not supported on big integers", 2) end
    elseif lz == "zenroom.time" or lz == "table" then
        n_codec.encoding = 'time'
        -- TODO: when other operations on time are supported remove this checks
        if op ~= _add and op ~= _sub then error("Operation not supported on time", 2) end
        if lz == "table" or rz == "table" then
            n_codec.encoding = 'complex'
            n_codec.schema = 'date_table'
            op = date_ops[op]
        end
	else
		n_codec.encoding = 'float'
	end
	ACK[res] = op(left, right)
    new_codec(res, n_codec)
end

When("create result of '' inverted sign", function(left)
	local l = have(left)
        local zero = 0;
        if type(l) == "zenroom.big" then
            zero = INT.new(0)
        elseif type(l) == "zenroom.float" then
            zero = F.new(0)
        end
	_math_op(_sub, zero, l, 'result')
end)

When("create result of '' + ''", function(left,right)
    _math_op(_add, table.pack(have(left)), table.pack(have(right)), 'result')
end)

When("create result of '' in '' + ''", function(left, dict, right)
    _math_op(_add, table.pack(have({dict, left})), table.pack(have(right)), 'result')
end)

When("create result of '' in '' + '' in ''", function(left, ldict, right, rdict)
    _math_op(_add, table.pack(have({ldict, left})), table.pack(have({rdict, right})), 'result')
end)

When("create result of '' - ''", function(left,right)
    _math_op(_sub, table.pack(have(left)), table.pack(have(right)), 'result')
end)

When("create result of '' in '' - ''", function(left, dict, right)
    _math_op(_sub, table.pack(have({dict, left})), table.pack(have(right)), 'result')
end)

When("create result of '' in '' - '' in ''", function(left, ldict, right, rdict)
    _math_op(_sub, table.pack(have({ldict, left})), table.pack(have({rdict, right})), 'result')
end)

When("create result of '' * ''", function(left,right)
    _math_op(_mul, table.pack(have(left)), table.pack(have(right)), 'result')
end)

When("create result of '' in '' * ''", function(left, dict, right)
    _math_op(_mul, table.pack(have({dict, left})), table.pack(have(right)), 'result')
end)

When("create result of '' * '' in ''", function(left, right, dict)
    _math_op(_mul, table.pack(have(left)), table.pack(have({dict, right})), 'result')
end)

When("create result of '' in '' * '' in ''", function(left, ldict, right, rdict)
    _math_op(_mul, table.pack(have({ldict, left})), table.pack(have({rdict, right})), 'result')
end)

When("create result of '' / ''", function(left,right)
    _math_op(_div, table.pack(have(left)), table.pack(have(right)), 'result')
end)

When("create result of '' in '' / ''", function(left, dict, right)
    _math_op(_div, table.pack(have({dict, left})), table.pack(have(right)), 'result')
end)

When("create result of '' / '' in ''", function(left, right, dict)
    _math_op(_div, table.pack(have(left)), table.pack(have({dict, right})), 'result')
end)

When("create result of '' in '' / '' in ''", function(left, ldict, right, rdict)
    _math_op(_div, table.pack(have({ldict, left})), table.pack(have({rdict, right})), 'result')
end)

When("create result of '' % ''", function(left,right)
    _math_op(_mod, table.pack(have(left)), table.pack(have(right)), 'result')
end)

When("create result of '' in '' % ''", function(left, dict, right)
    _math_op(_mod, table.pack(have({dict, left})), table.pack(have(right)), 'result')
end)

When("create result of '' in '' % '' in ''", function(left, ldict, right, rdict)
    _math_op(_mod, table.pack(have({ldict, left})), table.pack(have({rdict, right})), 'result')
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

When("remove all occurrences of character '' in ''",
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

local function utrim(s)
  s = string.gsub(s, "^[%s_]+", "")
  s = string.gsub(s, "[%s_]+$", "")
  return s
end

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

When("seed random with ''",
     function(seed)
	local s = have(seed)
	zencode_assert(iszen(type(s)), "New random seed is not a valid zenroom type: "..seed)
	local fingerprint = random_seed(s) -- pass the seed for srand init
	act("New random seed of "..#s.." bytes")
	xxx("New random fingerprint: "..fingerprint:hex())
     end
)

local ops2 = {
    ['zenroom.big'] = {['+'] = BIG.zenadd, ['-'] = BIG.zensub, ['*'] = BIG.zenmul, ['/'] = BIG.zendiv},
    ['zenroom.float'] = {['+'] = F.add, ['-'] = F.sub, ['*'] = F.mul, ['/'] = F.div},
    ['zenroom.time'] = {['+'] = TIME.add, ['-'] = TIME.sub}
}

local function apply_op2(op, a, b)
    local a_type = type(a)
    if a_type ~= type(b) then error("Different types to do arithmetics on: "..type(a).." and "..type(b), 2) end
    if ops2[a_type] and ops2[a_type][op] then
        return ops2[a_type][op](a, b)
    else
        error("Unknown type to do arithmetics on: "..type(a), 2)
    end
end

local ops1 = {
    ['zenroom.big'] = {['~'] = BIG.zenopposite},
    ['zenroom.float'] = {['~'] = F.opposite},
    ['zenroom.time'] = {['~'] = TIME.opposite}
}

local function apply_op1(op, a)
    local a_type = type(a)
    if ops1[a_type] and ops1[a_type][op] then
        return ops1[a_type][op](a)
    else
        error("Unknown type to do arithmetics on: "..type(a), 2)
    end
end


-- ~ is unary minus
local priorities = {['+'] = 0, ['-'] = 0, ['*'] = 1, ['/'] = 1, ['~'] = 2}
When("create result of ''", function(expr)
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
      zencode_assert(#operators > 0, "Paranthesis not balanced", 2)
      operators[#operators] = nil -- remove open parens
    else
      table.insert(rpn, v)
    end
  end

  -- all remaining operators have to be applied
  for i = #operators, 1, -1 do
    if operators[i] == '(' then
      zencode_assert(false, "Paranthesis not balanced", 2)
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
      zencode_assert(#values >= 2)
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

  zencode_assert(#values == 1, "Invalid arithmetical expression", 2)
  ACK.result = values[1]
  local n_codec = {zentype = 'e'}
  if type(values[1]) == 'zenroom.big' then
    n_codec.encoding = 'integer'
  elseif type(values[1]) == 'zenroom.float' then
    n_codec.encoding = 'float'
  elseif type(values[1]) == 'zenroom.time' then
    n_codec.encoding = 'time'
  end
  new_codec('result', n_codec)
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
