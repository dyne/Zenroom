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
--on Saturday, 4th September 2021
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
    else
        error('Keys table is corrupted', 2)
    end
    -- if ktype is specified then check overwriting
    if ktype then
        ZEN.assert(
            not ACK.keys[ktype],
            'Cannot overwrite existing key: ' .. ktype
        )
    end
end

-- KNOWN KEY TYPES FOUND IN ACK.keys
local keytypes = {
    ecdh = true,
    credential = true,
    issuer = true,
    bls = true,
	reflow = true,
    -- ethereum = true
}

function havekey(ktype)
    ZEN.assert(keytypes[ktype], 'Unknown key type: ' .. ktype)
    -- check that keys exist and are a table
    initkeys()
    local res
    res = ACK.keys[ktype]
    ZEN.assert(res, 'Key not found: ' .. ktype)
    return res
end

ZEN.add_schema(
    {
        keys = function(obj)
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
            return (res)
        end
    }
)
