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
T.RSK_length = 256
T.HASH = HASH.new('sha256') -- do not change
T.PROB = 4 -- probhash bytes for MAC

-- TODO: check IV length
-- find minimum length of k

-- probabilistic hash function returning only N bytes
function T:probhash(fobj)
    return self.HASH:process(obj):chop(self.PROB)
end

function T:encrypt(key, message, nonce)
    return AES.ctr_encrypt(
        self.HASH:process(key),
        message,
        self.HASH:process(nonce)
    )
end
function T:decrypt(key, cipher, nonce)
    return AES.ctr_encrypt(
        self.HASH:process(key),
        cipher,
        self.HASH:process(nonce)
    )
end

function T:encode_message(SS, nonce, cleartext, RSK)
    -- RSK arg is only used to verify vectors
    if RSK then
        if not ( #RSK == self.RSK_length ) then
            error("RSK length must be "..self.RSK_length, 2) end
    end
    local rsk = RSK or OCTET.random(self.RSK_length) -- + hash size
    local m = {
        n = nonce,
        k = self:encrypt(SS, rsk, nonce)
            :xor_grow(
                self:encrypt(SS, nonce, nonce )),
        p = self:encrypt(
            rsk,
            (self:probhash(T,rsk:xor_grow(SS)) .. cleartext)
            :xor_grow(rsk), nonce)
    }
    return m
end

function T:decode_message(SS, ciphertext, nonce)
    local iv = nonce or ciphertext.n
    if not iv then
        error("Undefined nonce in FSP:decode_message",2)
    end
    local rsk = self:decrypt(
        SS,
        ciphertext.k:xor_grow( self:encrypt(SS, iv, iv) ),
        iv)
    local m = self:decrypt(rsk,
                           ciphertext.p:xor_grow(rsk), iv):trim()
    if not (self:probhash(rsk:xor_grow(SS)) == m:sub(1,T.PROB)) then
        error("Invalid authentication of fsp ciphertext", 2)
    end
    return m:sub(T.PROB+1,#m), rsk
end

function T:encode_response(SS, nonce, rsk, cleartext)
    return self:encrypt(
        SS,
        (self:probhash(T,nonce:xor_grow(rsk)) .. cleartext):xor_grow(rsk),
        nonce)
end

function T:decode_response(SS, nonce, rsk, ciphertext)
    local m = self:decrypt(
        SS,
        ciphertext:xor_grow(rsk),
        nonce):trim()
    assert(self:probhash(T,nonce:xor_grow(rsk)) == m:sub(1,T.PROB),
        "Invalid authentication of fsp response")
    return m:sub(T.PROB+1,#m), mac
end

return T
