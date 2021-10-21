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
local function _get_addr(obj)
   local res = ZEN.get(obj, '.', O.from_base58, tostring)
   if not res then error("invalid segwit address",2) end
   return res
end

local function _schema_unspent_import(obj)
   local res = {}
   for _,v in pairs(obj) do
      -- compatibility with electrum and bitcoin core
      local n_amount = fif( v.amount, 'amount', 'value')
      local n_txid = fif( v.txid, 'txid', 'prevout_hash')
      local n_vout = fif( v.vout, 'vout', 'prevout_n')
      local address = ZEN.get(v,'address', O.from_segwit, tostring) 
      local amount  = ZEN.get(v,n_amount, btc.value_btc_to_satoshi, tostring)
      local txid    = ZEN.get(v,n_txid, OCTET.from_hex, tostring)
      local vout    = v[n_vout] -- number
      table.insert(res, { address = address,
			  amount  = amount,
			  txid    = txid,
			  vout    = vout })
   end
   return(res)
end
local function _schema_unspent_export(obj)
   local res = { }
   for _,v in pairs(obj) do
      -- to_segwit: octet, version number(0), 'bc' or 'tc'
      local address = v.address:segwit(0, 'tb')
      local amount = btc.value_satoshi_to_btc(v.amount)
      local txid = v.txid:hex()
      local vout = v.vout
      table.insert(res, { address = address,
			  amount  = amount,
			  txid    = txid,
			  vout    = vout })
   end
   return res
end

local function _address_import(obj)
   return { raw = ZEN.get(obj, '.', O.from_segwit, tostring) }
end
local function _address_export(obj)
   return O.to_segwit(obj.raw, obj.version, O.to_string(obj.network))
end


ZEN.add_schema(
   {
      satoshi_amount            = function(obj)
	 return ZEN.get(obj, '.', btc.value_btc_to_satoshi, tostring) end,
      satoshi_fee               = function(obj)
	 return ZEN.get(obj, '.', btc.value_btc_to_satoshi, tostring) end,

      bitcoin_unspent = { import = _schema_unspent_import,
		  export = _schema_unspent_export },

      bitcoin_address = { import = _address_import,
			  export = _address_export },

   })

-- generate a keypair in "bitcoin" format (only x coord, 03 prepended)
When('create the bitcoin key', function()
	initkeys'bitcoin'
	local kp = ECDH.keygen()
	ACK.keys.bitcoin = kp.private
end)

When("create the bitcoin key with secret key ''", function(sec)
		local sk = have(sec)
		local res
		if #sk == 32+6 then -- wif
		   btc.wif_to_sk(sk) -- checks
		   res = sk
		elseif #sk == 32 then
		   res = sk
		else
		   error("Invalid bitcoin key size for "..sec..": "..#sk)
		end
		initkeys'bitcoin'
		ACK.keys.bitcoin = res
end)

When("create the bitcoin public key", function()
	empty'bitcoin public key'
	local sk = havekey'bitcoin'
	ACK.bitcoin_public_key = btc.sk_to_pubc(sk)
	new_codec('bitcoin public key', { zentype = 'schema' })
end)

When("create the bitcoin testnet wif key", function()
	empty'bitcoin testnet wif key'
	local sk = havekey'bitcoin'
	ACK.bitcoin_testnet_wif_key = btc.sk_to_wif(sk, 'testnet')
	new_codec('bitcoin testnet wif key',
		  { zentype = 'element',
		    encoding = 'base58' })
end)

When("create the bitcoin address", function()
	empty'bitcoin testnet address'
	local pk = have'bitcoin public key'	
	ACK.bitcoin_address = { raw = btc.address_from_public_key(pk),
				version = 0,
				network = O.from_string('tb') }
	new_codec('bitcoin address', { zentype = 'schema',
				       encoding = 'complex' })
end)

When('create the bitcoin transaction', function()
	local to      = have'recipient address'
	local q       = have'satoshi amount'
	local fee     = have'satoshi fee'
	local unspent = have'bitcoin unspent'
	local tx = btc.build_tx_from_unspent(unspent, to, q, fee)
	ZEN.assert(tx, "Not enough bitcoins in the unspent list")
	ACK.bitcoin_transaction = tx
end)

When("sign the bitcoin transaction", function()
	local sk = havekey'bitcoin'
	local tx = have('bitcoin transaction')
	ZEN.assert(not tx.witness, "The bitcoin transaction is already signed")
	tx.witness = btc.build_witness(tx, sk)
end)

When("create the bitcoin raw transaction", function()
	local tx = have'bitcoin transaction'
	empty'bitcoin raw transaction'
	ACK.bitcoin_raw_transaction = btc.build_raw_transaction(tx)
     end
)
