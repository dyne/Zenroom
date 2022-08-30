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
--on Saturday, 9th April 2022
--]]

local btc -- mostly loaded at init
if not BTC then btc = require_once('crypto_bitcoin') else btc = BTC end

-- TODO: any mean to verify that the content of address and txid is valid
local function _get_addr(obj)
   local res = ZEN.get(obj, '.', O.from_base58, tostring)
   if not res then error("invalid segwit address",2) end
   return res
end

local function _bitcoin_unspent_import(obj)
   local res = {}
   for _,v in pairs(obj) do
      -- compatibility with electrum and bitcoin core
      local n_amount = fif( v.amount, 'amount', 'value')
      local n_txid = fif( v.txid, 'txid', 'prevout_hash')
      local n_vout = fif( v.vout, 'vout', 'prevout_n')
      local address
      if v.address then
	 address = ZEN.get(v,'address', O.from_segwit, tostring)
      end
      local amount  = ZEN.get(v,n_amount, btc.value_btc_to_satoshi, tostring)
      local txid    = ZEN.get(v,n_txid, OCTET.from_hex, tostring)
      local vout    = INT.new(v[n_vout])
      table.insert(res, { address = address,
			  amount  = amount,
			  txid    = txid,
			  vout    = vout })
   end
   return(res)
end
local function _bitcoin_unspent_export(obj)
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

local function _satoshi_unspent_import(obj)
   local res = {}
   for _,v in pairs(obj) do
      -- compatibility with electrum and bitcoin core
      table.insert(res, { amount = ZEN.get(v,'value', BIG.from_decimal, tostring),
			  txid    = ZEN.get(v,'txid', OCTET.from_hex, tostring),
			  vout    = v.vout }) 
   end
   return(res)
end
local function _satoshi_unspent_export(obj)
   local res = { }
   for _,v in pairs(obj) do
      -- to_segwit: octet, version number(0), 'bc' or 'tc'
      local address = v.address:segwit(0, 'tb')
      local amount = BIG.to_decimal(v.amount)
      local txid = v.txid:hex()
      local vout = v.vout
      table.insert(res, { amount  = amount,
			  txid    = txid,
			  vout    = vout })
   end
   return res
end

local function _address_import(obj)
   local raw, version, network
   raw, version = O.from_segwit(tostring(obj))
   network = obj:sub(0,2)
   return { raw = raw, version = F.new(version), network = O.from_string(network) }
end
local function _address_export(obj)
   return O.to_segwit(obj.raw, tonumber(obj.version), O.to_string(obj.network))
end

local function _wif_import(obj)	return ZEN.get(obj, '.', BTC.wif_to_sk, O.from_base58) end
local function _wif_bitcoin_export(obj)	return O.to_base58( BTC.sk_to_wif( obj, 'bitcoin') ) end
local function _wif_testnet_export(obj)	return O.to_base58( BTC.sk_to_wif( obj, 'testnet') ) end

ZEN.add_schema(
   {
      bitcoin_key = { import = _wif_import,
		      export = _wif_bitcoin_export },
      testnet_key = { import = _wif_import,
		      export = _wif_testnet_export },

      satoshi_amount            = function(obj)
	 return ZEN.get(obj, '.', BIG.from_decimal, tostring) end,
      satoshi_fee               = function(obj)
	 return ZEN.get(obj, '.', BIG.from_decimal, tostring) end,
      satoshi_unspent = { import = _satoshi_unspent_import,
			  export = _satoshi_unspent_export },
      bitcoin_unspent = { import = _bitcoin_unspent_import,
			  export = _bitcoin_unspent_export },
      testnet_unspent = { import = _bitcoin_unspent_import,
			  export = _bitcoin_unspent_export },
      bitcoin_address = { import = _address_import,
			  export = _address_export },
      testnet_address = { import = _address_import,
			  export = _address_export },
      -- TODO: { schema = 'transaction' })
})

