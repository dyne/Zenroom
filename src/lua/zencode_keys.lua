--[[
--This file is part of zenroom
--
--Copyright (C) 2021 Dyne.org foundation
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
--Last modified by Denis Roio
--on Friday, 12th November 2021
--]]


-- DESCRIPTION: Special keys schema has optional members common to
-- multiple scenarios, it provides a common interface to create keys,
-- verifiers and check their existance. It does not use the keys, that's
-- up to the specific scenarios. One single scenario may require and use
-- the same key types (one or more) as others do, for instance reflow
-- uses bls and credential, petition uses credential and ecdh.

function initkeys(ktype)

   if luatype(ACK.keys) == 'table' then
      -- TODO: check that curve types match
   elseif ACK.keys == nil then
      -- initialise empty ACK.keys
      ACK.keys = {} -- TODO: save curve types
      new_codec('keys', {
		   zentype = 'schema',
		   luatype = 'table',
		   encoding = 'complex' })
   else
      error('Keys table is corrupted', 2)
   end
   -- if ktype is specified then check overwriting
   if ktype then
      ZEN.assert(
	 not ACK.keys[uscore(ktype)],
	 'Cannot overwrite existing key: ' .. ktype
      )
   end
end
When("create the keys", function()
	empty'keys'
	initkeys()
end)

-- KNOWN KEY TYPES FOUND IN ACK.keys
local keytypes = {
    ecdh = true,
    credential = true,
    issuer = true,
    bls = true,
    reflow = true,
    bitcoin = true,
    testnet = true
}

function havekey(ktype)
   local kname = uscore(ktype)
   ZEN.assert(keytypes[kname], 'Unknown key type: ' .. ktype)
   -- check that keys exist and are a table
   initkeys()
   local res = ACK.keys[kname]
   ZEN.assert(res, 'Key not found: ' .. ktype)
   return res
end

local function _keys_import(obj)
   -- ecdh_curve
   -- bls_curve
   local res = {}
   if obj.ecdh then
      res.ecdh = ZEN.get(obj, 'ecdh')
   end
   if obj.credential then
      res.credential = ZEN.get(obj, 'credential', INT.new)
   end
   if obj.issuer then
      res.issuer = {
	 x = ZEN.get(obj.issuer, 'x', INT.new),
	 y = ZEN.get(obj.issuer, 'y', INT.new)
      }
   end
   if obj.bls then
      res.bls = ZEN.get(obj, 'bls', INT.new)
   end
   if obj.reflow then
      res.reflow = ZEN.get(obj, 'reflow', INT.new)
   end
   if obj.bitcoin then
      res.bitcoin = ZEN.get(obj, 'bitcoin', BTC.wif_to_sk, O.from_base58)
   end
   if obj.testnet then
      res.testnet = ZEN.get(obj, 'testnet', BTC.wif_to_sk, O.from_base58)
   end

   return (res)
end

local function _default_export(obj)
   local fun = guess_outcast(CONF.output.encoding.name)
   return fun(obj)
end

local function _keys_export(obj)
   -- ecdh_curve
   -- bls_curve
   local res = {}
   if obj.ecdh then res.ecdh = _default_export(obj.ecdh) end
   if obj.credential then res.credential = _default_export(obj.credential) end
   if obj.issuer then
      local fun = guess_outcast(CONF.output.encoding.name)
      res.issuer = deepmap(fun, obj.issuer)
   end
   if obj.bls then res.bls = _default_export(obj.bls) end
   if obj.reflow then res.reflow = _default_export(obj.reflow) end
   if obj.bitcoin then
      res.bitcoin = O.to_base58( BTC.sk_to_wif(obj.bitcoin, 'bitcoin') )
   end
   if obj.testnet then
      res.testnet = O.to_base58( BTC.sk_to_wif(obj.testnet, 'testnet') )
   end

   return (res)
end

ZEN.add_schema(
    {
        keys = { import = _keys_import,
		 export = _keys_export  }
    }
)
