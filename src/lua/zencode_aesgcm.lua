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

-- default to our favorite curve
CONF.curve = CONF.curve or 'goldilocks'

local _ecdh = ECDH.new(CONF.curve) -- used for validation

-- TODO: auto conversion from string prefix not just u64
ZEN.add_schema({
	  -- keypair (ECDH)
	  public = function(obj)
		 local o = obj.public or obj -- fix recursive schema check
		 if type(o) == "string" then o = OCTET.from_url64(o) end
		 ZEN.assert(_ecdh:checkpub(o), "Public key is not a valid point on curve: "..CONF.curve)
		 return o
	  end,
      keypair = function(obj)
		 local pk = obj.public
		 if type(pk) == "string" then pk = OCTET.from_url64(obj.public) end
		 ZEN.assert(_ecdh:checkpub(pk),
					"Public key is not a valid point on curve: "..CONF.curve)
		 local sk = obj.private
		 if type(sk) == "string" then sk = OCTET.from_url64(obj.private) end
         return { public  = pk,
				  -- ZEN:validate_recur(obj, 'public'), -- get(obj, 'public', ECDH.checkpub),
                  private = sk }
	  end,
	  secret_message = function(obj)
		 return { checksum = ZEN.get(obj, 'checksum'),
				  header   = ZEN.get(obj, 'header'),
				  iv       = ZEN.get(obj, 'iv'),
				  message  = ZEN.get(obj, 'message'),
				  pubkey   = ZEN.get(obj, 'pubkey') }
	  end
})

-- generate keypair
local function f_keygen()
   local kp
   local ecdh = ECDH.new(CONF.curve)
   kp = ecdh:keygen()
   ZEN:pick('keypair', kp)
   ZEN:ack('keypair')
end
When("I create my new keypair", f_keygen)
When("I generate my keys", f_keygen)

-- encrypt to a single public key
When("I encrypt the draft as ''", function(msg)
		local from = ECDH.new(CONF.curve)
		from:private(ACK.keypair.private)
		local to = ECDH.new(CONF.curve)
		to:public(ACK.public)
		ACK[msg] = from:encrypt(to, ACK.draft, str('empty'))
end)

When("I decrypt the '' as ''", function(src,dst)
		ZEN:pick(src)
		local recpt = ECDH.new(CONF.curve)
		recpt:private(ACK.keypair.private)
		ACK[dst] = recpt:decrypt(ACK[src])
end)
