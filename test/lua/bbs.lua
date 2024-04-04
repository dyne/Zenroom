local bbs = require'crypto_bbs'
local HASH = require'hash'

print('----------------- TEST SHA256 ------------------')

local ciphersuite = bbs.ciphersuite('sha256')

-- Key Pair
print('----------------------')
print("TEST: key pair")
local ikm = O.from_hex('746869732d49532d6a7573742d616e2d546573742d494b4d2d746f2d67656e65726174652d246528724074232d6b6579')
local key_info = O.from_hex('746869732d49532d736f6d652d6b65792d6d657461646174612d746f2d62652d757365642d696e2d746573742d6b65792d67656e')
local key_dst = O.from_hex("4242535f424c53313233383147315f584d443a5348412d3235365f535357555f524f5f4832475f484d32535f4b455947454e5f4453545f")
local sk = bbs.keygen(ciphersuite, ikm, key_info, key_dst)
print("Test Case 1")
assert(sk == BIG.new(O.from_hex('60e55110f76883a13d030b2f6bd11883422d5abde717569fc0731f51237169fc')))

assert(bbs.sk2pk(sk) == O.from_hex('a820f230f6ae38503b86c70dc50b61c58a77e45c39ab25c0652bbaa8fa136f2851bd4781c9dcde39fc9d1d52c9e60268061e7d7632171d91aa8d460acee0e96f1e7c4cfb12d3ff9ab5d5dc91c277db75c845d649ef3c4f63aebc364cd55ded0c'))

print('----------------------')
print("TEST: hash_to_field_m1_c2")
-- Test vectors originated from:
-- draft-irtf-cfrg-hash-to-curve, Appendix J.9.1
local DST_hash_to_field = 'QUUX-V01-CS02-with-BLS12381G1_XMD:SHA-256_SSWU_RO_'
local hash_to_curve_test = {

{
    msg  = '',
    P_x  = '052926add2207b76ca4fa57a8734416c8dc95e24501772c814278700eed6d1e4e8cf62d9c09db0fac349612b759e79a1',
    P_y  = '08ba738453bfed09cb546dbb0783dbb3a5f1f566ed67bb6be0e8c67e2e81a4cc68ee29813bb7994998f3eae0c9c6a265',
    u_0  = '0ba14bd907ad64a016293ee7c2d276b8eae71f25a4b941eece7b0d89f17f75cb3ae5438a614fb61d6835ad59f29c564f',
    u_1  = '019b9bd7979f12657976de2884c7cce192b82c177c80e0ec604436a7f538d231552f0d96d9f7babe5fa3b19b3ff25ac9',
    Q0_x = '11a3cce7e1d90975990066b2f2643b9540fa40d6137780df4e753a8054d07580db3b7f1f03396333d4a359d1fe3766fe',
    Q0_y = '0eeaf6d794e479e270da10fdaf768db4c96b650a74518fc67b04b03927754bac66f3ac720404f339ecdcc028afa091b7',
    Q1_x = '160003aaf1632b13396dbad518effa00fff532f604de1a7fc2082ff4cb0afa2d63b2c32da1bef2bf6c5ca62dc6b72f9c',
    Q1_y = '0d8bb2d14e20cf9f6036152ed386d79189415b6d015a20133acb4e019139b94e9c146aaad5817f866c95d609a361735e'

},
{
    msg  = 'abc',
    P_x  = '03567bc5ef9c690c2ab2ecdf6a96ef1c139cc0b2f284dca0a9a7943388a49a3aee664ba5379a7655d3c68900be2f6903',
    P_y  = '0b9c15f3fe6e5cf4211f346271d7b01c8f3b28be689c8429c85b67af215533311f0b8dfaaa154fa6b88176c229f2885d',
    u_0  = '0d921c33f2bad966478a03ca35d05719bdf92d347557ea166e5bba579eea9b83e9afa5c088573c2281410369fbd32951',
    u_1  = '003574a00b109ada2f26a37a91f9d1e740dffd8d69ec0c35e1e9f4652c7dba61123e9dd2e76c655d956e2b3462611139',
    Q0_x = '125435adce8e1cbd1c803e7123f45392dc6e326d292499c2c45c5865985fd74fe8f042ecdeeec5ecac80680d04317d80',
    Q0_y = '0e8828948c989126595ee30e4f7c931cbd6f4570735624fd25aef2fa41d3f79cfb4b4ee7b7e55a8ce013af2a5ba20bf2',
    Q1_x = '11def93719829ecda3b46aa8c31fc3ac9c34b428982b898369608e4f042babee6c77ab9218aad5c87ba785481eff8ae4',
    Q1_y = '0007c9cef122ccf2efd233d6eb9bfc680aa276652b0661f4f820a653cec1db7ff69899f8e52b8e92b025a12c822a6ce6'

},
{
    msg  = 'abcdef0123456789',
    P_x  = '11e0b079dea29a68f0383ee94fed1b940995272407e3bb916bbf268c263ddd57a6a27200a784cbc248e84f357ce82d98',
    P_y  = '03a87ae2caf14e8ee52e51fa2ed8eefe80f02457004ba4d486d6aa1f517c0889501dc7413753f9599b099ebcbbd2d709',
    u_0  = '062d1865eb80ebfa73dcfc45db1ad4266b9f3a93219976a3790ab8d52d3e5f1e62f3b01795e36834b17b70e7b76246d4',
    u_1  = '0cdc3e2f271f29c4ff75020857ce6c5d36008c9b48385ea2f2bf6f96f428a3deb798aa033cd482d1cdc8b30178b08e3a',
    Q0_x = '08834484878c217682f6d09a4b51444802fdba3d7f2df9903a0ddadb92130ebbfa807fffa0eabf257d7b48272410afff',
    Q0_y = '0b318f7ecf77f45a0f038e62d7098221d2dbbca2a394164e2e3fe953dc714ac2cde412d8f2d7f0c03b259e6795a2508e',
    Q1_x = '158418ed6b27e2549f05531a8281b5822b31c3bf3144277fbb977f8d6e2694fedceb7011b3c2b192f23e2a44b2bd106e',
    Q1_y = '1879074f344471fac5f839e2b4920789643c075792bec5af4282c73f7941cda5aa77b00085eb10e206171b9787c4169f'

},
{
    msg  = 'q128_qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq',
    P_x  = '15f68eaa693b95ccb85215dc65fa81038d69629f70aeee0d0f677cf22285e7bf58d7cb86eefe8f2e9bc3f8cb84fac488',
    P_y  = '1807a1d50c29f430b8cafc4f8638dfeeadf51211e1602a5f184443076715f91bb90a48ba1e370edce6ae1062f5e6dd38',
    u_0  = '010476f6a060453c0b1ad0b628f3e57c23039ee16eea5e71bb87c3b5419b1255dc0e5883322e563b84a29543823c0e86',
    u_1  = '0b1a912064fb0554b180e07af7e787f1f883a0470759c03c1b6509eb8ce980d1670305ae7b928226bb58fdc0a419f46e',
    Q0_x = '0cbd7f84ad2c99643fea7a7ac8f52d63d66cefa06d9a56148e58b984b3dd25e1f41ff47154543343949c64f88d48a710',
    Q0_y = '052c00e4ed52d000d94881a5638ae9274d3efc8bc77bc0e5c650de04a000b2c334a9e80b85282a00f3148dfdface0865',
    Q1_x = '06493fb68f0d513af08be0372f849436a787e7b701ae31cb964d968021d6ba6bd7d26a38aaa5a68e8c21a6b17dc8b579',
    Q1_y = '02e98f2ccf5802b05ffaac7c20018bc0c0b2fd580216c4aa2275d2909dc0c92d0d0bdc979226adeb57a29933536b6bb4'

},
{

    msg  = 'a512_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    P_x  = '082aabae8b7dedb0e78aeb619ad3bfd9277a2f77ba7fad20ef6aabdc6c31d19ba5a6d12283553294c1825c4b3ca2dcfe',
    P_y  = '05b84ae5a942248eea39e1d91030458c40153f3b654ab7872d779ad1e942856a20c438e8d99bc8abfbf74729ce1f7ac8',
    u_0  = '0a8ffa7447f6be1c5a2ea4b959c9454b431e29ccc0802bc052413a9c5b4f9aac67a93431bd480d15be1e057c8a08e8c6',
    u_1  = '05d487032f602c90fa7625dbafe0f4a49ef4a6b0b33d7bb349ff4cf5410d297fd6241876e3e77b651cfc8191e40a68b7',
    Q0_x = '0cf97e6dbd0947857f3e578231d07b309c622ade08f2c08b32ff372bd90db19467b2563cc997d4407968d4ac80e154f8',
    Q0_y = '127f0cddf2613058101a5701f4cb9d0861fd6c2a1b8e0afe194fccf586a3201a53874a2761a9ab6d7220c68661a35ab3',
    Q1_x = '092f1acfa62b05f95884c6791fba989bbe58044ee6355d100973bf9553ade52b47929264e6ae770fb264582d8dce512a',
    Q1_y = '028e6d0169a72cfedb737be45db6c401d3adfb12c58c619c82b93a5dfcccef12290de530b0480575ddc8397cda0bbebf'
}
}

