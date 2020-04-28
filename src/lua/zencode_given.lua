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

Given("I am known as ''", function(name) ZEN:Iam(name) end)
Given("I am ''", function(name) ZEN:Iam(name) end)

-- TODO: I have a '' as ''
Given("I have a ''", function(name)
		 ZEN:pick(name)
		 TMP.valid = true
		 ZEN:ack(name)
		 gc()
end)

Given("I have a '' as ''", function(name, enc)
		 local encoder = input_encoding(enc)
		 ZEN.assert(encoder, "Invalid input encoding for '"..name.."': "..enc)
		 ZEN:pick(name, nil, encoder)
		 TMP.valid = true
		 ZEN:ack(name)
		 gc()
end)

Given("I have my ''", function(name)
		 ZEN.assert(WHO, "No identity specified, use: Given I am ...")
		 ZEN:pickin(WHO, name)
		 TMP.valid = true
		 ZEN:ack(name)
		 gc()
end)

Given("I have my valid ''", function(name)
		 ZEN.assert(WHO, "No identity specified, use: Given I am ...")
		 ZEN:pickin(WHO, name)
		 ZEN:validate(name)
		 ZEN:ack(name)
		 gc()
end)

Given("I have a valid ''", function(name)
		 ZEN:pick(name)
		 ZEN:validate(name)
		 ZEN:ack(name)
		 gc()
end)
Given("the '' is valid", function(name)
		 ZEN:pick(name)
		 ZEN:validate(name)
		 ZEN:ack(name)
		 gc()
end)

Given("I have a '' inside ''", function(n, s)
		 ZEN:pickin(s, n)
		 TMP.valid = true
		 ZEN:ack(n) -- save it in ACK.n
		 gc()
end)
Given("I have inside '' a ''", function(s, n)
		 ZEN:pickin(s, n)
		 TMP.valid = true
		 ZEN:ack(s) -- save it in ACK.s.n
		 gc()
end)


Given("I have inside '' a valid ''", function(s, n)
		 ZEN:pickin(s, n)
		 ZEN:validate(n)
		 ZEN:ack(s) -- save it in ACK.s.n
		 gc()
end)
Given("I have a valid '' inside ''", function(n, s)
		 ZEN:pickin(s, n)
		 ZEN:validate(n)
		 ZEN:ack(n) -- save it in ACK.n
		 gc()
end)

-- public keys for keyring arrays
Given("I have a valid '' from ''", function(n, s)
		 ZEN:pickin(s, n)
		 ZEN:validate(n)
		 ZEN:ack_table(n, s)
		 gc()
end)

ZEN.add_schema({
	  array = function(obj)
		 ZEN.assert( isarray(obj) , "Not a valid array")
		 local fun = CONF.input.encoding.fun
		 ZEN.assert( luatype(fun) == 'function', "Conversion is not a valid function")
		 local _t = { }
		 for k,v in ipairs(obj) do
			table.insert(_t, fun(v))
		 end
		 return _t
	  end,
	  array_string = function(obj)
		 ZEN.assert( isarray(obj) , "Not a valid array")
		 local _t = { }
		 for k,v in ipairs(obj) do
			table.insert(_t, OCTET.from_string(v))
		 end
		 return _t
	  end,
	  array_ecp = function(obj)
		 ZEN.assert( isarray(obj) , "Not a valid array")
		 local fun = CONF.input.encoding.fun
		 ZEN.assert( luatype(fun) == 'function', "Conversion is not a valid function")
		 local _t = { }
		 for k,v in ipairs(obj) do
			table.insert(_t, ECP.new(fun(v)))
		 end
		 return _t
	  end

})

Given("I have a valid array in ''", function(a)
		 local got -- local impl of ZEN:pick for array
		 got = IN.KEYS[a] or IN[a]
		 ZEN.assert(got, "Cannot find '"..a.."' anywhere")
		 ZEN.assert(type(got) == 'table', "Object is not an array: "..a)
		 TMP = { root = nil,
				 data = got,
				 valid = false,
				 schema = 'array' }
		 assert(ZEN.OK)
		 ZEN:validate(a,'array')
		 ZEN:ack(a)
		 gc()
end)

Given("I have a valid array of '' in ''", function(t,a)
		 local got -- local impl of ZEN:pick for array
		 got = IN.KEYS[a] or IN[a]
		 ZEN.assert(got, "Cannot find '"..a.."' anywhere")
		 ZEN.assert(type(got) == 'table', "Object is not an array: "..a)
		 TMP = { root = nil,
				 data = got,
				 valid = false,
				 schema = 'array' }
		 assert(ZEN.OK)
		 ZEN:validate(a,'array_'..t:lower())
		 ZEN:ack(a)
		 gc()
end)

Given("I have a valid number in ''", function(n)
		 local num = tonumber(IN[n])
		 ZEN.assert(num, "Invalid number in "..n..": "..IN[n])
		 TMP = { root = nil,
				 data = num,
				 valid = type(num) == 'number',
				 schema = nil }
		 ZEN:ack(n)
		 gc()
end)
