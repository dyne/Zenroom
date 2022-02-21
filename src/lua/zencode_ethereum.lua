--[[
--This file is part of zenroom
--
--Copyright (C) 2022 Dyne.org foundation
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
--on Monday, 21th February 2022
--]]

ETH = require_once'crypto_ethereum'


local function big_wei_to_str_wei(x)
   return x:decimal()
end
local function str_wei_to_big_wei(x)
   return BIG.from_decimal(tostring(x))
end
-- TODO: these conversions are slow
weimult = BIG.new(10):modpower(BIG.new(18), ECP.order())
gweimult = BIG.new(10):modpower(BIG.new(9), ECP.order())
local function str_gwei_to_big_wei(x)
   return ( BIG.from_decimal(tostring(x)) * gweimult )
end
local function big_wei_to_str_gwei(x)
   return ( x / gweimult ):decimal()
end
local function str_eth_to_big_wei(x)
   return ( BIG.from_decimal(tostring(x)) * weimult )
end
local function big_wei_to_str_eth(x)
   return ( ( x / weimult ):decimal() )
end

ZEN.add_schema(
   {
      ethereum_public_key = { import = O.from_hex,
			      export = O.to_hex },
      ethereum_address = { import = O.from_hex,
			   export = O.to_hex },
      ethereum_nonce = function(obj)
	 return ZEN.get(obj, 'result', INT.new, tonumber) end,
      ethereum_transaction = { import = O.from_hex,
			       export = O.to_hex },
      gas_price = { import = str_wei_to_big_wei,
		    export = big_wei_to_str_wei },
      gas_limit = { import = str_wei_to_big_wei,
		    export = big_wei_to_str_wei },
      ethereum_value = { import = str_eth_to_big_wei,
			 export = big_wei_to_str_eth },
      gwei_value = { import = str_gwei_to_big_wei,
		     export = big_wei_to_str_gwei },
      wei_value = { import = str_wei_to_big_wei,
		    export = big_wei_to_str_wei }
})

When('create the ethereum key', function()
	initkeys'ethereum'
	ACK.keys.ethereum = ECDH.keygen().private
end)

When('create the ethereum address', function()
	empty'ethereum address'
	local pk = ACK.ethereum_public_key
	if not pk then
	   pk = ECDH.pubgen( havekey'ethereum' )
	end
	ACK.ethereum_address = ETH.address_from_public_key(pk)
	new_codec('ethereum address', { zentype = 'element',
					encoding = 'hex' })
end)

When("create the ethereum transaction of '' to ''",
     function(quantity, destaddr)
	empty'ethereum transaction'
	local gasprice = have'gas price'
	local gaslimit = have'gas limit'
	local nonce = have'ethereum nonce'
	local value = have(quantity)
	local dest = have(destaddr)
	ACK.ethereum_transaction =
	   ETH.erc20.transfer(dest, value)
	new_codec('ethereum transaction', { zentype = 'schema',
					    encoding = 'complex'})
end)
