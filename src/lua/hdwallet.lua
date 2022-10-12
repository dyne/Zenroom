--[[
--This file is part of zenroom
--
--Copyright (C) 2021 Dyne.org foundation
--designed, written and maintained by Alberto Lerda
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

local HDW = {}

-- an extended key is a table with the fields
-- secret, chain_code, level, fingerprint_parent, child_number
-- a private key may have public=nil
-- a public key have secret=nil


-- parse extended key
-- @param data octet to be parsed
-- @return extended key
function HDW.parse_extkey(data)
   data = O.from_base58(data)
   -- check checksum
   assert(#data == 82 and data:sub(#data-3, #data) == HASH.dsha256(data:sub(1, #data-4)):chop(4), "Wrong input key", 2)
   local extkey = {}
   local i = 1

   version = data:sub(i,i+3)
   i = i + 4

   assert(version == HDW.MAINPK or version == HDW.MAINSK or
	  version == HDW.TESTPK or version == HDW.TESTSK, "Unknown version", 2)
   local public = HDW.isPublic(version)

   extkey.level = tonumber(data:sub(i,i):hex(), 16)
   i = i + 1

   extkey.fingerprint_parent = data:sub(i, i+3)
   i = i + 4

   -- big endian 4 bytes integer
   extkey.child_number = BIG.new(data:sub(i, i+3))
   i = i + 4

   extkey.chain_code = data:sub(i, i+31)
   i = i + 32

   if public then
      extkey.public = data:sub(i,i+32)
   else
      extkey.secret = data:sub(i+1,i+32)
   end
   
   return extkey
end

HDW.MAINPK = O.from_hex('0488B21E')
HDW.TESTPK = O.from_hex('043587CF')
HDW.MAINSK = O.from_hex('0488ADE4')
HDW.TESTSK = O.from_hex('04358394')

function HDW.isPublic(version)
   return version == HDW.MAINPK or version == HDW.TESTPK
end

function HDW.getPublic(extkey)
   if not extkey.public then
      extkey.public = ECDH.sk_to_pubc(extkey.secret)
   end
   assert(extkey.public ~= nil)
   return extkey.public
end

function HDW.format_extkey(extkey, version)
   local data = O.empty()

   assert(version == HDW.MAINPK or version == HDW.MAINSK or
	  version == HDW.TESTPK or version == HDW.TESTSKK, "Unknown version", 2)

   local public = HDW.isPublic(version)

   data = data .. version

   data = data .. O.from_hex(string.format("%02x", extkey.level))

   data = data .. BIG.new(extkey.fingerprint_parent):fixed(4)

   data = data .. BIG.new(extkey.child_number):fixed(4)

   data = data .. extkey.chain_code

   if public then
      data = data .. HDW.getPublic(extkey)
   else
      assert(extkey.secret, "From a public key it is not possible to print a private key")
      data = data .. O.from_hex('00') .. extkey.secret
   end

   local check = HASH.dsha256(data):sub(1,4)

   data = data .. check
   
   return data:base58()
end

-- Child key derivation private key
-- @param parent_key extended key object
-- @param i index
function HDW.ckd_priv(parent_key, i)
   local newkey = {}
   local l
   local s512 = HASH.new('sha512')
   local pk
   
   -- check validity of index
   assert(i <= BIG.new(O.from_hex('ffffffff')), "Invalid index")

   -- we cannot derive a private key from a public key
   assert(parent_key.secret, "Cannot derive a private key from a public key")
   
   newkey.child_number = i
   local i_oct = i:octet()
   if #i_oct < 4 then
      i_oct = O.zero(4 - #i_oct) .. i_oct
   end
   if i >= BIG.new(O.from_hex('80000000')) then
      l = O.zero(1) .. parent_key.secret .. i_oct;      
   else
      pk = HDW.getPublic(parent_key)
      l = pk .. i_oct;
   end
   
   l = HASH.hmac(s512, parent_key.chain_code, l)

   lL = BIG.new(l:sub( 1,32))
   lR = l:sub(33,64)
  
   -- On BIP32 there is a mod, if I add it, it doesn't work
   -- TODO improve arithmetics modulo order of curve secp256k1
   newkey.secret = ((lL + BIG.new(parent_key.secret)) % (BIG.new(O.from_hex('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141')))):octet()

   -- check if lR >= order curve, in that case return ckd_priv(parent_key, i+1)
   if newkey.secret == INT.new(0) then
      return ckd_priv(parent_key, i+1)
   end

   -- compute fingerprint
   -- parent_key is a private key
   pk = HDW.getPublic(parent_key)
   newkey.fingerprint_parent = HASH.hash160(pk):sub(1,4)
   
   newkey.chain_code = lR

   newkey.level = parent_key.level + 1

   return newkey
end

-- the "neutered" version, as it removes the ability to sign transactions
function HDW.neutered(parent_key)
   local newkey = {}
   for k, v in pairs(parent_key) do
      newkey[k] = v
   end
   HDW.getPublic(newkey)
   newkey.secret = nil
   return newkey      
end

-- Child key derivation public key
-- @param parent_key extended key object
-- @param i it is only defined for non-hardened child keys (i <= 0x80000000)
function HDW.ckd_pub(parent_key, i)
   local newkey = {}
   local l, lR, lL
   local s512 = HASH.new('sha512')

   -- check validity of index
   --assert(i <= BIG.new(O.from_hex('ffffffff')), "Invalid index")

   assert(i < BIG.new(O.from_hex('80000000')), "Public key derivation is only defined for non-hardened child keys")

   if parent_key.secret then
      newkey = HDW.neutered(HDW.ckd_priv(parent_key, i))
   else
      pk = HDW.getPublic(parent_key)
      newkey.child_number = i
      
      l = parent_key.public .. i:fixed(4)
      l = HASH.hmac(s512, parent_key.chain_code, l)

      lL = BIG.new(l:sub( 1,32))
      lR = l:sub(33,64)

      local nG = ECDH.pubgen(lL) -- = n * G

      newkey.public = ECDH.compress_public_key(ECDH.add(nG, parent_key.public))
      -- check if lR >= order curve, in that case return ckd_priv(parent_key, i+1)
      if newkey.secret == INT.new(0) then
	 return ckd_priv(parent_key, i+1)
      end

      newkey.fingerprint_parent = HASH.hash160(pk):sub(1,4)
   
      newkey.chain_code = lR

      newkey.level = parent_key.level + 1
      
   end

   return newkey
end

function HDW.master_key_generation(seed)
   if not seed then
      seed = O.random(32)
   end
   local s512 = HASH.new('sha512')
   local l = HASH.hmac(s512, O.from_string('Bitcoin seed'), seed)
   local lL = l:sub( 1,32)
   -- check Ll < order of the curve
   local lR = l:sub(33,64)
   return {
      secret = lL,
      chain_code = lR,
      level = 0,
      fingerprint_parent = O.from_hex('00000000'),
      child_number = O.from_hex('00000000'),
   }
end

-- Implements the default wallet layout
-- only external keys are supported
-- @param parent_key parent private key
-- @param i bignum i >= 0 and i <= 80000000
-- @param wallet bignum or the string '' (the dafult wallet), optional
-- @param nohardened by default child keys are hardened (if there is not the parameter
-- nohardned = nil which is the same as false)
function HDW.standard_child(parent_key, i, wallet, nohardened)
   local HARDNED = BIG.new(O.from_hex('80000000'))
   assert(i < HARDNED)

   if not nohardened then
      i = i + HARDNED
   end

   if not wallet or wallet=='' then
      wallet = INT.new(0)
   end

   assert(wallet < HARDNED)

   wallet_key = HDW.ckd_priv(parent_key, wallet+HARDNED)
   external_key = HDW.ckd_priv(wallet_key, INT.new(0))
   address_key = HDW.ckd_priv(external_key, i)

   return address_key
end

function HDW.mnemonic_master_key(mnemonic, password)
   return HDW.master_key_generation(HASH.mnemonic_seed(mnemonic, password))
end

return HDW