local function run_test_hash_to_field_m1_c2 (test)
    local output_u = bbs.hash_to_field_m1_c2(ciphersuite, O.from_string(test.msg), O.from_string(DST_hash_to_field))
    assert(output_u[1] == BIG.new(O.from_hex(test.u_0)), "Wrong u_0")
    assert(output_u[2] == BIG.new(O.from_hex(test.u_1)), "Wrong u_1")
end
for k,v in pairs(hash_to_curve_test) do
    print("Test Case " .. k)
    run_test_hash_to_field_m1_c2(v)
end 

--[[
local function run_test_hash_to_field (test)
    local output_u = bbs.hash_to_field(O.from_string(test.msg), 2, O.from_string(DST_hash_to_field))
    assert(output_u[1][1] == BIG.new(O.from_hex(test.u_0)), "Wrong u_0")
    assert(output_u[2][1] == BIG.new(O.from_hex(test.u_1)), "Wrong u_1") 
end

print('----------------------')
print("TEST: hash_to_field")
for k,v in pairs(hash_to_curve_test) do
    print("Test Case " .. k)
    run_test_hash_to_field(v)
end 
--]]
--[[
local function run_test_hash_to_field_m1 (test)
    local output_u = bbs.hash_to_field_m1(O.from_string(test.msg), 2, O.from_string(DST_hash_to_field))
    assert(output_u[1] == BIG.new(O.from_hex(test.u_0)), "Wrong u_0")
    assert(output_u[2] == BIG.new(O.from_hex(test.u_1)), "Wrong u_1") 
end

print('----------------------')
print("TEST: hash_to_field_m1")
for k,v in pairs(hash_to_curve_test) do
    print("Test Case " .. k)
    run_test_hash_to_field_m1(v)
end 

local function run_test_hash_to_field_m1 (test)
    local output_u = bbs.hash_to_field_m1(O.from_string(test.msg), 2, O.from_string(DST_hash_to_field))
    assert(output_u[1] == BIG.new(O.from_hex(test.u_0)), "Wrong u_0")
    assert(output_u[2] == BIG.new(O.from_hex(test.u_1)), "Wrong u_1") 
end

print('----------------------')
print("TEST: hash_to_field_m1")
for k,v in pairs(hash_to_curve_test) do
    print("Test Case " .. k)
    run_test_hash_to_field_m1(v)
end 
--]]

print('----------------------')
print("TEST: map_to_curve")

local function run_test_map_to_curve (test)
    local output_Q0 = bbs.map_to_curve(BIG.new(O.from_hex(test.u_0)))
    local output_Q1 = bbs.map_to_curve(BIG.new(O.from_hex(test.u_1)))
    assert(output_Q0:x() == BIG.new(O.from_hex(test.Q0_x)), "Wrong Q0_x")
    assert(output_Q0:y() == BIG.new(O.from_hex(test.Q0_y)), "Wrong Q0_y")
    assert(output_Q1:x() == BIG.new(O.from_hex(test.Q1_x)), "Wrong Q1_x")
    assert(output_Q1:y() == BIG.new(O.from_hex(test.Q1_y)), "Wrong Q1_y")
end

for k,v in pairs(hash_to_curve_test) do
    print("Test Case " .. k)
    run_test_map_to_curve(v)
end

print('----------------------')
print("TEST: hash_to_curve (and clear_cofactor)")

local function run_test_hash_to_curve (test)
    local output_P = bbs.hash_to_curve(ciphersuite, O.from_string(test.msg), O.from_string(DST_hash_to_field))
    assert(output_P:x() == BIG.new(O.from_hex(test.P_x)), "Wrong P_x")
    assert(output_P:y() == BIG.new(O.from_hex(test.P_y)), "Wrong P_y")
end

for k,v in pairs(hash_to_curve_test) do
    print("Test Case " .. k)
    run_test_hash_to_curve(v)
end

print('----------------------')
print("TEST: MapMessageToScalarAsHash")

-- Test vectors originated from:
-- draft-irtf-cfrg-bbs-signatures-latest Sections 7.3 AND 7.5.1

local map_messages_to_scalar_messages = {
    O.from_hex('9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02'),
    O.from_hex("c344136d9ab02da4dd5908bbba913ae6f58c2cc844b802a6f811f5fb075f9b80"),
    O.from_hex('7372e9daa5ed31e6cd5c825eac1b855e84476a1d94932aa348e07b73'),
    O.from_hex('77fe97eb97a1ebe2e81e4e3597a3ee740a66e9ef2412472c'),
    O.from_hex('496694774c5604ab1b2544eababcf0f53278ff50'),
    O.from_hex('515ae153e22aae04ad16f759e07237b4'),
    O.from_hex('d183ddc6e2665aa4e2f088af'),
    O.from_hex('ac55fb33a75909ed'),
    O.from_hex('96012096'),
    O.empty()
}

local map_messages_to_scalar_test = {
    BIG.new(O.from_hex('1cb5bb86114b34dc438a911617655a1db595abafac92f47c5001799cf624b430')),
    BIG.new(O.from_hex('154249d503c093ac2df516d4bb88b510d54fd97e8d7121aede420a25d9521952')),
    BIG.new(O.from_hex('0c7c4c85cdab32e6fdb0de267b16fa3212733d4e3a3f0d0f751657578b26fe22')),
    BIG.new(O.from_hex('4a196deafee5c23f630156ae13be3e46e53b7e39094d22877b8cba7f14640888')),
    BIG.new(O.from_hex('34c5ea4f2ba49117015a02c711bb173c11b06b3f1571b88a2952b93d0ed4cf7e')),
    BIG.new(O.from_hex('4045b39b83055cd57a4d0203e1660800fabe434004dbdc8730c21ce3f0048b08')),
    BIG.new(O.from_hex('064621da4377b6b1d05ecc37cf3b9dfc94b9498d7013dc5c4a82bf3bb1750743')),
    BIG.new(O.from_hex('34ac9196ace0a37e147e32319ea9b3d8cc7d21870d3c3ba071246859cca49b02')),
    BIG.new(O.from_hex('57eb93f417c43200e9784fa5ea5a59168d3dbc38df707a13bb597c871b2a5f74')),
    BIG.new(O.from_hex('08e3afeb2b4f2b5f907924ef42856616e6f2d5f1fb373736db1cca32707a7d16'))
}


