--[[
--This file is part of zenroom
--
--Copyright (C) 2021-2024 Dyne.org foundation
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
--]]


-- DESCRIPTION: Special keys schema has optional members common to
-- multiple scenarios, it provides a common interface to create keys,
-- verifiers and check their existance. It does not use the keys, that's
-- up to the specific scenarios. One single scenario may require and use
-- the same key types (one or more) as others do, for instance reflow
-- uses bls and credential, petition uses credential and ecdh.

-- utils local functions
local function nop(x) return(x) end
-- the length of the kyber, dilithium and ntrup keys can be found in Zenroom/src/zen_qp.c
local function dilithium_f(o)
   if #o ~= 2528 then
       error('Dilithium key length is not correct: '..#o, 3)
   end
   return o
end
local function kyber_f(o)
   if #o ~= 1632 then
       error('Kyber key length is not correct: '..#o, 3)
   end
   return o
end
local function mlkem512_f(o)
   if #o ~= 1632 then
       error('ML-KEM-512 key length is not correct: '..#o, 3)
   end
   return o
end
local function ntrup_f(o)
   if #o ~= 1763 then
       error('Ntrup key length is not correct: '..#o, 3)
   end
   return o
end  
local function mldsa44_f(o)
   if #o ~= 2560 then
       error('mldsa44 key length is not correct: '..#o, 3)
   end
   return o
end
local function rsa_f(o)
   if #o ~= 1280 then
       error('rsa key length is not correct: '..#o, 3)
   end
   return o
end

-- KNOWN KEY TYPES FOUND IN ACK.keyring and their import/export
local keytypes <const> = {
    ecdh = {
        import = function(obj) return schema_get(obj, 'ecdh', nop, O.from_base64) end,
        export = function(obj) return obj.ecdh:octet():base64() end
    },
    es256 = {
        import = function(obj) return schema_get(obj, 'es256', nop, O.from_base64) end,
        export = function(obj) return obj.es256:octet():base64() end
    },
    credential = {
        import = function(obj) return schema_get(obj, 'credential', INT.new, O.from_base64) end,
        export = function(obj) return obj.credential:octet():base64() end
    },
    issuer = {
        import = function(obj)
            return {
                x = schema_get(obj.issuer, 'x', INT.new, O.from_base64),
                y = schema_get(obj.issuer, 'y', INT.new, O.from_base64)
            }
        end,
        export = function(obj) return {x = obj.issuer.x:octet():base64(), y = obj.issuer.y:octet():base64()} end
    },
    bbs = {
        import = function(obj) return schema_get(obj, 'bbs', INT.new, O.from_base64) end,
        export = function(obj) return obj.bbs:octet():base64() end
    },
    bbs_shake = {
        import = function(obj) return schema_get(obj, 'bbs_shake', INT.new, O.from_base64) end,
        export = function(obj) return obj.bbs_shake:octet():base64() end
    },
    pvss = {
        import = function(obj) return schema_get(obj, 'pvss', INT.new, O.from_base64) end,
        export = function(obj) return obj.pvss:octet():base64() end
    },
    reflow = {
        import = function(obj) return schema_get(obj, 'reflow', INT.new, O.from_base64) end,
        export = function(obj) return obj.reflow:octet():base64() end
    },
    bitcoin = {
        import = function(obj) return schema_get(obj, 'bitcoin', BTC.wif_to_sk, O.from_base58) end,
        export = function(obj) return O.to_base58(BTC.sk_to_wif(obj.bitcoin, 'bitcoin')) end
    },
    testnet = {
        import = function(obj) return schema_get(obj, 'testnet', BTC.wif_to_sk, O.from_base58) end,
        export = function(obj) return O.to_base58(BTC.sk_to_wif(obj.bitcoin, 'testnet')) end
    },
    ethereum = {
        import = function(obj) return schema_get(obj, 'ethereum', nop, O.from_hex) end,
        export = function(obj) return obj.ethereum:octet():hex() end
    },
    dilithium = {
        import = function(obj) return schema_get(obj, 'dilithium', dilithium_f, O.from_base64) end,
        export = function(obj) return obj.dilithium:octet():base64() end
    },
    mldsa44 = {
        import = function(obj) return schema_get(obj, 'mldsa44', mldsa44_f, O.from_base64) end,
        export = function(obj) return obj.mldsa44:octet():base64() end
    },
    schnorr = {
        import = function(obj) return schema_get(obj, 'schnorr', nop, O.from_base64) end,
        export = function(obj) return obj.schnorr:octet():base64() end
    },
    kyber = {
        import = function(obj) return schema_get(obj, 'kyber', kyber_f, O.from_base64) end,
        export = function(obj) return obj.kyber:octet():base64() end
    },
    mlkem512 = {
        import = function(obj) return schema_get(obj, 'mlkem512', mlkem512_f, O.from_base64) end,
        export = function(obj) return obj.mlkem512:octet():base64() end
    },
    rsa = {
        import = function(obj) return schema_get(obj, 'rsa', rsa_f, O.from_base64) end,
        export = function(obj) return obj.rsa:octet():base64() end
    },
    ntrup = {
        import = function(obj) return schema_get(obj, 'ntrup', ntrup_f, O.from_base64) end,
        export = function(obj) return obj.ntrup:octet():base64() end
    },
    eddsa = {
        import = function(obj) return schema_get(obj, 'eddsa', nop, O.from_base58) end,
        export = function(obj) return obj.eddsa:octet():base58() end
    },
    fsp = {
        import = function(obj) return schema_get(obj, 'fsp', nop, O.from_base64) end,
        export = function(obj) return obj.fsp:octet():base64() end
    }
}

local function import_keyring(obj)
    local res = {}
    for k,_ in pairs(obj) do
        local t = keytypes[k]
        if not t then
            error("Unsupported key type found in keyring: "..k, 2)
        end
        res[k] = t.import(obj)
    end
    return res
end

-- used in zencode_then directly
function export_keyring(obj)
    local res = {}
    for k,_ in pairs(obj) do
        local t = keytypes[k]
        if not t then
            error("Unsupported key type found in keyring: "..k, 2)
        end
        res[k] = t.export(obj)
    end
    return res
end

ZEN:add_schema(
    {
        keyring = {
            import = import_keyring,
            export = export_keyring
        }
    }
)

When("create keyring", function()
    empty'keyring'
    initkeyring()
end)

-- UTILS global functions

-- check various locations to find the public key
-- algo can be one of dilithium, keyber, eddsa
--  Given I have a 's' from 't'            --> ACK.s[t]
function load_pubkey_compat(_key, algo)
    local pubkey = ACK[_key]
    if pubkey then return pubkey end
    pubkey = ACK[algo..'_public_key']
    if not pubkey then
        error('Public key not found for: ' .. _key, 2)
    end
    if luatype(pubkey) == 'table' then
        return pubkey[_key]
    else
        return pubkey
    end
end

function havekey(ktype)
    local kname = uscore(ktype)
    if not keytypes[kname] then
        error('Unknown key type: ' .. ktype, 2)
    end
    -- check that keys exist and are a table
    initkeyring()
    local res = ACK.keyring[kname]
    if not res then
        error('Key not found: ' .. ktype, 2)
    end
    return res
 end

 -- keyring initialization
function initkeyring(ktype)
    if not ACK.keyring then
        ACK.keyring = {}
        new_codec('keyring')
    end
    if luatype(ACK.keyring) ~= 'table' then
        error('Keyring table is corrupted', 2)
    end
    -- TODO: check that curve types match
    -- if ktype is specified then check overwriting
    if ktype and ACK.keyring[uscore(ktype)] then
        error('Cannot overwrite existing key: ' .. ktype, 2)
    end
end
