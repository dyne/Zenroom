-- https://bitcointalk.org/index.php?topic=285142.msg3150733#msg3150733
-- Test Vectors for RFC 6979 ECDSA, secp256k1, SHA-256
-- {private key, message, expected k, expected signature}
local test_vectors = {
    {'0x01', "Satoshi Nakamoto", '0x8F8A276C19F4149656B280621E358CCE24F5F52542772691EE69063B74F15D15', "934b1ea10a4b3c1757e2b0c017d0b6143ce3c9a7e6a4a49860d7a6ab210ee3d8dbbd3162d46e9f9bef7feb87c16dc13b4f6568a87f4e83f728e2443ba586675c"},
    {'0x01', "All those moments will be lost in time, like tears in rain. Time to die...", '0x38AA22D72376B4DBC472E06C3BA403EE0A394DA63FC58D88686C611ABA98D6B3', "8600dbd41e348fe5c9465ab92d23e3db8b98b873beecd930736488696438cb6bab8019bbd8b6924cc4099fe625340ffb1eaac34bf4477daa39d0835429094520"},
    {'0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140', "Satoshi Nakamoto", '0x33A19B60E25FB6F4435AF53A3D42D493644827367E6453928554F43E49AA6F90', "fd567d121db66e382991534ada77a6bd3106f0a1098c231e47993447cd6af2d094c632f14e4379fc1ea610a3df5a375152549736425ee17cebe10abbc2a2826c"},
    {'0xf8b8af8ce3c7cca5e300d33939540c10d45ce001b8f252bfbc57ba0342904181', "Alan Turing", '0x525A82B70E67874398067543FD84C83D30C175FDC45FDEEE082FE13B1D7CFDF1', "7063ae83e7f62bbb171798131b4a0564b956930092b33b07b395615d9ec7e15ca72033e1ff5ca1ea8d0c99001cb45f0272d3be7525d3049c0d9e98dc7582b857"}
}

print("Deterministic ECDSA test")
for k,v in pairs(test_vectors) do
    print("Test case " .. k)
    local sk = O.from_hex(v[1])
    local msg = O.from_string(v[2])
    local sig = ECDH.sign_deterministic(sk, msg, 32)
    
    assert(sig.k == O.from_hex(v[3]), "Wrong k")
    assert((sig.r):hex() == string.sub(v[4],1,64), "Wrong r")
    assert((sig.s):hex() == string.sub(v[4],65,128), "Wrong s")
end


print("Sign and verify ecdsa det")
local msgs = {"Satoshi Nakamoto","All those moments will be lost in time, like tears in rain. Time to die...", "Alan Turing"}
for n,v in pairs(msgs) do
    print("Test case " .. n)
    local alice = ECDH.keygen()
    local sig = ECDH.sign_deterministic(alice.private, O.from_string(v), 32)
    assert(ECDH.verify_deterministic(alice.public, O.from_string(v), sig, 32), "Invalid signature")
    print("Test failure case " .. n)
    assert(not ECDH.verify_deterministic(alice.public, sha256(O.from_string(v)), sig, 32), "Valid signature with wrong msg")
    print("Test 2 failure case " .. n)
    assert(not ECDH.verify_deterministic(O.random(32), O.from_string(v), sig, 32), "Valid signature with wrong pubkey")
    print("Test 3 failure case " .. n)
    assert(not ECDH.verify_deterministic(alice.public, O.from_string(v), {["r"] = O.random(32), ["s"] = O.random(32)}, 32), "Valid signature with wrong sig")
end

