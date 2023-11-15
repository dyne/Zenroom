--[[
--This file is part of zenroom
--
--Copyright (C) 2021-2022 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
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


-- DESCRIPTION: Special keys schema has optional members common to
-- multiple scenarios, it provides a common interface to create keys,
-- verifiers and check their existance. It does not use the keys, that's
-- up to the specific scenarios. One single scenario may require and use
-- the same key types (one or more) as others do, for instance reflow
-- uses bls and credential, petition uses credential and ecdh.

function initkeyring(ktype)

   if luatype(ACK.keyring) == 'table' then
      -- TODO: check that curve types match
   elseif ACK.keyring == nil then
      -- initialise empty ACK.keyring
      ACK.keyring = {} -- TODO: save curve types
      new_codec('keyring')
   else
      error('Keyring table is corrupted', 2)
   end
   -- if ktype is specified then check overwriting
   if ktype then
      zencode_assert(
	 not ACK.keyring[uscore(ktype)],
	 'Cannot overwrite existing key: ' .. ktype
      )
   end
end
When("create keyring", function()
    empty'keyring'
    initkeyring()
end)

-- KNOWN KEY TYPES FOUND IN ACK.keyring
local keytypes = {
    ecdh = true,
    p256 = true,
    credential = true,
    issuer = true,
    bbs = true,
    pvss = true,
    reflow = true,
    bitcoin = true,
    testnet = true,
    ethereum = true,
    dilithium = true,
    schnorr = true,
    kyber = true,
    ntrup = true,
    eddsa = true,
}

function havekey(ktype)
   local kname = uscore(ktype)
   zencode_assert(keytypes[kname], 'Unknown key type: ' .. ktype)
   -- check that keys exist and are a table
   initkeyring()
   local res = ACK.keyring[kname]
   zencode_assert(res, 'Key not found: ' .. ktype)
   return res
end

local function nop(x) return(x) end
-- the length of the kyber, dilithium and ntrup keys can be found in Zenroom/src/zen_qp.c
local function dilithium_f(o)
   zencode_assert(#o == 2528, 'Dilithium key length` is not correct')
   return o
end
local function kyber_f(o)
   zencode_assert(#o == 1632, 'Kyber key length is not correct')
   return o
end
local function ntrup_f(o)
   zencode_assert(#o == 1763, 'Ntrup key length is not correct')
   return o
end  

local function import_keyring(obj)
   for k,_ in pairs(obj) do
      if not keytypes[k] then
	 error("Unsupported key type found in keyring: "..k, 2)
      end
   end
   -- ecdh_curve
   -- bls_curve
   local res = {}
   if obj.ecdh then
      res.ecdh = schema_get(obj, 'ecdh', nop, O.from_base64)
   end
   if obj.p256 then
    res.p256 = schema_get(obj, 'p256', nop, O.from_base64)
   end
   if obj.credential then
      res.credential = schema_get(obj, 'credential', INT.new, O.from_base64)
   end
   if obj.issuer then
      res.issuer = {
	 x = schema_get(obj.issuer, 'x', INT.new, O.from_base64),
	 y = schema_get(obj.issuer, 'y', INT.new, O.from_base64)
      }
   end
   if obj.bbs then
      res.bbs = schema_get(obj, 'bbs', INT.new, O.from_base64)
   end
   if obj.pvss then
      res.pvss = schema_get(obj, 'pvss', INT.new, O.from_base64)
   end
   if obj.reflow then
      res.reflow = schema_get(obj, 'reflow', INT.new, O.from_base64)
   end
   if obj.bitcoin then
      res.bitcoin = schema_get(obj, 'bitcoin', BTC.wif_to_sk, O.from_base58)
   end
   if obj.testnet then
      res.testnet = schema_get(obj, 'testnet', BTC.wif_to_sk, O.from_base58)
   end
   if obj.ethereum then
      res.ethereum = schema_get(obj, 'ethereum', nop, O.from_hex)
   end
   if obj.dilithium then
      res.dilithium = schema_get(obj, 'dilithium', dilithium_f, O.from_base64)
   end
   if obj.kyber then
      res.kyber = schema_get(obj, 'kyber', kyber_f, O.from_base64)
   end
   if obj.schnorr then
      res.schnorr = schema_get(obj, 'schnorr', nop, O.from_base64)
   end
   if obj.ntrup then
      res.ntrup = schema_get(obj, 'ntrup', ntrup_f, O.from_base64)
   end
   if obj.eddsa then
      res.eddsa = schema_get(obj, 'eddsa', nop, O.from_base58)
   end
   return (res)
end

-- used in zencode_then directly
function export_keyring(obj)
   -- ecdh_curve
   -- bls_curve
   local res = {}
   if obj.ecdh then res.ecdh = CONF.output.encoding.fun(obj.ecdh) end
   if obj.credential then res.credential = obj.credential:octet():base64() end
   if obj.issuer then
      local fun = get_encoding_function("base64")
      res.issuer = {x = obj.issuer.x:octet(), y = obj.issuer.y:octet()}
      res.issuer = deepmap(fun, res.issuer)
   end
   if obj.p256 then res.p256 = O.to_base64(obj.p256) end
   if obj.bbs then res.bbs = obj.bbs:octet():base64() end
   if obj.pvss then res.pvss = obj.pvss:octet():base64() end
   if obj.reflow then res.reflow = obj.reflow:octet():base64() end
   if obj.bitcoin then
      res.bitcoin = O.to_base58( BTC.sk_to_wif(obj.bitcoin, 'bitcoin') )
   end
   if obj.testnet then
      res.testnet = O.to_base58( BTC.sk_to_wif(obj.testnet, 'testnet') )
   end
   if obj.ethereum then
      res.ethereum = O.to_hex(obj.ethereum)
   end
   if obj.dilithium then res.dilithium = CONF.output.encoding.fun(obj.dilithium) end
   if obj.kyber then     res.kyber     = CONF.output.encoding.fun(obj.kyber) end
   if obj.schnorr then   res.schnorr   = CONF.output.encoding.fun(obj.schnorr) end
   if obj.ntrup then     res.ntrup     = CONF.output.encoding.fun(obj.ntrup) end
   if obj.eddsa then     res.eddsa     = O.to_base58(obj.eddsa) end
   return (res)
end

ZEN:add_schema(
   { keyring = { import = import_keyring,
				 export = export_keyring }
   }
)

-- UTILS
-- check various locations to find the public key
-- algo can be one of dilithium, keyber, eddsa
--  Given I have a 's' from 't'            --> ACK.s[t]
function load_pubkey_compat(_key, algo)
    local pubkey = ACK[_key]
    if not pubkey then
        local pubkey_arr = ACK[algo..'_public_key']
        if luatype(pubkey_arr) == 'table' then
            pubkey = pubkey_arr[_key]
        else
            pubkey = pubkey_arr
        end
        zencode_assert(
        pubkey,
        'Public key not found for: ' .. _key
        )
    end
    return pubkey
end


