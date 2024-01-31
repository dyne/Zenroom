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
FSP = require'crypto_fsp'

message = OCTET.from_string('My very secret message that none can reade excpet the receiver')
response = OCTET.from_string('My very secret response')
hash = HASH.new('sha256')



-- random session key length -32 marks the maximum message length
-- in other words: rsk is max length + 32 (hash len)
SS = OCTET.zero(32)
RSK = OCTET.random(256)
NONCE = FSP:makenonce()
print("MSG length: ".. #message)
print("RSP length: ".. #response)
print("RSK length: ".. #RSK)
print("Nonce length: ".. #NONCE)
print("probHASH: "..FSP.PROB)
-- from the paper:
-- Message:
-- {<Public key>,
-- AES(RSK, SS) XOR AES (<Public key>,SS) : Key transfer
-- (AES ((Hash(RSK XOR SS)||<Message1>) XOR RSK,RSK) : Message / MAC
-- CRYPTO LIB


Tm = FSP:encode_message(SS, NONCE, message, RSK)
-- assert(zencode_serialize(ciphertext)
-- 	   ==
-- 	   zencode_serialize(Tm))

Tmr, Trsk = FSP:decode_message(SS, Tm, NONCE)
assert(Trsk == RSK)
assert(Tmr == message)

Tr = FSP:encode_response(SS, NONCE, Trsk, response)
-- assert(zencode_serialize(ciphertext_response)
-- 	   ==
-- 	   zencode_serialize(Tr))

Trd = FSP:decode_response(SS, NONCE, Trsk, Tr)
assert(Trd == response)

-- ciphertext entropy check
entropy = {
   k = FLOAT.new( Tm.k:entropy() ),
   p = FLOAT.new( Tm.p:entropy() ),
   r = FLOAT.new( Tr:entropy() )
}
I.print({entropy = entropy,
         cipher = { k = Tm.k,
                    p = Tm.p,
                    r = Tr}})
-- I.print({entropy = entropy})
assert(entropy.k > FLOAT.new(0.9))
assert(entropy.p > FLOAT.new(0.9))
assert(entropy.r > FLOAT.new(0.9))

print'-- OK'
