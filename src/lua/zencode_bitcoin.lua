--[[
--This file is part of zenroom
--
--Copyright (C) 2021-2025 Dyne.org foundation
--designed, written and maintained by Alberto Lerda and Denis Roio
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License as
--published by the Free Software Foundation, either version 3 of the
--License, or (at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--You should have received a copy of the GNU Affero General Public License 
--along with this program.  If not, see <https://www.gnu.org/licenses/>.
--
--Last modified by Denis Roio
--on Saturday, 9th April 2022
--]]

BTC = require_once'crypto_bitcoin'

local function _bitcoin_unspent_import(obj)
    local res = {}
    for _,v in pairs(obj) do
        -- compatibility with electrum and bitcoin core
        local n_amount = fif( v.amount, 'amount', 'value')
        local n_txid = fif( v.txid, 'txid', 'prevout_hash')
        local n_vout = fif( v.vout, 'vout', 'prevout_n')
        local address
        if v.address then
	        address = schema_get(v,'address', O.from_segwit, tostring)
        end
        table.insert(res, {
            address = address,
            amount  = schema_get(v, n_amount, BTC.value_btc_to_satoshi, tostring),
            txid    = schema_get(v, n_txid, OCTET.from_hex, tostring),
            vout    = schema_get(v, n_vout, INT.new)
        })
   end
   return res
end
local function _bitcoin_unspent_export(obj)
    local res = { }
    for _,v in pairs(obj) do
        -- to_segwit: octet, version number(0), 'bc' or 'tc'
        table.insert(res, {
            address = v.address:segwit(0, 'tb'),
            amount  = BTC.value_satoshi_to_btc(v.amount),
            txid    = v.txid:hex(),
            vout    = v.vout
        })
    end
    return res
end

local function _satoshi_unspent_import(obj)
    local res = {}
    for _,v in pairs(obj) do
        table.insert(res, {
            amount = schema_get(v,'value', INT.new),
            txid   = schema_get(v,'txid', OCTET.from_hex, tostring),
            vout   = F.new(v.vout)
        })
    end
    return(res)
end
local function _satoshi_unspent_export(obj)
    local res = {}
    for _,v in pairs(obj) do
        table.insert(res, {
            amount = BIG.to_decimal(v.amount),
            txid   = v.txid:hex(),
            vout   = v.vout
        })
    end
    return res
end

local function _address_import(obj)
    local raw, version = O.from_segwit(tostring(obj))
    local network = obj:sub(0,2)
    return {
        raw = raw,
        version = F.new(version),
        network = O.from_string(network)
    }
end
local function _address_export(obj)
    if not obj.raw then error("Cannot export invalid bitcoin address",2) end
    return O.to_segwit(obj.raw, tonumber(obj.version), O.to_string(obj.network))
end

local function _pk_import(o)
    local res = schema_get(o, '.')
    if #res ~= 33 then
        error('Invalid public key size: '..#res, 2)
    end
    if not ECDH.pubcheck(ECDH.uncompress_public_key(res)) then
        error('Public key is not a valid point on curve', 2)
    end
    return res
end

ZEN:add_schema(
    {
        bitcoin_public_key = {
            import = _pk_import
        },
        satoshi_amount = {
            import = function(obj) return schema_get(obj, '.', BIG.from_decimal, tostring) end,
            export = BIG.to_decimal
        },
        satoshi_fee = {
            import = function(obj) return schema_get(obj, '.', BIG.from_decimal, tostring) end,
            export = BIG.to_decimal
        },
        satoshi_unspent = {
            import = _satoshi_unspent_import,
            export = _satoshi_unspent_export
        },
        bitcoin_unspent = {
            import = _bitcoin_unspent_import,
            export = _bitcoin_unspent_export
        },
        testnet_unspent = {
            import = _bitcoin_unspent_import,
            export = _bitcoin_unspent_export
        },
        bitcoin_address = {
            import = _address_import,
            export = _address_export
        },
        testnet_address = {
            import = _address_import,
            export = _address_export
        },
      -- TODO: { schema = 'transaction' })
    }
)

-- generate a keypair in "bitcoin" format (only x coord, 03 prepended)
local function _keygen(name)
	initkeyring(name)
	local kp = ECDH.keygen()
	ACK.keyring[name] = kp.private
end
When("create bitcoin key", function() _keygen('bitcoin') end)
When("create testnet key", function() _keygen('testnet') end)

local function _import_wif(sec, name)
		local sk = have(sec)
		local res
		if #sk == 32+6 then -- wif
		   BTC.wif_to_sk(sk) -- checks
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
When("create bitcoin key with secret key ''", function(sec)
	_import_wif(sec, 'bitcoin') end)
When("create testnet key with secret key ''", function(sec)
	_import_wif(sec, 'testnet') end)
When("create bitcoin key with secret ''", function(sec)
	_import_wif(sec, 'bitcoin') end)
When("create testnet key with secret ''", function(sec)
	_import_wif(sec, 'testnet') end)

local function _get_pub(name)
	empty(name..' public key')
	local sk = havekey(name)
	ACK[name..'_public_key'] = ECDH.sk_to_pubc(sk)
	new_codec(name..' public key')
end
When("create bitcoin public key", function() _get_pub('bitcoin') end)
When("create testnet public key", function() _get_pub('testnet') end)

local function _create_addr(name,pfx)
	empty(name..' address')
	local pk
	if ACK[name..'_public_key'] then
	   pk = have(name..' public key')
	else
	   pk = ECDH.sk_to_pubc( havekey(name) )
	end
	ACK[name..'_address'] = { raw = BTC.address_from_public_key(pk),
				  version = F.new(0),
				  network = O.from_string(pfx) }
	new_codec(name..' address')
end
When("create bitcoin address", function() _create_addr('bitcoin','bc') end)
When("create testnet address", function() _create_addr('testnet','tb') end)

local function _create_tx(name, recipient)
	local to      = have(recipient or 'recipient')
	if not to then
		error("Cannot create "..name.." transaction: recipient not specified")
	end
	local q       = have'satoshi amount'
	local fee     = have'satoshi fee'
	local unspent = have(name..' unspent')
	local tx = BTC.build_tx_from_unspent(unspent, to, q, fee, ACK.sender)
	zencode_assert(tx, "Not enough "..name.." in the unspent list")
	ACK[name..'_transaction'] = tx
	new_codec(name..'_transaction') -- TODO: { schema = 'transaction' })
end
When("create bitcoin transaction", function() _create_tx('bitcoin') end)
When("create testnet transaction", function() _create_tx('testnet') end)
When("create bitcoin transaction to ''", function(recipient) _create_tx('bitcoin', recipient) end)
When("create testnet transaction to ''", function(recipient) _create_tx('testnet', recipient) end)

local function _sign_tx(name)
   local sk = havekey(name)
   local tx = have(name..'_transaction')
   zencode_assert(not tx.witness, "The "..name.." transaction is already signed")
   tx.witness = BTC.build_witness(tx, sk)
end
When("sign bitcoin transaction", function() _sign_tx('bitcoin') end)
When("sign testnet transaction", function() _sign_tx('testnet') end)

local function _toraw_tx(name)
	local tx = have(name..' transaction')
	local dst = name..'_raw_transaction'
	empty(dst)
	ACK[dst] = BTC.build_raw_transaction(tx)
	new_codec(dst, { encoding = 'hex' })
end

When("create bitcoin raw transaction", function() _toraw_tx('bitcoin') end)
When("create testnet raw transaction", function() _toraw_tx('testnet') end)
