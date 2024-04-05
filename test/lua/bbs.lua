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
        ---print(output_generators[1]:to_zcash():hex())
        assert(output_generators[i] == test[i], 'Wrong point')
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

print('----------------------')
print("TEST: key pair")
--Section 8.3.1.
local ikm = O.from_hex('746869732d49532d6a7573742d616e2d546573742d494b4d2d746f2d67656e65726174652d246528724074232d6b6579')
local key_info = O.from_hex('746869732d49532d736f6d652d6b65792d6d657461646174612d746f2d62652d757365642d696e2d746573742d6b65792d67656e')
local key_dst = O.from_hex('4242535f424c53313233383147315f584f463a5348414b452d3235365f535357555f524f5f4832475f484d32535f4b455947454e5f4453545f')
local sk = bbs.keygen(ciphersuite, ikm, key_info, key_dst)
print("Test Case 1")
assert(sk == BIG.new(O.from_hex('2eee0f60a8a3a8bec0ee942bfd46cbdae9a0738ee68f5a64e7238311cf09a079')))

assert(bbs.sk2pk(sk) == O.from_hex('92d37d1d6cd38fea3a873953333eab23a4c0377e3e049974eb62bd45949cdeb18fb0490edcd4429adff56e65cbce42cf188b31bddbd619e419b99c2c41b38179eb001963bc3decaae0d9f702c7a8c004f207f46c734a5eae2e8e82833f3e7ea5'))

print('----------------------')
print("TEST: Map Message to Scalar")
--Section 8.3.2.

local map_messages_to_scalar_test = {
    BIG.new(O.from_hex('1e0dea6c9ea8543731d331a0ab5f64954c188542b33c5bbc8ae5b3a830f2d99f')),
    BIG.new(O.from_hex("3918a40fb277b4c796805d1371931e08a314a8bf8200a92463c06054d2c56a9f")),
    BIG.new(O.from_hex("6642b981edf862adf34214d933c5d042bfa8f7ef343165c325131e2ffa32fa94")),
    BIG.new(O.from_hex("33c021236956a2006f547e22ff8790c9d2d40c11770c18cce6037786c6f23512")),
    BIG.new(O.from_hex("52b249313abbe323e7d84230550f448d99edfb6529dec8c4e783dbd6dd2a8471")),
    BIG.new(O.from_hex('2a50bdcbe7299e47e1046100aadffe35b4247bf3f059d525f921537484dd54fc')),
    BIG.new(O.from_hex("0e92550915e275f8cfd6da5e08e334d8ef46797ee28fa29de40a1ebccd9d95d3")),
    BIG.new(O.from_hex("4c28f612e6c6f82f51f95e1e4faaf597547f93f6689827a6dcda3cb94971d356")),
    BIG.new(O.from_hex("1db51bedc825b85efe1dab3e3ab0274fa82bbd39732be3459525faf70f197650")),
    BIG.new(O.from_hex('27878da72f7775e709bb693d81b819dc4e9fa60711f4ea927740e40073489e78'))
}

local output_scalar = bbs.messages_to_scalars(ciphersuite,map_messages_to_scalar_messages)
for i = 1, 10 do
    assert(output_scalar[i] == map_messages_to_scalar_test[i], "Wrong scalar")
end

print('----------------------')
print("TEST: create_generators")
-- Section 8.3.3.

