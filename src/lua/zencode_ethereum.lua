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
--on Sunday, 10th April 2022
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

local function import_eth_address_f(str_add)
    local oct_add = O.from_hex(str_add)
    local check = ETH.checksum_encode(oct_add)
    if check ~= str_add then
        I.warn("Invalid encoding for ethereum address. Expected encoding: " .. check)
    end
    return oct_add
end

local function import_eth_tx(obj)
  local res = { }
  res.nonce = ZEN.get(obj, 'nonce', INT.from_decimal, tostring)
  res.gas_price = ZEN.get(obj, 'gas_price', INT.from_decimal, tostring)
  res.gas_limit = ZEN.get(obj, 'gas_limit', INT.from_decimal, tostring)
  res.value = ZEN.get(obj, 'value', INT.from_decimal, tostring)
  res.to = ZEN.get(obj, 'to', import_eth_address_f, tostring)
  if obj.data then
    res.data = ZEN.get(obj, 'data', O.from_hex, tostring)
  else res.data = O.new() end
  if obj.v then res.v = ZEN.get(obj, 'v', O.from_hex) end
  if obj.r then res.r = ZEN.get(obj, 'r', O.from_hex) end
  if obj.s then res.s = ZEN.get(obj, 's', O.from_hex) end
  return res
end
local function export_eth_tx(obj)
  local res = { }
  if obj.nonce then res.nonce = obj.nonce:decimal() end
  res.gas_price = obj.gas_price:decimal()
  res.gas_limit = obj.gas_limit:decimal()
  res.to = ETH.checksum_encode(obj.to)
  if #obj.value == 0 then res.value = '0'
  elseif type(obj.value) == 'zenroom.big' then
    res.value = obj.value:decimal()
  else
    error("invalid value type: "..type(obj.value))
  end
  if obj.data then res.data = obj.data:octet():hex() end
  if obj.v then res.v = obj.v:octet():hex() end
  if obj.r then res.r = obj.r:octet():hex() end
  if obj.s then res.s = obj.s:octet():hex() end
  return res
end

local function import_signature_f(obj)
    local res = {}
    local supp = ZEN.get(obj, '.', nil, O.from_hex)
    if (type(supp) == 'zenroom.octet') then
        res = {
            r = supp:sub(1,32),
            s = supp:sub(33, 64),
            v = BIG.new(supp:sub(65, 65))
        }
    else
        res.r = ZEN.get(obj, 'r', nil, O.from_hex)
        res.v = ZEN.get(obj, 'v', nil, BIG.from_decimal)
        res.s = ZEN.get(obj, 's', nil, O.from_hex)
    end
    return res
end

local function export_signature_f(obj)
    if (type(obj) == 'table') then
        obj = obj.r..obj.s..O.new(obj.v)
    end
    return "0x"..O.to_hex(obj)
end

local function import_method_f(obj)
    local res = {}
    res.name = ZEN.get(obj, 'name', nil, O.from_string)
    local input = ZEN.get(obj, 'input', nil, O.from_string)
    if type(input) ~= "table" then
        error("invalid input type: "..type(obj.output).."should be a string array")
    end
    res.input = input
    local output = ZEN.get(obj, 'output', nil, O.from_string)
    if type(input) ~= "table" then
        error("invalid output type: "..type(obj.output).."should be a string array")
    end
    res.output = output
    return res
end

local function export_method_f(obj)
    res = {}
    res.name = obj.name:octet():string()
    res.input = deepmap(function(o) return o:octet():string() end, obj.input)
    res.output = deepmap(function(o) return o:octet():string() end, obj.output)
    return res
end

ZEN.add_schema(
   {
      ethereum_public_key = { import = O.from_hex,
			      export = O.to_hex },
      ethereum_address = { import = function(obj)
                return ZEN.get(obj, '.', import_eth_address_f, tostring)
                end,
			   export = ETH.checksum_encode },
      -- TODO generic import from string in zenroom.big,
      -- if a number begins with 0x import it as hex
      -- otherwise as decimal (here we have to use tonumber
      -- in order to contemplate hex strings)
      ethereum_nonce = { import = function(o)
							local n = tonumber(o)
							ZEN.assert(n, "Ethereum nonce not valid")
							return INT.new(n) end,
                         export = function(o) return o:decimal() end },
      ethereum_transaction = { import = import_eth_tx,
							   export = export_eth_tx },
      signed_ethereum_transaction = { import = O.from_hex,
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
		    export = big_wei_to_str_wei },
      ethereum_signature = { import = import_signature_f,
            export = export_signature_f},
      ethereum_method = { import = import_method_f,
            export = export_method_f},
})

When('create the ethereum key', function()
	initkeyring'ethereum'
	ACK.keyring.ethereum = ECDH.keygen().private
end)

