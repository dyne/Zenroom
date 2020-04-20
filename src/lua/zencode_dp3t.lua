-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2020 Dyne.org foundation
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

-- Decentralized Privacy-Preserving Proximity Tracing scenarion in Zencode

SHA256 = HASH.new('sha256')

-- ZEN.add_schema({
-- 	  -- secret_day_key = function(obj)
-- 	  -- 	 ZEN.assert(#obj == 32, "Secret day key has wrong size (not 32 bytes / 256 bits)")
-- 	  -- 	 return obj
-- 	  -- end
-- 	  -- TODO:
-- 	  -- list of infected (array of 32 byte random hashes)
-- 	  -- ephemeral ids (array of 16 byte AES-GCM checksums)
-- })

When("I renew the secret day key to a new day", function()
		ZEN.assert(ACK.secret_day_key, "Secret day key not found")
		local sk = SHA256:process(ACK.secret_day_key)
		ZEN.assert(sk, "Error renewing secret day key (SHA256)")
		ACK.secret_day_key = sk
end)

When("I create the ephemeral ids for today", function()
		ZEN.assert(ACK.secret_day_key, "Secret day key not found")
		ZEN.assert(ACK.broadcast_key, "Broadcast key not found")
		ZEN.assert(type(ACK.epoch) == 'number', "Epoch length (minutes) not found")
		local PRF = SHA256:hmac(ACK.secret_day_key, ACK.broadcast_key)
		local epd = (24*60)/ACK.epoch -- num epochs per day
		local zero = OCTET.new(epd*16):zero() -- 0 byte buffer
		ACK.ephemeral_ids = { }
		for i = 0,epd,1 do
		   local PRG = AES.ctr(PRF, zero, O.from_number(i))
		   local l,r = OCTET.chop(PRG,16)
		   table.insert(ACK.ephemeral_ids, l)
		end
end)

When("I create the proximity tracing of infected ids", function()
		ZEN.assert(type(ACK.epoch) == 'number', "Number of moments not found")
		ZEN.assert(type(ACK.list_of_infected) == 'table', "List of infected not found")
		ZEN.assert(type(ACK.ephemeral_ids) == 'table', "List of ephemeral ids not found")
		ZEN.assert(ACK.broadcast_key, "Broadcast key not found")
		ACK.proximity_tracing = { }
		local epd = (24*60)/ACK.epoch -- num epochs per day
		local zero = OCTET.new(epd*16):zero() -- 0 byte buffer
		for n,sk in ipairs(ACK.list_of_infected) do
		   local PRF = SHA256:hmac(sk, ACK.broadcast_key)
		   for i = 0,epd,1 do
			  local PRG = OCTET.chop( AES.ctr(PRF, zero, O.from_number(i)), 16)
			  for nn,eph in next, ACK.ephemeral_ids, nil do
				 if eph == PRG then
					table.insert(ACK.proximity_tracing, sk)
				 end
			  end
		   end
		end
end)
