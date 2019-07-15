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

-- Zencode statements to manage data

-- GLOBALS:
-- data        (root, decoded from DATA in Given)
-- selection   (currently selected portion of root)

ZEN.data = { }

function ZEN.data.load()
   local _data
   if DATA then -- global set by zenroom
      _data = JSON.decode(DATA)
   else
      _data = { }
   end
   return _data
end

function ZEN.data.add(_data, key, value)
   if _data[key] then
      error("ZEN.data.add(): DATA already contains '"..key.."' key")
   end
   if value['schema'] then
      ZEN.assert(validate(value, schemas[value['schema']]),
                 "ZEN.data.add(): invalid data format for "..key..
                    " (schema: "..value['schema']..")", value)
   end
   _data[key] = value
   return _data
end

function ZEN.data.conjoin(_data, key, value, section)
   portion = { }
   if section and _data[section] then
      portion = _data[section]
   end
   if value['schema'] then
      ZEN.assert(validate(value, schemas[value.schema]),
   				 "conjoin(): invalid data format for "..section.."."..key..
   					" (schema: "..value.schema..")")
   end
   portion[key] = value
   if section then
   	  _data[section] = portion
   else
   	  table.insert(_data, portion)
   end
   return _data
end

function ZEN.data.disjoin(_data, section, key)
   portion = _data[section] -- L.property(section)(_data)
   local out = {}
   L.map(portion, function(k,v)
            if k ~= key then
               out[k] = v end end)
   _data[section] = out
   return _data
end


-- most used functions
Then("print all data", function()
		OUT = ACK
end)
f_hello = function(nam) ACK.whoami = nam end
Given("I introduce myself as ''", f_hello)
Given("I am known as ''", f_hello)
Given("I have a ''", function(sc)
		 local obj = IN[sc] or IN.KEYS[sc]
		 ZEN.assert(obj, "Data not found: '"..sc.."'")
		 -- xxx(2,"importing data '"..sc.."'")
		 ACK[sc] = import(obj,sc)
end)
Given("I have inside '' a ''", function(k, sc) 
		 local obj = IN[k] or IN.KEYS[k]
		 obj = obj[sc]
		 ZEN.assert(obj, "Data not found: '"..k.."' containing '"..sc.."'")
		 -- xxx(2,"importing data '"..k.."' with schema '"..sc.."'")
		 ACK[sc] = import(obj,sc)
end)
Given("I have my ''", function(sc)
		 local obj = IN[ACK.whoami] or IN.KEYS[ACK.whoami]
		 if obj[sc] then obj = obj[sc] end
		 ZEN.assert(obj, "Data not found: '"..ACK.whoami.."' containing '"..sc.."'")
		 ACK[sc] = import(obj,sc)
end)
Given("my keys have ''", function(sc)
		 local obj
		 if ACK.whoami then
			obj = IN.KEYS[ACK.whoami]
		 else obj = IN.KEYS end
		 if obj[sc] then obj = obj[sc] end -- nested object inside name
		 ZEN.assert(obj, "Keys not found: '"..sc.."'")
		 ACK[sc] = import(obj,sc)
end)

-- debug functions
Given("print debug info", function() ZEN.debug() end)
When("print debug info", function() ZEN.debug() end)
Then("print debug info", function() ZEN.debug() end)

f_datarm = function (section)
   --   local _data = IN or ZEN.data.load()
   if not IN          then error("No data loaded") end
   if not selection   then error("No data selected") end
   if not section     then error("Specify the data portion to remove") end
   OUT = ZEN.data.disjoin(IN, selection, section)
end

When("I declare that I am ''", function(decl)
		-- declaration
		if not ACK.declared then ACK.declared = decl
		else ACK.declared = ACK.declared .." and ".. decl end
end)

When("I declare to '' that I am ''",function (auth,decl)
        -- declaration
        if not ACK.declared then ACK.declared = decl
        else ACK.declared = ACK.declared .." and ".. decl end
        -- authority
        ACK.authority = auth
end)

When("I include the text ''", function(text)
		if not ACK.draft then ACK.draft = { } end
		if ACK.draft.text then
			  ACK.draft.text = ACK.draft.text.."\n"..text
		else
		   ACK.draft.text = text
		end
end)

When("I include the hex data ''", function(data)
		if not ACK.draft then ACK.draft = { } end
		ZEN.assert(IN[data], "Data not found in input: "..data)
		ACK.draft.data = hex(IN[data])
end)

When("I include myself as sender", function(data)
		ZEN.assert(ACK.whoami, "No identity specified")
		if not ACK.draft then ACK.draft = { } end
		ACK.draft.from = ACK.whoami
end)

Given("that '' declares to be ''",function(who, decl)
         -- declaration
         if not ACK.declared then ACK.declared = decl
         else ACK.declared = ACK.declared .." and ".. decl end
         ACK.whois = who
end)
Given("declares also to be ''", function(decl)
         ZEN.assert(ACK.who ~= "", "The subject making the declaration is unknown")
         -- declaration
         if not ACK.declared then ACK.declared = decl
         else ACK.declared = ACK.declared .." and ".. decl end
end)

When("I remove '' from data", f_datarm)

local function _print_the_data(what)
   ZEN.assert(ACK[what], "Cannot print, data not found: "..what)
   OUT[what] = ACK[what]
end
Then("print data ''", _print_the_data)
Then("print the ''", _print_the_data)
Then("print my ''", function(what)
		ZEN.assert(ACK.whoami, "No identity specified")
		ZEN.assert(ACK[what], "Cannot print, data not found: "..what)
		local t = OUT[ACK.whoami] or { }
		t[what] = ACK[what]
		OUT[ACK.whoami] = t
end)
Then("print my data", function()
		ZEN.assert(ACK.whoami, "No identity specified")
		OUT[ACK.whoami] = ACK[ACK.whoami]
end)
Then("print '' ''", function (sect, what)
		OUT[sect] = what
end)
