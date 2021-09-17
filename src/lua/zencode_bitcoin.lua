--[[
--This file is part of zenroom
--
--Copyright (C) 2021 Dyne.org foundation
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
--on Tuesday, 17th September 2021
--]]

-- local BTC = require 'crypto_bitcoin'
require 'crypto_bitcoin'

-- TODO: any mean to verify that the content of address and txid is valid

-- used also in zencode_keys
function readBech32Address(addr)
   local Bech32Chars = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
   local BechInverse = {}
   for i=1,#Bech32Chars,1 do
      BechInverse[Bech32Chars:sub(i,i)] = i-1
   end
   local prefix, data, res, byt, countBit,val
   prefix = nil
   if addr:sub(1,4) == 'bcrt' then
      prefix = 4
   elseif addr:sub(1,2) == 'bc' or addr:sub(1,2) == 'tb' then
      prefix = 2
   end
   if not prefix then
      error("Invalid bech32 prefix", 2)
   end
   -- +3 = do not condider separator and version bit
   data = addr:sub(prefix+3, #addr)

   res = O.new()
   byt=0 -- byte accumulator
   countBit = 0 -- how many bits I have put in the accumulator
   for i=1,#data,1 do
      val = BechInverse[data:sub(i,i)]

      -- Add 5 bits to the buffer
      byt = (byt << 5) + val
      countBit = countBit + 5

      if countBit >= 8 then
  res = res .. INT.new(byt >> (countBit-8)):octet()

  byt = byt % (1 << (countBit-8))

  countBit = countBit - 8
      end
   end

   -- TODO: I dont look at the checksum
   
   return res:chop(20)
end

local function bigFromString(src)
   if not src then
      error("null input to bigFromString", 2)
   end
   local acc = BIG.new(0)
   local ten = BIG.new(10)
   for i=1, #src, 1 do
      local digit = tonumber(src:sub(i,i), 10)
      if digit == nil then
	 error("string is not a BIG number", 2)
      end
      acc = acc * ten + BIG.new(digit)
   end

   return acc
end

function valueSatoshiToBTC(value)
   pos = value:find("%.")
   decimals = value:sub(pos+1, #value)

   if #decimals > 8 then
      error("Satoshi is the smallest unit of measure")
   end

   decimals = decimals .. string.rep("0", 8-#decimals)

   return bigFromString(value:sub(1, pos-1) .. decimals)
end

ZEN.add_schema(
   {
      recipient_address = function(obj) 
	 return(readBech32Address(obj))
      end,
      amount = bigFromString,
      fee = bigFromString,
      unspent = function(obj)
	 local res = {}
	 for _,v in pairs(obj) do
	    local address = readBech32Address(v.address)
	    local amount  = valueSatoshiToBTC(v.amount)
	    local txid    = OCTET.from_hex(v.txid)
	    local vout    = v.vout
	    table.insert(res, { address = address,
				amount  = amount,
				txid    = txid,
				vout    = vout })
	 end
	 return(res)
      end
   })

When('create the bitcoin transaction',
     function()
	havekey'bitcoin'
	-- now available ACK.keys.bitcoin
	have'recipient address'
	have'amount'
	have'fee'
	-- TODO: validation bitcoin.secret <-> address
	-- local rawtx = BTC.maketx(ACK.keys.bitcoin.secret, ACK.keys.bitcoin.address,
	-- 			 ACK.recipient_address, ACK.amount, ACK.fee)
	-- ACK.bitcoin_transaction = rawtx
	-- ACK.bitcoin_transaction = O.from_string("OK")

	local tx = buildTxFromUnspent(ACK.unspent, ACK.keys.bitcoin.secret,
				      ACK.recipient_address, ACK.amount, ACK.fee)
	
	tx.witness = buildWitness(tx, ACK.keys.bitcoin.secret)
	ACK.bitcoin_transaction = buildRawTransaction(tx)
     end
)