local create_generators_test = {
    ECP.from_zcash(O.from_hex("a9d40131066399fd41af51d883f4473b0dcd7d028d3d34ef17f3241d204e28507d7ecae032afa1d5490849b7678ec1f8")),
    ECP.from_zcash(O.from_hex("903c7ca0b7e78a2017d0baf74103bd00ca8ff9bf429f834f071c75ffe6bfdec6d6dca15417e4ac08ca4ae1e78b7adc0e")),
    ECP.from_zcash(O.from_hex("84321f5855bfb6b001f0dfcb47ac9b5cc68f1a4edd20f0ec850e0563b27d2accee6edff1a26b357762fb24e8ddbb6fcb")),
    ECP.from_zcash(O.from_hex("b3060dff0d12a32819e08da00e61810676cc9185fdd750e5ef82b1a9798c7d76d63de3b6225d6c9a479d6c21a7c8bf93")),
    ECP.from_zcash(O.from_hex("8f1093d1e553cdead3c70ce55b6d664e5d1912cc9edfdd37bf1dad11ca396a0a8bb062092d391ebf8790ea5722413f68")),
    ECP.from_zcash(O.from_hex("990824e00b48a68c3d9a308e8c52a57b1bc84d1cf5d3c0f8c6fb6b1230e4e5b8eb752fb374da0b1ef687040024868140")),
    ECP.from_zcash(O.from_hex("b86d1c6ab8ce22bc53f625d1ce9796657f18060fcb1893ce8931156ef992fe56856199f8fa6c998e5d855a354a26b0dd")),
    ECP.from_zcash(O.from_hex("b4cdd98c5c1e64cb324e0c57954f719d5c5f9e8d991fd8e159b31c8d079c76a67321a30311975c706578d3a0ddc313b7")),
    ECP.from_zcash(O.from_hex("8311492d43ec9182a5fc44a75419b09547e311251fe38b6864dc1e706e29446cb3ea4d501634eb13327245fd8a574f77")),
    ECP.from_zcash(O.from_hex("ac00b493f92d17837a28d1f5b07991ca5ab9f370ae40d4f9b9f2711749ca200110ce6517dc28400d4ea25dddc146cacc")),
    ECP.from_zcash(O.from_hex("965a6c62451d4be6cb175dec39727dc665762673ee42bf0ac13a37a74784fbd61e84e0915277a6f59863b2bb4f5f6005"))
}

local count_test = 11

local function run_test_create_generators (test)
    local output_generators = bbs.create_generators(ciphersuite, count_test)
    for i = 1, count_test do
        print("Test case ".. i)
        ---print(output_generators[1]:to_zcash():hex())
        assert(output_generators[i] == test[i], 'Wrong point')
    end
end

run_test_create_generators(create_generators_test)

print('----------------------')
print("TEST: Single message signature SHAKE 256")
print("Test case 1")
--Section 8.3.4.1.

local SECRET_KEY = "2eee0f60a8a3a8bec0ee942bfd46cbdae9a0738ee68f5a64e7238311cf09a079"
local PUBLIC_KEY = "92d37d1d6cd38fea3a873953333eab23a4c0377e3e049974eb62bd45949cdeb18fb0490edcd4429adff56e65cbce42cf188b31bddbd619e419b99c2c41b38179eb001963bc3decaae0d9f702c7a8c004f207f46c734a5eae2e8e82833f3e7ea5"
local HEADER = "11223344556677889900aabbccddeeff"
local SINGLE_MSG_ARRAY = { O.from_hex("9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02") }
local VALID_SIGNATURE = "98eb37fceb31115bf647f2983aef578ad895e55f7451b1add02fa738224cb89a31b148eace4d20d001be31d162c58d12574f30e68665b6403956a83b23a16f1daceacce8c5fde25d3defd52d6d5ff2e1"

local output_signature = bbs.sign(ciphersuite, BIG.new(O.from_hex(SECRET_KEY)), O.from_hex(PUBLIC_KEY), O.from_hex(HEADER), SINGLE_MSG_ARRAY)
assert(output_signature == O.from_hex(VALID_SIGNATURE))
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), output_signature, O.from_hex(HEADER), SINGLE_MSG_ARRAY) == true)

print("Test case 2")
-- Section D.1.1.2.

local MODIFIED_MSG_ARR = { O.empty() }

assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), O.from_hex(VALID_SIGNATURE),O.from_hex(HEADER), MODIFIED_MSG_ARR) == false)
-- RETURNS AN ERROR: fail signature validation due to the message value being different from what was signed.

print("Test case 3")
-- Section D.1.1.3.

local TWO_MESSAGES = {
    O.from_hex('9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02'),
    O.from_hex('c344136d9ab02da4dd5908bbba913ae6f58c2cc844b802a6f811f5fb075f9b80')
}

assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), O.from_hex(VALID_SIGNATURE), O.from_hex(HEADER), TWO_MESSAGES) == false)
-- fails signature validation due to an additional message being supplied that was not signed

print("Test case 4")
--Section D.1.1.4.