local output_scalar = bbs.messages_to_scalars(ciphersuite,map_messages_to_scalar_messages)
for i = 1, 10 do
    assert(output_scalar[i] == map_messages_to_scalar_test[i], "Wrong scalar")
end


--[[
print('----------------------')
print("TEST: MapMessageToScalarAsHash (BBS paper, C.2.7)")
print("(literally only first test vector of the above test with same name)")

-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.7

local INPUT_MSG_BBS_SHA_256 = '9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02'

local DEFAULT_DST_HASH_TO_SCALAR = '4242535f424c53313233383147315f584d443a5348412d3235365f535357555f524f5f4832535f'

local BBS_SHA_256_H2S_TEST = '669e7db2fcd926d6ec6ff14cbb3143f50cce0242627f1389d58b5cccbc0ef927'

print('Test case 1')
assert(bbs.MapMessageToScalarAsHash(ciphersuite, O.from_hex(INPUT_MSG_BBS_SHA_256), O.from_hex(DEFAULT_DST_HASH_TO_SCALAR)) == BIG.new(O.from_hex(BBS_SHA_256_H2S_TEST)))
--]]

print('----------------------')
print("TEST: create_generators")

-- Section 7.5.2
local create_generators_test = {
    ECP.from_zcash(O.from_hex("a9ec65b70a7fbe40c874c9eb041c2cb0a7af36ccec1bea48fa2ba4c2eb67ef7f9ecb17ed27d38d27cdeddff44c8137be")),
    ECP.from_zcash(O.from_hex("98cd5313283aaf5db1b3ba8611fe6070d19e605de4078c38df36019fbaad0bd28dd090fd24ed27f7f4d22d5ff5dea7d4")),
    ECP.from_zcash(O.from_hex("a31fbe20c5c135bcaa8d9fc4e4ac665cc6db0226f35e737507e803044093f37697a9d452490a970eea6f9ad6c3dcaa3a")),
    ECP.from_zcash(O.from_hex("b479263445f4d2108965a9086f9d1fdc8cde77d14a91c856769521ad3344754cc5ce90d9bc4c696dffbc9ef1d6ad1b62")),
    ECP.from_zcash(O.from_hex("ac0401766d2128d4791d922557c7b4d1ae9a9b508ce266575244a8d6f32110d7b0b7557b77604869633bb49afbe20035")),
    ECP.from_zcash(O.from_hex("b95d2898370ebc542857746a316ce32fa5151c31f9b57915e308ee9d1de7db69127d919e984ea0747f5223821b596335")),
    ECP.from_zcash(O.from_hex("8f19359ae6ee508157492c06765b7df09e2e5ad591115742f2de9c08572bb2845cbf03fd7e23b7f031ed9c7564e52f39")),
    ECP.from_zcash(O.from_hex("abc914abe2926324b2c848e8a411a2b6df18cbe7758db8644145fefb0bf0a2d558a8c9946bd35e00c69d167aadf304c1")),
    ECP.from_zcash(O.from_hex("80755b3eb0dd4249cbefd20f177cee88e0761c066b71794825c9997b551f24051c352567ba6c01e57ac75dff763eaa17")),
    ECP.from_zcash(O.from_hex("82701eb98070728e1769525e73abff1783cedc364adb20c05c897a62f2ab2927f86f118dcb7819a7b218d8f3fee4bd7f")),
    ECP.from_zcash(O.from_hex("a1f229540474f4d6f1134761b92b788128c7ac8dc9b0c52d59493132679673032ac7db3fb3d79b46b13c1c41ee495bca"))
}

local count_test = 11

local function run_test_create_generators (test)
    local output_generators = bbs.create_generators(ciphersuite, count_test)
    for i = 1, count_test do
        print("Test case ".. i)
        print(output_generators[1]:to_zcash():hex())
        assert(output_generators[i] == test[i])
    end
end

run_test_create_generators(create_generators_test)

print('----------------------')
print("TEST: Mocked/Seeded random scalars")

-- draft-irtf-cfrg-bbs-signatures-latest Section 7.1
-- It SIMULATES a random generation of scalars.
-- DO NOT USE IN FINAL ProofGen
local function seeded_random_scalars_xmd(count)
    local EXPAND_LEN = 48
    local SEED = O.from_hex("332e313431353932363533353839373933323338343632363433333833323739")
    local r = ECP.order()
    local out_len = EXPAND_LEN * count
    assert(out_len <= 65535)
    local v = HASH.expand_message_xmd(SEED, O.from_string("BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_H2G_HM2S_MOCK_RANDOM_SCALARS_DST_"), out_len)
    -- if v is INVALID return INVALID

    local arr = {}
    for i = 1, count do
        local start_idx = 1 + (i-1)*EXPAND_LEN
        local end_idx = i * EXPAND_LEN
        arr[i] = BIG.mod(v:sub(start_idx, end_idx), r) -- = os2ip(v:sub(start_idx, end_idx)) % r
    end
    return arr
end

local function seeded_random_scalars_xof(count)
    local EXPAND_LEN = 48
    local SEED = O.from_hex("332e313431353932363533353839373933323338343632363433333833323739")
    local r = ECP.order()
    local out_len = EXPAND_LEN * count
    assert(out_len <= 65535)
    local v = HASH.expand_message_xof(SEED, O.from_string("BBS_BLS12381G1_XOF:SHAKE-256_SSWU_RO_H2G_HM2S_MOCK_RANDOM_SCALARS_DST_"), out_len)
    -- if v is INVALID return INVALID

    local arr = {}
    for i = 1, count do
        local start_idx = 1 + (i-1)*EXPAND_LEN
        local end_idx = i * EXPAND_LEN
        arr[i] = BIG.mod(v:sub(start_idx, end_idx), r) -- = os2ip(v:sub(start_idx, end_idx)) % r
    end
    return arr
end

local old_random = bbs.calculate_random_scalars

bbs.calculate_random_scalars = seeded_random_scalars_xmd

-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Section 7.5.4
local MOCKED_RANDOM_SCALARS_TEST = {
    '04f8e2518993c4383957ad14eb13a023c4ad0c67d01ec86eeb902e732ed6df3f',
    '5d87c1ba64c320ad601d227a1b74188a41a100325cecf00223729863966392b1',
    '0444607600ac70482e9c983b4b063214080b9e808300aa4cc02a91b3a92858fe',
    '548cd11eae4318e88cda10b4cd31ae29d41c3a0b057196ee9cf3a69d471e4e94',
    '2264b06a08638b69b4627756a62f08e0dc4d8240c1b974c9c7db779a769892f4',
    '4d99352986a9f8978b93485d21525244b21b396cf61f1d71f7c48e3fbc970a42',
    '5ed8be91662386243a6771fbdd2c627de31a44220e8d6f745bad5d99821a4880',
    '62ff1734b939ddd87beeb37a7bbcafa0a274cbc1b07384198f0e88398272208d',
    '05c2a0af016df58e844db8944082dcaf434de1b1e2e7136ec8a99b939b716223',
    '485e2adab17b76f5334c95bf36c03ccf91cef77dcfcdc6b8a69e2090b3156663'
}

local function run_test_mocked_random (test)
    local output_mocked = seeded_random_scalars_xmd(10)
    for i = 1, 10 do
        print("Test case ".. i)
        assert(output_mocked[i] == BIG.new(O.from_hex(test[i])))
    end
end

run_test_mocked_random(MOCKED_RANDOM_SCALARS_TEST)

print('----------------------')
print("TEST: Single message signature SHA 256")
print("Test case 1")

