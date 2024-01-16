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
SS = OCTET.from_hex('1e3f2ec68a14fe9c6812df91bb5f76e5b8c221afebf03a44975342e76e2a2ff9')
alice = OCTET.from_string('My very secret message')
bob = OCTET.from_string('My very secret response')
hash = HASH.new('sha256')

nonce = os.time() -- concatenated to a semantic parameter
RSK_len = 32 -- chose according to message length
-- Peel_len = 32 -- for MAC and ACK

-- random session key
RSK = OCTET.random(RSK_len)

-- from the paper:
-- Message:
-- {<Public key>,
-- AES(RSK, SS) XOR AES (<Public key>,SS) : Key transfer
-- (AES ((Hash(RSK XOR SS)||<Alice1>) XOR RSK,RSK) : Alice / MAC


-- sender side
message = {
   n = nonce,
   k = AES.ctr_encrypt(SS, RSK, IV) ~ AES.ctr_encrypt(SS, nonce, IV),
   p = AES.ctr_encrypt(RSK, hash:process(RSK ~ SS) .. alice, IV) ~ RSK
}
I.print({message = message})

-- receiver side
local rsk = AES.ctr_decrypt(SS, message.k ~ AES.ctr_encrypt(SS, message.n, IV), IV)
assert(rsk == RSK)

local recv_alice = AES.ctr_decrypt(RSK, message.p ~ rsk, IV)
local mac = hash:process(rsk ~ SS)
assert(recv_alice == hash:process(rsk ~ SS) .. alice)
print(recv_alice:elide_at_start(mac):string())

-- AES(RSK XOR (Hash(<Public key> XOR RSK)||<bob>), SS) : Payload / ACK
response = {
   ACK = AES.ctr_encrypt(SS, (hash:process(nonce ~ rsk) .. bob) ~ rsk, IV)
}
I.print({response = response})

-- sender side
local recv_bob = AES.ctr_decrypt(SS, response.ACK, IV) ~ RSK
local mac_response = hash:process(nonce ~ RSK)
print(recv_bob:elide_at_start(mac_response):string())



-- AES(Hash(RSK XOR SS)||<Payload1>, RSK) XOR RSK : Payload / MAC
-- AES(RSK, (Hash(RSK XOR SS) .. Payload) XOR RSK)
