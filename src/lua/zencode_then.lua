-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2019 Dyne.org foundation
-- designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

--- THEN

-- Octet to string encoding conversion mechanism: takes the name of
-- the encoding and returns the function. Octet is a first class
-- citizen in Zenroom therefore all WHEN/ACK r/w HEAP types can be
-- converted by its methods.
local function outcast_string(obj)
   local t = luatype(obj)
   if t == 'number' then
	  return tostring(obj) end
   return O.to_string(obj)
end
local function outcast_hex(obj)
   local t = luatype(obj)
   if t == 'number' then
	  return O.to_hex( O.from_string( tostring(obj) ):hex() ) end
   return O.to_hex(obj)
end
local function outcast_base64(obj)
   local t = luatype(obj)
   if t == 'number' then
	  return O.from_string( tostring(obj) ):base64() end
   return O.to_base64(obj)
end
local function outcast_url64(obj)
   local t = luatype(obj)
   if t == 'number' then
	  return O.from_string( tostring(obj) ):url64() end
   return O.to_url64(obj)
end
local function outcast_base58(obj)
	local t = luatype(obj)
	if t == 'number' then
	   return O.from_string( tostring(obj) ):base58() end
	return O.to_base58(obj)
 end 
local function outcast_bin(obj)
   local t = luatype(obj)
   if t == 'number' then
	  return O.from_string( tostring(obj) ):bin() end
   return O.to_bin(obj)
end
-- takes a string returns the function, good for use in deepmap(fun,table)
local function guess_outcast(cast)
   if     cast == 'string' then return outcast_string
   elseif cast == 'hex'    then return outcast_hex
   elseif cast == 'base64' then return outcast_base64
   elseif cast == 'url64'  then return outcast_url64
   elseif cast == 'base58'  then return outcast_base58
   elseif cast == 'bin'    then return outcast_bin
   elseif cast == 'binary'    then return outcast_bin
   elseif cast == 'number' then return(function(v) return(v) end)
   else
	  error("Invalid output conversion: "..cast, 2)
	  return nil
   end
end
local function check_codec(value)
   if not CODEC[value] then
	  return CONF.output.encoding.name
   else
	  if CODEC[value].isschema then
		 return CONF.output.encoding.name
	  else
		 return CODEC[value].name or CONF.output.encoding.name
	  end
   end
end

--------------------------------------

Then("print ''", function(v)
		if ACK[v] then
		   local fun = guess_outcast( check_codec(v) )
		   OUT[v] = fun(ACK[v]) -- value in ACK
		else
		   OUT.output = v -- raw string value
		end
end)

Then("print '' as ''", function(v,s)
		local fun = guess_outcast(s)
		if ACK[v] then
			if luatype(ACK[v]) == 'table' then
				OUT[v] = deepmap(fun, ACK[v])
			else
				OUT[v] = fun(ACK[v])
			end
		else
		   OUT.output = fun(v)
		end
end)


Then("print '' as '' in ''", function(v,s,k)
		local fun = guess_outcast(s)
		OUT[k] = fun(v)
end)

Then("print data", function()
		OUT = ACK
		local fun = function(v,k) return guess_outcast( check_codec(k) )(v) end
		if luatype(OUT) == 'table' then
		   OUT = deepmap(fun, OUT)
		else
		   OUT = fun(OUT)
		end
end)

Then("print data as ''", function(e)
		OUT = ACK
		local fun = guess_outcast(e)
		if luatype(OUT) == 'table' then
		   OUT = deepmap(fun, OUT)
		else
		   OUT = fun(OUT)
		end
end)

Then("print my data", function()
		ZEN:Iam() -- sanity checks
		OUT[WHO] = ACK
		local fun = function(v,k) return guess_outcast( check_codec(k) )(v) end
		if luatype(OUT[WHO]) == 'table' then
		   OUT[WHO] = deepmap(fun, OUT[WHO])
		else
		   OUT[WHO] = fun(OUT[WHO])
		end
end)