local SECRET_KEY = "60e55110f76883a13d030b2f6bd11883422d5abde717569fc0731f51237169fc"
local PUBLIC_KEY = "a820f230f6ae38503b86c70dc50b61c58a77e45c39ab25c0652bbaa8fa136f2851bd4781c9dcde39fc9d1d52c9e60268061e7d7632171d91aa8d460acee0e96f1e7c4cfb12d3ff9ab5d5dc91c277db75c845d649ef3c4f63aebc364cd55ded0c"
local HEADER = "11223344556677889900aabbccddeeff"
local SINGLE_MSG_ARRAY = { O.from_hex("9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02") }
local VALID_SIGNATURE = "88c0eb3bc1d97610c3a66d8a3a73f260f95a3028bccf7fff7d9851e2acd9f3f32fdf58a5b34d12df8177adf37aa318a20f72be7d37a8e8d8441d1bc0bc75543c681bf061ce7e7f6091fe78c1cb8af103"

-- FROM trinsic-id / bbs BRANCH update result.
-- 0x8fb17415378ec4462bc167be75583989e0528913da142239848ae88309805bfb3656bcff322e5d8fd1a7e40a660a62266099f27fa81ff5010443f36285f6f0758e4d701c444b20447cded906a3f2001714087f165f760369b901ccbe5173438b32ad195b005e2747492cf002cf51e498

local output_signature = bbs.sign(ciphersuite, BIG.new(O.from_hex(SECRET_KEY)), O.from_hex(PUBLIC_KEY), O.from_hex(HEADER), SINGLE_MSG_ARRAY)
assert(output_signature == O.from_hex(VALID_SIGNATURE))
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), output_signature, O.from_hex(HEADER), SINGLE_MSG_ARRAY) == true)

print("Test case 2")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix D.2.1.2
local MODIFIED_MSG_ARR = { O.empty() }

assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), O.from_hex(VALID_SIGNATURE),O.from_hex(HEADER), MODIFIED_MSG_ARR) == false)
-- RETURNS AN ERROR: fail signature validation due to the message value being different from what was signed.

print("Test case 3")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix D.2.1.3
local TWO_MESSAGES = {
    O.from_hex('9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02'),
    O.from_hex('c344136d9ab02da4dd5908bbba913ae6f58c2cc844b802a6f811f5fb075f9b80')
}

assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), O.from_hex(VALID_SIGNATURE), O.from_hex(HEADER), TWO_MESSAGES) == false)
-- fails signature validation due to an additional message being supplied that was not signed

print('----------------------')
print("TEST: Single message proof SHA 256")
print("Test case 1")

local PRESENTATION_HEADER = O.from_hex("bed231d880675ed101ead304512e043ade9958dd0241ea70b4b3957fba941501")

local PROOF_GEN_OUT = O.from_hex('a7c217109e29ecab846691eaad757beb8cc93356daf889856d310af5fc5587ea4f8b70b0d960c68b7aefa62cae806baa8edeca19ca3dd884fb977fc43d946dc2a0be8778ec9ff7a1dae2b49c1b5d75d775ba37652ae759b9bb70ba484c74c8b2aeea5597befbb651827b5eed5a66f1a959bb46cfd5ca1a817a14475960f69b32c54db7587b5ee3ab665fbd37b506830a0fdc9a7f71072daabd4cdb49038f5c55e84623400d5f78043a18f76b272fd65667373702763570c8a2f7c837574f6c6c7d9619b0834303c0f55b2314cec804b33833c7047865587b8e55619123183f832021dd97439f324fa3ad90ec45417070067fb8c56b2af454562358b1509632f92f2116c020fe7de1ba242effdb36e980')

--con PH empty
--local PROOF_GEN_OUT = O.from_hex('99b6215be8357400353057b57b440e3998c259d34bce12e1d24dc7f9b63762122d4144cacefc5f3231172308907e3f2c8cf98d238dccf7e1eecf66441f27a7e140fc1a11788f24c634c5e4e6675c904670be71cdd44e613d1436f6badc4d9f319380b42122f33e956e861ad5e01d1bb2355015cd3d510f9636a1a746f496142a709f9d4914cdaffdf1ca936e12244e4850c9bdb7570028bb16233a92c0c4af229e528b4074fba2266dfd3023ee622b0832e92251e1b29d356111cb50cffae36c88b11baaaceb02553b5dcd6b348eb88370c8d06c93b3b56f91d1c3d7969f732d1ffc7620c68936f2d0e04b515dda8e41661706b3f851e51d154a8efbd036acee9b5cbbfec266d45acd5fd9f2fe47c54b15b0e30ba2e0e26bae6228ffdb499beea962ec564dabc3010e6f4021340ad77b')

local pg_output = bbs.proof_gen(ciphersuite, O.from_hex(PUBLIC_KEY), O.from_hex(VALID_SIGNATURE), O.from_hex(HEADER), PRESENTATION_HEADER, SINGLE_MSG_ARRAY, {1})

assert(PROOF_GEN_OUT == pg_output)

print("Test case 1 ProofVerify")

assert( bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), pg_output, O.from_hex(HEADER), PRESENTATION_HEADER, SINGLE_MSG_ARRAY, {1}) == true)

print("Test case 2 ProofVerify")
assert( bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), pg_output, O.from_hex(HEADER), PRESENTATION_HEADER, MODIFIED_MSG_ARR, {1}) == false)
-- Fails because of wrong message as input.

print("Test case 3 ProofVerify")
assert( bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), pg_output, O.from_hex(HEADER), PRESENTATION_HEADER, TWO_MESSAGES, {1,2}) == false)
-- Fails because of wrong messages as input.

print('----------------------')
print("TEST: multi message signature SHA 256")
print("Test case 1")

local MULTI_MSG_ARRAY = { }

for i = 1, 10 do
    MULTI_MSG_ARRAY[i] = map_messages_to_scalar_messages[i]
end

local VALID_MULTI_SIGNATURE = O.from_hex("895cd9c0ccb9aca4de913218655346d718711472f2bf1f3e68916de106a0d93cf2f47200819b45920bbda541db2d91480665df253fedab2843055bdc02535d83baddbbb2803ec3808e074f71f199751e")

local output_multi_signature = bbs.sign(ciphersuite, BIG.new(O.from_hex(SECRET_KEY)), O.from_hex(PUBLIC_KEY), O.from_hex(HEADER),MULTI_MSG_ARRAY)
assert( output_multi_signature == VALID_MULTI_SIGNATURE)
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), output_multi_signature, O.from_hex(HEADER), MULTI_MSG_ARRAY) == true)

print("Test case 2")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix D.2.1.1
local VALID_MULTI_SIGNATURE_NO_HEADER= O.from_hex("ae0b1807865598b3884e3e9b110e8faec662050dc9b4d95309d957fd30f6fc24161f6f8b5680f1f5d1b547be221547915ca665c7b3087a336d5e0c5fcfea62576afd13e563b730ef6d6d81f9944ab95b") 

local output_multi_signature_no_header = bbs.sign(ciphersuite, BIG.new(O.from_hex(SECRET_KEY)), O.from_hex(PUBLIC_KEY),nil, MULTI_MSG_ARRAY)
assert( output_multi_signature_no_header == VALID_MULTI_SIGNATURE_NO_HEADER)
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), output_multi_signature_no_header, nil , MULTI_MSG_ARRAY) == true)

print("Test case 3")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix D.2.1.4
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, O.from_hex(HEADER), TWO_MESSAGES) == false)
-- fail signature validation due to missing messages that were originally present during the signing.