When('create the ethereum address', function()
	empty'ethereum address'
	local pk = ACK.ethereum_public_key
	if not pk then
	   pk = ECDH.pubgen( havekey'ethereum' )
	end
	ACK.ethereum_address = ETH.address_from_public_key(pk)
	new_codec('ethereum address', {encoding = 'complex'})
end)

-- Note that the address must be given as a string
When("verify the ethereum address string '' is valid", function(add)
    local str_add = O.to_string(have(add))
    local address = O.from_hex(str_add)
    ZEN.assert(str_add == ETH.checksum_encode(address), "The address has a wrong encoding")
end)

When("create the ethereum transaction of '' to ''",
function(quantity, destaddr)
  empty'ethereum transaction'
  local tx = { }
  tx.gas_price = have'gas price'
  tx.gas_limit = have'gas limit'
  tx.nonce = have'ethereum nonce'
  tx.value = have(quantity)
  tx.to = have(destaddr)
  tx.data = O.new()
  ACK.ethereum_transaction = tx
  new_codec('ethereum transaction')
end)

When("create the ethereum transaction to ''",
function(destaddr)
  empty'ethereum transaction'
  local tx = { }
  tx.gas_price = have'gas price'
  tx.gas_limit = have'gas limit'
  tx.nonce = have'ethereum nonce'
  tx.value = O.empty()
  tx.data = O.empty()
  tx.to = have(destaddr)
  ACK.ethereum_transaction = tx
  new_codec('ethereum transaction')
end)

