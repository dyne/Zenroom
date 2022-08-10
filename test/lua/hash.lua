-- Zenroom HASH tests
-- Control vectors from FIPS-180 appendix and NIST Example Algorithms
print "HASH test known vectors"
hash_algos = {'sha256', 'sha384', 'sha512', 'sha3_256', 'sha3_512' }

local res
local str448 = O.from_str('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq')
sha256_str448 = hex('248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1')
sha384_str448 = hex('3391fdddfc8dc7393707a65b1b4709397cf8b1d162af05abfe8f450de5f36bc6b0455a8520bc4e6f5fe95b1fe3c8452b')
sha512_str448 = hex('204a8fc6dda82f0a0ced7beb8e08a41657c16ef468b228a8279be331a703c33596fd15c13b1b07f9aa1d3bea57789ca031ad85c7a71dd70354ec631238ca3445')
sha3_256_str448 = hex('41c0dba2a9d6240849100376a8235e2c82e1b9998a999e21db32dd97496d3376')
sha3_512_str448 = hex('04a371e84ecfb5b8b77cb48610fca8182dd457ce6f326a0fd3d7ec2f1e91636dee691fbe0c985302ba1b0d8dc78c086346b533b49c030d99a27daf1139d6e75e')

local str896 = O.from_str('abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu')
sha256_str896 = hex('cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1')
sha384_str896 = hex('09330c33f71147e83d192fc782cd1b4753111b173b3b05d22fa08086e3b0f712fcc7c71a557e2db966c3e9fa91746039')
sha512_str896 = hex('8e959b75dae313da8cf4f72814fc143f8f7779c6eb9f7fa17299aeadb6889018501d289e4900f7e4331b99dec4b5433ac7d329eeb6dd26545e96e55b874be909')
sha3_256_str896 = hex('916f6061fe879741ca6469b43971dfdb28b1a32dc36cb3254e812be27aad1d18')
sha3_512_str896 = hex('afebb2ef542e6579c50cad06d2e578f9f8dd6881d7dc824d26360feebf18a4fa73e3261122948efcfd492e74e82e2189ed0fb440d187f382270cb455f21dd185')

local straMB = O.zero(1000000)
local straMB1 = O.zero(500000)
local straMB2 = O.zero(500000)
straMB:fill(O.from_str('a'))
straMB1:fill(O.from_str('a'))
straMB2:fill(O.from_str('a'))

sha256_straMB = hex('cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0')
sha512_straMB = hex('e718483d0ce769644e2e42c7bc15b4638e1f98b13b2044285632a803afa973ebde0ff244877ea60a4cb0432ce577c31beb009c5c2c49aa2e4eadb217ad8cc09b')
sha384_straMB = hex('9d0e1809716474cb086e834e310a4a1ced149e9c00f248527972cec5704c2a5b07b8b3dc38ecc4ebae97ddd87f3d8985')
sha3_256_straMB = hex('5c8875ae474a3634ba4fd55ec85bffd661f32aca75c6d699d0cdcb6c115891c1')
sha3_512_straMB = hex('3c3a876da14034ab60627c077bb98f7e120a2a5370212dffb3385a18d4f38859ed311d0a9d5141ce9cc5c66ee689b266a8aa18ace8282a0e0db596c90b0a7b87')

print " test on 448 bytes"
for i,h in ipairs(hash_algos) do
   local H = HASH.new(h)
   assert(H:process(str448) == _G[h..'_str448'], "Error in "..h)
   print(h.." OK")
end

print " test on 896 bytes"
for i,h in ipairs(hash_algos) do
   local H = HASH.new(h)
   assert(H:process(str896) == _G[h..'_str896'], "Error in "..h)
   print(h.." OK")
end

print " test on 1000000 bytes"
for i,h in ipairs(hash_algos) do
   local H = HASH.new(h)
   assert(H:process(straMB) == _G[h..'_straMB'], "Error in "..h)
   print(h.." OK")
end

print " feed/yeld test on 448 bytes"
for i,h in ipairs(hash_algos) do
   local H = HASH.new(h)
   H:feed(str448)
   assert(H:yeld() == _G[h..'_str448'], "Error in "..h)
   print(h.." OK")
end

print " feed/yeld test on 896 bytes"
for i,h in ipairs(hash_algos) do
   local H = HASH.new(h)
   H:feed(str896)
   assert(H:yeld() == _G[h..'_str896'], "Error in "..h)
   print(h.." OK")
end

print " feed/yeld test on 1000000 bytes"
for i,h in ipairs(hash_algos) do
   local H = HASH.new(h)
   H:feed(straMB1)
   H:feed(straMB2)
   assert(H:yeld() == _G[h..'_straMB'], "Error in "..h)
   print(h.." OK")
end

