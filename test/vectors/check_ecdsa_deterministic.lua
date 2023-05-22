-- https://bitcointalk.org/index.php?topic=285142.msg3150733#msg3150733
-- https://bitcointalk.org/index.php?topic=285142.msg3300992#msg3300992
-- Test Vectors for RFC 6979 ECDSA, secp256k1, SHA-256
-- {private key, message, expected k, expected signature}
local test_vectors = {
    {'0x01', "Satoshi Nakamoto", '0x8F8A276C19F4149656B280621E358CCE24F5F52542772691EE69063B74F15D15', "934b1ea10a4b3c1757e2b0c017d0b6143ce3c9a7e6a4a49860d7a6ab210ee3d8dbbd3162d46e9f9bef7feb87c16dc13b4f6568a87f4e83f728e2443ba586675c"},
    {'0x01', "All those moments will be lost in time, like tears in rain. Time to die...", '0x38AA22D72376B4DBC472E06C3BA403EE0A394DA63FC58D88686C611ABA98D6B3', "8600dbd41e348fe5c9465ab92d23e3db8b98b873beecd930736488696438cb6bab8019bbd8b6924cc4099fe625340ffb1eaac34bf4477daa39d0835429094520"},
    {'0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140', "Satoshi Nakamoto", '0x33A19B60E25FB6F4435AF53A3D42D493644827367E6453928554F43E49AA6F90', "fd567d121db66e382991534ada77a6bd3106f0a1098c231e47993447cd6af2d094c632f14e4379fc1ea610a3df5a375152549736425ee17cebe10abbc2a2826c"},
    {'0xf8b8af8ce3c7cca5e300d33939540c10d45ce001b8f252bfbc57ba0342904181', "Alan Turing", '0x525A82B70E67874398067543FD84C83D30C175FDC45FDEEE082FE13B1D7CFDF1', "7063ae83e7f62bbb171798131b4a0564b956930092b33b07b395615d9ec7e15ca72033e1ff5ca1ea8d0c99001cb45f0272d3be7525d3049c0d9e98dc7582b857"}
}

-- "Haskoin test vectors for RFC 6979 ECDSA (secp256k1, SHA-256)"
-- "(PrvKey HEX, message, R || S as HEX)"
local test_vec_2 = {{ "0000000000000000000000000000000000000000000000000000000000000001",
    "Everything should be made as simple as possible, but not simpler.", "33a69cd2065432a30f3d1ce4eb0d59b8ab58c74f27c41a7fdb5696ad4e6108c96f807982866f785d3f6418d24163ddae117b7db4d5fdf0071de069fa54342262"
    },
    { "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140",
    "Equations are more important to me, because politics is for the present, but an equation is something for eternity.", "54c4a33c6423d689378f160a7ff8b61330444abb58fb470f96ea16d99d4a2fed07082304410efa6b2943111b6a4e0aaa7b7db55a07e9861d1fb3cb1f421044a5"
    },
    { "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140",
    "Not only is the Universe stranger than we think, it is stranger than we can think.", "ff466a9f1b7b273e2f4c3ffe032eb2e814121ed18ef84665d0f515360dab3dd06fc95f5132e5ecfdc8e5e6e616cc77151455d46ed48f5589b7db7771a332b283"
    },
    { "0000000000000000000000000000000000000000000000000000000000000001",
    "How wonderful that we have met with a paradox. Now we have some hope of making progress.", "c0dafec8251f1d5010289d210232220b03202cba34ec11fec58b3e93a85b91d375afdc06b7d6322a590955bf264e7aaa155847f614d80078a90292fe205064d3"
    },
    { "69ec59eaa1f4f2e36b639716b7c30ca86d9a5375c7b38d8918bd9c0ebc80ba64",
    "Computer science is no more about computers than astronomy is about telescopes.", "7186363571d65e084e7f02b0b77c3ec44fb1b257dee26274c38c928986fea45d0de0b38e06807e46bda1f1e293f4f6323e854c86d58abdd00c46c16441085df6"
    },
    { "00000000000000000000000000007246174ab1e92e9149c6e446fe194d072637",
    "...if you aren't, at any given time, scandalized by code you wrote five or even three years ago, you're not learning anywhere near enough", "fbfe5076a15860ba8ed00e75e9bd22e05d230f02a936b653eb55b61c99dda4870e68880ebb0050fe4312b1b1eb0899e1b82da89baa5b895f612619edf34cbd37"
    },
    { "000000000000000000000000000000000000000000056916d0f9b31dc9b637f3",
    "The question of whether computers can think is like the question of whether submarines can swim.", "cde1302d83f8dd835d89aef803c74a119f561fbaef3eb9129e45f30de86abbf906ce643f5049ee1f27890467b77a6a8e11ec4661cc38cd8badf90115fbd03cef"
    }
}

