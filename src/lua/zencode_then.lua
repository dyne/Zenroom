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

 -- CODEC format:
 -- { name: string,
 --   encoding: encoding of object data, both basic and schema
 --   zentype:  zencode type: 'e'lement, 'a'rray or 'd'ictionary
 --   schema: schema name used to import or nil when basic object
 -- }

local function then_outcast(val, key, enc)
   if not val then
      error("Then outcast called on empty variable", 2)
   end
   local fun
   local codec
   if enc then
	  fun = get_encoding_function(enc)
	  if fun then return deepmap(fun, val) end
	  error("Output encoding not found: "..enc)
   end
   local codec = ZEN.HEAP.CODEC[uscore(key)]
   if not codec then error("CODEC not found for object: "..key, 2) end
   if codec.schema then
	  local schema = ZEN.schemas[codec.schema]
	  if not schema then error("Schema not found: "..key,2) end
	  if luatype(schema) == 'function' then fun = default_export_f
	  else
		 fun = schema.export or default_export_f
	  end
      -- table
      if codec.zentype ~= 'e' then
        local res = {}
        for k,v in pairs(val) do
            res[k] = fun(v)
        end
        return res
      end
      -- element
      return fun(val)
   end
   if codec.encoding then
	  fun = get_encoding_function(codec.encoding)
	  if not fun then error("CODEC encoding not found: "..codec.encoding) end
   else
	  fun = default_export_f
   end
   return deepmap(fun,val)
end

local function then_insert(dest, val, key)
   -- initialize ZEN.HEAP.OUT
   if not ZEN.HEAP.OUT[dest] then
      if ACK[dest] then
	 if luatype(ACK[dest]) ~= 'table' then
	    ZEN.HEAP.OUT[dest] = { ACK[dest] }
	    table.insert(ZEN.HEAP.OUT[dest], val)
	 elseif isarray(ACK[dest]) then
	    ZEN.HEAP.OUT[dest] = ACK[dest]
	    table.insert(ZEN.HEAP.OUT[dest], val)
	 else -- isdictionary
	    ZEN.HEAP.OUT[dest] = ACK[dest]
	    ZEN.HEAP.OUT[dest][key] = val
	 end
      else -- use only val and key
	 ZEN.HEAP.OUT[dest] = {}
	 if key then
	    ZEN.HEAP.OUT[dest][key] = val
	 else
	    table.insert(ZEN.HEAP.OUT[dest], val)
	 end
      end
   else -- load ZEN.HEAP.OUT
      if luatype(ZEN.HEAP.OUT[dest]) ~= 'table' then
	 -- extend string to array
	 local tmp = ZEN.HEAP.OUT[dest]
	 ZEN.HEAP.OUT[dest] = { tmp }
	 table.insert(ZEN.HEAP.OUT[dest], val)
      elseif isarray(ZEN.HEAP.OUT[dest]) then
	 table.insert(ZEN.HEAP.OUT[dest], val)
      else -- isdictionary
	 if not key then
	    error(key, 'Then statement targets dictionary with empty key: '..dest, 2)
	 end
	 ZEN.HEAP.OUT[dest][key] = val
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
	ZEN:crumb()
	if not ZEN.HEAP.OUT.output then
		ZEN.HEAP.OUT.output = {}
	end
	table.insert(ZEN.HEAP.OUT.output, k) -- raw string value
end)

Then("print ''", function(name)
	local val = have(name)
	ZEN.HEAP.OUT[name] = then_outcast( val, name )
end)

Then("print '' as ''",function(k, s)
	local val = have(k)
	ZEN.HEAP.OUT[k] = then_outcast( val, k, s )
end)

Then("print my name in ''",function(dst)
		ZEN.assert(WHO, 'No identity specified: please use Given I am')
		ZEN.assert(not ZEN.HEAP.OUT[dst], 'Cannot overwrite ZEN.HEAP.OUT.'..dst)
		ZEN.HEAP.OUT[dst] = WHO
end)

Then("print my ''",function(k)
	Iam()
	local val = have(k)
	-- my statements always print to a dictionary named after WHO
	if not ZEN.HEAP.OUT[WHO] then ZEN.HEAP.OUT[WHO] = { } end
	ZEN.HEAP.OUT[WHO][k] = then_outcast( val, k )
end)

Then("print my '' as ''",function(k, s)
	Iam()
	local val = have(k) -- use array to check in depth
	if k == 'keyring' or s == 'keyring' then
	   ZEN.HEAP.OUT[k] = export_keyring(val)
	   warn("DEPRECATED: Then print 'keyring' as '...'")
	   warn("Please use: Then print keyring")
	else
	   then_insert( WHO, then_outcast( val, k, s), k)
	end
end)

