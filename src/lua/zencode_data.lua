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

-- IN->ACK non-validated import 
Given("I have ''",function(key)
		 ZEN:push(key, ZEN:find(key, 'IN'))
end)
Given("I have my ''",function(key)
		 ZEN.assert(ACK.whoami, "No identity specified")
		 ZEN:push(key, ZEN:find(key, 'IN')) -- TODO: :myfind
end)
-- IN->ACK validated import
Given("I have a valid ''",function(name)
		 local obj = ZEN:find(name,'IN')
		 ZEN:push(name, ZEN:valid(name,obj))
end)
-- IN->ACK validated personal import
Given("I have my valid ''",function(name)
		 ZEN.assert(ACK.whoami, "No identity specified")
		 local obj = ZEN:find(name,'IN') -- TODO: :myfind
		 ZEN:push(name, ZEN:valid(name, obj))
end)

Then("print all data", function() OUT = ACK end)
Then("print my data", function()
		ZEN.assert(ACK.whoami, "No identity specified")
		OUT[ACK.whoami] = ACK
		OUT[ACK.whoami].whoami = nil
end)
Then("print the ''", function(key)
		ZEN:push(key,ACK[key],'OUT')
end)
-- PRINT MY: put in output under my identifier (whoami)
Then("print my ''", function(key)
		ZEN:mypush(key,ACK[key],'OUT')
end)

f_hello = function(nam) ZEN:push('whoami', nam) end
Given("I introduce myself as ''", f_hello)
Given("I am known as ''", f_hello)

-- debug functions
Given("debug", function() ZEN.debug() end)
When("debug", function() ZEN.debug() end)
Then("debug", function() ZEN.debug() end)

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
