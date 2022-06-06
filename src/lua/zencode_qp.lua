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
--on Friday, 19th April 2022
--]]

local QP = require'qp'

local function dilithium_public_key_f(obj)
   local res = ZEN.get(obj, '.')
   ZEN.assert(
      QP.sigpubcheck(res),
      'Dilithium public key length is not correct'
   )
   return res
end

local function dilithium_signature_f(obj)
   local res = ZEN.get(obj, '.')
   ZEN.assert(
      QP.signature_check(res),
      'Dilithium signature length is not correcr'
   )
   return res
end

local function kyber_public_key_f(obj)
   local res = ZEN.get(obj, '.')
   ZEN.assert(
      QP.kempubcheck(res),
      'Kyber public key length is not correct'
   )
   return res
end

local function kyber_secret_f(obj)
   local res = ZEN.get(obj, '.')
   ZEN.assert(
      QP.kemsscheck(res),
      'Kyber secret lentgth is not correct'
   )
   return res
end

local function kyber_ciphertext_f(obj)
   local res = ZEN.get(obj, '.')
   ZEN.assert(
      QP.kemctcheck(res),
      'Kyber ciphertext length is not correct'
   )
   return res
end

local function kyber_import_kem(obj)
   local res = {}
   res.kyber_secret = kyber_secret_f(obj.kyber_secret)
   res.kyber_ciphertext = kyber_ciphertext_f(obj.kyber_ciphertext)
   return res
end

local function ntrup_public_key_f(obj)
   local res = ZEN.get(obj, '.')
   ZEN.assert(
      QP.ntrup_pubcheck(res),
      'NTRUP public key length is not correct'
   )
   return res
end

local function ntrup_secret_f(obj)
   local res = ZEN.get(obj, '.')
   ZEN.assert(
      QP.ntrup_sscheck(res),
      'NTRUP secret lentgth is not correct'
   )
   return res
end

local function ntrup_ciphertext_f(obj)
   local res = ZEN.get(obj, '.')
   ZEN.assert(
      QP.ntrup_ctcheck(res),
      'NTRUP ciphertext length is not correct'
   )
   return res
end

local function ntrup_import_kem(obj)
   local res = {}
   res.ntrup_secret = ntrup_secret_f(obj.ntrup_secret)
   res.ntrup_ciphertext = ntrup_ciphertext_f(obj.ntrup_ciphertext)
   return res
end

-- check various locations to find the public key
-- algo can be either 'dilithium' or 'kyber'
--  Given I have a 's' from 't'            --> ACK.s[t] 
local function _pubkey_compat(_key, algo)
   local pubkey = ACK[_key]
   if not pubkey then
      local pubkey_arr = ACK[algo..'_public_key']
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
      dilithium_public_key = dilithium_public_key_f,
      dilithium_signature = dilithium_signature_f,
      kyber_public_key = kyber_public_key_f,
      kyber_secret = kyber_secret_f,
      kyber_ciphertext = kyber_ciphertext_f,
      kyber_kem = kyber_import_kem,
      ntrup_public_key = ntrup_public_key_f,
      ntrup_secret = ntrup_secret_f,
      ntrup_ciphertext = ntrup_ciphertext_f,
      ntrup_kem = ntrup_import_kem
   }
)

--# DILITHIUM #--

-- generate the private key
When('create the dilithium key',function()
	initkeyring'dilithium'
	ACK.keyring.dilithium = QP.sigkeygen().private
end)

-- generate the public key
When('create the dilithium public key',function()
	empty'dilithium public key'
	local sk = havekey'dilithium'
	ACK.dilithium_public_key = QP.sigpubgen(sk)
	new_codec('dilithium public key', { zentype = 'element'})
end)

When("create the dilithium public key with secret key ''",function(sec)
	local sk = have(sec)
	initkeyring'dilithium'
	ACK.keyring.dilithium = sk
	empty'dilithium public key'
	ACK.dilithium_public_key = QP.sigpubgen(sk)
	new_codec('dilithium public key', { zentype = 'element'})
end)

