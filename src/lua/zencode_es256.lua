--[[
--This file is part of zenroom
--
--Copyright (C) 2023-2025 Dyne.org foundation
--
--designed, written and maintained by:
--Rebecca Selvaggini, Alberto Lerda and Denis Roio
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
--]]

local ES256 = require('es256')

local function public_key_f(obj)
	local res = schema_get(obj, '.')
	zencode_assert(
		ES256.pubcheck(res),
		'Public key is not a valid point on curve'
	)
	return res
end

ZEN:add_schema(
    {
        es256_public_key = { import = public_key_f },
        es256_signature = { import = function(obj) return schema_get(obj, '.') end }
    }
)

-- generate the private key
When('create es256 key',function()
	initkeyring'es256'
	ACK.keyring.es256 = ES256.keygen()
end)

-- generate the public key
When('create es256 public key',function()
	empty'es256 public key'
	local sk = havekey'es256'
	ACK.es256_public_key = ES256.pubgen(sk)
	new_codec('es256 public key', { zentype = 'e',
                                    encoding = 'base64'})
end)

local function _pubkey_from_secret(sec)
   local sk = have(sec)
   initkeyring'es256'
   ES256.pubgen(sk)
   ACK.keyring.es256 = sk
end

When("create es256 key with secret key ''",
     _pubkey_from_secret
)

When("create es256 key with secret ''",
     _pubkey_from_secret
)

When("create es256 public key with secret key ''",function(sec)
	local sk = have(sec)
	empty'es256 public key'
	ACK.es256_public_key = ES256.pubgen(sk)
	new_codec('es256 public key', { zentype = 'e',
                                    encoding = 'base64'})
end)

-- generate the sign for a msg and verify
When("create es256 signature of ''",function(doc)
	local sk <const> = havekey'es256'
	local obj <const> = have(doc)
	empty'es256 signature'
    local ot <const> = type(obj)
    if iszen(ot) then
        ACK.es256_signature = ES256.sign(sk, obj:octet())
    elseif ot == 'table' then
        ACK.es256_signature = ES256.sign(sk, zencode_serialize(obj))
    else
        ACK.es256_signature = ES256.sign(sk, obj)
    end
	new_codec('es256 signature', { zentype = 'e',
                                   encoding = 'base64'})
end)

IfWhen("verify '' has a es256 signature in '' by ''",function(msg, sig, by)
	  local pk <const> = load_pubkey_compat(by, 'es256')
	  local m <const> = have(msg)
	  local s <const> = have(sig)
      local mt <const> = type(m)
      if iszen(mt) then
          zencode_assert(
              ES256.verify(pk, m:octet(), s),
              'The es256 signature by '..by..' is not authentic'
          )
      elseif mt == 'table' then
          zencode_assert(
              ES256.verify(pk, zencode_serialize(m), s),
              'The es256 signature by '..by..' is not authentic'
          )
      else
          zencode_assert(
              ES256.verify(pk, m, s),
              'The es256 signature by '..by..' is not authentic'
          )
      end
end)
