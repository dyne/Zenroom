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
--on Sunday, 10th April 2022
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

-- executes a guess_outcast and then operates it
-- sch may be fed with check_codec() result (name of encoding)
local function then_outcast(val, sch)
   if not val then
      error("Then outcast called on empty variable", 2)
   end
   local codec = ZEN.CODEC[sch]
   -- if sch has a codec then we extract its export function from its
   -- schema name if it exist, otherwise from its name
   -- if no codec is found then we simply extract the export function
   -- from the name sch
   local fun
   if codec then
      fun = guess_outcast(codec.schema or codec.name)
   else
      fun = guess_outcast(sch)
   end

   local lt = luatype(val)
   -- handle simple conversions
   if lt ~= 'table' then return fun(val) end
   if not codec or codec and codec.zentype ~= 'schema' then
      return deepmap(fun, val)
   end
   -- handle schema conversions
   if codec.encoding and codec.encoding == 'complex' then
      -- complex
      if not isdictionary(val) and not isarray(val) then
	 error('Complex schema value is not a dictionary: '..sch, 2)
      end
      return fun(val)
   else -- schema not complex
      local res = fun(val)
      local enc = guess_outcast( codec.encoding )
      if luatype(res) == 'table' then
	 return deepmap(enc, res)
      else
	 return enc(res)
      end
   end
   error("Then outcast cannot handle data: "..sch,2)
end

local function then_insert(dest, val, key)
   -- initialize OUT
   if not OUT[dest] then
      if ACK[dest] then
	 if luatype(ACK[dest]) ~= 'table' then
	    OUT[dest] = { ACK[dest] }
	    table.insert(OUT[dest], val)
	 elseif isarray(ACK[dest]) then
	    OUT[dest] = ACK[dest]
	    table.insert(OUT[dest], val)
	 else -- isdictionary
	    OUT[dest] = ACK[dest]
	    OUT[dest][key] = val
	 end
      else -- use only val and key
	 OUT[dest] = {}
	 if key then
	    OUT[dest][key] = val
	 else
	    table.insert(OUT[dest], val)
	 end
      end
   else -- load OUT
      if luatype(OUT[dest]) ~= 'table' then
	 -- extend string to array
	 local tmp = OUT[dest]
	 OUT[dest] = { tmp }
	 table.insert(OUT[dest], val)
      elseif isarray(OUT[dest]) then
	 table.insert(OUT[dest], val)
      else -- isdictionary
	 if not key then
	    error(key, 'Then statement targets dictionary with empty key: '..dest, 2)
	 end
	 OUT[dest][key] = val
      end
   end
end

local function iterate_data(t)
	local a = {}
	for k,v in lua_pairs(t) do
		if k ~= 'keyring' then
			table.insert(a, n)
		end
	end
	local i = 0      -- iterator variable
	return function ()   -- iterator function
	   i = i + 1
	   return a[i], t[a[i]]
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
    local codec = check_codec(name)
	if name == 'keyring' or codec == 'keyring' then
	   OUT[name] = export_keyring(val)
	else
	   OUT[name] = then_outcast( val, codec )
	end
end)

Then("print '' as ''",function(k, s)
	local val = have(k)
	if k == 'keyring' or s == 'keyring' then
	   OUT[k] = export_keyring(val)
	   warn("DEPRECATED: Then print 'keyring' as '...'")
	   warn("Please use: Then print keyring")
	else
	   OUT[k] = then_outcast( val, s )
	end
end)

Then("print my name in ''",function(dst)
		ZEN.assert(WHO, 'No identity specified: please use Given I am')
		ZEN.assert(not OUT[dst], 'Cannot overwrite OUT.'..dst)
		OUT[dst] = WHO
end)

Then("print my ''",function(k)
	Iam()
	local val = have(k)
    local codec = check_codec(k)
	-- my statements always print to a dictionary named after WHO
	if not OUT[WHO] then OUT[WHO] = { } end
	if k == 'keyring' or codec == 'keyring' then
	   OUT[WHO][k] = export_keyring(val)
	else
	   OUT[WHO][k] = then_outcast( val, codec )
	end
end)

Then("print my '' as ''",function(k, s)
	Iam()
	local val = have(k) -- use array to check in depth
	if k == 'keyring' or s == 'keyring' then
	   OUT[k] = export_keyring(val)
	   warn("DEPRECATED: Then print 'keyring' as '...'")
	   warn("Please use: Then print keyring")
	else
	   then_insert( WHO, then_outcast( val, s ), k)
	end
end)

