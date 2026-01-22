--[[
--This file is part of zenroom
--
--Copyright (C) 2021-2026 Dyne.org foundation
--designed, written and maintained by Giulio Sacchet
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
--
--
--References:
--https://datatracker.ietf.org/doc/html/draft-google-cfrg-libzk-00#name-sumcheck
--https://github.com/google/longfellow-zk/blob/main/lib/random
--
--]]

local FS = {}

local function Aes(key, plaintext)
    local zero = O.from_hex('00000000000000000000000000000000')
    return AES.ctr_encrypt(key, zero, plaintext)
end

local function ceil_div16(n)
    assert(type(n) == "number", "n is not a number")
    if math.fmod(n,16) == "0" then
        return n/16 
    else
        return math.ceil(n/16)
    end 
end

local function floor_div16(n)
    assert(type(n) == "number", "n is not a number")
    if math.fmod(n,16) == "0" then
        return n/16 
    else
        return math.floor(n/16)
    end 
end

function FS.fiat_shamir(transcript,n_bytes,start_index)
    local key = sha256(transcript)
    local stream = O.new()
    local n_blocks = ceil_div16(n_bytes)+1
    for i = floor_div16(start_index), floor_div16(start_index)+n_blocks-1 do 
        stream = stream:__concat(Aes(key, O.from_number(i):reverse()))
    end 
    if n_bytes == 0 then
        return O.from_number(0), start_index+1
    else 
        return stream:sub(math.fmod(start_index,16)+1, math.fmod(start_index,16)+n_bytes), start_index+n_bytes
    end 
end
    
local function ceil_div8(n)
    assert(type(n) == "zenroom.big", "n is not a BIG")
    if n:__mod(big.new(8)):__eq(big.new(0)) then
        return n:__div(big.new(8)) 
    else
        return n:__div(big.new(8)):__add(big.new(1))
    end 
end

function FS.generate_nat(m, transcript, start_index)
--generates a random natural between 0 and m-1 inclusive
    assert(type(m) == "zenroom.big", "m is not a BIG")
    assert(type(transcript) == "zenroom.octet", "transcript is not an octet")
    if m:__eq(big.new(1)) then 
        return big.new(0), start_index+1
    end 
    local l = big.new(0) 
    while big.new(2):modpower(l,ECP.order()):__lt(m) do
        l = big.zenadd(l,big.new(1))
    end
    local n_bytes = ceil_div8(l):int()
    local mod = big.new(2):modpower(l,ECP.order())
    local r = m
    if n_bytes == 0 then 
        return big.new(0), start_index+1
    else
        while m:__lte(r) do 
            b, start_index = FS.fiat_shamir(transcript, n_bytes, start_index)
            local k = big.new(b:reverse())
            r = k:__mod(mod)
        end  
        return r, start_index
    end
end 

function FS.generate_field_element_p(transcript,p,start_index)
    assert(type(p) == "zenroom.big", "p is not a BIG")
    local nat, si =  FS.generate_nat(p,transcript,start_index)
    oct = O.new(nat)
    return oct:reverse(), si
end 

function FS.generate_field_element_gf(transcript,deg,start_index)
    assert(type(deg) == "number", "deg is not a number")
    local n_bytes = deg/8
    local nat, si = FS.fiat_shamir(transcript,n_bytes,start_index)
    return nat, si
end

function FS.generate_challenge_p(transcript,p,len,start_index)
    assert(type(p) == "zenroom.big", "p is not a BIG")
    assert(type(len) == "number", "len is not a number")
    local array = {}
    for i = 1, len do 
        elt, start_index =  FS.generate_field_element_p(transcript,p,start_index)
        table.insert(array,elt)
    end
    return array, start_index
end 

function FS.generate_challenge_gf(transcript,deg,len,start_index)
    assert(type(deg) == "number", "deg is not a number")
    assert(type(len) == "number", "len is not a number")
    local array = {}
    for i = 1, len do 
        elt, start_index =  FS.generate_field_element_gf(transcript,deg,start_index)
        table.insert(array,elt)
    end
    return array, start_index
end 

return FS



