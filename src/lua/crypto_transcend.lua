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

local T = { }

-- The length of RSK marks the maximum message length
-- to make sure that its XOR covers the whole message
-- it is limited to 32 because of the AES.ctr limit.
T.RSK_length = 32
T.HASH = HASH.new('sha256') -- do not change

-- TODO: check IV length

T.encode_message = function(SS, nonce, cleartext, IV, RSK)
   local len = #cleartext
   -- RSK arg is only used to verify vectors
   local rsk = RSK or OCTET.random(len + 32) -- + hash size
   -- hash result must be 32 bytes to fit as AES.ctr key
   local m = {
	  n = nonce,
	  k = AES.ctr_encrypt(T.HASH:process(SS), rsk, IV)
		 ~ AES.ctr_encrypt(T.HASH:process(SS), nonce, IV),
	  p = AES.ctr_encrypt(
		 T.HASH:process(rsk),
		 T.HASH:process(rsk ~ SS) .. cleartext, IV)
		 ~ rsk
   }
   return m
end

T.decode_message = function(SS, ciphertext, IV)
   local rsk = AES.ctr_decrypt(
	  T.HASH:process(SS), ciphertext.k
	  ~ AES.ctr_encrypt(T.HASH:process(SS), ciphertext.n, IV),
	  IV)
   local m = AES.ctr_decrypt(T.HASH:process(rsk),
							 ciphertext.p ~ rsk, IV)
   local mac = T.HASH:process(rsk ~ SS)
   return m:sub(33,#m), rsk
end

T.encode_response = function(SS, nonce, rsk, cleartext, IV)
   local r_len = #rsk - 32
   -- response length must be smaller or equal to message len
   assert(#cleartext <= r_len)
   return AES.ctr_encrypt(
	  T.HASH:process(SS),
	  (T.HASH:process(nonce ~ rsk) .. cleartext:pad(r_len))
	  ~ rsk, IV)
end

T.decode_response = function(SS, nonce, rsk, ciphertext, IV)
   local m = AES.ctr_decrypt(
	  T.HASH:process(SS), ciphertext, IV) ~ rsk
   local mac = T.HASH:process(nonce ~ rsk)
   return m:sub(33,#m), mac
end

return T
