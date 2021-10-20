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
--on Tuesday, 13th July 2021
--]]

--- THEN combinations:
-- the
-- the from
-- the as
-- the in
-- my
-- my from
-- my as
-- the from as
-- the from in
-- the as in
-- the from as in
-- my from as
----------------------

local function then_outcast(val, sch)
	if not val then
		error("Then outcast called on empty variable", 2)
	end
	local fun = guess_outcast(sch)
	if luatype(val) == 'table' then
	   local codec = ZEN.CODEC[sch]
	   if codec and codec.zentype == 'schema' and codec.encoding == 'complex' then
	      if not isdictionary(val) then
		 error('Complex schema value is not a dictionary: '..sch, 2)
	      end
	      -- check that the schema has an hardcoded encoding
	      if ZEN.CODEC[sch] and ZEN.CODEC[sch].encoding
		 and  ZEN.CODEC[sch].encoding ~= 'complex' then
		 local res = fun(val)
		 local enc = guess_outcast( ZEN.CODEC[sch].encoding )
		 if luatype(res) == 'table' then
		    return deepmap(enc, res)
		 else
		    return enc(res)
		 end
	      else
		 return fun(val)
	      end
	   else
	      if luatype(val) == 'table' then
		 return deepmap(fun, val)
	      else
		 return fun(val)
	      end
	   end
	else
	   return fun(val)
	end
end

local function then_insert(dest, val, key)
	if not ACK[dest] then
		OUT[dest] = val
	elseif luatype(OUT[dest]) == 'table' then
		if isarray(OUT[dest]) then
			table.insert(OUT[dest], val)
		else
			assert(key, 'Then statement targets dictionary with empty key: '..dest)
			OUT[dest][key] = val
		end
	else -- extend string to array
		local tmp = OUT[dest]
		OUT[dest] = { tmp }
		table.insert(OUT[dest], val)
	end
end

Then("nothing", function() return end) -- nop to terminate if

Then("print string ''", function(k)
	if not OUT.output then
		OUT.output = {}
	end
	table.insert(OUT.output, k) -- raw string value
end)

Then("print ''", function(name)
	local val = have(name)
	OUT[name] = then_outcast( val, check_codec(name) )
end)

Then(
	"print '' as ''",
	function(k, s)
		local val = have(k)
		OUT[k] = then_outcast( val, s )
	end
)

Then(
	"print '' from ''",
	function(k, f)
		local val = have({f,k}) -- use array to check in depth
		OUT[k] = then_outcast( val, check_codec(f) )
	end
)

Then(
	"print '' from '' as ''",
	function(k, f, s)
		local val = have({f,k}) -- use array to check in depth
		OUT[k] = then_outcast( val, s )
	end
)

Then(
	"print '' from '' as '' in ''",
	function(k, f, s, d)
		local val = have({f,k}) -- use array to check in depth
		then_insert( d, then_outcast( val, s ), k)
	end
)

Then(
	"print '' as '' in ''",
	function(k, s, d)
		local val = have(k) -- use array to check in depth
		then_insert( d, then_outcast( val, s ), k)
	end
)

Then(
	"print my '' from '' as ''",
	function(k, f, s)
		local val = have({f,k}) -- use array to check in depth
		then_insert( WHO, then_outcast( val, s ), k)
	end
)

Then(
	"print my '' from ''",
	function(k, f)
		local val = have({f,k}) -- use array to check in depth
		-- my statements always print to a dictionary named after WHO
		if not OUT[WHO] then OUT[WHO] = { } end
		OUT[WHO][k] = then_outcast( val, check_codec(f) )
	end
)

Then(
	"print my '' as ''",
	function(k, s)
		local val = have(k) -- use array to check in depth
		then_insert( WHO, then_outcast( val, s ), k)
	end
)

Then(
	"print my ''",
	function(k)
		local val = have(k)
		-- my statements always print to a dictionary named after WHO
		if not OUT[WHO] then OUT[WHO] = { } end
		OUT[WHO][k] = then_outcast( val, check_codec(k) )
	end
)

Then(
	'print data',
	function()
		local fun
		for k, v in pairs(ACK) do
			fun = guess_outcast(check_codec(k))
			if luatype(v) == 'table' then
				OUT[k] = deepmap(fun, v)
			else
				OUT[k] = fun(v)
			end
		end
	end
)

Then(
	"print data as ''",
	function(e)
		local fun
		for k, v in pairs(ACK) do
			fun = guess_outcast(e)
			if luatype(v) == 'table' then
				OUT[k] = deepmap(fun, v)
			else
				OUT[k] = fun(v)
			end
		end
	end
)

Then(
	'print my data',
	function()
		Iam() -- sanity checks
		local fun
		OUT[WHO] = {}
		for k, v in pairs(ACK) do
			fun = guess_outcast(check_codec(k))
			if luatype(v) == 'table' then
				OUT[WHO][k] = deepmap(fun, v)
			else
				OUT[WHO][k] = fun(v)
			end
		end
	end
)

Then(
	"print my data as ''",
	function(s)
		Iam() -- sanity checks
		local fun
		OUT[WHO] = {}
		for k, v in pairs(ACK) do
			fun = guess_outcast(s)
			if luatype(v) == 'table' then
				OUT[WHO][k] = deepmap(fun, v)
			else
				OUT[WHO][k] = fun(v)
			end
		end
	end
)