print("Test case 4")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix D.2.1.5
local REORDERED_MSGS = {
    O.empty(),
    O.from_hex('96012096'),
    O.from_hex('ac55fb33a75909ed'),
    O.from_hex('d183ddc6e2665aa4e2f088af'),
    O.from_hex('515ae153e22aae04ad16f759e07237b4'),
    O.from_hex('496694774c5604ab1b2544eababcf0f53278ff50'),
    O.from_hex('77fe97eb97a1ebe2e81e4e3597a3ee740a66e9ef2412472c'),
    O.from_hex('7372e9daa5ed31e6cd5c825eac1b855e84476a1d94932aa348e07b73'),
    O.from_hex('c344136d9ab02da4dd5908bbba913ae6f58c2cc844b802a6f811f5fb075f9b80'),
    O.from_hex('9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02')
}

assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, O.from_hex(HEADER), REORDERED_MSGS) == false)
-- fails signature validation due to messages being re-ordered from the order in which they were signed.

print("Test case 5")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix D.2.1.6(WRONG SENTENCES THOUGH)
assert(bbs.verify(ciphersuite, O.from_hex("b064bd8d1ba99503cbb7f9d7ea00bce877206a85b1750e5583dd9399828a4d20610cb937ea928d90404c239b2835ffb104220a9c66a4c9ed3b54c0cac9ea465d0429556b438ceefb59650ddf67e7a8f103677561b7ef7fe3c3357ec6b94d41c6"), VALID_MULTI_SIGNATURE, O.from_hex(HEADER), MULTI_MSG_ARRAY) == false)
-- fails signature validation due to public key used to verify is incorrect.

print("Test case 6")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix D.2.1.7
local WRONG_HEADER = 'ffeeddccbbaa00998877665544332211'

assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, O.from_hex(WRONG_HEADER), MULTI_MSG_ARRAY) == false)
-- fails signature validation due to header value being modified from what was originally signed.

print('----------------------')
print("TEST: Valid multi message proof SHA 256")
print("Test case 1 : disclose all messages")

local DISCLOSED_INDEXES = {1,2,3,4,5,6,7,8,9,10}

local PROOF_GEN_MULTI_OUT = O.from_hex('a6faacf33f935d1910f21b1bbe380adcd2de006773896a5bd2afce31a13874298f92e602a4d35aef5880786cffc5aaf08978484f303d0c85ce657f463b71905ee7c3c0c9038671d8fb925525f623745dc825b14fc50477f3de79ce8d915d841ba73c8c97264177a76c4a03341956d2ae45ed3438ce598d5cda4f1bf9507fecef47855480b7b30b5e4052c92a4360110c322b4cb2d9796ff2d741979226249dc14d4b1fd5ca1a8f6fdfc16f726fc7683e3605d5ec28d331111a22ed81729cbb3c8c3732c7593e445f802fc3169c26857622ed31bc058fdfe68d25f0c3b9615279719c64048ea9cdb74104b27757c2d01035507d39667d77d990ec5bda22c866fcc9fe70bb5b7826a2b4e861b6b8124fbd')

local pg_multi_output = bbs.proof_gen(ciphersuite, O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, O.from_hex(HEADER), PRESENTATION_HEADER, MULTI_MSG_ARRAY, DISCLOSED_INDEXES)
assert(PROOF_GEN_MULTI_OUT == pg_multi_output)

print("Test ProofVerify")

assert( bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), pg_multi_output, O.from_hex(HEADER), PRESENTATION_HEADER, MULTI_MSG_ARRAY, DISCLOSED_INDEXES ) == true)

print("Test case 2 : disclose some messages")
--disclosed (messages in index 0, 2, 4 and 6, in that order)

local disclosed_some_indexes = {1,3,5,7}

local PROOF_GEN_MULTI_D_OUT = O.from_hex('a8da259a5ae7a9a8e5e4e809b8e7718b4d7ab913ed5781ebbff4814c762033eda4539973ed9bf557f882192518318cc4916fdffc857514082915a31df5bbb79992a59fd68dc3b48d19d2b0ad26be92b4cf78a30f472c0fd1e558b9d03940b077897739228c88afc797916dca01e8f03bd9c5375c7a7c59996e514bb952a436afd24457658acbaba5ddac2e693ac481352bb6fce6084eb1867c71caeac2afc4f57f4d26504656b798b3e4009eb227c7fa41b6ae00daae0436d853e86b32b366b0a9929e1570369e9c61b7b177eb70b7ff27326c467c362120dfeacc0692d25ccdd62d733ff6e8614abd16b6b63a7b78d11632cf41bc44856aee370fee6690a637b3b1d8d8525aff01cd3555c39d04f8ee1606964c2da8b988897e3d27cb444b8394acc80876d3916c485c9f36098fed6639f12a6a6e67150a641d7485656408e9ae22b9cb7ec77e477f71c1fe78cab3ee5dd62c34dd595edb15cbce061b29192419dfadcdee179f134dd8feb9323c426c51454168ffacb65021995848e368a5c002314b508299f67d85ad0eaaaac845cb029927191152edee034194cca3ae0d45cbd2f5e5afd1f9b8a3dd903adfa17ae43a191bf3119df57214f19e662c7e01e8cc2eb6b038bc7d707f2f3e13545909e0')

local pg_multi_d_output = bbs.proof_gen(ciphersuite, O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, O.from_hex(HEADER), PRESENTATION_HEADER, MULTI_MSG_ARRAY, disclosed_some_indexes)

assert(PROOF_GEN_MULTI_D_OUT == pg_multi_d_output)

print("Test ProofVerify")
local DISC_MSG = {MULTI_MSG_ARRAY[1], MULTI_MSG_ARRAY[3],MULTI_MSG_ARRAY[5], MULTI_MSG_ARRAY[7]}
assert( bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), pg_multi_d_output, O.from_hex(HEADER), PRESENTATION_HEADER, DISC_MSG, disclosed_some_indexes) == true)

print("Test case 3: no header")

local disclosed_some_indexes = {1,3,5,7}

local PROOF_GEN_MULTI_D_OUT_NO_HEADER = O.from_hex('958783d7d535fe1860a71ad5a7cf42df6527246300e3f3d94d67639c7e8a7dbcf3f082f63e3b1bcc1cdad71e1f6d5f0d821c4c6bb4b2dcdfe945491d4f4a23d10752431d364fcbdd199c753f0beee7ffe02abbad57384244294ef7c2031d9c50ac310574f509c712bb1a181d64ea3c1ee075c018a2bc773e2480b5c033ccb9bfea5af347a88ab83746c9342ba76db36771c74f1feec7f67b30e3805d71c8f893837b455d734d360c80e119b00dc63e2756b81a320d659a9a0f1ee57c41773f304c37c278d169faec5f6720bb9187e9333b793a57ba69f27e4b0c2ea35271276fc0011306d6c909cf4d4a7a50dbc9f6ef35d43e2043046dc3041ac0a9b893dfd2dcd147910d719e818b4189a76f791a3600acd76623573c1796262a3914921ec504d0f727c63e16b432f6256db62b9667016e516e97e2ef0bfa3bd192306564df28e019af18c50ca86a0e1d8d6b08b0641e549accd5e34ada8903d55021780865edfa70f63b85f0ddaf50787f8ced8eee658f2dd61673d2cbeca2aa2a5b649c22501b72cc7ee2d10bc9fe3aa3a7e169dc070d90b37735488cd0c27517ffd634b99c1dc016a4086d24feff6f19f3c92fa11cc198830295ccc56e5f9527216765105eee34324c5f3834154943608a8ca652')

local pg_multi_d_output_no_header = bbs.proof_gen(ciphersuite, O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE_NO_HEADER, nil, PRESENTATION_HEADER, MULTI_MSG_ARRAY, disclosed_some_indexes)

assert(PROOF_GEN_MULTI_D_OUT_NO_HEADER == pg_multi_d_output_no_header)

print("Test ProofVerify")
local DISC_MSG = {MULTI_MSG_ARRAY[1], MULTI_MSG_ARRAY[3],MULTI_MSG_ARRAY[5], MULTI_MSG_ARRAY[7]}
assert( bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), pg_multi_d_output_no_header, nil, PRESENTATION_HEADER, DISC_MSG, disclosed_some_indexes) == true)

