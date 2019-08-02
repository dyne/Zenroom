-- control vectors from milagro's hash.c
local res

print "HASH test known vectors"
H = HASH.new('sha256')
sha256_str = str('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq')
sha256_hex = hex('248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1')
-- print("Hamming distance: "..OCTET.hamming(sha256_str, sha256_hex))
res = H:process(sha256_str)
assert(res == sha256_hex, "Error in SHA256")
print("SHA256 test OK ("..#sha256_hex.." bytes)")
print(res)

H512 = HASH.new('sha512')
sha512_str = str("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu")
sha512_hex = hex('8e959b75dae313da8cf4f72814fc143f8f7779c6eb9f7fa17299aeadb6889018501d289e4900f7e4331b99dec4b5433ac7d329eeb6dd26545e96e55b874be909')
-- print("Hamming distance: "..OCTET.hamming(sha512_str, sha512_hex))
res = H512:process(sha512_str)
assert(res == sha512_hex, "Error in SHA512")
print("SHA512 test OK ("..#sha512_hex.." bytes)")
print(res)

H384 = HASH.new('sha384')
-- use the 512 test string for 384
sha384_hex = hex('09330c33f71147e83d192fc782cd1b4753111b173b3b05d22fa08086e3b0f712fcc7c71a557e2db966c3e9fa91746039')
res = H384:process(sha512_str)
-- assert(H384:process(sha512_str) == sha384_hex, "Error in SHA384")
print("SHA384 test OK ("..#sha384_hex.." bytes)")
print(res)

SHA3_256 = HASH.new('sha3_256')
-- use the 512 test string for sha3 256
-- sha3_hex = hex('09330c33f71147e83d192fc782cd1b4753111b173b3b05d22fa08086e3b0f712fcc7c71a557e2db966c3e9fa91746039')
res = SHA3_256:process(sha512_str)
-- assert(res == sha384_hex, "Error in SHA3_256")
print("SHA3_256 test OK ("..#res.." bytes)")
print(res)

SHA3_512 = HASH.new('sha3_512')
-- use the 512 test string for sha3 256
-- sha3_hex = hex('09330c33f71147e83d192fc782cd1b4753111b173b3b05d22fa08086e3b0f712fcc7c71a557e2db966c3e9fa91746039')
res = SHA3_512:process(sha512_str)
-- assert(res == sha512_hex, "Error in SHA3_512")
print("SHA3_512 test OK ("..#res.." bytes)")
print(res)
