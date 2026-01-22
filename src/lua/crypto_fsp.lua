--[[
    --This file is part of zenroom
    --
    --Copyright (C) 2024-2026 Dyne.org foundation
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

-- Default SS size 256 bit or 32 bytes
-- Default Probabilistic hash size 32 bits / 4 bytes
-- Default RSK size 256 bytes
T.RSK_length = 256
T.PROB = 4 -- probhash bytes for MAC

T.HASH = HASH.new('sha256') -- do not change

-- TODO: check IV length
-- find minimum length of k

-- probabilistic hash function returning only N bytes
function T:probhash(fobj)
    return self.HASH:process(obj):chop(self.PROB)
end

function T:encrypt(key, message, nonce)
   if not nonce then error("FSP encrypt missing nonce",2) end
    return AES.ctr_encrypt(
        self.HASH:process(key),
        message,
        self.HASH:process(nonce)
    )
end
function T:decrypt(key, cipher, nonce)
   if not nonce then error("FSP decrypt missing nonce",2) end
    return AES.ctr_encrypt(
        self.HASH:process(key),
        cipher,
        self.HASH:process(nonce)
    )
end

-- generate a nonce with default format
function T:makenonce()
   return OCTET.from_string(os.date("%Y%m%d%H%M%S", os.time()))
end

-- prepare a clear text message to be encrypted
function T:encodetxt(text)
   local max = self.RSK_length - self.PROB -1 -- EOM is [1] 00
   local len = #text
   -- message too long for encoding
   if (len > max) then return nil
   elseif (len == max) then return text
   end
   -- len<max: message needs filling with random
   return ( text .. OCTET.zero(1) .. OCTET.random(max-len) )
end

function T:decodetxt(text)
   -- read out the null terminated string
   return OCTET.from_string(text:string())
end

function T:encode_message(SS, nonce, cleartext, RSK)
    -- RSK arg is only used to verify vectors
   if not SS then error("FSP secret key missing",2) end
	if not ( #SS == 32 ) then
			error("FSP secret key length must be 32 bytes", 2) end
    if RSK then
        if not ( #RSK == self.RSK_length ) then
            error("FSP session key length must be "..self.RSK_length.." bytes", 2) end
    end
    local rsk = RSK or OCTET.random(self.RSK_length)
    local m = {
        n = nonce,
        k = self:encrypt(SS, rsk, nonce)
		   ~
		   self:encrypt(SS, nonce:fillrepeat(self.RSK_length), nonce),
        p = self:encrypt(
            rsk,
            rsk ~ (self:probhash(SS ~ rsk) .. self:encodetxt(cleartext)),
			nonce)
    }
    return m
end

function T:decode_message(SS, ciphertext, nonce)
    local iv = nonce or ciphertext.n
    if not iv then
        error("Undefined nonce in FSP:decode_message",2)
    end
	-- decode rsk from k
    local rsk = self:decrypt(
        SS,
        ciphertext.k
		~ self:encrypt(SS, iv:fillrepeat(self.RSK_length), iv),
        iv)
    local m = self:decrypt(rsk,
                           ciphertext.p:xor_grow(rsk), iv)
    if not (self:probhash(SS ~ rsk) == m:sub(1,self.PROB)) then
        error("Invalid authentication of fsp ciphertext", 2)
    end
    return self:decodetxt(m:sub(self.PROB+1,#m)), rsk
end

function T:encode_response(SS, nonce, rsk, cleartext)
    return self:encrypt(
        SS,
        rsk ~ (self:probhash(rsk ~ nonce) .. self:encodetxt(cleartext)),
        nonce)
end

function T:decode_response(SS, nonce, rsk, ciphertext)
    local m = self:decodetxt(
	   self:decrypt(SS, rsk ~ ciphertext, nonce) )
    assert(self:probhash(rsk ~ nonce) == m:sub(1,self.PROB),
        "Invalid authentication of fsp response")
    return m:sub(self.PROB+1,#m), mac
end

return T