print("Test case 4: no presentation header")

local disclosed_some_indexes = {1,3,5,7}

local PROOF_GEN_MULTI_D_OUT_NO_PH = O.from_hex('a8da259a5ae7a9a8e5e4e809b8e7718b4d7ab913ed5781ebbff4814c762033eda4539973ed9bf557f882192518318cc4916fdffc857514082915a31df5bbb79992a59fd68dc3b48d19d2b0ad26be92b4cf78a30f472c0fd1e558b9d03940b077897739228c88afc797916dca01e8f03bd9c5375c7a7c59996e514bb952a436afd24457658acbaba5ddac2e693ac481356d60aa96c9b53ff5c63b3930bbcb3940f2132b7dcd800be4afbffd3325ecedaf033d354de52e12e924b32dd13c2f7cebef3614a4a519ff94d1bcceb7e22562ab4a5729a74cc3746558e25469651d7da37f714951c2ca03fc364a2272d13b2dee53412f97f42dfd6b57ae92fc7cb4859f418d6a912f5c446002cbf96ee6b8f4a849577a43ef303592c33e03608a9ca93066084bdfb3d3974ba322b7523d48fc9b35227e776c994b0e2da1587b496660836a7307a2125eae5912be3ea839bb4db16a21cc394c9a63fce91040d8321b30313677f7cbc4a9119fd0849aacef25fe9336db2dcbd85a2e3fd2ca2efff623c13e6c48b832c9e07dbe4337320dd0264a573f25bb46876e8153db47de2f0176db68cca1f55406a78c89c1a65716c00e9230098c6a9690a190b20720a7662ccd13b392fe08d045b99d5010f625cd74f7e90a')

local pg_multi_d_output_no_ph = bbs.proof_gen(ciphersuite, O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, O.from_hex(HEADER), nil, MULTI_MSG_ARRAY, disclosed_some_indexes)

assert(PROOF_GEN_MULTI_D_OUT_NO_PH == pg_multi_d_output_no_ph)

print("Test ProofVerify")
local DISC_MSG = {MULTI_MSG_ARRAY[1], MULTI_MSG_ARRAY[3],MULTI_MSG_ARRAY[5], MULTI_MSG_ARRAY[7]}
assert( bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), pg_multi_d_output_no_ph, O.from_hex(HEADER), nil, DISC_MSG, disclosed_some_indexes) == true)




bbs.calculate_random_scalars = old_random

print('----------------------')
print("TEST: ProofGen is random")
print("Test Case 1")
local pfg1 = bbs.proof_gen(ciphersuite, O.from_hex(PUBLIC_KEY), O.from_hex(VALID_SIGNATURE), O.from_hex(HEADER), PRESENTATION_HEADER, SINGLE_MSG_ARRAY, {1})
local pfg2 = bbs.proof_gen(ciphersuite, O.from_hex(PUBLIC_KEY), O.from_hex(VALID_SIGNATURE), O.from_hex(HEADER), PRESENTATION_HEADER, SINGLE_MSG_ARRAY, {1})
assert(pfg1 ~= pfg2)
print("ProofVerify 1")
assert(bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), pfg1, O.from_hex(HEADER), PRESENTATION_HEADER,SINGLE_MSG_ARRAY,{1}) == true)
print("ProofVerify 2")
assert(bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), pfg2, O.from_hex(HEADER), PRESENTATION_HEADER,SINGLE_MSG_ARRAY,{1}) == true)

print('----------------- TEST SHAKE256 ------------------')

ciphersuite = bbs.ciphersuite('SHAKE256')

bbs.calculate_random_scalars = seeded_random_scalars_xof

print('----------------------')
print("TEST: MapMessageToScalarAsHash")

--Test vectors originated from:
--draft-irtf-cfrg-bbs-signatures.html Section 7.4.1

local Shake_dst = O.from_hex('4242535f424c53313233383147315f584f463a5348414b452d3235365f535357555f524f5f4d41505f4d53475f544f5f5343414c41525f41535f484153485f')
assert(Shake_dst == O.from_string('BBS_BLS12381G1_XOF:SHAKE-256_SSWU_RO_MAP_MSG_TO_SCALAR_AS_HASH_'))

local MapMsgToScalar_test = {
    '47f99622ec7bdc140b947eacc95f716a7223527751589febf4877e669a636667',
    '55464a899adb6635e449e4289b7d4540655017242843116f419294b363f15662',
    '3575b312561f50a72cff7652345264173afc4858f7d63dbfc2760978dbb0fe9a',
    '4365f9e2175e58be3dff52760e52583374cf8b02f4c71336b1d31d1b780d0b79',
    '1145adf00892d230c084e585fdfd656022957695265152c8964309f03fc8c4c1',
    '06182ce52763232b1aeb1aa5164e0984b6243ab8bb65a17ef82274140378078f',
    '46fb647beb5547df20ffdb5cb4a6492b7796e24c14283b7f2793b1b14ca2cdf1',
    '4e42aecc90ad7a59820ecd74eaa70404abbc1f979b3f2ea164abe42d79e5d9c9',
    '6194d15c9c8f4dbf710b2bbfa6a95356a8999b1192698b8cfdddd4b9b8a67025',
    '363ba017bba906cab5f9dd5c289f93ff5f9e6cc76296c7a3a1992c1dafe2c979'
}

for k = 1, #MapMsgToScalar_test do
    print("Test Case " .. k)
    local output_scalar = bbs.MapMessageToScalarAsHash(ciphersuite, O.from_hex(map_messages_to_scalar_messages[k]), Shake_dst)
    assert(output_scalar == BIG.new(O.from_hex(MapMsgToScalar_test[k])), "Wrong scalar")
end

print("Test case 11")
-- Appendix C.1.7
local SHAKE_DEFAULT_DST_HASH_TO_SCALAR = O.from_hex("4242535f424c53313233383147315f584f463a5348414b452d3235365f535357555f524f5f4832535f")
-- assert(SHAKE_DEFAULT_DST_HASH_TO_SCALAR == {})
assert(bbs.MapMessageToScalarAsHash(ciphersuite, O.from_hex(INPUT_MSG_BBS_SHA_256), SHAKE_DEFAULT_DST_HASH_TO_SCALAR) == BIG.new(O.from_hex('619db5f43cc92d3f5bd71502b99791bc1022c3eced4f1e3058a9c191af0118a4')))

print('----------------------')
print("TEST: create_generators")

--Test vectors originated from:
--draft-irtf-cfrg-bbs-signatures.html Section 7.4.2

local SHAKE_create_gen_test = {
    'b60acd4b0dc13b580394d2d8bc6c07d452df8e2a7eff93bc9da965b57e076cae640c2858fb0c2eaf242b1bd11107d635',
    'ad03f655b4c94f312b051aba45977c924bc5b4b1780c969534c183784c7275b70b876db641579604328c0975eaa0a137',
    'b63ae18d3edd64a2edd381290f0c68bebabaf3d37bc9dbb0bd5ad8daf03bbd2c48260255ba73f3389d2d5ad82303ac25',
    'b0b92b79a3e1fc59f39c6b9f78f00b873121c6a4c1814b94c07848efd172762fefbc48447a16f9ba8ed1b638e2933029',
    'b671ed7256777fb5b82f66d1268d03492a1cecc19fd327d56e100cce69c2e15fcd03dcdcfe6b2d42aa039edcd58092f4',
    '867009da287e1186884084ed71477ce9bd401e0bf4a7be48e2af0a3a4f2e7e21d2b7bb0ffdc4c03b5aa9672c3c76e0c9',
    'a3a10489bf1a244753e864454fd24ed8c312f737c0c2a529905222509199a0b48715a048cd93d134dac2cd4934c549bb',
    '81d548904ec8aa58b3f56f69c3f543fb73f339699a33df82c338cad9657b70c457b735c4ae96e8ea0c1ea0da65059d95',
    'b4bbc2a56104c2289fc7688fef30222746467df27698b6c2d53dad5477fd05b7ec8a84122b8122c1de2d2f16750d2a92',
    'ae22a4e89029d3507b8e40af3531b114b564cc77375c249036926e6973f69d21b356e734cdeda47fd320035781eda7df',
    '98b266b03b9cea3d466bafbcd2e1c600c40cba8817d52d46ea77612df911a6e6c040635211fc1bffd4ca914afca1ce55',
    'b458cd3d7af0b5ceea335436a66e2015b216467c204b850b15547f68f6f2a209e8229d154d4f998c7b96aa4f88cdca15'
}

