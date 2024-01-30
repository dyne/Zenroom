--[[
--This file is part of zenroom
--
--Copyright (C) 2024 Dyne.org foundation
--Written by Denis Roio
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

print'Lua TEST: French Servant Protocol (FSP, TRANSCEND 2024)'
T = require'crypto_fsp'

-- setup
IV = OCTET.zero(32)
SS = OCTET.zero(64)
message = OCTET.from_string('My very secret message that none can reade excpet the receiver')
response = OCTET.from_string('My very secret response')
hash = HASH.new('sha256')

nonce = TIME.new(os.time()):octet() -- TODO: concatenate to semantic parameter


-- random session key length -32 marks the maximum message length
-- in other words: rsk is max length + 32 (hash len)
local max = math.max(#message, #response)
local padded_response = response:pad(max)
RSK = OCTET.random(max + 32)
print("MSG length: ".. #message)
print("RSP length: ".. #response)
print("RSK length: ".. #RSK)
print("probHASH: "..T.PROB)
-- from the paper:
-- Message:
-- {<Public key>,
-- AES(RSK, SS) XOR AES (<Public key>,SS) : Key transfer
-- (AES ((Hash(RSK XOR SS)||<Message1>) XOR RSK,RSK) : Message / MAC

local function _enc(key, msg)
    return AES.ctr_encrypt(hash:process(key), msg, IV)
end
local function _dec(key, msg)
    return AES.ctr_decrypt(hash:process(key), msg, IV)
end

-- sender side
ciphertext = {
   n = nonce,
   k = _enc(SS, RSK):xor_grow( _enc(SS, nonce) ),
--   p = hash:process(RSK ~ SS) .. message ~ RSK
   p = _enc(RSK, (hash:process(RSK:xor_grow( SS)):chop(T.PROB) .. message):xor_grow(RSK))
--   p = AES.ctr_encrypt(RSK, hash:process(RSK ~ SS) .. message, IV) ~ RSK
}

-- I.print({ciphertext = ciphertext})
-- I.print({entropy = deepmap(OCTET.entropy, ciphertext)})
-- receiver side
local rsk = _dec(SS, ciphertext.k:xor_grow( _enc(SS, ciphertext.n) ))
assert(rsk == RSK)

local recv_message = _dec(RSK, ciphertext.p:xor_grow( rsk )):trim()
local mac = hash:process(rsk:xor_grow(SS)):chop(T.PROB)
assert(recv_message == hash:process(rsk:xor_grow( SS )):chop(T.PROB) .. message)
assert(message == recv_message:elide_at_start(mac))

-- AES(RSK XOR (Hash(<Public key> XOR RSK)||<response>), SS) : Payload / ACK
ciphertext_response = _enc(SS, (hash:process(nonce:xor_grow( rsk )):chop(T.PROB) .. response):xor_grow( rsk ))


-- sender side
local recv_response = _dec(SS, ciphertext_response ~ RSK):trim()
local mac_response = hash:process(nonce:xor_grow(rsk)):chop(T.PROB)
assert(response == recv_response:elide_at_start(mac_response))
-- AES(Hash(RSK XOR SS)||<Payload1>, RSK) XOR RSK : Payload / MAC
-- AES(RSK, (Hash(RSK XOR SS) .. Payload) XOR RSK)
---

-- CRYPTO LIB


Tm = T.encode_message(SS, nonce, message, RSK, IV)
assert(zencode_serialize(ciphertext)
	   ==
	   zencode_serialize(Tm))

Tmr, Trsk = T.decode_message(SS, Tm, IV)
assert(Trsk == RSK)
assert(Tmr == message)

Tr = T.encode_response(SS, nonce, Trsk, response, IV)
assert(zencode_serialize(ciphertext_response)
	   ==
	   zencode_serialize(Tr))

Trd = T.decode_response(SS, nonce, Trsk, Tr, IV)
assert(Trd == response)

-- ciphertext entropy check
entropy = {
   k = FLOAT.new( Tm.k:entropy() ),
   p = FLOAT.new( Tm.p:entropy() ),
   r = FLOAT.new( Tr:entropy() )
}
-- I.print({entropy = entropy})
assert(entropy.k > FLOAT.new(0.9))
assert(entropy.p > FLOAT.new(0.9))
assert(entropy.r > FLOAT.new(0.9))

print'-- OK'
