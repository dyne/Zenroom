-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

print'French Servant Protocol (TRANSCEND 2024)'

-- setup
IV = OCTET.zero(32)
SS = OCTET.zero(64)
-- message = OCTET.from_string('My very secret message'):pad(32)
-- response = OCTET.from_string('My very secret response'):pad(32)
message = OCTET.random(128)
response = OCTET.random(12)
hash = HASH.new('sha256')

nonce = TIME.new(os.time()) -- TODO: concatenate to semantic parameter


-- random session key length -32 marks the maximum message length
-- in other words: rsk is max length + 32 (hash len)
local max = math.max(#message, #response)
message = message:pad(max)
response = response:pad(max)
RSK = OCTET.random(max + 32)
print("MSG length: ".. max)
print("RSK length: ".. #RSK)
-- from the paper:
-- Message:
-- {<Public key>,
-- AES(RSK, SS) XOR AES (<Public key>,SS) : Key transfer
-- (AES ((Hash(RSK XOR SS)||<Message1>) XOR RSK,RSK) : Message / MAC


-- sender side
ciphertext = {
   n = nonce,
   k = AES.ctr_encrypt(hash:process(SS), RSK, IV) ~ AES.ctr_encrypt(hash:process(SS), nonce, IV),
--   p = hash:process(RSK ~ SS) .. message ~ RSK
   p = AES.ctr_encrypt(hash:process(RSK), hash:process(RSK ~ SS) .. message, IV) ~ RSK
--   p = AES.ctr_encrypt(RSK, hash:process(RSK ~ SS) .. message, IV) ~ RSK
}

I.print({ciphertext = ciphertext})
I.print({entropy = deepmap(OCTET.entropy, ciphertext)})
-- receiver side
local rsk = AES.ctr_decrypt(hash:process(SS), ciphertext.k ~ AES.ctr_encrypt(hash:process(SS), ciphertext.n, IV), IV)
assert(rsk == RSK)

local recv_message = AES.ctr_decrypt(hash:process(RSK), ciphertext.p ~ rsk, IV)
local mac = hash:process(rsk ~ SS)
assert(recv_message == hash:process(rsk ~ SS) .. message)
assert(message == recv_message:elide_at_start(mac))

-- AES(RSK XOR (Hash(<Public key> XOR RSK)||<response>), SS) : Payload / ACK
ciphertext = AES.ctr_encrypt(hash:process(SS), (hash:process(nonce ~ rsk) .. response) ~ rsk, IV)

I.print({response = ciphertext,
		 entropy = ciphertext:entropy()})

-- sender side
local recv_response = AES.ctr_decrypt(hash:process(SS), ciphertext, IV) ~ RSK
local mac_response = hash:process(nonce ~ RSK)
assert(response == recv_response:elide_at_start(mac_response))



-- AES(Hash(RSK XOR SS)||<Payload1>, RSK) XOR RSK : Payload / MAC
-- AES(RSK, (Hash(RSK XOR SS) .. Payload) XOR RSK)
