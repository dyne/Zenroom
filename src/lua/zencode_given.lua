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


-- GIVEN

Given("nothing", function() ZEN.assert(not DATA and not KEYS, "Unused data passed as input") end)
Given("I introduce myself as ''", function(name) ZEN:Iam(name) end)
Given("I am known as ''", function(name) ZEN:Iam(name) end)
Given("I am ''", function(name) ZEN:Iam(name) end)

Given("I have a ''", function(name)
		 ZEN:pick(name)
		 TMP.valid = true
		 TMP.data = ZEN:import(TMP.data, CONF.input.tagged)
		 ZEN:ack(name)
		 TMP = { }
end)
Given("I have my ''", function(name)
		 ZEN.assert(WHO, "No identity specified, use: Given I am ...")
		 ZEN:pickin(WHO, name)
		 TMP.valid = true
		 TMP.data = ZEN:import(TMP.data, CONF.input.tagged)
		 ZEN:ack(name)
		 TMP = { }
end)

Given("I have my valid ''", function(name)
		 ZEN.assert(WHO, "No identity specified, use: Given I am ...")
		 ZEN:pickin(WHO, name)
		 ZEN:validate(name)
		 ZEN:ack(name)
		 TMP = { }
end)

Given("I have a valid ''", function(name)
		 ZEN:pick(name)
		 ZEN:validate(name)
		 ZEN:ack(name)
		 TMP = { }
end)
Given("the '' is valid", function(name)
		 ZEN:pick(name)
		 ZEN:validate(name)
		 ZEN:ack(name)
		 TMP = { }
end)

Given("I have a '' inside ''", function(n, s)
		 ZEN:pickin(s, n)
		 TMP.valid = true
		 TMP.data = ZEN:import(TMP.data, CONF.input.tagged)
		 ZEN:ack(n)
		 ZEN:ack(s) -- save it also in ACK.section
		 TMP = { }
end)
Given("I have inside '' a ''", function(s, n)
		 ZEN:pickin(s, n)
		 TMP.valid = true
		 TMP.data = ZEN:import(TMP.data, CONF.input.tagged)
		 ZEN:ack(n)
		 ZEN:ack(s) -- save it also in ACK.section
		 TMP = { }
end)


Given("I have inside '' a valid ''", function(s, n)
		 ZEN:pickin(s, n)
		 ZEN:validate(n)
		 ZEN:ack(n)
		 ZEN:ack(s) -- save it also in ACK.section
		 TMP = { }
end)
Given("I have a valid '' inside ''", function(n, s)
		 ZEN:pickin(s, n)
		 ZEN:validate(n)
		 ZEN:ack(n)
		 ZEN:ack(s) -- save it also in ACK.section
		 TMP = { }
end)

-- public keys for keyring arrays
Given("I have a valid '' from ''", function(n, s)
		 ZEN:pickin(s, n)
		 ZEN:validate(n)
		 ZEN:ack_table(n, s)
		 TMP = { }
end)

