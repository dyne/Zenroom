--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2026 Dyne.org foundation
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
--Last modified by Matteo Sangalli
--on Tuesday, 12th May 2026
--]]

LARKG = require_once'larkg'

local function larkg_public_key_f(obj)
    local res = schema_get(obj, '.')
    zencode_assert(
        LARKG.pubcheck(res),
        'Public key is not valid'
    )
    return res
end

local function larkg_cred_f(obj)
    local res = schema_get(obj, '.')
    zencode_assert(
        LARKG.credcheck(res),
        'Credential is not valid'
    )
    return res
end

ZEN:add_schema(
    {
        larkg_public_key = {import=larkg_public_key_f},
        larkg_derived_public_key = {import=larkg_public_key_f},
        larkg_cred = {import=larkg_cred_f},
        larkg_rho = {import=function(obj) return schema_get(obj, '.') end}
    }
)

-- Generate initial keypair and public parameters for larkg
When("create larkg key", function()
    initkeyring'larkg'
    local kp = LARKG.keygen()
    ACK.keyring.larkg = kp.private
    ACK.larkg_public_key = kp.public
    ACK.larkg_rho = kp.rho -- part of public parameters
    new_codec('larkg public key')
    new_codec('larkg rho')
end)

-- Derive next public key (sender side)
When("derive next larkg public key from '' with rho ''", function(pub, rho_in)
    local pk  = have(pub)
    local rho = have(rho_in)
    local res = LARKG.derive_pk(pk, rho)
    ACK.larkg_derived_public_key = res.next_public
    ACK.larkg_credential = res.credential
    if not CODEC.larkg_derived_public_key then
        new_codec('larkg derived public key')
    end
    new_codec('larkg credential')
end)

-- Derive next secret key (receiver side)
When("derive next larkg secret key with credential ''", function(cred_in)
    local sk = havekey'larkg'
    local cred = have(cred_in)
    ACK.keyring.larkg = LARKG.derive_sk(sk, cred)
end)