local FALSE_SIGNATURE = "97a296c83ed3626fe254d26021c5e9a087b580f1e8bc91bb51efb04420bfdaca215fe376a0bc12440bcc52224fb33c696cca9239b9f28dcddb7bd850aae9cd1a9c3e9f3639953fe789dbba53b8f0dd6f"

assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), O.from_hex(FALSE_SIGNATURE), O.from_hex(HEADER), TWO_MESSAGES) == false)
-- fails signature validation due to to missing messages that were originally present during the signing


print('----------------------')
print("TEST: Mocked/Seeded random scalars")

-- It SIMULATES a random generation of scalars.

bbs.calculate_random_scalars = seeded_random_scalars_xof

-- Section 8.3.5.

local MOCKED_RANDOM_SCALARS_TEST = {
    '1004262112c3eaa95941b2b0d1311c09c845db0099a50e67eda628ad26b43083',
    '6da7f145a94c1fa7f116b2482d59e4d466fe49c955ae8726e79453065156a9a4',
    '05017919b3607e78c51e8ec34329955d49c8c90e4488079c43e74824e98f1306',
    '4d451dad519b6a226bba79e11b44c441f1a74800eecfec6a2e2d79ea65b9d32d',
    '5e7e4894e6dbe68023bc92ef15c410b01f3828109fc72b3b5ab159fc427b3f51',
    '646e3014f49accb375253d268eb6c7f3289a1510f1e9452b612dd73a06ec5dd4',
    '363ecc4c1f9d6d9144374de8f1f7991405e3345a3ec49dd485a39982753c11a4',
    '12e592fe28d91d7b92a198c29afaa9d5329a4dcfdaf8b08557807412faeb4ac6',
    '513325acdcdec7ea572360587b350a8b095ca19bdd8258c5c69d375e8706141a',
    '6474fceba35e7e17365dde1a0284170180e446ae96c82943290d7baa3a6ed429'
}

local function run_test_mocked_random (test)
    local output_mocked = seeded_random_scalars_xof(10)
    for i = 1, 10 do
        print("Test case ".. i)
        assert(output_mocked[i] == BIG.new(O.from_hex(test[i])))
    end
end

run_test_mocked_random(MOCKED_RANDOM_SCALARS_TEST)

print('----------------------')
print("TEST: Single message proof SHAKE 256")
print("Test case 1")
--Section 8.3.5.1.

local SINGLE_MSG_ARRAY = {O.from_hex("9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02") }
local PUBLIC_KEY = "92d37d1d6cd38fea3a873953333eab23a4c0377e3e049974eb62bd45949cdeb18fb0490edcd4429adff56e65cbce42cf188b31bddbd619e419b99c2c41b38179eb001963bc3decaae0d9f702c7a8c004f207f46c734a5eae2e8e82833f3e7ea5"
local VALID_SIGNATURE = "98eb37fceb31115bf647f2983aef578ad895e55f7451b1add02fa738224cb89a31b148eace4d20d001be31d162c58d12574f30e68665b6403956a83b23a16f1daceacce8c5fde25d3defd52d6d5ff2e1"

local PRESENTATION_HEADER = O.from_hex("bed231d880675ed101ead304512e043ade9958dd0241ea70b4b3957fba941501")

local PROOF_GEN_OUT = O.from_hex('89b485c2c7a0cd258a5d265a6e80aae416c52e8d9beaf0e38313d6e5fe31e7f7dcf62023d130fbc1da747440e61459b1929194f5527094f56a7e812afb7d92ff2c081654c6d5a70e369474267f1c7f769d47160cd92d79f66bb86e994c999226b023d58ee44d660434e6ba60ed0da1a5d2cde031b483684cd7c5b13295a82f57e209b584e8fe894bcc964117bf3521b468cc9c6ba22419b3e567c7f72b6af815ddeca161d6d5270c3e8f269cdabb7d60230b3c66325dcf6caf39bcca06d889f849d301e7f30031fdeadc443a7575de547259ffe5d21a45e5a0da9b113512f7b124f031b0b8329a8625715c9245033ae13dfadd6bdb0b4364952647db3d7b91faa4c24cbb65344c03473c5065bb414ff7')

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
print("TEST: multi message signature SHAKE 256")
print("Test case 1")
--Section 8.3.4.2.

local MULTI_MSG_ARRAY = { }

