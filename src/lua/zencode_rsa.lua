--[[
--This file is part of zenroom
--
--Copyright (C) 2024-2025 Dyne.org foundation
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
--]]

local RSA = require'rsa'

local function rsa_public_key_f(obj)
    local res = schema_get(obj, '.')
    zencode_assert(
        RSA.pubcheck(res),
        'rsa public key length is not correct'
    )
    return res
end
 
local function rsa_signature_f(obj)
    local res = schema_get(obj, '.')
    zencode_assert(
        RSA.signature_check(res),
        'rsa signature length is not correct'
    )
    return res
end

ZEN:add_schema(
    {
        rsa_public_key = {import=rsa_public_key_f},
        rsa_signature = {import=rsa_signature_f}
    }
)

When("create rsa key",function()
    initkeyring'rsa'
    ACK.keyring.rsa = RSA.keygen().private
end)

-- generate the public key
When("create rsa public key",function()
    empty'rsa public key'
    local sk = havekey'rsa'
    ACK.rsa_public_key = RSA.pubgen(sk)
    new_codec('rsa public key')
end)

When("create rsa public key with secret key ''",function(sec)
    local sk = have(sec)
    empty'rsa public key'
    ACK.rsa_public_key = RSA.pubgen(sk)
    new_codec('rsa public key')
end)

-- generate the sign for a msg and verify
When("create rsa signature of ''",function(doc)
    local sk = havekey'rsa'
    local obj = have(doc)
    empty'rsa signature'
    ACK.rsa_signature = RSA.sign(sk, zencode_serialize(obj))
    new_codec('rsa signature')
end)

IfWhen("verify '' has a rsa signature in '' by ''",function(msg, sig, by)
    local pk = load_pubkey_compat(by, 'rsa')
    local m = have(msg)
    local s = have(sig)
    zencode_assert(
        RSA.verify(pk, zencode_serialize(m), s),
        'The rsa signature by '..by..' is not authentic'
    )
end)
