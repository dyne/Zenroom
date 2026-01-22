--[[
--This file is part of zenroom
--
--Copyright (C) 2021-2026 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
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
--Last modified by Matteo Cristino
--on Friday, 20th June 2025
--]]

local crypto = {
    algos = {
        { IANA = 'EDDSA',
          keyring = 'eddsa',
          lib = 'eddsa',
          alias = { 'ed25519' },
          methods = { } -- default names sign=sign, verify=verify, etc
        },
        { IANA = 'ES256K',
          keyring = 'ecdh',
          lib = 'ecdh',
          alias = { 'ecdsa', 'secp256k1' },
          methods = { }
        },
        { IANA = 'ES256',
          keyring = 'es256',
          lib = 'es256',
          alias = { 'p256', 'es-256', 'secp256r1', 'p-256' },
          methods = { }
        },
        { IANA = 'ML-DSA-44',
          keyring = 'mldsa44',
          lib = 'qp',
          alias = { 'dilithium2-44', 'fips204', 'fips204-44' },
          -- here methods have names different from sign, verify, etc.
          methods = { sign   = 'mldsa44_signature',
                      verify = 'mldsa44_verify',
                      pubgen = 'mldsa44_pubgen'  }
        }
    }
}

-- case insensitive search of a string in an array of strings
local function _is_found(_arr, _obj)
    local found = false
    if #_obj > 32 then
        error("CRYPTO algo name too long: ".._obj,3)
    end
    local needle = _obj:lower()
    if _arr.IANA:lower() == needle then found = true end
    if _arr.keyring:lower() == needle then found = true end
    for _,v in ipairs(_arr.alias) do
        if v == needle then found = true end
    end
    return found
end

-- take any known string for an algo name and return IANA
-- keep constant time (side channel attack mitigation)
local function _lookup(id)
    local res
    for _,v in ipairs(crypto.algos) do
        if _is_found(v,id) then
            local lib <const> = require_once(v.lib)
            res = { IANA = v.IANA,
                    keyname = v.keyring,
                    class = lib, -- direct access to lib methods
                    sign =   lib[v.methods.sign   or 'sign'],
                    verify = lib[v.methods.verify or 'verify'],
                    pubgen = lib[v.methods.pubgen or 'pubgen']
                  }
        end
    end
    if res then return res end
    error("Crypto algorithm not found: "..id,2)
end

-- Load (require-once) and return crypto class, with function pointers
-- for common functions as well correct name according to:
-- https://www.iana.org/assignments/jose/jose.xhtml
-- This procedure avoids use procedural branching to keep constant time
-- (side channel attack mitigation)
-- @param any string describing the crypto signature algo
-- @return struct { name, sign, verify, pubgen, public_xy, keyname, ... }
function crypto.load(any)
    local id
    local t <const> = type(any)
    if t == 'zenroom.octet' then
        id = any:to_string()
    elseif t == 'string' then
        id = any
    else
        error('CRYPTO loader wrong argument type: '..t,2)
    end
    return _lookup(any)
end

return crypto
