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
--Last modified by Alberto Lerda
--on Monday, 20th June 2022
--]]

local BBS = require'crypto_bbs'

-- TODO: Substitute the function "O.from_base64" in bbs_public_key with a custom function checking the validity of the pk point

ZEN.add_schema(
   {
      bbs_public_key = O.from_base64,
      bbs_signature = O.from_base64
   }
)

-- generate the private key
When('create the bbs key',function()
	initkeyring'bbs'
	ACK.keyring.bbs = BBS.keygen()
end)

-- generate the public key
When('create the bbs public key',function()
	empty'bbs public key'
	local sk = havekey'bbs'
	ACK.bbs_public_key = BBS.sk2pk(sk)
	new_codec('bbs public key', { zentype = 'element'})
end)

local function _key_from_secret(sec)
   local sk = have(sec)
   initkeyring'bbs'
   -- Check if the user-provided sk is reasonable
   assert(type(sk) == "zenroom.big", "sk must have type integer")
   assert(sk < ECP.order(), "sk is not a scalar")
   ACK.keyring.bbs = sk
end

When("create the bbs key with secret key ''",
     _key_from_secret
)

When("create the bbs key with secret ''",
     _key_from_secret
)

When("create the bbs public key with secret key ''",function(sec)
	local sk = have(sec)
    -- Check if the user-provided sk is reasonable
    assert(type(sk) == "zenroom.big", "sk must have type integer")
    assert(sk < ECP.order(), "sk is not a scalar")

	empty'bbs public key'
	ACK.bbs_public_key = BBS.sk2pk(sk)
	new_codec('bbs public key', { zentype = 'element'})
end)

function sign_bbs_generic(ciphersuite)
    return function(doc)
        local sk = havekey'bbs'
        local obj = have(doc)

        empty'bbs signature'
        ACK.bbs_signature = BBS.sign(ciphersuite, sk, ACK.bbs_public_key, obj)
        new_codec('bbs signature', { zentype = 'element'})
    end
end

When("create the bbs signature of '' using sha256",
    sign_bbs_generic(BBS.ciphersuite("sha256"))
)

When("create the bbs signature of '' using shake256",
    sign_bbs_generic(BBS.ciphersuite("shake256"))
)

--[[
IfWhen("verify the '' has a bbs signature in '' by ''",function(msg, sig, by)
	  local pk = load_pubkey_compat(by, 'bbs')
	  local m = have(msg)
	  local s = have(sig)
	  ZEN.assert(
	     ED.verify(pk, s, ZEN.serialize(m)),
	     'The signature by '..by..' is not authentic'
	  )
end)
--]]
