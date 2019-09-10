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

Then("print '' ''", function(k,v)
		OUT[k] = ZEN:import(v, false)
end)

Then("print all data", function()
		OUT = ACK
		OUT.whoami = nil
end)
Then("print my data", function() ZEN:Iam() -- sanity checks
		OUT[ACK.whoami] = ACK
		OUT[ACK.whoami].whoami = nil
end)
Then("print all my data", function() ZEN:Iam() 
		OUT[ACK.whoami] =
		ACK OUT[ACK.whoami].whoami = nil end)
Then("print my ''", function(obj) ZEN:Iam()
		ZEN.assert(ACK[obj], "Data not found in ACK: "..obj)
		if not OUT[ACK.whoami] then OUT[ACK.whoami] = { } end
		OUT[ACK.whoami][obj] = ACK[obj]
end)

Then("print as '' my ''", function(conv,obj)		ZEN:Iam()
		ZEN.assert(ACK[obj], "My data: "..obj.." not found to print: "..conv)
		OUT[ACK.whoami] = { draft = ZEN:export(ACK[obj], conv) }
end)
Then("print my '' as ''", function(obj,conv)		ZEN:Iam()
		ZEN.assert(ACK[obj], "My data: "..obj.." not found to print: "..conv)
		OUT[ACK.whoami] = { draft = ZEN:export(ACK[obj], conv) }
end)

Then("print the ''", function(key)
		ZEN.assert(ACK[key], "Data to print not found: "..key)
		OUT[key] = ACK[key] end)

Then("print as '' the ''", function(conv, obj) OUT[obj] = ZEN:export(ACK[obj], conv) end)
Then("print the '' as ''", function(obj, conv) OUT[obj] = ZEN:export(ACK[obj], conv) end)

Then("print as '' the '' inside ''", function(conv, obj, section)
		local src = ACK[section][obj]
		ZEN.assert(src, "Not found "..obj.." inside "..section)
		OUT[obj] = ZEN:export(src, conv)
end)
Then("print the '' as '' inside ''", function(obj, conv, section)
		local src = ACK[section][obj]
		ZEN.assert(src, "Not found "..obj.." inside "..section)
		OUT[obj] = ZEN:export(src, conv)
end)

