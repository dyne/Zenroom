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
      recipient_address = O.from_segwit,
      amount = BIG.from_decimal,
      fee = BIG.from_decimal,
      unspent = function(obj)
	 local res = {}
	 for _,v in pairs(obj) do
	    local address = O.from_segwit(v.address)
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

-- generate a keypair in "bitcoin" format (only x coord, 03 prepended)
When('create the bitcoin testnet key', function()
	initkeys'bitcoin testnet'
	local kp = ECDH.keygen()
	ACK.keys.bitcoin_testnet = { secret = btc.sk_to_wif( kp.private, 'testnet' ) }
end)

When('create the bitcoin key', function()
	initkeys'bitcoin'
	local kp = ECDH.keygen()
	ACK.keys.bitcoin = { secret = btc.sk_to_wif( kp.private, 'mainnet' ) }
end)

When("create the bitcoin key with secret key ''", function(sec)
		local sk = have(sec)
		local wif
		if #sk == 32 then -- bare sk
		   wif = btc.sk_to_wif(sk)
		elseif #sk == 32+6 then -- wif
		   btc.wif_to_sk(sk) -- checks
		   wif = sk
		else
		   error("Invalid bitcoin key size for "..sec..": "..#sk)
		end
		initkeys'bitcoin'
		ACK.keys.bitcoin = wif
end)
When("create the bitcoin testnet key with secret key ''", function(sec)
		local sk = have(sec)
		local wif
		if #sk == 32 then -- bare sk
		   wif = btc.sk_to_wif(sk)
		elseif #sk == 32+6 then -- wif
		   btc.wif_to_sk(sk) -- checks
		   wif = sk
		else
		   error("Invalid bitcoin key size for "..sec..": "..#sk)
		end
		initkeys'bitcoin testnet'
		ACK.keys.bitcoin_testnet = wif
end)

When("create the bitcoin public key", function()
	empty'bitcoin public key'
	local wif = havekey'bitcoin'
	local pk = btc.wif_to_sk(wif)
	ACK.bitcoin_public_key = btc.sk_to_pubc(pk)
	new_codec('bitcoin public key', { zentype = 'schema' })
end)

When("create the bitcoin testnet public key", function()
	empty'bitcoin testnet public key'
	local wif = havekey'bitcoin testnet'
	local pk = btc.wif_to_sk(wif)
	ACK.bitcoin_testnet_public_key = btc.sk_to_pubc(pk)
	new_codec('bitcoin testnet public key', { zentype = 'schema' })
end)

When('create the bitcoin transaction',
     function()
	havekey'bitcoin'
	-- now available ACK.keys.bitcoin
	have'recipient address'
	have'amount'
	have'fee'

	local tx = btc.build_tx_from_unspent(ACK.unspent, ACK.recipient_address, ACK.amount, ACK.fee)
	ZEN.assert(tx ~= nil, "Not enough bitcoins in the unspent list")
	
	ACK.bitcoin_transaction = tx
     end
)
When("sign with bitcoin the ''",
     function(_bitcoin_transaction)

	local bitcoin_transaction = have(_bitcoin_transaction)
	ZEN.assert(bitcoin_transaction.witness == nil, "The bitcoin transaction has already been signed")

	bitcoin_transaction.witness = btc.build_witness(ACK.bitcoin_transaction, ACK.keys.bitcoin.secret)

     end
)
When("create the bitcoin raw transaction of the ''",
     function(_bitcoin_transaction)

	local bitcoin_transaction = have(_bitcoin_transaction)

	ACK.bitcoin_raw_transaction = btc.build_raw_transaction(bitcoin_transaction)
     end
)