-- generate a keypair in "bitcoin" format (only x coord, 03 prepended)
local function _keygen(name)
	initkeyring(name)
	local kp = ECDH.keygen()
	ACK.keyring[name] = kp.private
end
When('create the bitcoin key', function() _keygen('bitcoin') end)
When('create the testnet key', function() _keygen('testnet') end)

local function _import_wif(sec, name)
		local sk = have(sec)
		local res
		if #sk == 32+6 then -- wif
		   btc.wif_to_sk(sk) -- checks
		   res = sk
		elseif #sk == 32 then
		   res = sk
		   -- TODO: import from hdwallet xpriv format
		else
		   error("Invalid "..name.." key size for "..sec..": "..#sk)
		end
		initkeyring(name)
		ACK.keyring[name] = res
end
When("create the bitcoin key with secret key ''", function(sec)
	_import_wif(sec, 'bitcoin') end)
When("create the testnet key with secret key ''", function(sec)
	_import_wif(sec, 'testnet') end)
When("create the bitcoin key with secret ''", function(sec)
	_import_wif(sec, 'bitcoin') end)
When("create the testnet key with secret ''", function(sec)
	_import_wif(sec, 'testnet') end)

local function _get_pub(name)
	empty(name..' public key')
	local sk = havekey(name)
	ACK[name..'_public_key'] = ECDH.sk_to_pubc(sk)
	new_codec(name..' public key', { zentype = 'schema' })
end
When("create the bitcoin public key", function() _get_pub('bitcoin') end)
When("create the testnet public key", function() _get_pub('testnet') end)

local function _create_addr(name,pfx)
	empty(name..' address')
	local pk
	if ACK[name..'_public_key'] then
	   pk = have(name..' public key')
	else
	   pk = ECDH.sk_to_pubc( havekey(name) )
	end
	ACK[name..'_address'] = { raw = btc.address_from_public_key(pk),
				  version = F.new(0),
				  network = O.from_string(pfx) }
	new_codec(name..' address', { zentype = 'schema',
				      encoding = 'complex' })
end
When("create the bitcoin address", function() _create_addr('bitcoin','bc') end)
When("create the testnet address", function() _create_addr('testnet','tb') end)

local function _create_tx(name, recipient)
	local to      = have(recipient or 'recipient')
	if not to then
		error("Cannot create "..name.." transaction: recipient not specified")
	end
	local q       = have'satoshi amount'
	local fee     = have'satoshi fee'
	local unspent = have(name..' unspent')
	local tx = btc.build_tx_from_unspent(unspent, to, q, fee, ACK.sender)
	ZEN.assert(tx, "Not enough "..name.." in the unspent list")
	ACK[name..'_transaction'] = tx
	new_codec(name..'_transaction') -- TODO: { schema = 'transaction' })
end
When('create the bitcoin transaction', function() _create_tx('bitcoin') end)
When('create the testnet transaction', function() _create_tx('testnet') end)
When("create the bitcoin transaction to ''", function(recipient) _create_tx('bitcoin', recipient) end)
When("create the testnet transaction to ''", function(recipient) _create_tx('testnet', recipient) end)

local function _sign_tx(name)
   local sk = havekey(name)
   local tx = have(name..'_transaction')
   ZEN.assert(not tx.witness, "The "..name.." transaction is already signed")
   tx.witness = btc.build_witness(tx, sk)
end
When("sign the bitcoin transaction", function() _sign_tx('bitcoin') end)
When("sign the testnet transaction", function() _sign_tx('testnet') end)

local function _toraw_tx(name)
	local tx = have(name..' transaction')
	local dst = name..'_raw_transaction'
	empty(dst)
	ACK[dst] = btc.build_raw_transaction(tx)
	new_codec(dst, { encoding = 'hex' })
end

When("create the bitcoin raw transaction", function() _toraw_tx('bitcoin') end)
When("create the testnet raw transaction", function() _toraw_tx('testnet') end)
