local BTC = require('crypto_bitcoin')

local HDW = {}

-- parse extended key
function HDW.parse_extkey(data)
   data = O.from_base58(data)
   -- check checksum
   assert(#data == 82 and data:sub(#data-3, #data) == BTC.dsha256(data:sub(1, #data-4)):chop(4), "Wrong input key", 2)
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

-- fixed size encoding for integer
local function to_uint_be(num, nbytes)
   if type(num) ~= "zenroom.big" then
      num = INT.new(num)
   end
   num = num:octet()
   if #num < nbytes then
      num = O.zero(nbytes - #num) .. num
   end
   return num
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
      extkey.public = BTC.sk_to_pubc(extkey.secret)
   end
   assert(extkey.public ~= nil)
   return extkey.public
end

function HDW.format_extkey(extkey, version)
   local data = O.new()

   assert(version == HDW.MAINPK or version == HDW.MAINSK or
	  version == HDW.TESTPK or version == HDW.TESTSKK, "Unknown version", 2)

   local public = HDW.isPublic(version)

   data = data .. version

   data = data .. O.from_hex(string.format("%02x", extkey.level))

   data = data .. to_uint_be(extkey.fingerprint_parent, 4)

   data = data .. to_uint_be(extkey.child_number, 4)

   data = data .. extkey.chain_code

   if public then
      data = data .. HDW.getPublic(extkey)
   else
      assert(extkey.secret, "From a public key it is not possible to print a private key")
      data = data .. O.from_hex('00') .. extkey.secret
   end

   local check = BTC.dsha256(data):sub(1,4)

   data = data .. check
   
   return data:base58()
end


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
   newkey.fingerprint_parent = BTC.address_from_public_key(pk):sub(1,4)
   
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


-- It is only defined for non-hardened child keys (i <= 0x80000000)
function HDW.ckd_pub(parent_key, i)
   local newkey = {}
   local l
   local s512 = HASH.new('sha512')

   -- check validity of index
   --assert(i <= BIG.new(O.from_hex('ffffffff')), "Invalid index")

   assert(i < BIG.new(O.from_hex('80000000')), "Public key derivation is only defined for non-hardened child keys")

   if parent_key.secret then
      newkey = HDW.neutered(HDW.ckd_priv(parent_key, i))
   else
      pk = HDW.getPublic(parent_key)
      
      l = parent_key.public .. to_uint_be(i, 4)
      l = HASH.hmac(s512, parent_key.chain_code, l)

      lL = BIG.new(l:sub( 1,32))
      lR = l:sub(33,64)

      local nG = ECDH.mul_gen(lL)

      newkey.public = ECDH.compress_public_key(ECDH.add(nG, parent_key.public))
      -- check if lR >= order curve, in that case return ckd_priv(parent_key, i+1)
      if newkey.secret == INT.new(0) then
	 return ckd_priv(parent_key, i+1)
      end

      newkey.fingerprint_parent = BTC.address_from_public_key(pk):sub(1,4)
   
      newkey.chain_code = lR

      newkey.level = parent_key.level + 1
      
   end

   return newkey
end


return HDW
