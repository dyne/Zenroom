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

BROADCAST_KEY = "Decentralized Privacy-Preserving Proximity Tracing"
SHA256 = HASH.new('sha256')

ZEN.add_schema({
	  secret_day_key = function(obj)
		 local o = obj.public_key or obj -- fix recursive schema check
		 if type(o) == "string" then o = ZEN:import(o) end
		 ZEN.assert(#o == 32, "Secret day key has wrong size (not 256 bits)")
		 return o
	  end
	  -- TODO:
	  -- list of infected (array of 32 byte random hashes)
	  -- ephemeral ids (array of 16 byte AES-GCM checksums)
})

When("I renew the secret day key to a new day", function()
		ZEN.assert(ACK.secret_day_key, "Secret day key not found")
		local sk = SHA256:process(ACK.secret_day_key)
		ZEN.assert(sk, "HMAC Error renewing secret day key")
		ACK.secret_day_key = sk
end)

When("I create the ephemeral ids for each moment of the day", function()
		ZEN.assert(ACK.secret_day_key, "Secret day key not found")
		ZEN.assert(type(ACK.moments) == 'number', "Number of moments not found")
		ACK.ephemeral_ids = { }
		for i = ACK.moments,1,-1 do
		   local iv = SHA256:process(tostring(i*1000000)) -- IV = counter * 1000000
		   local PRF = SHA256:hmac(ACK.secret_day_key, BROADCAST_KEY)
		   local PRG, checksum = ECDH.aead_encrypt(PRF, PRF, iv, BROADCAST_KEY)
		   -- BROADCAST_KEY is the authenticated header
		   table.insert(ACK.ephemeral_ids, checksum) -- use the 16byte checksums
		end
end)

When("I create the proximity tracing of infected ids", function()
		ZEN.assert(type(ACK.moments) == 'number', "Number of moments not found")
		ZEN.assert(type(ACK.list_of_infected) == 'table', "List of infected not found")
		ZEN.assert(type(ACK.ephemeral_ids) == 'table', "List of ephemeral ids not found")
		ACK.proximity_tracing = { }
		for n,sk in ipairs(ACK.list_of_infected) do
		   for i = ACK.moments,1,-1 do
			  local iv = SHA256:process(tostring(i*1000000)) -- IV = counter * 1000000
			  local PRF = SHA256:hmac(sk, BROADCAST_KEY)
			  local PRG, checksum = ECDH.aead_encrypt(PRF, PRF, iv, BROADCAST_KEY)
			  for nn,eph in next, ACK.ephemeral_ids, nil do
				 if eph == checksum then
					table.insert(ACK.proximity_tracing, sk)
				 end
			  end
		   end
		end
end)