-- generate the sign for a msg and verify
When("create the dilithium signature of ''",function(doc)
	local sk = havekey'dilithium'
	local obj = have(doc)
	empty'dilithium signature'
	ACK.dilithium_signature = QP.sign(sk, ZEN.serialize(obj))
	new_codec('dilithium signature', { zentype = 'element'})
end)

IfWhen("verify the '' has a dilithium signature in '' by ''",function(msg, sig, by)
	  local pk = _pubkey_compat(by, 'dilithium')
	  local m = have(msg)
	  local s = have(sig)
	  ZEN.assert(
	     QP.verify(pk, s, ZEN.serialize(m)),
	     'The signature by '..by..' is not authentic'
	  )
end)

--# KYBER #--

-- generate the private key
When('create the kyber key',function()
	initkeyring'kyber'
	ACK.keyring.kyber = QP.kemkeygen().private
end)

-- generate the public key
When('create the kyber public key',function()
	empty'kyber public key'
	local sk = havekey'kyber'
	ACK.kyber_public_key = QP.kempubgen(sk)
	new_codec('kyber public key', { zentype = 'element'})
end)

When("create the kyber public key with secret key ''",function(sec)
	local sk = have(sec)
	initkeyring'kyber'
	ACK.keyring.kyber = sk
	empty'kyber public key'
	ACK.kyber_public_key = QP.kempubgen(sk)
	new_codec('kyber public key', { zentype = 'element'})
end)

-- create a secret message and its ciphertext
When("create the kyber kem for ''",function(pub)
	local pk = _pubkey_compat(pub, 'kyber')
	empty'kyber kem'
	ACK.kyber_kem = {}
	local enc = QP.enc(pk)
	ACK.kyber_kem.kyber_ciphertext = enc.cipher
	ACK.kyber_kem.kyber_secret = enc.secret
	new_codec('kyber kem', { zentype = 'schema'})
end)
-- create the secret starting from a ciphertext
When("create the kyber secret from ''",function(secret)
	local sk = havekey'kyber'
	local sec = have(secret)
	empty 'kyber secret'
	ACK.kyber_secret = QP.dec(sk, sec)
	new_codec('kyber secret', { zentype = 'element'})
end)

--# NTRUP #--

-- generate the private key
When('create the ntrup key',function()
	initkeyring'ntrup'
	ACK.keyring.ntrup = QP.ntrup_keygen().private
end)

-- generate the public key
When('create the ntrup public key',function()
	empty'ntrup public key'
	local sk = havekey'ntrup'
	ACK.ntrup_public_key = QP.ntrup_pubgen(sk)
	new_codec('ntrup public key', { zentype = 'element'})
end)

When("create the ntrup public key with secret key ''",function(sec)
	local sk = have(sec)
	initkeyring'ntrup'
	ACK.keyring.ntrup = sk
	empty'ntrup public key'
	ACK.ntrup_public_key = QP.ntrup_pubgen(sk)
	new_codec('ntrup public key', { zentype = 'element'})
end)

-- create a secret message and its ciphertext
When("create the ntrup kem for ''",function(pub)
	local pk = _pubkey_compat(pub, 'ntrup')
	empty'ntrup kem'
	ACK.ntrup_kem = {}
	local enc = QP.ntrup_enc(pk)
	ACK.ntrup_kem.ntrup_ciphertext = enc.cipher
	ACK.ntrup_kem.ntrup_secret = enc.secret
	new_codec('ntrup kem', { zentype = 'schema'})
end)
-- create the secret starting from a ciphertext
When("create the ntrup secret from ''",function(ciphertext)
	local sk = havekey'ntrup'
	local ct = have(ciphertext)
	empty'ntrup secret'
	ACK.ntrup_secret = QP.ntrup_dec(sk, ct)
	new_codec('ntrup secret', { zentype = 'element'})
end)
