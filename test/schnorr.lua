
p = BIG.new(OCTET.from_hex('5565569564AB6EB5A06DADC41FEA9284A0AD462CF365A511AC31B801696124F47A8C3F298A64852BDA371D6485AAB0AB'))
o = ECP.order()
--generator of the curve
G = ECP.generator()

function key_gen()
    keypair = { }
    repeat
    sk = OCTET.random(32)
        d = BIG.new(sk)
        if  o <= d then d = BIG.new(0) end --guaranties that the generated keypair is valid
    until (d ~= BIG.new(0)) 
    local P = d*G
    pk = (P:x()):octet()
    keypair.sk = sk
    keypair.pk = pk
    return keypair
end

function pkey_gen(sk)
    assert(sk, "no secret key found")
    assert(#sk == 32, 'invalid secret key: length is not of 32B')
    local d = BIG.new(sk)
    assert(d ~= BIG.new(0), 'invalid secret key, is zero')
    assert(d <= o, 'invalid secret key, overflow with curve order')
    P = d*G
    return P
end

hash_tag = function(tag, data)
    return sha256(sha256(OCTET.str(tag))..sha256(OCTET.str(tag))..data)
end


function Sign(sk, m)
    P = pkey_gen(sk)
    if (P:y() % BIG.new(2)) ~= BIG.new(0) then d = o - d end
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
    local e = BIG.new(hash_tag("BIP0340/challenge", ((R:x()):octet())..((P:x()):octet())..m)) % o
    local r = (R:x()):octet():pad(48) --padding is fundamental, otherwise we could lose non-significant zeros
    local s = BIG.mod(k + e*d, o):octet():pad(32)
    local sig = r..s
    print("P = ", P)
    print("x_P = ", P:x())
    print("y_P = ", P:y())
    --print("s = ", s)
    print("R = ", R)
    print("x_R = ", R:x())
    print("y_R = ", R:y())
    return sig
end

function Verify(pk, m, sig)
    local P = ECP.new(BIG.new(pk))    
    assert(P, "lifting failed")
    print("P = ", P)
    print("x_P = ", P:x())
    print("y_P = ", P:y())
    local r_arr, s_arr = OCTET.chop(sig,48)
    local r = BIG.new(r_arr)
    print("r = ", r)
    assert(r <= p, "Verification failed, r overflows p")
    local s = BIG.new(s_arr)
    --print("s = ", s)
    assert(s <= o, "Verification failed, s overflows o")    
    local e = BIG.new(hash_tag("BIP0340/challenge", r:octet()..(P:x()):octet()..m)) % o 
    local R = (s*G) - (e*P) 
    print("R = ", R)
    assert(not ECP.isinf(R), "Verification failed, point to infinity")
    local sign, x = OCTET.chop(R:octet(),1)
    R = ECP.new(BIG.new(x))
    print("x_R = ", R:x())
    assert((BIG.new(sign) % BIG.new(2) == BIG.new(0)) , "Verification failed, y is odd")
    assert((R:x() == r), "Verification failed")
    return true
end


print("--------Initialization phase--------")  
m = OCTET.random(32)
--print(m)
keypair = key_gen()
I.print(keypair)
secret = keypair.sk
public = keypair.pk
print(public)
print('\n')
--ok

print("--------Signing phase--------")
firma = Sign(secret, m)
--I.print(firma)
--print(firma)
print('\n')
--ok

print("--------Verification phase--------")
if Verify(public, m, firma) then 
    print('\n')
    print("Verification passed") 
end