for i = 1, 10 do
    MULTI_MSG_ARRAY[i] = map_messages_to_scalar_messages[i]
end

local VALID_MULTI_SIGNATURE = O.from_hex("97a296c83ed3626fe254d26021c5e9a087b580f1e8bc91bb51efb04420bfdaca215fe376a0bc12440bcc52224fb33c696cca9239b9f28dcddb7bd850aae9cd1a9c3e9f3639953fe789dbba53b8f0dd6f")

local output_multi_signature = bbs.sign(ciphersuite, BIG.new(O.from_hex(SECRET_KEY)), O.from_hex(PUBLIC_KEY), O.from_hex(HEADER),MULTI_MSG_ARRAY)
assert( output_multi_signature == VALID_MULTI_SIGNATURE)
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), output_multi_signature, O.from_hex(HEADER), MULTI_MSG_ARRAY) == true)

print("Test case 2")
-- Section D.1.1.1
local VALID_MULTI_SIGNATURE_NO_HEADER= O.from_hex("abfa513cdb323e47214b7c182fb623197a0681b753f897545a73d82ee133a8ecf69db9aa09fe425df4e7687d99d779db5c66199c0dc9d2a442d331c43f56e060edc69a69ed2f13de3813b98ce6b05737") 

local output_multi_signature_no_header = bbs.sign(ciphersuite, BIG.new(O.from_hex(SECRET_KEY)), O.from_hex(PUBLIC_KEY),nil, MULTI_MSG_ARRAY)
assert( output_multi_signature_no_header == VALID_MULTI_SIGNATURE_NO_HEADER)
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), output_multi_signature_no_header, nil , MULTI_MSG_ARRAY) == true)

print("Test case 3")
-- Section D.1.1.2
local PUBLIC_KEY = "92d37d1d6cd38fea3a873953333eab23a4c0377e3e049974eb62bd45949cdeb18fb0490edcd4429adff56e65cbce42cf188b31bddbd619e419b99c2c41b38179eb001963bc3decaae0d9f702c7a8c004f207f46c734a5eae2e8e82833f3e7ea5"
local MODIFIED_MULTI_SIGNATURE = O.from_hex("98eb37fceb31115bf647f2983aef578ad895e55f7451b1add02fa738224cb89a31b148eace4d20d001be31d162c58d12574f30e68665b6403956a83b23a16f1daceacce8c5fde25d3defd52d6d5ff2e1")

assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), MODIFIED_MULTI_SIGNATURE, O.from_hex(HEADER), {O.empty()}) == false)
-- fail signature validation due to missing messages that were originally present during the signing.

print("Test case 4")
--Section D.1.1.3
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), MODIFIED_MULTI_SIGNATURE, O.from_hex(HEADER), TWO_MESSAGES) == false)
-- fail signature validation due to an additional message being supplied that was not signed

print("Test case 5")
--Section D.1.1.4
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, O.from_hex(HEADER), TWO_MESSAGES) == false)
-- fail signature validation due to an additional message being supplied that was not signed

print("Test case 6")
-- Section D.1.1.5
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

print("Test case 7")
-- Section D.1.1.6
assert(bbs.verify(ciphersuite, O.from_hex("b24c723803f84e210f7a95f6265c5cbfa4ecc51488bf7acf24b921807801c0798b725b9a2dcfa29953efcdfef03328720196c78b2e613727fd6e085302a0cc2d8d7e1d820cf1d36b20e79eee78c13a1a5da51a298f1aef86f07bc33388f089d8"), VALID_MULTI_SIGNATURE, O.from_hex(HEADER), MULTI_MSG_ARRAY) == false)
-- fails signature validation due to public key used to verify is incorrect.

print("Test case 8")
-- Section D.1.1.7
local WRONG_HEADER = 'ffeeddccbbaa00998877665544332211'

assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, O.from_hex(WRONG_HEADER), MULTI_MSG_ARRAY) == false)
-- fails signature validation due to header value being modified from what was originally signed.

print('----------------------')
print("TEST: multi message proof SHAKE 256")
print("Test case 1 : disclose all messages")
--Section 8.3.5.2.

