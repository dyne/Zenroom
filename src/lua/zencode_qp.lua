--[[
--This file is part of zenroom
--
--Copyright (C) 2022 Dyne.org foundation
--designed, written and maintained by Alberto Lerda and Denis Roio
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License v3.0
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--Along with this program you should have received a copy of the
--GNU Affero General Public License v3.0
--If not, see http://www.gnu.org/licenses/agpl.txt
--
--Last modified by Denis Roio
--on 
--]]

local QP = require'qp'

--[[non ho ben capito se 
   -qua devo dichiarare tutte le varibili che useròall'interno di tutti i when
   -se dora in poi ogni volta che dichiaro una chaive
    privata devo chiamarla dilithium_private_key (stessa cosa con public_key),
   -il msg da firmare come lo prendo in input?
--]]
ZEN.add_schema(
   {
      dilithium_public_key = { import = O.from_hex,
			       export = O.to_hex },
      dilithium_private_key = { import = O.from_hex,
				export = O.to_hex },
      dilithium_signature = { import = O.from_hex,
			      export = O.to_hex },     
   }
)

-- generates the keys
When('create the dilithium key',
     function()
	initkeys'dilithium'
	ACK.keys.dilithium = QP.sigkeygen().private
     end
)

When('create the dilithium public key',
     function()
	empty'dilithium public key'
	local sk = havekey'dilithium'
	ACK.dilithium_public_key = QP.sigpubgen(sk)
	new_codec('dilithium public key', { zentype = 'element', encoding = 'hex'})
     end
)

When("create the dilithium public key with secret key ''",
     function(sec)
	initkeys'dilithium'
	local sk = have(sec)
	ACK.keys.dilithium = sk
	empty'dilithium public key'
	ACK.dilithium_public_key = QP.sigpubgen(sk)
	new_codec('dilithium public key', { zentype = 'element', encoding = 'hex'})
     end
)

When("create the dilithium keypair with secret key ''",
     function(sec)
	local sk = have(sec)
	empty'keys'
	local pub = QP.sigpubgen(sk)
	ACK.keys = {
	   dilithium_public_key = pub,
	   dilithium_private_key = sk
	}
	new_codec('keys', { zentype = 'schema' })
     end
)

-- generate the sign for a msg and verify
When("create the signature of ''",
     function(doc)
	local sk = havekey'dilithium'
	local obj = have(doc)
	empty'dilithium_signature'
	ACK.dilithium_signature = QP.sign(sk, obj)
     end
)

-- check various locations to find the public key
local function _pubkey_compat(_key)
   local pubkey = ACK[_key]
   if not pubkey then
      local pubkey_arr
      pubkey_arr = ACK.dilithium_public_key
      if luatype(pubkey_arr) == 'table' then
	 pubkey = pubkey_arr[_key]
      else
	 pubkey = pubkey_arr
      end
      ZEN.assert(pubkey, 'Public key not found for: ' .. _key)
   end
   return pubkey
end


IfWhen("verify the '' has a signature in '' by ''",
       function(msg, sig, by)
	  local pk = -pubkey_compat(by)
	  local m = have(msg)
	  local s = have(sig)
	  
	  ZEN.assert(
	     QP.verify(pk, s, m),
	     'The signature by '..by..' is not authentic'
	  )
       end
)
