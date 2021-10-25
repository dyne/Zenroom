--[[
--This file is part of zenroom
--
--Copyright (C) 2021 Dyne.org foundation
--designed, written and maintained by Alberto Lerda <albertolerda97@gmail.com>
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


local ETH = {}

-- number to octet (n2o), were number is a big integer
-- in RLP the 0 is reppresented as the empty octet
zero = INT.new(0)
function ETH.n2o(num)
   if num == zero then
      return O.new()
   else
      return num:octet()
   end
end

-- idem for octet to number (o2n)
function ETH.o2n(o)
   if o == O.new() then
      return zero
   else
      return INT.new(o)
   end
end

-- the empty octect is encoded as nil
-- a table contains in the first position (i.e. 1) the number of elements
function ETH.encodeRLP(data)
   local header = nil
   local res = nil
   local byt = nil

   if type(data) == 'zenroom.big' then
      data = ETH.n2o(data)
   end

   if type(data) == 'table' then
      -- empty octet
      res = O.new()
      for _, v in pairs(data) do
	 res = res .. ETH.encodeRLP(v)
      end
      if #res < 56 then
	 res = INT.new(192+#res):octet() .. res
      else
	 -- Length of the result to be saved before the bytes themselves
	 byt = INT.new(#res):octet()
	 header = INT.new(247+#byt):octet() .. byt

      end
   elseif iszen(type(data)) then
      res = data:octet()

      -- index single bytes of an octet
      local byt = INT.new(0)
      if #res > 0 then
	 byt = INT.new( res:chop(1) )
      end

      if #res ~= 1 or byt >= INT.new(128) then
	 if #res < 56 then
	    header = INT.new(128+#res):octet()
	 else
	    -- Length of the result to be saved before the bytes themselves
	    byt = INT.new(#res):octet()
	    header = INT.new(183+#byt):octet() .. byt
	 end
      end

   else
      error("Invalid data type for ETH RLP encoder: "..type(data))      
   end
   if header then
      res = header .. res
   end
   return res
end


-- i is the position from which we start to parse
-- return a table with
-- * res which is the content read
-- * idx which is the position of the next byte to read
local function decodeRLPgeneric(rlp, i)
   local byt, res, idx
   local u128

   u128 = INT.new(128)

   byt = rlp:sub(i, i)
   idx=i+1
   bytInt = tonumber(byt:hex(), 16)

   if bytInt < 128 then
      res = byt
   elseif bytInt <= 183 then
      idx = i+bytInt-128+1
      if bytInt == 128 then
	 res = O.new()
      else
	 res = rlp:sub(i+1, idx-1)
      end

   elseif bytInt < 192 then
      local sizeEnd = bytInt-183;
      local size = tonumber(rlp:sub(i+1, i+sizeEnd):hex(), 16)
      idx = i+sizeEnd+size+1
      res = rlp:sub(i+sizeEnd+1, idx-1)
   else -- it is a tuple
      local j
      if bytInt <= 247 then
	 idx = i+bytInt-192+1 -- total number of bytes
      else -- decode big endian encoding
	 local sizeEnd
	 sizeEnd = bytInt-247;
	 local size = tonumber(rlp:sub(i+1, i+sizeEnd):hex(), 16)
	 idx = i+sizeEnd+size+1
	 i=i+sizeEnd
      end
      i=i+1 -- initial position
      j=1 -- index inside res
      res = {}
      -- decode the tuple in a table
      while i < idx do
	 local readNext
	 readNext = decodeRLPgeneric(rlp, i)
	 res[j] = readNext.res
	 j = j+1
	 i = readNext.idx
      end
   end
   return {
      res=res,
      idx=idx
   }
end

function ETH.decodeRLP(rlp)
   return decodeRLPgeneric(rlp, 1).res
end

function ETH.encodeTransaction(tx)
   local fields = {tx["nonce"], tx["gasPrice"], tx["gasLimit"], tx["to"],
		   tx["value"], tx["data"], tx["v"], tx["r"], tx["s"]}
   return ETH.encodeRLP(fields)
end

function ETH.decodeTransaction(rlp)
   local t = ETH.decodeRLP(rlp)
   return {
      nonce=ETH.o2n(t[1]),
      gasPrice=ETH.o2n(t[2]),
      gasLimit=ETH.o2n(t[3]),
      to=t[4],
      value=ETH.o2n(t[5]),
      data=t[6],
      v=ETH.o2n(t[7]),
      r=t[8],
      s=t[9]
   }
end

-- modify the input transaction
function ETH.encodeSignedTransaction(sk, tx)
   local H, txHash, sig, pk, x, y, two, res
   H = HASH.new('keccak256')
   txHash = H:process(ETH.encodeTransaction(tx))

   sig = ECDH.sign_ecdh(sk, txHash)

   pk = ECDH.pubgen(sk)
   x, y = ECDH.pubxy(pk);

   two = INT.new(2);
   res = tx
   res.v = two * INT.new(tx.v) + INT.new(35) + INT.new(y) % two
   res.r = sig.r
   res.s = sig.s

   return ETH.encodeTransaction(res)

end

-- Verify the signature of a transaction which implements EIP-155
-- Simple replay attack protection
-- https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
function ETH.verifySignatureTransaction(pk, txSigned)
   local fields, H, txHash, tx
   fields = {"nonce", "gasPrice", "gasLimit", "to",
	     "value", "data"}

   -- construct the transaction which was signed
   tx = {}
   for _, v in pairs(fields) do
      tx[v] = txSigned[v]
   end
   tx["v"] = (txSigned["v"]-INT.new(35))/INT.new(2)
   tx["r"] = O.new()
   tx["s"] = O.new()


   H = HASH.new('keccak256')
   txHash = H:process(ETH.encodeTransaction(tx))

   sig = {
      r=txSigned["r"],
      s=txSigned["s"]
   }

   return ECDH.verify_hashed(pk, txHash, sig, #txHash)
end

-- Assume we are given a smart contract with a function with the
-- following signature
-- function writeString(string memory)
-- We send a string and the smart contract signals an event

-- Smart contract
-- // SPDX-License-Identifier: GPL-3.0
-- pragma solidity ^0.8.4;


-- contract SaveString {

--     event StringSaveEvent(address user, string content);

--     function writeString(string memory content) public {
--         emit StringSaveEvent(msg.sender, content);
--     }
-- }

-- TODO see smart contract with Jaromil
-- Taken from https://docs.soliditylang.org/en/v0.5.6/abi-spec.html#function-selector-and-argument-encoding
function ETH.makeWriteStringData(str)
   local fId, offset, oStr, paddingLength, padding, bytLen, paddingLen

   -- local H = HASH.new('keccak256')
   -- string.sub(hex(H:process('writeString(string)')), 1, 8)
   fId = O.from_hex('dd206202')

   -- dynamic parameter are saved at the end of string, this is at which offset they are saved
   offset = O.from_hex('0000000000000000000000000000000000000000000000000000000000000020')

   -- length as a 256 unsigned integer
   bytLen = INT.new(#str):octet()
   paddingLength = 32-#bytLen
   paddingLen = O.zero(paddingLength)

   -- octet string
   oStr = O.to_octet(str)

   paddingLength = #str % 32
   
   if paddingLength > 0 then
      paddingLength = 32 - paddingLength
      padding = O.zero(paddingLength)
   else
      padding = O.new()

   end

   return fId .. offset .. paddingLen .. bytLen  .. oStr .. padding
end

-- generate an ethereum keypair
function ETH.keygen()
   local kp = ECDH.keygen()
   -- the address is the keccak hash of the x concatenated with
   -- the y of the public key (without 04 at the beginning!)
   -- Taken from https://github.com/ethereumbook/ethereumbook/blob/develop/04keys-addresses.asciidoc
   -- in the section Ethereum Address
   -- or in the Yellow Paper

   -- Warning: we take only the last 20bytes of the hash (...)
   return {
      address=ETH.address_from_public_key(kp.public),
      private=kp.private,
   }
end

function ETH.address_from_public_key(pk)
   local H = HASH.new('keccak256')
   return H:process(pk:sub(2, #pk)):sub(13, 32)
end

-- Really simple data encoder, it only works with elementary types (for
-- example ERC-20 only uses this kind of data types)
function ETH.data_contract(fz_name, params)
   local H = HASH.new('keccak256')
   local signature = fz_name .. '(' .. table.concat(params, ",") .. ')'
   local f_id = O.from_hex(string.sub(hex(H:process(signature)), 1, 8))
   return function(...)
      local args = table.pack(...)

      local res = f_id

      for i, v in ipairs(params) do
	 -- I don't check the range of values (for bool the input should be 0 or 1),
	 -- while for int<M> should be 0 ... 2^(<M>)-1
	 if string.match(v, 'int%d+') or v == 'address' then
	    res = res .. BIG.from_decimal(args[i]):fixed(32)
	 elseif v == 'bool' then
	    res = res .. BIG.new(fif(args[i], 1, 0)):fixed(32)
	 end
      end
      return res
   end
end

return ETH