local shake_multi_msg_all_disclosed_proof = O.from_hex("80ff9367fda28896618e8ede02481d660fe80bfce51a46bebe7e1d6a4c751d60e09e87cd8d1e2a078d0838de56b6a7ca94651eec82e5f689b4dfc7e3c879ff7e33906271b17af20eab678d64903515971e39484e712fd3c8a45f279c1e058955b3dd7ed57aaadc348361e2501a17317352e555a333e014e8e7d71eef808ae4f8fbdf45cd19fde45038bb310d5135f5205611672c8d50d505af8a6e038729230458a6ceb663fa048f4ce3a7a92998de4200882156ba6b6e60d855c0645d2fdd628518d2e6fc5221b7456ccbc1c5210a1704e4d662dddd1f99a767344a7944ab7f9b6f9d9069de4a132e4feebb6d70a87b0856635e1b8b8ca49e2992f8c80221398e08935824f959a821b4120cdfb5e6be")
local shake_all_disclosed_ind = {1,2,3,4,5,6,7,8,9,10}

local spg_multi_output = bbs.proof_gen(ciphersuite, O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, O.from_hex(HEADER), PRESENTATION_HEADER, MULTI_MSG_ARRAY, shake_all_disclosed_ind)

assert(shake_multi_msg_all_disclosed_proof == spg_multi_output)

print("Test ProofVerify")

assert( bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), spg_multi_output, O.from_hex(HEADER), PRESENTATION_HEADER, MULTI_MSG_ARRAY, shake_all_disclosed_ind) == true)

print("Test case 2 : disclose some messages")
--Section 8.3.5.3.

local shake_multi_msg_some_disclosed_proof = O.from_hex("853f4927bd7e4998af27df65566c0a071a33a5207d1af33ef7c3be04004ac5da860f34d35c415498af32729720ca4d92977bbbbd60fdc70ddbb2588878675b90815273c9eaf0caa1123fe5d0c4833fefc459d18e1dc83d669268ec702c0e16a6b73372346feb94ab16189d4c525652b8d3361bab43463700720ecfb0ee75e595ea1b13330615011050a0dfcffdb21af36ac442df87545e0e8303260a97a0d251de15fc1447b82fff6b47ffb0ff94022869b315dc48c9302523b2715ddec9f56975a0892f5f3aeed3203c29c7a03cfc79187eef45f72b7c5bf0d4fc852adcc7528c05b0ba9554f2eb9b39c168a4dd6bdc3ac603ce14856184f6d713139f9d3930efcc9842e724517dbccff6912088b399447ff786e2f9db8b1061cc89a1636ba9282344729bcd19228ccde2318286c5a115baaf317b48341ac7906c6cc957f94b060351563907dca7f598a4cbdaeab26c4a4fcb6aa7ff6fd999c5f9bc0c9a9b0e4f4a3301de901a6c68b174ed24ccf5cd0cac6726766c91aded6947c4b446a9dfc8ec0aa11ec9ddda57dcc22c554a83a25471be93ae69ad9234b1fc3d133550d7ff570a4bc6555cd0bf23ee1b2a994b2434ea222bc221ba1615adc53b47ba99fc5a66495585d4c86f1f0aecb18df802b8")
local shake_disclosed_ind = {1, 3, 5, 7}

local spg_multi_output = bbs.proof_gen(ciphersuite, O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, O.from_hex(HEADER), PRESENTATION_HEADER, MULTI_MSG_ARRAY, shake_disclosed_ind)
assert(shake_multi_msg_some_disclosed_proof  == spg_multi_output)

--
print("Test ProofVerify")
local DISC_MSG = {MULTI_MSG_ARRAY[1], MULTI_MSG_ARRAY[3],MULTI_MSG_ARRAY[5], MULTI_MSG_ARRAY[7]}
assert( bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), spg_multi_output, O.from_hex(HEADER), PRESENTATION_HEADER, DISC_MSG, shake_disclosed_ind) == true)


print("Test case 3: no header")
--Section D.1.2.1.

