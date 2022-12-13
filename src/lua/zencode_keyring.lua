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
      new_codec('keyring', {
		   zentype = 'schema',
		   encoding = 'keyring',
		   luatype = 'table'    })
   else
      error('Keyring table is corrupted', 2)
   end
   -- if ktype is specified then check overwriting
   if ktype then
      ZEN.assert(
	 not ACK.keyring[uscore(ktype)],
	 'Cannot overwrite existing key: ' .. ktype
      )
   end
end
When("create the keyring", function()
    empty'keyring'
    initkeyring()
end)

-- KNOWN KEY TYPES FOUND IN ACK.keyring
local keytypes = {
    ecdh = true,
    credential = true,
    issuer = true,
    bls = true,
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
   ZEN.assert(keytypes[kname], 'Unknown key type: ' .. ktype)
   -- check that keys exist and are a table
   initkeyring()
   local res = ACK.keyring[kname]
   ZEN.assert(res, 'Key not found: ' .. ktype)
   return res
end

local function nop(x) return(x) end
-- the length of the kyber, dilithium and ntrup keys can be found in Zenroom/src/zen_qp.c
local function dilithium_f(o)
   ZEN.assert(#o == 2528, 'Dilithium key length` is not correct')
   return o
end
local function kyber_f(o)
   ZEN.assert(#o == 1632, 'Kyber key length is not correct')
   return o
end
local function ntrup_f(o)
   ZEN.assert(#o == 1763, 'Ntrup key length is not correct')
   return o
end  

function import_keyring(obj)
   for k,_ in pairs(obj) do
      if not keytypes[k] then
	 error("Unsupported key type found in keyring: "..k, 2)
      end
   end
   -- ecdh_curve
   -- bls_curve
   local res = {}
   if obj.ecdh then
      res.ecdh = ZEN.get(obj, 'ecdh', nop, O.from_base64)
   end
   if obj.credential then
      res.credential = ZEN.get(obj, 'credential', INT.new, O.from_base64)
   end
   if obj.issuer then
      res.issuer = {
	 x = ZEN.get(obj.issuer, 'x', INT.new, O.from_base64),
	 y = ZEN.get(obj.issuer, 'y', INT.new, O.from_base64)
      }
   end
   if obj.bls then
      res.bls = ZEN.get(obj, 'bls', INT.new, O.from_base64)
   end
   if obj.reflow then
      res.reflow = ZEN.get(obj, 'reflow', INT.new, O.from_base64)
   end
   if obj.bitcoin then
      res.bitcoin = ZEN.get(obj, 'bitcoin', BTC.wif_to_sk, O.from_base58)
   end
   if obj.testnet then
      res.testnet = ZEN.get(obj, 'testnet', BTC.wif_to_sk, O.from_base58)
   end
   if obj.ethereum then
      res.ethereum = ZEN.get(obj, 'ethereum', nop, O.from_hex)
   end
   if obj.dilithium then
      res.dilithium = ZEN.get(obj, 'dilithium', dilithium_f, O.from_base64)
   end
   if obj.kyber then
      res.kyber = ZEN.get(obj, 'kyber', kyber_f, O.from_base64)
   end
   if obj.schnorr then
      res.schnorr = ZEN.get(obj, 'schnorr', nop, O.from_base64)
   end
   if obj.ntrup then
      res.ntrup = ZEN.get(obj, 'ntrup', ntrup_f, O.from_base64)
   end
   if obj.eddsa then
      res.eddsa = ZEN.get(obj, 'eddsa', nop, O.from_base58)
   end
   return (res)
end

local function _default_export(obj)
   local fun = guess_outcast(CONF.output.encoding.name)
   return fun(obj)
end

function export_keyring(obj)
   -- ecdh_curve
   -- bls_curve
   local res = {}
   if obj.ecdh then res.ecdh = _default_export(obj.ecdh) end
   if obj.credential then res.credential = obj.credential:octet():base64() end
   if obj.issuer then
      local fun = guess_outcast("base64")
      res.issuer = {x = obj.issuer.x:octet(), y = obj.issuer.y:octet()}
      res.issuer = deepmap(fun, res.issuer)
   end
   if obj.bls then res.bls = obj.bls:octet():base64() end
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
   if obj.dilithium then res.dilithium = _default_export(obj.dilithium) end
   if obj.kyber then     res.kyber     = _default_export(obj.kyber) end
   if obj.schnorr then   res.schnorr   = _default_export(obj.schnorr) end
   if obj.ntrup then     res.ntrup     = _default_export(obj.ntrup) end
   if obj.eddsa then     res.eddsa     = O.to_base58(obj.eddsa) end
   return (res)
end


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
        ZEN.assert(
        pubkey,
        'Public key not found for: ' .. _key
        )
    end
    return pubkey
end


