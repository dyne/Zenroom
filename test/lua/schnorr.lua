--[[
--This file is part of zenroom
--
--Copyright (C) 2020-2021 Dyne.org foundation
--written by Alberto Ibrisevich
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

local O = ECP.order()
--generator of the curve
G = ECP.generator()


-- schema checks:
-- if (P:y() % BIG.new(2)) ~= BIG.new(0) then d = o - d end
-- assert(sk ~= BIG.new(0), 'invalid secret key, is zero')
-- assert(sk <= o, 'invalid secret key, overflow with curve order')

function keygen()
--    local sk
    repeat
--        sk = OCTET.random(32)
        d = BIG.new(OCTET.random(32))
        if  O <= d then d = false end --guaranties that the generated keypair is valid

    until (d)
    -- check public y is even 
    --    if (P:y() % BIG.new(2)) ~= BIG.new(0) then d = o - d end
    return d
end

function pubkey(sk)
    assert(sk, "no secret key found")
    -- assert(#sk == 32, 'invalid secret key: length is not of 32B')
    -- local d = BIG.new(sk)
    assert(sk ~= BIG.new(0), 'invalid secret key, is zero')
    assert(sk <= O, 'invalid secret key, overflow with curve order')
    return(sk*G)
end

function hash_tag(tag, data)
    -- TODO: can this be changed, used ZEN.serialize?
    -- original implementation follows BIP0340
--    return sha256(sha256(OCTET.str(tag))..sha256(OCTET.str(tag))..data)
--    return(sha256( ZEN.serialize( {tag, data})))
    return(sha256(OCTET.from_str(tag)..data))
end


function Sign(sk, m)
    P = pubkey(sk)
    -- TODO: is this needed? : schema check for input key to be < order
--    if (P:y() % BIG.new(2)) ~= BIG.new(0) then d = o - d end
    local k
    repeat
        local a = OCTET.random(32)
        local h = hash_tag("BIP0340/aux", a)
        local t = OCTET.xor(d:octet(), h)
        local rand = hash_tag("BIP0340/nonce", t..((P:x()):octet())..m)
        k = BIG.new(rand) % O  --maybe it is not needed since o is bigger
    until k ~= BIG.new(0)
    local R = k*G
    if (R:y() % BIG.new(2)) ~= BIG.new(0) then k = O - k end
    -- TODO: BIP string in challenge?
    -- local e = BIG.new(hash_tag("BIP0340/challenge", ((R:x()):octet())..((P:x()):octet())..m)) % o
    local e = BIG.new( ZKP_challenge({R:x(), P:x(), m}) ) % O
    local r = (R:x()):octet():pad(48) --padding is fundamental, otherwise we could lose non-significant zeros
    local s = BIG.mod(k + e*d, O):octet():pad(32)
    -- local sig = r..s
    return ({r = BIG.new(r),
             s = BIG.new(s)})
    -- print("P = ", P)
    -- print("x_P = ", P:x())
    -- print("y_P = ", P:y())
    --print("s = ", s)
    -- I.print({R = R,
    --         Rx = R:x(),
    --         Ry = R:y()})
    -- assert(Verify(P,m,sig), "Invalid signature")
    -- return sig
end

function Verify(P, m, sig)
    -- local P = pk --ECP.new(BIG.new(pk))
    assert(P, "lifting failed")
    -- I.print({P = P,
    --         Px = P:x(),
    --         Py = P:y() })
--    local r_arr, s_arr = OCTET.chop(sig,48)
--    local r = BIG.new(r_arr)
--     I.print({r = r})
    assert(sig.r <= ECP.prime(), "Verification failed, r overflows p")
--    local s = BIG.new(s_arr)
    --print("s = ", s)
    assert(sig.s <= O, "Verification failed, s overflows o")
    local e = BIG.new( ZKP_challenge({sig.r, P:x(), m}) ) % O

--    local e = BIG.new(hash_tag("BIP0340/challenge", sig.r:octet()..(P:x()):octet()..m)) % O
    local R = (sig.s*G) - (e*P) 
    -- I.print({R = R})
    assert(not ECP.isinf(R), "Verification failed, point to infinity")
    assert((R:y() % BIG.new(2) == BIG.new(0)) , "Verification failed, y is odd")
    assert((R:x() == sig.r), "Verification failed")
    return true
end


print("--------Initialization phase--------")  
m = OCTET.random(32)
--print(m)
secret = keygen()
public = pubkey(secret)

print("sk: "..secret:octet():base64())
print("pk: "..public:octet():base64())
--ok

print("--------Signing phase--------")
firma = Sign(secret, m)
I.print({signature = firma})
--print(firma)
print('\n')
--ok

print("--------Verification phase--------")
if Verify(public, m, firma) then 
    print("  OK Verification passed")
    print''
end






