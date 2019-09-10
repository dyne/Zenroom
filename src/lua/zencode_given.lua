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
		 TMP.valid = ZEN:import(TMP.data)
		 ZEN:ack(name)
		 TMP = { }
end)
Given("I have my ''", function(name)
		 ZEN:pickin(ACK.whoami, name)
		 TMP.valid = ZEN:import(TMP.data)
		 ZEN:ack(name)
		 TMP = { }
end)
Given("I have a valid ''", function(name)
		 ZEN:pick(name)
		 ZEN:validate(name)
		 ZEN:ack(name)
		 TMP = { }
end)
Given("I have my valid ''", function(name)
		 ZEN.assert(ACK.whoami, "No identity specified, use: Given I am ...")
		 ZEN:pickin(ACK.whoami, name)
		 ZEN:validate(name)
		 ZEN:ack(name)
		 TMP = { }
end)


local have_a_in = function(n, s)
   ZEN:pickin(s, n)
   TMP.valid = ZEN:import(TMP.data)
   ZEN:ack(n)
   ZEN:ack(s) -- save it also in ACK.section
   TMP = { }
end
Given("I have a '' inside ''",       have_a_in)

local have_a_valid_in = function(n, s)
   ZEN:pickin(s, n)
   ZEN:validate(n)
   ZEN:ack(n)
   ZEN:ack(s) -- save it also in ACK.section
   TMP = { }
end

-- 
Given("I have a valid '' inside ''", have_a_valid_in)

-- public keys for keyring arrays
local have_a_from = function(k, f)
   ZEN:pickin(f, k)
   ZEN:validate(k)
   ZEN:ack_table(k, f)
   TMP = nil
end
Given("I have a '' from ''", have_a_from)
Given("I have a valid '' from ''", have_a_from)

-- TODO: this enforces identity of schema with key name
Given("the '' is valid", function(k)
		 ZEN:validate(k)
		 ZEN:ack(k)
		 TMP = nil
end)