local function run_test_create_generators2 (test)
    local output_generators = bbs.create_generators(ciphersuite, count_test)
    for i = 1, count_test do
        print("Test case ".. i)
        assert(output_generators[i] == ECP.from_zcash(O.from_hex(test[i])))
    end
end

run_test_create_generators2(SHAKE_create_gen_test)

print('----------------------')
print("TEST: Mocked/Seeded random scalars")

local shake_seeded_test = {
    BIG.new(O.from_hex("01b6e08fc79e13fad32d67f961ddb2e78d71efc3535ca36a5ff473f48266ce64")),
    BIG.new(O.from_hex("0cdd099ab5ed28de45eccfff6ef8aca07572c771bcea4540ae1bd946c4f08824")),
    BIG.new(O.from_hex("43353ad073f69d394b60a74ff6c3ec776fdb2d5ef3c74e5e2e1608fb108621a9")),
    BIG.new(O.from_hex("035cec79e2a2f8110e521d5d58b8b905799505a87f287e80ec7b5597b278b3c1")),
    BIG.new(O.from_hex("3fef09ffc2157bac6bebbd27f6a8fcea7d2220c319514aa23f3e7ea0c13307a4")),
    BIG.new(O.from_hex("12a5e44260a0da4ce2e05fb02c7d004990f89cd30c80eca9fabe2f3ca09c5d6c")),
    BIG.new(O.from_hex("5329ef2334622fde7f10c1963e19bd0a4fdaf39477b377be19cdcdc4b8b95fa9")),
    BIG.new(O.from_hex("3fc6ae2d0c872e17be8444e6eb8197923c3f91372e5261e59d79b49983ef62d5")),
    BIG.new(O.from_hex("732d59e95be946b589ffaa98f096bc51a8c0babf99f903303db1aca0645e4eee")),
    BIG.new(O.from_hex("50ef4ed6a0aee7fda4d21df7a566bea1fc4eb1efe567affbc41795c9f044fa09"))
}

local function run_test_mocked_random_shake (test)
    local output_mocked = seeded_random_scalars_xof(10)
    for i = 1, 10 do
        print("Test case ".. i)
        assert(output_mocked[i] == shake_seeded_test[i])
    end
end

run_test_mocked_random_shake(shake_seeded_test)

print('----------------------')
print("TEST: Single message signature SHAKE 256")
print("Test case 1")

local SECRET_KEY = "4a39afffd624d69e81808b2e84385cc80bf86adadf764e030caa46c231f2a8d7"
local PUBLIC_KEY = "aaff983278257afc45fa9d44d156c454d716fb1a250dfed132d65b2009331f618c623c14efa16245f50cc92e60334051087f1ae92669b89690f5feb92e91568f95a8e286d110b011e9ac9923fd871238f57d1295395771331ff6edee43e4ccc6"
local Shake_HEADER = "11223344556677889900aabbccddeeff"
local SSINGLE_MSG_ARRAY = { O.from_hex("9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02") }
local S_VALID_SIGNATURE = "a7386ffaa4e70a9a44483adccc202a658e1c1f02190fb95bfd0f826a0188d73ab910c556fb3c1d9e212dea3c5e9989271a5e578c4625d290a0e7f2355eabe7584af5eb822c72319e588b2c20cd1e8256698d6108f599c2e48cf1be8e4ebfaf7ae397a5733a498d3d466b843c027311bb"

output_signature = bbs.sign(ciphersuite, BIG.new(O.from_hex(SECRET_KEY)), O.from_hex(PUBLIC_KEY), SSINGLE_MSG_ARRAY, O.from_hex(Shake_HEADER))
assert(output_signature == O.from_hex(S_VALID_SIGNATURE))
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), output_signature, SSINGLE_MSG_ARRAY, O.from_hex(Shake_HEADER)) == true)

print("Test case 2")
-- Appendix C.1.1
local shake_modified_msg = {
    O.from_hex("c344136d9ab02da4dd5908bbba913ae6f58c2cc844b802a6f811f5fb075f9b80")
}
local shake_modified_msg_signature = O.from_hex("a7386ffaa4e70a9a44483adccc202a658e1c1f02190fb95bfd0f826a0188d73ab910c556fb3c1d9e212dea3c5e9989271a5e578c4625d290a0e7f2355eabe7584af5eb822c72319e588b2c20cd1e8256698d6108f599c2e48cf1be8e4ebfaf7ae397a5733a498d3d466b843c027311bb")
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), shake_modified_msg_signature, shake_modified_msg, O.from_hex(Shake_HEADER)) == false)
-- fails signature validation due to wrong message used.

print("Test case 3")
-- Appendix C.1.2

local shake_extra_msg = {
    O.from_hex("9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02"),
    O.from_hex("87a8bd656d49ee07b8110e1d8fd4f1dcef6fb9bc368c492d9bc8c4f98a739ac6")
}
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), shake_modified_msg_signature, shake_extra_msg, O.from_hex(Shake_HEADER)) == false)
-- fails signature validation due to an extra unsigned message.

print('----------------------')
print('TEST: Single message proof SHAKE 256')
local shake_pres_header = O.from_hex("bed231d880675ed101ead304512e043ade9958dd0241ea70b4b3957fba941501")
local shake_single_msg_proof = O.from_hex("8acd61a806203fb1c5203c4d90d92e8dfb1b7706cd9fc6e4233116204e9bfb96b0b0293f4b7c3fac69229e62c9e2bf36a9052cce6cc4ed37ebfbc3a45e45f77a87c2d4f90dc88aae23433b761f420debdfd2041057dc57f5cdf945c4e1df729cace4a3043f1b832731362434a0ab77086be5750a18505eb96422b9ff9fecf325197898760a4304af699e3d35ee99692048b58e5864da380772e16fd3e339b05b334f900a0b663b329379713ae925dbdc5dfa2490c7ebf390ec7d39e1bdfd1c1e3c8062d5254e683d46003cf5bf4a9366607d1e5c4ed120b4e9a7776d205c83aac9559ff1110ee4550801abdb5ea48a9d33514b9afb2fbc9eaca94ed1af5795ee5dec1664dc38ec908b4b7dd92cfd6f995c6bc436842be7608437c813b812220efe6a06b780cfaf8a57214319c0618915")

print('Test case 1')
local pg_output = bbs.proof_gen(ciphersuite, O.from_hex(PUBLIC_KEY), O.from_hex(S_VALID_SIGNATURE), O.from_hex(Shake_HEADER), shake_pres_header, SSINGLE_MSG_ARRAY, {1})
assert(shake_single_msg_proof  == pg_output)

print("Test case 1 ProofVerify")
assert( bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), pg_output, O.from_hex(Shake_HEADER), shake_pres_header, SSINGLE_MSG_ARRAY, {1}) == true)