Then("print '' from ''",function(k, f)
	local val = have(f)
    local codec = check_codec(f)
	ZEN.assert(val[k], "Object: "..k..", not found in "..f)
	if k == 'keyring' or codec == 'keyring' then
	   OUT[k] = export_keyring(val[k])
	   warn("DEPRECATED: Then print 'keyring' from '...'")
	   warn("Please use: Then print keyring from '...'")
	else
	   -- f is used in the then_outcast to support schemas
	   OUT[k] = then_outcast( val, codec )[k]
	end
end)

Then("print '' from '' as ''",function(k, f, s)
	local val = have({f,k}) -- use array to check in depth
	OUT[k] = then_outcast( val, s )
end)

Then("print '' from '' as '' in ''",function(k, f, s, d)
	local val = have({f,k}) -- use array to check in depth
	then_insert( d, then_outcast( val, s ), k)
end)

Then("print '' as '' in ''",function(k, s, d)
	local val = have(k) -- use array to check in depth
	then_insert( d, then_outcast( val, s ), k)
end)

Then("print my '' from '' as ''",function(k, f, s)
	Iam()
	local val = have({f,k}) -- use array to check in depth
	then_insert( WHO, then_outcast( val, s ), k)
end)

Then("print my '' from ''",function(k, f)
	Iam()
	local val = have(f)
	ZEN.assert(val[k], "Object: "..k..", not foun in "..f)
	-- my statements always print to a dictionary named after WHO
	if not OUT[WHO] then OUT[WHO] = { } end
	OUT[WHO][k] = then_outcast( val, check_codec(f) )[k]
end)

Then('print keyring',function()
	local val = have'keyring'
	OUT.keyring = export_keyring(val)
end)
Then('print my keyring',function()
	Iam()
	local val = have'keyring'
	OUT[WHO] = { keyring = export_keyring(val) }
end)

-- data
-- data as
-- data from
-- data from as
-- my data
-- my data as
-- my data from
-- my data from as

Then('print data',function()
	for k, v in pairs(ACK) do
       local codec = check_codec(k)
	   if k ~= 'keyring' and codec ~= 'keyring' then
	      OUT[k] = then_outcast(v, codec)
	   end
	end
end
)

Then("print data as ''",function(e)
	local fun
	for k, v in pairs(ACK) do
	   if k ~= 'keyring' then
	      OUT[k] = then_outcast(v, e)
	   end
	end
end
)
Then("print data from ''", function(src)
	local obj = have(src)
	for k,v in pairs(obj) do
	   if k ~= 'keyring' then
	      OUT[k] = then_outcast( v, check_codec(src) )
	   end
	end
end)

Then("print data from '' as ''", function(src, e)
	local obj = have(src)
	for k,v in pairs(obj) do
	   if k ~= 'keyring' then
	      OUT[k] = then_outcast( v, e )
	   end
	end
end)

Then('print my data',function()
	Iam() -- sanity checks
	OUT[WHO] = { }
	for k, v in pairs(ACK) do
	   if k ~= 'keyring' then
	      OUT[WHO][k] = then_outcast( v, check_codec(k) )
	   end
	end
end)
Then("print my data as ''",function(e)
	Iam() -- sanity checks
	OUT[WHO] = { }
	for k, v in pairs(ACK) do
	   if k ~= 'keyring' then
	      OUT[WHO][k] = then_outcast( v, e )
	   end
	end
end
)
Then("print my data from ''",function(src)
	Iam() -- sanity checks
	OUT[WHO] = { }
	local obj = have(src)
	for k, v in pairs(obj) do
	   if k ~= 'keyring' then
	      OUT[WHO][k] = then_outcast( v, check_codec(k) )
	   end
	end
end
)
Then("print my data from '' as ''",function(src, e)
	Iam() -- sanity checks
	OUT[WHO] = { }
	local obj = have(src)
	for k, v in pairs(obj) do
	   if k ~= 'keyring' then
	      OUT[WHO][k] = then_outcast( v, e )
	   end
	end
end
)

Then("print object named by ''", function(name)
	local val = have(name):string()
	local real_name = have(val)
	if real_name ~= 'keyring' then
	   OUT[val] = then_outcast( real_name, check_codec(val) )
	end
end)