Then("print my data as ''", function(s)
		ZEN:Iam() -- sanity checks
		OUT[WHO] = ACK
		local fun = guess_outcast(s)
		if luatype(OUT[WHO]) == 'table' then
		   OUT[WHO] = deepmap(fun, OUT[WHO])
		else
		   OUT[WHO] = fun(OUT[WHO])
		end
end)

Then("print my ''", function(obj)
		ZEN:Iam()
		ZEN.assert(ACK[obj], "Data object not found: "..obj)
		if not OUT[WHO] then OUT[WHO] = { } end
		local fun = guess_outcast( check_codec(obj) )
		OUT[WHO][obj] = ACK[obj]
		if luatype(OUT[WHO][obj]) == 'table' then
		   OUT[WHO][obj] = deepmap(fun, OUT[WHO][obj])
		else
		   OUT[WHO][obj] = fun(OUT[WHO][obj])
		end
end)

Then("print my '' from ''", function(obj, section)
		ZEN:Iam()
		ZEN.assert(ACK[section], "Section not found: "..section)
		local got
		got = ACK[section][obj]
		ZEN.assert(got, "Data object not found: "..obj)
		local fun = guess_outcast( check_codec(obj, section) )
		if luatype(got) == 'table' then
		   got = deepmap(fun, got)
		else
		   got  = fun(got)
		end
		if not OUT[WHO] then OUT[WHO] = { } end
		OUT[WHO][obj] = got
end)

Then("print my '' as ''", function(obj,conv)
		ZEN:Iam()
		ZEN.assert(ACK[obj], "My data object not found: "..obj)
		if not OUT[WHO] then OUT[WHO] = { } end
		local fun = guess_outcast(conv)
		OUT[WHO][obj] = ACK[obj]
		if luatype(OUT[WHO][obj]) == 'table' then
		   OUT[WHO][obj] = deepmap(fun, OUT[WHO][obj])
		else
		   OUT[WHO][obj] = fun(OUT[WHO][obj])
		end
end)

Then("print the ''", function(key)
		ZEN.assert(ACK[key], "Data object not found: "..key)
		if not OUT[key] then OUT[key] = { } end
		OUT[key] = ACK[key]
		local fun = guess_outcast( check_codec(key) )
		if luatype(OUT[key]) == 'table' then
		   OUT[key] = deepmap(fun, OUT[key])
		else
		   OUT[key] = fun(OUT[key])
		end
end)

Then("print the '' as ''", function(key, conv)
		ZEN.assert(ACK[key], "Data object not found: "..key)
		if not OUT[key] then OUT[key] = { } end
		OUT[key] = ACK[key]
		local fun = guess_outcast(conv)
		if luatype(OUT[key]) == 'table' then
		   OUT[key] = deepmap(fun, OUT[key])
		else
		   OUT[key] = fun(OUT[key])
		end
end)

Then("print the '' as '' in ''", function(key, conv, section)
		ZEN.assert(ACK[section][key], "Data object not found: "..key.." inside "..section)
		if not OUT[key] then OUT[key] = { } end
		OUT[key] = ACK[section][key]
		local fun = guess_outcast(conv)
		if luatype(OUT[key]) == 'table' then
		   OUT[key] = deepmap(fun, OUT[key])
		else
		   OUT[key] = fun(OUT[key])
		end
end)

Then("print the '' in ''", function(key, section)
		ZEN.assert(ACK[section][key], "Data object not found: "..key.." inside "..section)
		if not OUT[key] then OUT[key] = { } end
		OUT[key] = ACK[section][key]
		local fun = guess_outcast( check_codec(section) )
		if luatype(OUT[key]) == 'table' then
		   OUT[key] = deepmap(fun, OUT[key])
		else
		   OUT[key] = fun(OUT[key])
		end
end)

