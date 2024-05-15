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
   local res = schema_get(obj, '.')
   zencode_assert(
      QP.sigpubcheck(res),
      'Dilithium public key length is not correct'
   )
   return res
end

local function dilithium_signature_f(obj)
   local res = schema_get(obj, '.')
   zencode_assert(
      QP.signature_check(res),
      'Dilithium signature length is not correct'
   )
   return res
end

local function kyber_public_key_f(obj)
   local res = schema_get(obj, '.')
   zencode_assert(
      QP.kempubcheck(res),
      'Kyber public key length is not correct'
   )
   return res
end

local function kyber_secret_f(obj)
   local res = schema_get(obj, '.')
   zencode_assert(
      QP.kemsscheck(res),
      'Kyber secret lentgth is not correct'
   )
   return res
end

local function kyber_ciphertext_f(obj)
   local res = schema_get(obj, '.')
   zencode_assert(
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

local function mlkem512_public_key_f(obj)
	local res = schema_get(obj, '.')
	zencode_assert(
	   QP.mlkem512_pubcheck(res),
	   'ML-KEM-512 public key length is not correct'
	)
	return res
 end
 
 local function mlkem512_secret_f(obj)
	local res = schema_get(obj, '.')
	zencode_assert(
	   QP.mlkem512_sscheck(res),
	   'ML-KEM-512 secret lentgth is not correct'
	)
	return res
 end
 
 local function mlkem512_ciphertext_f(obj)
	local res = schema_get(obj, '.')
	zencode_assert(
	   QP.mlkem512_ctcheck(res),
	   'ML-KEM-512 ciphertext length is not correct'
	)
	return res
 end
 
 local function mlkem512_import_kem(obj)
	local res = {}
	res.mlkem512_secret = mlkem512_secret_f(obj.mlkem512_secret)
	res.mlkem512_ciphertext = mlkem512_ciphertext_f(obj.mlkem512_ciphertext)
	return res
 end

local function ntrup_public_key_f(obj)
   local res = schema_get(obj, '.')
   zencode_assert(
      QP.ntrup_pubcheck(res),
      'NTRUP public key length is not correct'
   )
   return res
end

local function ntrup_secret_f(obj)
   local res = schema_get(obj, '.')
   zencode_assert(
      QP.ntrup_sscheck(res),
      'NTRUP secret lentgth is not correct'
   )
   return res
end

local function ntrup_ciphertext_f(obj)
   local res = schema_get(obj, '.')
   zencode_assert(
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

local function mldsa44_public_key_f(obj)
	local res = schema_get(obj, '.')
	zencode_assert(
	   QP.mldsa44_pubcheck(res),
	   'mldsa44 public key length is not correct'
	)
	return res
 end
 
 local function mldsa44_signature_f(obj)
	local res = schema_get(obj, '.')
	zencode_assert(
	   QP.mldsa44_signature_check(res),
	   'mldsa44 signature length is not correct'
	)
	return res
 end

ZEN:add_schema(
   {
      dilithium_public_key = {import=dilithium_public_key_f},
      dilithium_signature = {import=dilithium_signature_f},
      kyber_public_key = {import=kyber_public_key_f},
      kyber_secret = {import=kyber_secret_f},
      kyber_ciphertext = {import=kyber_ciphertext_f},
      kyber_kem = {import=kyber_import_kem},
	  mlkem512_public_key = {import=mlkem512_public_key_f},
      mlkem512_secret = {import=mlkem512_secret_f},
      mlkem512_ciphertext = {import=mlkem512_ciphertext_f},
      mlkem512_kem = {import=mlkem512_import_kem},
      ntrup_public_key = {import=ntrup_public_key_f},
      ntrup_secret = {import=ntrup_secret_f},
      ntrup_ciphertext = {import=ntrup_ciphertext_f},
      ntrup_kem = {import=ntrup_import_kem},
	  mldsa44_public_key = {import=mldsa44_public_key_f},
	  mldsa44_signature = {import=mldsa44_signature_f}
   }
)

--# DILITHIUM #--

-- generate the private key
When("create dilithium key",function()
	initkeyring'dilithium'
	ACK.keyring.dilithium = QP.sigkeygen().private
end)

-- generate the public key
When("create dilithium public key",function()
	empty'dilithium public key'
	local sk = havekey'dilithium'
	ACK.dilithium_public_key = QP.sigpubgen(sk)
	new_codec('dilithium public key')
end)

When("create dilithium public key with secret key ''",function(sec)
	local sk = have(sec)
	empty'dilithium public key'
	ACK.dilithium_public_key = QP.sigpubgen(sk)
	new_codec('dilithium public key')
end)

-- generate the sign for a msg and verify
When("create dilithium signature of ''",function(doc)
	local sk = havekey'dilithium'
	local obj = have(doc)
	empty'dilithium signature'
	ACK.dilithium_signature = QP.sign(sk, zencode_serialize(obj))
	new_codec('dilithium signature')
end)

IfWhen("verify '' has a dilithium signature in '' by ''",function(msg, sig, by)
	  local pk = load_pubkey_compat(by, 'dilithium')
	  local m = have(msg)
	  local s = have(sig)
	  zencode_assert(
	     QP.verify(pk, s, zencode_serialize(m)),
	     'The dilithium signature by '..by..' is not authentic'
	  )
end)

--# KYBER #--

-- generate the private key
When("create kyber key",function()
	initkeyring'kyber'
	ACK.keyring.kyber = QP.kemkeygen().private
end)

-- generate public key
When("create kyber public key",function()
	empty'kyber public key'
	local sk = havekey'kyber'
	ACK.kyber_public_key = QP.kempubgen(sk)
	new_codec('kyber public key')
end)

When("create kyber public key with secret key ''",function(sec)
	local sk = have(sec)
	empty'kyber public key'
	ACK.kyber_public_key = QP.kempubgen(sk)
	new_codec('kyber public key')
end)

-- create a secret message and its ciphertext
When("create kyber kem for ''",function(pub)
	local pk = load_pubkey_compat(pub, 'kyber')
	empty'kyber kem'
	ACK.kyber_kem = {}
	local enc = QP.enc(pk)
	ACK.kyber_kem.kyber_ciphertext = enc.cipher
	ACK.kyber_kem.kyber_secret = enc.secret
	new_codec('kyber kem')
end)
-- create the secret starting from a ciphertext
When("create kyber secret from ''",function(secret)
	local sk = havekey'kyber'
	local sec = have(secret)
	empty 'kyber secret'
	ACK.kyber_secret = QP.dec(sk, sec)
	new_codec('kyber secret')
end)

--# ML-KEM-512 #--

-- generate the private key
When("create mlkem512 key",function()
	initkeyring'mlkem512'
	ACK.keyring.mlkem512 = QP.mlkem512_keygen().private
end)

-- generate public key
When("create mlkem512 public key",function()
	empty'mlkem512 public key'
	local sk = havekey'mlkem512'
	ACK.mlkem512_public_key = QP.mlkem512_pubgen(sk)
	new_codec('mlkem512 public key')
end)

When("create mlkem512 public key with secret key ''",function(sec)
	local sk = have(sec)
	empty'mlkem512 public key'
	ACK.mlkem512_public_key = QP.mlkem512_pubgen(sk)
	new_codec('mlkem512 public key')
end)

-- create a secret message and its ciphertext
When("create mlkem512 kem for ''",function(pub)
	local pk = load_pubkey_compat(pub, 'mlkem512')
	empty'mlkem512 kem'
	ACK.mlkem512_kem = {}
	local enc = QP.mlkem512_enc(pk)
	ACK.mlkem512_kem.mlkem512_ciphertext = enc.cipher
	ACK.mlkem512_kem.mlkem512_secret = enc.secret
	new_codec('mlkem512 kem')
end)
-- create the secret starting from a ciphertext
When("create mlkem512 secret from ''",function(secret)
	local sk = havekey'mlkem512'
	local sec = have(secret)
	empty 'mlkem512 secret'
	ACK.mlkem512_secret = QP.mlkem512_dec(sk, sec)
	new_codec('mlkem512 secret')
end)

--# NTRUP #--

-- generate the private key
When("create ntrup key",function()
	initkeyring'ntrup'
	ACK.keyring.ntrup = QP.ntrup_keygen().private
end)

-- generate the public key
When("create ntrup public key",function()
	empty'ntrup public key'
	local sk = havekey'ntrup'
	ACK.ntrup_public_key = QP.ntrup_pubgen(sk)
	new_codec('ntrup public key')
end)

When("create ntrup public key with secret key ''",function(sec)
	local sk = have(sec)
	empty'ntrup public key'
	ACK.ntrup_public_key = QP.ntrup_pubgen(sk)
	new_codec('ntrup public key')
end)

-- create a secret message and its ciphertext
When("create ntrup kem for ''",function(pub)
	local pk = load_pubkey_compat(pub, 'ntrup')
	empty'ntrup kem'
	ACK.ntrup_kem = {}
	local enc = QP.ntrup_enc(pk)
	ACK.ntrup_kem.ntrup_ciphertext = enc.cipher
	ACK.ntrup_kem.ntrup_secret = enc.secret
	new_codec('ntrup kem')
end)
-- create the secret starting from a ciphertext
When("create ntrup secret from ''",function(ciphertext)
	local sk = havekey'ntrup'
	local ct = have(ciphertext)
	empty'ntrup secret'
	ACK.ntrup_secret = QP.ntrup_dec(sk, ct)
	new_codec('ntrup secret')
end)

--# ML DSA 44 #--

-- generate the private key
When("create mldsa44 key",function()
	initkeyring'mldsa44'
	ACK.keyring.mldsa44 = QP.mldsa44_keypair().private
end)

-- generate the public key
When("create mldsa44 public key",function()
	empty'mldsa44 public key'
	local sk = havekey'mldsa44'
	ACK.mldsa44_public_key = QP.mldsa44_pubgen(sk)
	new_codec('mldsa44 public key')
end)

When("create mldsa44 public key with secret key ''",function(sec)
	local sk = have(sec)
	empty'mldsa44 public key'
	ACK.mldsa44_public_key = QP.mldsa44_pubgen(sk)
	new_codec('mldsa44 public key')
end)

-- generate the sign for a msg and verify
When("create mldsa44 signature of ''",function(doc)
	local sk = havekey'mldsa44'
	local obj = have(doc)
	empty'mldsa44 signature'
	ACK.mldsa44_signature = QP.mldsa44_signature(sk, zencode_serialize(obj))
	new_codec('mldsa44 signature')
end)

IfWhen("verify '' has a mldsa44 signature in '' by ''",function(msg, sig, by)
	  local pk = load_pubkey_compat(by, 'mldsa44')
	  local m = have(msg)
	  local s = have(sig)
	  zencode_assert(
	     QP.mldsa44_verify(pk, s, zencode_serialize(m)),
	     'The mldsa44 signature by '..by..' is not authentic'
	  )
end)