print("---------------------")
print("Deterministic ECDSA test 1")
for i,v in pairs(test_vectors) do
    print("Test case " .. i)
    local sk = O.from_hex(v[1])
    local msg = O.from_string(v[2])
    local sig, k = ECDH.sign_deterministic(sk, msg, 32)

    assert(k == O.from_hex(v[3]), "Wrong k")
    assert((sig.r):hex() == string.sub(v[4],1,64), "Wrong r")
    assert((sig.s):hex() == string.sub(v[4],65,128), "Wrong s")
end

print("---------------------")
print("Deterministic ECDSA test 2")
for i,v in pairs(test_vec_2) do
    print("Test case " .. i)
    local sk = O.from_hex(v[1])
    local msg = O.from_string(v[2])
    local sig = ECDH.sign_ecdh_deterministic(sk, msg, 32)

    local pk = ECDH.pubgen(sk)
    assert(ECDH.verify_deterministic(pk, msg, sig, 32), "FAILED SIGN")

    local o = ECDH.order()
    local sig_s = INT.new(sig.s)
    if sig_s > INT.shr(o, 1) then
       sig_s = INT.modsub(o, sig_s, o)
       sig.s = sig_s:octet():pad(32)
    end
    assert((sig.r):hex() == string.sub(v[3],1,64), "Wrong r")
    assert((sig.s):hex() == string.sub(v[3],65,128), "Wrong s")
end

print("---------------------")
print("Deterministic ECDSA HASHED test 2")
for i,v in pairs(test_vec_2) do
    print("Test case " .. i)
    local sk = O.from_hex(v[1])
    local msg = O.from_string(v[2])
    local hmsg = sha256(msg)
    local sig = ECDH.sign_ecdh_deterministic(sk, hmsg, 32)

    local pk = ECDH.pubgen(sk)
    assert(ECDH.verify_hashed(pk, hmsg, sig, 32), "FAILED SIGN")

    assert((sig.r):hex() == string.sub(v[3],1,64), "Wrong r")
    assert((sig.s):hex() == string.sub(v[3],65,128), "Wrong s")
end


print("---------------------")
print("Sign and verify ecdsa det")
local msgs = {"Satoshi Nakamoto","All those moments will be lost in time, like tears in rain. Time to die...", "Alan Turing"}
for n,v in pairs(msgs) do
    print("Test case " .. n)
    local alice = ECDH.keygen()
    local sig = ECDH.sign_deterministic(alice.private, O.from_string(v), 64)
    assert(ECDH.verify(alice.public, O.from_string(v), sig), "Invalid signature")

    assert(ECDH.verify_deterministic(alice.public, O.from_string(v), sig, 64), "Invalid signature")
    print("Test failure case " .. n)
    assert(not ECDH.verify_deterministic(alice.public, sha256(O.from_string(v)), sig, 64), "Valid signature with wrong msg")
    print("Test 2 failure case " .. n)
    assert(not ECDH.verify_deterministic(O.random(64), O.from_string(v), sig, 64), "Valid signature with wrong pubkey")
    print("Test 3 failure case " .. n)
    assert(not ECDH.verify_deterministic(alice.public, O.from_string(v), {["r"] = O.random(64), ["s"] = O.random(64)}, 64), "Valid signature with wrong sig")
end
