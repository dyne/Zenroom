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

-- TODO: use strict table
-- https://stevedonovan.github.io/Penlight/api/libraries/pl.strict.html

-- GIVEN
local function gc()
   TMP = { }
   collectgarbage'collect'
end

Given("nothing", function() ZEN.assert(not DATA and not KEYS, "Undesired data passed as input") end)

-- maybe TODO: Given all valid data
-- convert and import data only when is known by schema and passes validation
-- ignore all other data structures that are not known by schema or don't pass validation

-- Given("I am known as ''", function(name) ZEN:Iam(name) end)
Given("am ''", function(name) ZEN:Iam(name) end)

-- variable names:
-- s = schema of variable (or encoding)
-- n = name of variable
-- t = table containing the variable

-- TODO: I have a '' as ''
Given("have a ''", function(n)
		 ZEN:pick(n)
		 ZEN:ack(n)
		 gc()
end)

Given("have a '' in ''", function(s, t)
		 ZEN:pickin(t, s)
		 ZEN:ack(s) -- save it in ACK.obj
		 gc()
end)

-- public keys for keyring arrays (scenario simple)
-- supports bot ways in from given
-- public_key : { name : value }
-- or
-- name : { public_key : value }
Given("have a '' from ''", function(s, t)
		 if not ZEN:pickin(t, s, nil, false) then
			ZEN:pickin(s, t)
		 end
		 ZEN:ack_table(s, t)
		 gc()
end)

Given("have a '' named ''", function(s, n)
		 -- ZEN.assert(encoder, "Invalid input encoding for '"..n.."': "..s)
		 ZEN:pick(n, nil, s)
		 ZEN:ack(n)
		 gc()
end)

Given("have a '' named '' in ''", function(s,n,t)
		 ZEN:pickin(t, n, s)
		 ZEN:ack(n) -- save it in ACK.name
		 gc()
end)

Given("have my ''", function(n)
		 ZEN.assert(WHO, "No identity specified, use: Given I am ...")
		 ZEN:pickin(WHO, n)
		 ZEN:ack(n)
		 gc()
end)
Given("the '' is valid", function(n)
		 ZEN:pick(n)
		 gc()
end)
Given("my '' is valid", function(n)
		 ZEN:pickin(WHO, n)
		 gc()
end)

local function array_convert(name, obj)
	local conv = guess_conversion('table',name)
	-- deepmap(conv.check, obj)
	return deepmap(conv.fun, obj)
end

ZEN.add_schema({
	  -- string = function(obj)
	  -- 	 ZEN.assert( luatype(obj) == 'string', 'Not a valid string')
	  -- 	 return OCTET.from_string(obj)
	  -- end,
	  -- number = function(obj)
	  -- 	 ZEN.assert( luatype(obj) == 'number', 'Not a valid number')
	  -- 	 return obj -- lua number internally
	  -- end,
	  array = function(obj)
		 if not isarray(obj) then error("Not a valid array: "..type(obj), 3) end
		 -- default rule input encoding
		 return deepmap(CONF.input.encoding.fun, obj)
	  end,
	  string_array = function(obj)
		 if not isarray(obj) then error("Not a valid array: "..type(obj), 3) end
		 return array_convert('string', obj)
	  end,
	  number_array = function(obj)
		 if not isarray(obj) then error("Not a valid array: "..type(obj), 3) end
		 return array_convert('number', obj)
	  end,
	  hex_array = function(obj)
		 if not isarray(obj) then error("Not a valid array: "..type(obj), 3) end
		 return array_convert('hex', obj)
	  end,
	  bin_array = function(obj)
		 if not isarray(obj) then error("Not a valid array: "..type(obj), 3) end
		 return array_convert('bin', obj)
	  end,
	  base64_array = function(obj)
		 if not isarray(obj) then error("Not a valid array: "..type(obj), 3) end
		 return array_convert('base64', obj)
	  end,
	  base58_array = function(obj)
		if not isarray(obj) then error("Not a valid array: "..type(obj), 3) end
		return array_convert('base58', obj)
	  end,
	  url64_array = function(obj)
		 if not isarray(obj) then error("Not a valid array: "..type(obj), 3) end
		 return array_convert('url64', obj)
	  end,
	  -- default encoding, semantic conversion
	  int_array = function(obj)
		 if not isarray(obj) then error("Not a valid array: "..type(obj), 3) end
		 return deepmap(INT.new, deepmap(CONF.input.encoding.fun, obj))
	  end,
	  ecp_array = function(obj)
		 if not isarray(obj) then error("Not a valid array: "..type(obj), 3) end
		 return deepmap(ECP.new, deepmap(CONF.input.encoding.fun, obj))
	  end,
	  ecp2_array = function(obj)
		 if not isarray(obj) then error("Not a valid array: "..type(obj), 3) end
		 return deepmap(ECP2.new, deepmap(CONF.input.encoding.fun, obj))
	  end
})
-- alias big to int
ZEN.add_schema({big_array = ZEN.schemas.int_array})