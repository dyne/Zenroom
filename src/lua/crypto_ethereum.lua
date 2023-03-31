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
function ETH.n2o(num)
   if num == INT.new(0) then
      return O.empty()
   else
      return num:octet()
   end
end

-- idem for octet to number (o2n)
function ETH.o2n(o)
   if #o == 0 then
      return INT.new(0)
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
      res = O.empty()
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
   local byt, bytInt, res, idx

   byt = rlp:sub(i, i)
   idx=i+1
   bytInt = tonumber(byt:hex(), 16)

   if bytInt < 128 then
      res = byt
   elseif bytInt <= 183 then
      idx = i+bytInt-128+1
      if bytInt == 128 then
	 res = O.empty()
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
   local fields = {tx["nonce"], tx["gas_price"], tx["gas_limit"], tx["to"],
		   tx["value"], tx["data"], tx["v"], tx["r"], tx["s"]}
   return ETH.encodeRLP(fields)
end

function ETH.decodeTransaction(rlp)
   local t = ETH.decodeRLP(rlp)
   return {
      nonce=ETH.o2n(t[1]),
      gas_price=ETH.o2n(t[2]),
      gas_limit=ETH.o2n(t[3]),
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
   local H, txHash, sig, y_parity, two, res
   H = HASH.new('keccak256')
   txHash = H:process(ETH.encodeTransaction(tx))

   sig, y_parity = ECDH.sign_ecdh(sk, txHash)

   two = INT.new(2)

   res = tx
   res.v = two * INT.new(tx.v) + INT.new(35)
   if y_parity then
     res.v = res.v + INT.new(1)
   end
   res.r = INT.new(sig.r)
   res.s = INT.new(sig.s)

   return ETH.encodeTransaction(res)
end

local function hashFromSignedTransaction(txSigned)
   local fields, H, tx
   fields = {"nonce", "gas_price", "gas_limit", "to",
	     "value", "data"}

   -- construct the transaction which was signed
   tx = {}
   for _, v in pairs(fields) do
      tx[v] = txSigned[v]
   end
   tx["v"] = INT.shr(txSigned["v"]-INT.new(35), 1)
   tx["r"] = O.empty()
   tx["s"] = O.empty()

   H = HASH.new('keccak256')
   return H:process(ETH.encodeTransaction(tx))
end

-- Verify the signature of a transaction which implements EIP-155
-- Simple replay attack protection
-- https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
function ETH.verifySignatureTransaction(pk, txSigned)
   local txHash = hashFromSignedTransaction(txSigned)

   local sig = {
      r=txSigned["r"],
      s=txSigned["s"]
   }

   return ECDH.verify_hashed(pk, txHash, sig, #txHash)
end

-- verify the signature of a transaction only with the address
function ETH.verify_from_address(add, txSigned)
   local txHash, sig, y_parity, pk, valid
   txHash = hashFromSignedTransaction(txSigned)

   sig = {
      r=txSigned.r,
      s=txSigned.s
   }

   y_parity = fif(txSigned.v:parity(), 0, 1) -- y_parity=0 <=> v:parity()=1

   local x = INT.new(sig.r)
   local p = ECDH.prime()
   local n = ECDH.order()
   local h = ECDH.cofactor() --h=1
   repeat
	   pk, valid = ECDH.recovery(x:octet(), y_parity, txHash, sig)
	   if h > 0 then   -- do not add n last iteration
		   x = (x + n) % p
	   end
	   h = h-1
   until (valid and ETH.address_from_public_key(pk) == add) or (h < 0)

   return (valid and ETH.address_from_public_key(pk) == add)
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

-- Taken from https://docs.soliditylang.org/en/v0.5.6/abi-spec.html#function-selector-and-argument-encoding
function ETH.make_storage_data(src)
   local fId, offset, paddingLength, padding, bytLen, paddingLen

   -- local H = HASH.new('keccak256')
   -- string.sub(hex(H:process('storage(string)')), 1, 8)
   fId = O.from_hex('b374012b')

   -- dynamic parameter are saved at the end of string, this is at which offset they are saved
   offset = O.from_hex('0000000000000000000000000000000000000000000000000000000000000020')

   -- length as a 256 unsigned integer
   local src_o = src
   if iszen(type(src_o)) then
      src_o = src_o:octet()
   end
   bytLen = INT.new(#src_o):octet()
   paddingLength = 32-#bytLen
   paddingLen = O.zero(paddingLength)
   paddingLength = #src_o % 32
   if paddingLength > 0 then
      paddingLength = 32 - paddingLength
      padding = O.zero(paddingLength)
   else
      padding = O.empty()
   end
   -- done with padding

   return fId .. offset .. paddingLen .. bytLen  .. src_o .. padding
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

local function encode_uint(val)
   return BIG.new(val):fixed(32)
end

-- The following types are called “dynamic”:
--     bytes
--     string
--     T[] for any T
--     T[k] for any dynamic T and any k >= 0
--     (T1,...,Tk) if Ti is dynamic for some 1 <= i <= k
local function is_dynamic(t)
   local dyn = t == 'string' or t == 'bytes' or string.match(t, '[a-zA-Z0-9]+%[%]')
   if not dyn then
      t = string.match(t, '([a-zA-Z]+)%[%d+%]')
      if t then
         dyn = is_dynamic(t)
      end
   end
   return dyn
end

local encode_tuple

local function encode(t, arg)
   local res
   if type(t) == "string" then
      if string.match(t, 'uint%d+$') or t == 'address' then
         res = encode_uint(arg)
      elseif string.match(t, 'bytes%d+$') then
         if iszen(type(arg)) then
            arg = arg:octet()
         else
            arg = O.new(arg)
         end
         local paddingLength = #arg % 32
         local padding
         if paddingLength > 0 then
            paddingLength = 32 - paddingLength
            padding = O.zero(paddingLength)
         else
            padding = O.empty()
         end
         res = arg .. padding
      elseif t == 'bool' then
         res = BIG.new(fif(arg, 1, 0)):fixed(32)
      elseif t == 'string' or t == 'bytes' then
         if iszen(type(arg)) then
            arg = arg:octet()
         else
            arg = O.new(arg)
         end
         -- right padding
         local paddingLength = #arg % 32
         local padding
         if paddingLength > 0 then
            paddingLength = 32 - paddingLength
            padding = O.zero(paddingLength)
         else
            padding = O.empty()
         end
         res = INT.new(#arg):fixed(32) .. arg .. padding
      else
         -- try to parse an array type
         local len
         local tt, k = string.match(t, "([a-zA-Z0-9]+)%[(%d*)%]")
         if tt then
            if k and #k > 0 then
               len = tonumber(k)
               res = O.empty()
            else
               len = #arg
               res = encode_uint(#arg)
            end
            local params = {}
            for i=1,len, 1 do
               table.insert(params, tt)
            end
            res = res .. encode(params, arg)
         else
            error("Unable to encode " .. t)
         end

      end
   elseif type(t) == 'table' then
      res = encode_tuple(t, arg)
   end
   return res
end

function encode_tuple(params, args)
   local res = O.empty()

   if type(params) ~= 'table' then
      error("Type not encodable as tuple")
   end

   local tails = {}
   local heads = {}

   local head_size = 0;
   local tail_size = 0;
   -- check if there are dynamic types and compute tails
   for i, v in ipairs(params) do
      if is_dynamic(v) then
         head_size = head_size + 32
         table.insert(tails, encode(v, args[i]))
      else
         local t, k = string.match(v, "([a-zA-Z0-9]+)%[(%d+)%]")
         if t and k then
            head_size = head_size + 32 * tonumber(k)
         else
            head_size = head_size + 32
         end
         table.insert(tails, O.empty())
      end
   end

   for i, v in ipairs(params) do
      -- I don't check the range of values (for bool the input should be 0 or 1),
      -- while for int<M> should be 0 ... 2^(<M>)-1
      -- append offset
      if is_dynamic(v) then
         table.insert(heads, encode_uint(head_size+tail_size))
         tail_size = tail_size + #tails[i]
      else
         table.insert(heads, encode(v, args[i]))
      end
   end

   -- implement O.concat for memory efficient concat
   for _, v in pairs(heads) do
      res = res .. v
   end
   for _, v in pairs(tails) do
      res = res .. v
   end
   return res
end


-- TODO: remove so many .., there should be something like table.concat for octets
-- Really simple data encoder, it only works with elementary types (for
-- example ERC-20 only uses this kind of data types)
function ETH.data_contract_factory(fz_name, params)
   local H = HASH.new('keccak256')
   if type(params) ~= 'table' then
      params = {}
   end
   local signature = fz_name .. '(' .. table.concat(params, ",") .. ')'
   local f_id = O.from_hex(string.sub(hex(H:process(signature)), 1, 8))
   return function(...)
      return f_id .. encode_tuple(params, table.pack(...))
   end
end

function ETH.contract_return_factory(params)
   if type(params) ~= 'table' then
      params = {}
   end
   -- @param val string or octet with the value returned by the contract
   return function(val)
      if type(val) == 'string' then
   	  val = O.from_hex(val)
      end
      assert(type(val) == 'zenroom.octet')

      local res = {}
      for i, v in ipairs(params) do
	 -- I don't check the range of values (for bool the input should be 0 or 1),
	 -- while for int<M> should be 0 ... 2^(<M>)-1
	 if v == 'address' or string.match(v, '^uint%d+$') then
	    table.insert(res, BIG.new(val:sub(32 * (i-1)+1, 32 * i)))
	 elseif v == 'bool' then
	    table.insert(res, BIG.new(val:sub(32 * (i-1)+1, 32 * i)) ~= BIG.new(0))
	 elseif v == 'string' or v == 'bytes' then
	    -- TODO: don't know the maximum size of argument
	    -- there could be an overflow
	    local offset = tonumber(val:sub(32 * (i-1)+1, 32 * i):hex(), 16)
	    local slen = tonumber(val:sub(1+offset, 32+offset):hex(), 16)
	    local s = val:sub(1+offset+32, offset+32+slen):string()
            if v == 'string' then
              s = s:string()
            end
	    table.insert(res, s)
	 else
	    assert(false, "Unknown data type")
	 end
      end

      return res
   end
end


-- methods with the modifier "view" have to be executed (locally) with
-- eth_call, they don't change the blockchain
-- the i property are the input parameter
-- the o property is (are) the output return types
local ERC20_SIGNATURES = {
   balanceOf         = { i={'address'}, o={'uint256'}, view=true },
   transfer          = { i={'address', 'uint256'}, o={'bool'} },
   approve           = { i={'address', 'uint256'}, o={'bool'} },
   allowance         = { i={'address', 'address'}, view=true, o={'uint256'} },
   transferFrom      = { i={'address', 'address', 'uint256'}, o={'bool'} },
   decimals          = { o={'uint8'}, view=true },
   name              = { o={'string'}, view=true },
   symbol            = { o={'string'}, view=true },
   totalSupply       = { o={'uint256'}, view=true },
}

ETH.erc20 = {}
for k, v in pairs(ERC20_SIGNATURES) do
   ETH.erc20[k] = ETH.data_contract_factory(k, v.i)
end

ETH.erc20return = {}
for k, v in pairs(ERC20_SIGNATURES) do
   ETH.erc20return[k] = ETH.contract_return_factory(v.o)
end

local FAUCET_SIGNATURES = {
   transfer = { i={'address'} },
}

ETH.transfer_erc20_details = ETH.data_contract_factory(
        "transferDetails",
        {"address", "uint256", "bytes"})

ETH.faucet = {}
for k, v in pairs(FAUCET_SIGNATURES) do
   ETH.faucet[k] = ETH.data_contract_factory(k, v.i)
end

-- TODO implement all ERC721 methods
local ERC721_SIGNATURES = {
   safeTransferFrom = { i={'address', 'address', 'uint256'} },
   approve = { i={'address', 'uint256'} },
}

ETH.erc721 = {}
for k, v in pairs(ERC721_SIGNATURES) do
   ETH.erc721[k] = ETH.data_contract_factory(k, v.i)
end

ETH.create_erc721 = ETH.data_contract_factory("createAsset", { 'string' })

ETH.eth_to_planetmint = ETH.data_contract_factory("beginTransfer", { 'address', 'uint256', 'bytes' })
return ETH
