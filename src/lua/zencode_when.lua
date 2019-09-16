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


--- WHEN

When("I append '' to ''", function(content, dest)
		ZEN.assert(not ZEN.schemas[dest], "When denied, schema collision detected: "..dest)
		ACK[dest] = ACK[dest] .. ZEN:import(content)
end)
When("I write '' in ''", function(content, dest)
		ZEN.assert(not ZEN.schemas[dest], "When denied, schema collision detected: "..dest)
		ACK[dest] = ZEN:import(content) -- O.from_string
end)
When("I set '' to ''", function(dest, content)
		ZEN.assert(not ZEN.schemas[dest], "When denied, schema collision detected: "..dest)
		ACK[dest] = ZEN:import(content) -- O.from_string
end)
When("I create a random ''", function(s)
		ZEN.assert(not ZEN.schemas[s], "When denied, schema collision detected: "..s)
		ACK[s] = OCTET.random(64) -- TODO: right now hardcoded 256 bit random secrets
end)

When("I verify '' is equal to ''", function(l,r)
		ZEN.assert(ACK[l] == ACK[r],
				   "When comparison failed: objects are not equal: "
					  ..l.." == "..r)
end)

When("I create a random array of '' elements", function(s)
		ACK.array = { }
		for i = s,1,-1 do
		   table.insert(ACK.array,OCTET.random(64))
		end
end)

When("I create a random '' bit array of '' elements", function(bits, s)
		ACK.array = { }
		for i = s,1,-1 do
		   table.insert(ACK.array,OCTET.random(bits/8))
		end
end)

-- TODO:
-- When("I set '' as '' with ''", function(dest, format, content) end)
-- When("I append '' as '' to ''", function(content, format, dest) end)
-- When("I write '' as '' in ''", function(content, dest) end)
-- implicit conversion as string