print("Test case 2 ProofVerify")
assert( bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), pg_output, O.from_hex(Shake_HEADER), shake_pres_header, shake_modified_msg, {1}) == false)
-- Fails because of wrong message as input.

print("Test case 3 ProofVerify")
assert( bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), pg_output, O.from_hex(Shake_HEADER), shake_pres_header, shake_extra_msg, {1,2}) == false)
-- Fails because of wrong messages as input.

print('----------------------')
print("TEST: multi message signature SHAKE 256")
print("Test case 1")

local S_VALID_MULTI_SIGNATURE = O.from_hex("ae0587beb6b307f847eaf654f74177de4689b46c6d2b3eca6a6a80c798db78b0ccc251966debb500ec7fee8ca382bcc925860a0030570b2b56eb39868215b3b1ca1ab1ad9cdd5baccc8825f8133f12a4288c875e7f1aedc5861d7f3e45542e456425c632c9a82f4cc0b237e3b603b1b6")
output_multi_signature = bbs.sign(ciphersuite, BIG.new(O.from_hex(SECRET_KEY)), O.from_hex(PUBLIC_KEY), MULTI_MSG_ARRAY, O.from_hex(Shake_HEADER))
assert( output_multi_signature == S_VALID_MULTI_SIGNATURE)
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), output_multi_signature, MULTI_MSG_ARRAY, O.from_hex(Shake_HEADER)) == true)

print("Test case 2")
-- Appendix C.1.2
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), S_VALID_MULTI_SIGNATURE, shake_extra_msg, O.from_hex(Shake_HEADER)) == false)
-- fails signature validation due to missing messages in msg_array.

print("Test case 3")
-- Appendix C.1.4
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), S_VALID_MULTI_SIGNATURE, REORDERED_MSGS, O.from_hex(Shake_HEADER)) == false)
-- fails signature validation due to wrong order in message array.

print("Test case 4")
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), S_VALID_MULTI_SIGNATURE, MULTI_MSG_ARRAY, O.from_hex(WRONG_HEADER)) == false)
-- fails signature validation due to header used to verify is incorrect.
print("Test case 5")
assert(bbs.verify(ciphersuite, bbs.sk2pk(bbs.keygen(O.from_hex('0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b'))), S_VALID_MULTI_SIGNATURE, MULTI_MSG_ARRAY, O.from_hex(Shake_HEADER)) == false)
-- fails signature validation due to public key used to verify is incorrect.

print('----------------------')
print("TEST: multi message proof SHAKE 256")
print("Test case 1 : disclose all messages")

local shake_multi_msg_all_disclosed_proof = O.from_hex("af210c6571df52d805fa17620bf1a88dbcfb23829b5af59a86b9f4bc931d72942a94edfaaa88fa2363dce155ec70a2368e9b01eef49ec11f13fe4bb6b730bbec6b0cce4c3e7a0705fb57218563ec997d31daf49ad2b52621c03b83af8568b0a1a4daa67c99b04482f7556fb45f892e90ee0383564eed3ef199db76189d575c97307b02cf1fc8e384357f7c14ef308732287ae4e96c6f371e6864f6527542895e28ef39c8354ebb0174958212aba8da360fc6d5bed9faabad83601d8035cf8b86ab8b1a2a4984bbe09f653d68e06af0952c3a78e9a47d2b20c626e13a33a7830f147a41d306b3dcb97488d46cd561312c112ba29eb82bda43f452b255627210c2c4d9197be6bbaa9e5113617716caa6a25f6e297ccd4a6d716bdd9d258f9dc529477098cd69b6282ff351c21e35c19dc8")
local shake_all_disclosed_ind = {1,2,3,4,5,6,7,8,9,10}

local spg_multi_output = bbs.proof_gen(ciphersuite, O.from_hex(PUBLIC_KEY), S_VALID_MULTI_SIGNATURE, O.from_hex(Shake_HEADER), shake_pres_header, MULTI_MSG_ARRAY, shake_all_disclosed_ind)

assert(shake_multi_msg_all_disclosed_proof == spg_multi_output)

print("Test ProofVerify")

assert( bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), spg_multi_output, O.from_hex(Shake_HEADER), shake_pres_header, MULTI_MSG_ARRAY, shake_all_disclosed_ind) == true)

print("Test case 2 : disclose some messages")
local shake_multi_msg_some_disclosed_proof = O.from_hex("8733f60b98294aea82f8cc2994203a5ff630a50147d5aca82f41f26cbb4425e9b23b41874110d4f5de1e7c2db5945dc88e2f0c1ac96a03ccb3f6fd5759799302f100db5c14975eb68331442a99544c096b18efc9500ece042e628303faf7fa0f91047bc8295d97953bb8a1c034f17963ba70eff00eea8e41d1c4218a42132b536dc22ee56405f8c4f8a9576bb206aabc66052fc0e9ce161349966b9c257137eddef48b33a87fb4e492376e54dabe7b256523e6710cee7f117679943b4768faf4c516cb656cbc85199d9b4f51472c5b4464dda241332c4501b6fcae13c746e460e0478f241837efa80d87151dd72c57b664faaa912fe781ad4589d67ccb86270aadcc8f8786052d5599f902640f0d1de55f188b3e5f077841fdd6379e7b27df42b0069df43700eb5381aba2b2ba9d74890fc710a17567ec0b8052282d68a61eafd289f4767f0a927b6a1c6e6b2ce7546928cbd5c2e61407a76654d0ed19102effb8330d883a40af5c9cd6bb2e15103c5733b0eba1cc7ec617ceabd65beb8dee3abb2bd32f584c5cd3ff0637fdcaa700212548816512cbbb5e218ff74cf6f6ae8e327b9e29d5e578c400ca334ba0e1e17633215c59152d3c933eb9db6ca954558df5a2bc211e8f6e6b7a779a6c46222c1e6ec129d7d38aad9a9eff5a1bc0cef0e87cb58205f86c8c92f01fe04c4805aba3")
local shake_disclosed_ind = {1, 3, 5, 7}

local spg_multi_output = bbs.proof_gen(ciphersuite, O.from_hex(PUBLIC_KEY), S_VALID_MULTI_SIGNATURE, O.from_hex(Shake_HEADER), shake_pres_header, MULTI_MSG_ARRAY, shake_disclosed_ind)
assert(shake_multi_msg_some_disclosed_proof  == spg_multi_output)

print("Test ProofVerify")
local S_Disclosed_msg = {MULTI_MSG_ARRAY[1], MULTI_MSG_ARRAY[3], MULTI_MSG_ARRAY[5], MULTI_MSG_ARRAY[7]}
assert( bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), spg_multi_output, O.from_hex(Shake_HEADER), shake_pres_header, S_Disclosed_msg, shake_disclosed_ind) == true)

print('----------------------')
print("TEST: ProofGen is random")
bbs.calculate_random_scalars = old_random

print("Test Case 1")
local spfg1 = bbs.proof_gen(ciphersuite, O.from_hex(PUBLIC_KEY), O.from_hex(S_VALID_SIGNATURE), O.from_hex(HEADER), PRESENTATION_HEADER, SINGLE_MSG_ARRAY, {1})
local spfg2 = bbs.proof_gen(ciphersuite, O.from_hex(PUBLIC_KEY), O.from_hex(S_VALID_SIGNATURE), O.from_hex(HEADER), PRESENTATION_HEADER, SINGLE_MSG_ARRAY, {1})
assert(spfg1 ~= spfg2)
print("Proof Verify 1")
assert(bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), spfg1, O.from_hex(HEADER), PRESENTATION_HEADER, SINGLE_MSG_ARRAY, {1}) == true)
print("Proof Verify 2")
assert(bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), spfg2, O.from_hex(HEADER), PRESENTATION_HEADER, SINGLE_MSG_ARRAY, {1}) == true)