local function _use_eth_transaction(abi_fun, ...)
  local tx = have'ethereum transaction'
  ZEN.assert(not tx.data or #tx.data == 0, "Cannot overwrite transaction data")
  tx.data = abi_fun(...)
end

-- we can store only strings (for the moment)
When("use the ethereum transaction to store ''",
function(content)
  _use_eth_transaction(ETH.make_storage_data, have(content))
end)

-- TODO: DEPRECATE
When("create the string from the ethereum bytes named ''", function(obj)
  empty'string'
  local data = have(obj):octet()
  local eth_decoder = ETH.contract_return_factory({ 'bytes' })
  local result = eth_decoder(data)
  ZEN.assert(#result == 1, "Wrong data format")
  ACK.string = O.from_str(result[1])
  new_codec('string', { encoding = 'string'})
end)

When("create the '' decoded from ethereum bytes ''", function(dst, obj)
  empty(dst)
  local data = have(obj):octet()
  local eth_decoder = ETH.contract_return_factory({ 'bytes' })
  local result = eth_decoder(data)
  ZEN.assert(#result == 1, "Wrong data format")
  ACK[dst] = O.from_rawlen(result[1], #result[1])
  new_codec(dst)
end)

-- TODO: more contract methods
-- use the ethereum transaction to store ''
-- use the ethereum transaction to transfer '' to ''
-- use the ethereum transaction to elect ''
-- use the ethereum transaction to vote ''

When("create the signed ethereum transaction",
function()
  local sk = havekey'ethereum'
  local tx = have'ethereum transaction'
  tx.v = INT.new(1337) -- default local testnet
  ACK.signed_ethereum_transaction =
  ETH.encodeSignedTransaction(sk, tx)
  new_codec('signed ethereum transaction')
end)

When("create the signed ethereum transaction for chain ''",
function(chainid)
  local sk = havekey'ethereum'
  local tx = have'ethereum transaction'
  local cid, cid_codec = mayhave(chainid)
  if cid then
      local enc = cid_codec.encoding
      if enc == "string" then
          cid = tonumber(cid:str()) or cid:octet()
      elseif enc ~= "integer" then
          error("Invalid chain id encoding: "..cid_codec.encoding)
      end
  else
      cid = tonumber(chainid) or O.from_string(chainid)
  end
  cid = INT.new(cid)
  ZEN.assert(cid, "Invalid chain id")
  if not tx.data  then tx.data = O.new() end
  if not tx.value then tx.value = O.new() end
  tx.v = cid
  tx.r = O.new()
  tx.s = O.new()
  ACK.signed_ethereum_transaction =
  ETH.encodeSignedTransaction(sk, tx)
  new_codec('signed ethereum transaction')
end)

When("verify the signed ethereum transaction from ''",
function(pubkey)
  local pk = have(pubkey)
  local rawtx = have'signed ethereum transaction'
  local tx = ETH.decodeTransaction(rawtx)
  -- TODO: check decode errors
  ZEN.assert( ETH.verifySignatureTransaction(pk, tx) )
end)

When("create the ethereum key with secret key ''",function(sec)
	local sk = have(sec)
	initkeyring'ethereum'
	ECDH.pubgen(sk)
	ACK.keyring.ethereum = sk
end)
When("create the ethereum key with secret ''",function(sec)
	local sk = have(sec)
	initkeyring'ethereum'
	ECDH.pubgen(sk)
	ACK.keyring.ethereum = sk
end)

When("use the ethereum transaction to transfer '' erc20 tokens to ''",
function(quantity, destaddr)
    _use_eth_transaction(ETH.erc20.transfer,
                         have(destaddr),
                         BIG.new(have(quantity)))
end)


When("use the ethereum transaction to transfer '' erc20 tokens to '' with details ''",
function(quantity, destaddr, details)
    _use_eth_transaction(ETH.transfer_erc20_details,
                         have(destaddr),
                         BIG.new(have(quantity)),
                         have(details))
end)

When("use the ethereum transaction to create the erc721 of uri ''",
function(uri)
    _use_eth_transaction(ETH.create_erc721,
                         have(uri):string())
end)

When("use the ethereum transaction to create the erc721 of object ''",
function(uri)
    _use_eth_transaction(ETH.create_erc721,
                         have(uri):base64())
end)

When("use the ethereum transaction to transfer the erc721 '' from '' to ''",
function(token_id, from, dest)
    _use_eth_transaction(ETH.erc721.safeTransferFrom,
                         have(from),
                         have(dest),
                         BIG.new(have(token_id)))
end)

When("use the ethereum transaction to approve the erc721 '' transfer from ''",
function(token_id, from)
    _use_eth_transaction(ETH.erc721.approve,
                         have(from),
                         BIG.new(have(token_id)))
end)

When("use the ethereum transaction to transfer the erc721 '' in the contract '' to '' in planetmint",
function(token_id, nft, to)
    _use_eth_transaction(ETH.eth_to_planetmint,
                         have(nft),
                         BIG.new(have(token_id)),
                         have(to))
end)

When("create the ethereum abi encoding of '' using ''", function(t, args)
    -- We imply that t is an octet/octet array and args is a single string/a string array
    local data = have(t)
    local o_type_spec = have(args)
    local type_spec
    -- TODO: support for nested array using deepmap.
    if(type(o_type_spec) == "table") then
        type_spec = {}
        for i,v in pairs(o_type_spec) do
            type_spec[i] = O.to_string(v)
        end
    else
        type_spec = O.to_string(o_type_spec)
    end
    empty'ethereum abi encoding'
    ACK.ethereum_abi_encoding = ETH.abi_encode(type_spec, data)
    new_codec('ethereum abi encoding', {encoding = 'hex'})
end)

When("create the ethereum abi decoding of '' using ''", function(t, args)
    -- We imply that t is an octet/octet array and args is a single string/a string array
    local data = have(t)
    local o_type_spec = have(args)
    local type_spec
    -- TODO: support for nested array using deepmap.
    if(type(o_type_spec) == "table") then
        type_spec = {}
        for i,v in pairs(o_type_spec) do
            type_spec[i] = O.to_string(v)
        end
    else
        type_spec = O.to_string(o_type_spec)
    end
    empty'ethereum abi decoding'
    ACK.ethereum_abi_decoding = ETH.abi_decode(type_spec)(data)
    new_codec('ethereum abi decoding', {zentype="a"})
end)

When("create the ethereum signature of ''", function(object)
    local sk = havekey'ethereum'
    local data = have(object)

    empty'ethereum signature'
    ACK.ethereum_signature = ETH.encodeSignedData(sk, data)
    new_codec('ethereum signature')
end)

IfWhen("verify the '' has a ethereum signature in '' by ''", function(doc, sig, by)

    local msg = have(doc)
    local ethersMessage = O.from_string("\x19Ethereum Signed Message:\n") .. O.new(#msg) .. msg
    local hmsg = keccak256(ethersMessage)

    local signature = have(sig)
    local address = have(by)

    ZEN.assert(
        ETH.verify_signature_from_address(signature, address, fif(signature.v:parity(), 0, 1), hmsg),
       'The ethereum signature by '..by..' is not authentic'
    )
end)

When("use the ethereum transaction to run '' using ''", function(m, p)

    local method, codec = have(m)
    local params = have(p)
    ZEN.assert(
       codec.schema == 'ethereum_method',
       'method must be a `ethereum method`'
    )
    local input = deepmap(function(o)
        return o:octet():string() end, method.input)
    local encoder = ETH.data_contract_factory(
        method.name:octet():string(), input)
    local transaction_data = encoder(table.unpack(params))
    local tx = have'ethereum transaction'
    ZEN.assert(not tx.data or #tx.data == 0, "Cannot overwrite transaction data")
    tx.data = transaction_data
end)
