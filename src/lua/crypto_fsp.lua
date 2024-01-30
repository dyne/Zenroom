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
T.PROB = 4 -- probhash bytes for MAC

-- TODO: check IV length
-- find minimum length of k

-- probabilistic hash function returning only N bytes
local function probhash(fsp, obj)
    return fsp.HASH:process(obj):octet():chop(fsp.PROB)
end

T.encode_message = function(SS, nonce, cleartext, RSK, IV)
    local len = #cleartext
    if len < 32 then
        cleartext = cleartext:pad(32)
        len = 32
    end
    -- RSK arg is only used to verify vectors
    if RSK then assert(#RSK >= len+32, "RSK length must be grater than message length + 32 bytes") end
    local rsk = RSK or OCTET.random(len + 32) -- + hash size
    local iv = IV or T.HASH:process(nonce)
    -- hash result must be 32 bytes to fit as AES.ctr key
    assert(#nonce < #rsk, "RSK length must be grater than nonce length")
    local m = {
        n = nonce,
        k = AES.ctr_encrypt(T.HASH:process(SS), rsk, iv)
            ~ AES.ctr_encrypt(T.HASH:process(SS), nonce, iv),
        p = AES.ctr_encrypt(
            T.HASH:process(rsk),
            (probhash(T,rsk ~ SS) .. cleartext) ~ rsk, iv)
    }
    return m
end

T.decode_message = function(SS, ciphertext, IV)
    local iv = IV or T.HASH:process(ciphertext.n)
    local rsk = AES.ctr_decrypt(
        T.HASH:process(SS), ciphertext.k
        ~ AES.ctr_encrypt(T.HASH:process(SS), ciphertext.n, iv),
        iv)
    local m = AES.ctr_decrypt(T.HASH:process(rsk),
                              ciphertext.p ~ rsk, iv):trim()
    if not probhash(T,rsk ~ SS) == m:sub(1,T.PROB) then
        error("Invalid authentication of fsp ciphertext", 2)
    end
    return m:sub(T.PROB+1,#m), rsk
end

T.encode_response = function(SS, nonce, rsk, cleartext, IV)
    local r_len = #rsk - 32
    -- response length must be smaller or equal to message len
    assert(#cleartext <= r_len, "Response length must be smaller or equal to message len")
    local iv = IV or T.HASH:process(nonce)
    return AES.ctr_encrypt(
        T.HASH:process(SS),
        (probhash(T,nonce ~ rsk) .. cleartext)
        ~ rsk, iv)
end

T.decode_response = function(SS, nonce, rsk, ciphertext, IV)
    local iv = IV or T.HASH:process(nonce)
    local m = AES.ctr_decrypt(
        T.HASH:process(SS), ciphertext ~ rsk, iv):trim()
    assert(probhash(T,nonce ~ rsk) == m:sub(1,T.PROB),
        "Invalid authentication of fsp response")
    return m:sub(T.PROB+1,#m), mac
end

return T