Then("print '' from ''",function(k, f)
	local val = have(f)
	ZEN.assert(val[k], "Object: "..k..", not found in "..f)
	-- f is used in the then_outcast to support schemas
	local tmp = then_outcast( val, f )
	ZEN.HEAP.OUT[k] = tmp[k]
end)

Then("print '' from '' as ''",function(k, f, s)
	local val = have({f,k}) -- use array to check in depth
	ZEN.HEAP.OUT[k] = then_outcast( val, k, s )
end)

Then("print '' from '' as '' in ''",function(k, f, s, d)
	local val = have({f,k}) -- use array to check in depth
	then_insert( d, then_outcast( val, k, s ), k)
end)

Then("print '' as '' in ''",function(k, s, d)
	local val = have(k) -- use array to check in depth
	then_insert( d, then_outcast( val, k, s ), k)
end)

Then("print my '' from '' as ''",function(k, f, s)
	Iam()
	local val = have({f,k}) -- use array to check in depth
	then_insert( WHO, then_outcast( val, k, s ), k)
end)

Then("print my '' from ''",function(k, f)
	Iam()
	local val = have(f)
	local codec = ZEN.HEAP.CODEC[f]
	ZEN.assert(val[k], "Object: "..k..", not foun in "..f)
	-- my statements always print to a dictionary named after WHO
	if not ZEN.HEAP.OUT[WHO] then ZEN.HEAP.OUT[WHO] = { } end
	ZEN.HEAP.OUT[WHO][k] = then_outcast( val, k, codec.encoding )[k]
end)

Then('print keyring',function()
	local val = have'keyring'
	ZEN.HEAP.OUT.keyring = ZEN.schemas['keyring'].export(val)
end)
Then('print my keyring',function()
	Iam()
	local val = have'keyring'
	ZEN.HEAP.OUT[WHO] = { keyring = ZEN.schemas['keyring'].export(val) }
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
	   if k ~= 'keyring' then
	      ZEN.HEAP.OUT[k] = then_outcast(v, k)
	   end
	end
end
)

Then("print data as ''",function(e)
	local fun
	for k, v in pairs(ACK) do
	   if k ~= 'keyring' then
	      ZEN.HEAP.OUT[k] = then_outcast(v, k, e)
	   end
	end
end
)

Then("print data from ''", function(src)
	local obj = have(src)
	local codec = ZEN.HEAP.CODEC[src]
	for k,v in pairs(obj) do
	   if k ~= 'keyring' then
	      ZEN.HEAP.OUT[k] = then_outcast( v, k, codec.encoding)
	   end
	end
end)

Then("print data from '' as ''", function(src, e)
	local obj = have(src)
	for k,v in pairs(obj) do
	   if k ~= 'keyring' then
	      ZEN.HEAP.OUT[k] = then_outcast( v, k, e )
	   end
	end
end)

Then('print my data',function()
	Iam() -- sanity checks
	ZEN.HEAP.OUT[WHO] = { }
	for k, v in pairs(ACK) do
	   if k ~= 'keyring' then
	      ZEN.HEAP.OUT[WHO][k] = then_outcast( v, k )
	   end
	end
end)
Then("print my data as ''",function(e)
	Iam() -- sanity checks
	ZEN.HEAP.OUT[WHO] = { }
	for k, v in pairs(ACK) do
	   if k ~= 'keyring' then
	      ZEN.HEAP.OUT[WHO][k] = then_outcast( v, k, e )
	   end
	end
end
)

Then("print my data from ''",function(src)
	Iam() -- sanity checks
	ZEN.HEAP.OUT[WHO] = { }
	local obj = have(src)
	local codec = ZEN.HEAP.CODEC[src]
	for k, v in pairs(obj) do
	   if k ~= 'keyring' then
	      ZEN.HEAP.OUT[WHO][k] = then_outcast( v, k, codec.encoding )
	   end
	end
end
)
Then("print my data from '' as ''",function(src, e)
	Iam() -- sanity checks
	ZEN.HEAP.OUT[WHO] = { }
	local obj = have(src)
	local codec = ZEN.HEAP.CODEC[src]
	for k, v in pairs(obj) do
	   if k ~= 'keyring' then
	      ZEN.HEAP.OUT[WHO][k] = then_outcast( v, k, codec.encoding )
	   end
	end
end
)

Then("print object named by ''", function(name)
	local real_name = have(name):string()
	local val = have(real_name)
	if real_name ~= 'keyring' then
	   ZEN.HEAP.OUT[real_name] = then_outcast( val, real_name )
	end
end)

