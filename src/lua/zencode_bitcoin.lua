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

local btc = require('crypto_bitcoin')

-- TODO: any mean to verify that the content of address and txid is valid

ZEN.add_schema(
   {
      recipient_address = function(obj) 
	 return(btc.read_bech32_address(obj))
      end,
      amount = BIG.from_decimal,
      fee = BIG.from_decimal,
      unspent = function(obj)
	 local res = {}
	 for _,v in pairs(obj) do
	    local address = btc.read_bech32_address(v.address)
	    local amount  = btc.value_btc_to_satoshi(v.amount)
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

	local tx = btc.build_tx_from_unspent(ACK.unspent, ACK.keys.bitcoin.secret,
					     ACK.recipient_address, ACK.amount, ACK.fee)
	
	tx.witness = btc.build_witness(tx, ACK.keys.bitcoin.secret)
	ACK.bitcoin_transaction = btc.build_raw_transaction(tx)
     end
)