local disclosed_some_indexes = {1,3,5,7}
local VALID_MULTI_SIGNATURE_NO_HEADER = O.from_hex("abfa513cdb323e47214b7c182fb623197a0681b753f897545a73d82ee133a8ecf69db9aa09fe425df4e7687d99d779db5c66199c0dc9d2a442d331c43f56e060edc69a69ed2f13de3813b98ce6b05737")
local PROOF_GEN_MULTI_D_OUT_NO_HEADER = O.from_hex("ada2a57ae3d869255d1533f74317b131ad4f0f24cae413ac40028d70f0cf0372b503ff6e705220532727002b8958ebf987e2e8378984afe3214511b9feeee830ffe3121ed005d2c382c04e6db37b646bc2f7002f3699648570fe9b67a0a5aac995644ee738810772d90c1033f1dfe45c0b1b453d131170aafa8a99f812f3b90a5d1d9e6bd05a4dee6a50dd277ffc646f6b676faadceff172a0002325e7f22f47ed9b5125f30dd5fffe9ed1dc99dc283100cb702fa63aaef1bd1f530a5368ca4c7e78a01c7fcc3563b25c6c10c0e063092cbe2590fdfcc7b6a2859e482796f1f6783a41dfdf133ce28d13071b77cbe7fe06bf6e138bd3323e7edc4a6ec9942bfa0b6d1287836e2b1c2db84833d8325d145e6d2a3e94ddd5b6f58c1d1b2a15a854f7cf46711239ebe522bf5e428131e31e2f5f322eba2399fa7a8efec4be722dcaf6ec6adaf84af72c3d7690072d07928045327f3a6587102b066fb9cf96b27aca7f5698a2ec66d04efa05ed57fd6ac27636322c013a168100b733269e9bd6f23d7562affebafc3d9b3c5f54a0c57216b733f8ecb24dc292c17e18b6b8e0f3b8303dfaedee84fba02d491994b95f965deb3c1295545bb9802d98449d98d1af18e9c60536146cfa7aa267bd888b25552dd2")
local PRESENTATION_HEADER_NH = O.from_hex("bed231d880675ed101ead304512e043ade9958dd0241ea70b4b3957fba941501")

local pg_multi_d_output_no_header = bbs.proof_gen(ciphersuite, O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE_NO_HEADER, nil, PRESENTATION_HEADER_NH, MULTI_MSG_ARRAY, shake_disclosed_ind)
assert(PROOF_GEN_MULTI_D_OUT_NO_HEADER == pg_multi_d_output_no_header)

print("Test ProofVerify")
local DISC_MSG = {MULTI_MSG_ARRAY[1], MULTI_MSG_ARRAY[3],MULTI_MSG_ARRAY[5], MULTI_MSG_ARRAY[7]}
assert( bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), pg_multi_d_output_no_header, nil, PRESENTATION_HEADER, DISC_MSG, disclosed_some_indexes) == true)

print("Test case 4: no presentation header")
--Section D.1.2.2.

local disclosed_some_indexes = {1,3,5,7}

local PROOF_GEN_MULTI_D_OUT_NO_PH = O.from_hex('853f4927bd7e4998af27df65566c0a071a33a5207d1af33ef7c3be04004ac5da860f34d35c415498af32729720ca4d92977bbbbd60fdc70ddbb2588878675b90815273c9eaf0caa1123fe5d0c4833fefc459d18e1dc83d669268ec702c0e16a6b73372346feb94ab16189d4c525652b8d3361bab43463700720ecfb0ee75e595ea1b13330615011050a0dfcffdb21af37286b5d6012208605b7c3fe5457936db502aa7eec43ae4a9d1bdf5f675153d521b1e587c6ddd195e80358667aae42e64754595a0d35c1d6e72f147f67f591c823e75340360615b9c0173445afe53002d4face239979f697eff7183826449d4dc285a15e0c6afec9289b0b39e0741d0c4925c090f722569b8c64e2829904a02ec1ab6340cfe999a59196bbb8da2be2a89ddd84378dba0a22533e76fd6ac14f2b52a3972b041950539c19debaf7454e6ef3b9cec23086dc26b8a104e319aa4394e4e376c133d6c00133daf2f414e1df8ebca2de0a23e6ba37663f8074b9c8f440e37459bc08a8a4a587b78b2102c81b2f48f0fa73c331f7b6f64f6d8d50f3f8cb1424626f9cf3171cdea7f8cedb7bbb5a269856b37e8ba16ba8604fb1681be22dc6b64827a8326691524b7c05ac462ec8d8eee64bc6e09df622bb974fba93a75f8')

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
