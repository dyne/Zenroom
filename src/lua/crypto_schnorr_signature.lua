--[[
--This file is part of zenroom
--
--Copyright (C) 2020-2021 Dyne.org foundation
--Implementation by Alberto Ibrisevic and Denis Roio

--designed, written and maintained by Denis Roio <jaromil@dyne.org>
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
--Last modified by Denis Roio
--on Tuesday, 20th July 2021
--]]


--prime modulus of the coordinates of ECP and order of the curve
p = ECP.prime()
o = ECP.order()
--generator of the curve
G = ECP.generator()

--method for obtaining a valid EC keypair where the secret key is chosen at random
function key_gen()
    keypair = { }
    local sk
    repeat
    sk = OCTET.random(32)
        d = BIG.new(sk)
        if  o <= d then d = BIG.new(0) end --guaranties that the generated keypair is valid
    until (d ~= BIG.new(0)) 
    local P = d*G
    pk = (P:x()):octet():pad(48)
    keypair.sk = sk
    keypair.pk = pk
    return keypair
end

--given a valid secret key, extracts the related public key as the x-coordinate of the alleged ECP
--N.B: key_gen() already provides this functionality, the difference is that pkey_gen stops if sk is invalid
function pkey_gen(sk)
    assert(sk, "no secret key found")
    assert(#sk == 32, 'invalid secret key: length is not of 32B')
    d = BIG.new(sk)
    assert(d ~= BIG.new(0), 'invalid secret key, is zero')
    assert(d <= o, 'invalid secret key, overflow with curve order')
    P = d*G
    return P
end

--method for obtaining an hash digest using a (UTF-8) encoded tag name together with the data to process
--N.B1: By doing this, we make sure hashes used in one context can't be reinterpreted in another one, 
--      in such a way that collisions across contexts can be assumed to be infeasible.
--N.B2: tag names can be customized at will
hash_tag = function(tag, data)
    return sha256(sha256(OCTET.str(tag))..sha256(OCTET.str(tag))..data)
end

--signing algorithm
--input:    a 32 Byte OCTET secret key 'sk'
--          a 32 Byte OCTET message 'm'
--output:   an 80 Byte OCTET signature '(r,s)'', where r is long 48 Byte, and s is long 32 Byte
function Sign(sk, m)
    P = pkey_gen(sk)
    --for convention we need that P has even y-coordinate
    if (P:y() % BIG.new(2)) ~= BIG.new(0) then d = o - d end 
    --N.B: we don't change the point with the new one, but only store the coefficient d needed to obtain it
    local k
    repeat 
        local a = OCTET.random(32)
        local h = hash_tag("BIP0340/aux", a)
        local t = OCTET.xor(d:octet(), h)
        local rand = hash_tag("BIP0340/nonce", t..((P:x()):octet())..m)
        k = BIG.new(rand) % o  --maybe it is not needed since o is bigger
    until k ~= BIG.new(0)
    local R = k*G
    if (R:y() % BIG.new(2)) ~= BIG.new(0) then k = o - k end
    --also here we store only the coefficient k, /wo changing the point R
    local e = BIG.new(hash_tag("BIP0340/challenge", ((R:x()):octet())..((P:x()):octet())..m)) % o
    local r = (R:x()):octet():pad(48) --padding is fundamental, otherwise we could lose non-significant zeros
    local s = BIG.mod(k + e*d, o):octet():pad(32)
    local sig = r..s
    assert(Verify(P:x(),m,sig), "Invalid signature")          --comment this line if it is unnecessary
    return sig
end

--verification algortihm
--input:    a 48 Byte OCTET public key 'pk'
--          a 32 Byte OCTET message 'm'
--          an 80 Byte OCTET signature 'sig'=(r,s)
--output:   true if verification passes, false otherwise
function Verify(pk, m, sig)
    --the follwing "lifts" pk to an ECP with x = pk and y is even
    local P = ECP.new(BIG.new(pk))    
    assert(P, "lifting failed")
    local r_arr, s_arr = OCTET.chop(sig,48)
    local r = BIG.new(r_arr)
    assert(r <= p, "Verification failed, r overflows p")
    local s = BIG.new(s_arr)
    assert(s <= o, "Verification failed, s overflows o")    
    local e = BIG.new(hash_tag("BIP0340/challenge", r:octet()..(P:x()):octet()..m)) % o 
    local R = (s*G) - (e*P)     --if the signature is valid the result will be k*G as expected
    assert(not ECP.isinf(R), "Verification failed, point to infinity")
    assert((R:y() % BIG.new(2) == BIG.new(0)) , "Verification failed, y is odd")
    assert((R:x() == r), "Verification failed")
    return true
end

--TODO: batch verification