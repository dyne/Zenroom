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
--Last modified by Matteo Cristino
--on 14/03/2022
--]]

local QP = require'qp'

local function dilithium_public_key_f(obj)
   local res = O.from_hex(obj)
   ZEN.assert(
      QP.sigpubcheck(res),
      'Dilithium public key length is not correct'
   )
   return res
end

local function kyber_public_key_f(obj)
   local res = O.from_hex(obj)
   ZEN.assert(
      QP.kempubcheck(res),
      'Kyber public key length is not correct'
   )
   return res
end

-- check various locations to find the public key
-- algo can be either 'dilithium' or 'kyber'
-- I. Given I have a 's' from 't'            --> ACK.s[t] 
-- II.Given I have a 's' public key from 't' --> ACK.public_key_session[t]
local function _pubkey_compat(_key, algo)
   local pubkey = ACK[_key]
   if not pubkey then
      local pubkey_arr
      pubkey_arr = ACK[algo..'_public_key'] or ACK.public_key_session
      if luatype(pubkey_arr) == 'table' then
	 pubkey = pubkey_arr[_key]
      else
	 pubkey = pubkey_arr
      end
      ZEN.assert(
	 pubkey,
	 'Public key not found for: ' .. _key
      )
   end
   return pubkey
end

ZEN.add_schema(
   {
      dilithium_public_key = { import = dilithium_public_key_f,
			       export = O.to_hex },
      dilithium_private_key = { import = O.from_hex,
				export = O.to_hex },
      dilithium_signature = { import = O.from_hex,
			      export = O.to_hex },
      
      
      kyber_public_key = { import = kyber_public_key_f,
			   export = O.to_hex },
      kyber_private_key = { import = O.from_hex,
			    export = O.to_hex },
      kyber_secret = { import = O.from_hex,
		       export = O.to_hex },
      kyber_ciphertext = { import = O.from_hex,
			   export = O.to_hex }
   }
)

--# DILITHIUM #--

-- generate the private key
When('create the dilithium key',
     function()
	initkeys'dilithium'
	ACK.keys.dilithium = QP.sigkeygen().private
     end
)

-- generate the public key
When('create the dilithium public key',
     function()
	empty'dilithium public key'
	local sk = havekey'dilithium'
	ACK.dilithium_public_key = QP.sigpubgen(sk)
	new_codec('dilithium public key', { zentype = 'element',
					    encoding = 'hex'})
     end
)

When("create the dilithium public key with secret key ''",
     function(sec)
	local sk = have(sec)
	initkeys'dilithium'
	ACK.keys.dilithium = sk
	empty'dilithium public key'
	ACK.dilithium_public_key = QP.sigpubgen(sk)
	new_codec('dilithium public key', { zentype = 'element',
					    encoding = 'hex'})
     end
)

-- generate the sign for a msg and verify
When("create the dilithium signature of ''",
     function(doc)
	local sk = havekey'dilithium'
	local obj = have(doc)
	empty'dilithium signature'
	ACK.dilithium_signature = QP.sign(sk, obj)
	new_codec('dilithium signature', { zentypr = 'element',
					   encoding = 'hex'})
     end
)

IfWhen("verify the '' has a dilithium signature in '' by ''",
       function(msg, sig, by)
	  local pk = _pubkey_compat(by, 'dilithium')
	  local m = have(msg)
	  local s = have(sig)
	  ZEN.assert(
	     QP.verify(pk, s, m),
	     'The signature by '..by..' is not authentic'
	  )
       end
)

--# KYBER #--

-- generate the private key
When('create the kyber key',
     function()
	initkeys'kyber'
	ACK.keys.kyber = QP.kemkeygen().private
     end
)

-- generate the public key
When('create the kyber public key',
     function()
	empty'kyber public key'
	local sk = havekey'kyber'
	ACK.kyber_public_key = QP.kempubgen(sk)
	new_codec('kyber public key', { zentype = 'element',
					encoding = 'hex'})
     end
)

When("create the kyber public key with secret key ''",
     function(sec)
	local sk = have(sec)
	initkeys'kyber'
	ACK.keys.kyber = sk
	empty'kyber public key'
	ACK.kyber_public_key = QP.kempubgen(sk)
	new_codec('kyber public key', { zentype = 'element',
					encoding = 'hex' })
     end
)

-- encrypt/decrypt a secret message
When("encrypt a secret message for ''",
     function(pub)
	local pk = _pubkey_compat(pub, 'kyber')
	empty'kyber secret'
	empty'kyber ciphertext'
	local enc = QP.enc(pk)
	ACK.kyber_secret = enc.secret
	ACK.kyber_ciphertext = enc.cipher 
	new_codec('kyber secret', { zentype = 'element',
				    encoding = 'hex'})
	new_codec('kyber ciphertext', { zentype = 'element',
				       encoding = 'hex' })
     end
)

When("decrypt the text of ''",
     function(secret)
	local sk = havekey'kyber'
	local sec = have(secret)
	empty 'kyber secret'
	ACK.kyber_secret = QP.dec(sk, sec)
	new_codec('kyber secret', { zentype = 'element',
				    encoding = 'hex' })
     end
)
