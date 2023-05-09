local bbs = require'crypto_bbs'

print('----------------- TEST SHA256 ------------------')

local ciphersuite = bbs.ciphersuite('sha256')

-- Key Pair
print('----------------------')
print("TEST: key pair")
local ikm = O.from_hex('746869732d49532d6a7573742d616e2d546573742d494b4d2d746f2d67656e65726174652d246528724074232d6b6579')
local key_info = O.from_hex('746869732d49532d736f6d652d6b65792d6d657461646174612d746f2d62652d757365642d696e2d746573742d6b65792d67656e')
local sk = bbs.keygen(ikm, key_info)
print("Test Case 1")
assert(sk == BIG.new(O.from_hex('4a39afffd624d69e81808b2e84385cc80bf86adadf764e030caa46c231f2a8d7')))
-- p=bbs.sk2pk(sk)
-- oct = O.from_hex('aaff983278257afc45fa9d44d156c454d716fb1a250dfed132d65b2009331f618c623c14efa16245f50cc92e60334051087f1ae92669b89690f5feb92e91568f95a8e286d110b011e9ac9923fd871238f57d1295395771331ff6edee43e4ccc6')
assert(bbs.sk2pk(sk) == O.from_hex('aaff983278257afc45fa9d44d156c454d716fb1a250dfed132d65b2009331f618c623c14efa16245f50cc92e60334051087f1ae92669b89690f5feb92e91568f95a8e286d110b011e9ac9923fd871238f57d1295395771331ff6edee43e4ccc6'))

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
local DST_MAP_MESSAGES_TO_SCALAR = O.from_string('BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_MAP_MSG_TO_SCALAR_AS_HASH_') -- '4242535f424c53313233383147315f584d443a5348412d3235365f535357555f524f5f4d41505f4d53475f544f5f5343414c41525f41535f484153485f'

local map_messages_to_scalar_messages = {
    '9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02',
    '87a8bd656d49ee07b8110e1d8fd4f1dcef6fb9bc368c492d9bc8c4f98a739ac6',
    '96012096adda3f13dd4adbe4eea481a4c4b5717932b73b00e31807d3c5894b90',
    'ac55fb33a75909edac8994829b250779298aa75d69324a365733f16c333fa943',
    'd183ddc6e2665aa4e2f088af9297b78c0d22b4290273db637ed33ff5cf703151',
    '515ae153e22aae04ad16f759e07237b43022cb1ced4c176e0999c6a8ba5817cc',
    '496694774c5604ab1b2544eababcf0f53278ff5040c1e77c811656e8220417a2',
    '77fe97eb97a1ebe2e81e4e3597a3ee740a66e9ef2412472c23364568523f8b91',
    '7372e9daa5ed31e6cd5c825eac1b855e84476a1d94932aa348e07b7320912416',
    'c344136d9ab02da4dd5908bbba913ae6f58c2cc844b802a6f811f5fb075f9b80'
}

local map_messages_to_scalar_test = {
    '0e95c55a6ba91b0ed5e9425151dca52fff8748d935e780c828ad00031b93ed7f',
    '1b8a006679df6534aca94caf0fed58234b1d7f575a2646308e6c9d5fdf4bba60',
    '0060ba23303163460a943404fa505b5e039bb11d6efd3689560cc9985094d0c2',
    '4380b070a45f309c3abed92324a15a8a6ccdc6972f9735e043e267745b50b3a0',
    '6df7849922283ab15f3dfe1b4699f33d5820acf5dede3e48e33df5e7fcf3762c',
    '0e1aa2ed096260ebd262673b5d3613c44371374849b9f3dd25c456a41f56ecc1',
    '4ceec5a33e7c25c95e6234825b013f846243f492805a81a65b242c2422b516e6',
    '05dfbcc38db8c56cd638903805a0068be05c8201afebc04926b6332f44ff46f0',
    '313750e2398ea3547d558aa8d25ad2426c8cea82d68d9f159f08c72223e1673a',
    '364dd864673c8b33ebd7a1f8a1249f5735c757f08e3c94e2265b61a019cb4bd3'
}

for k = 1, #map_messages_to_scalar_test do
    print("Test Case " .. k)
    local output_scalar = bbs.MapMessageToScalarAsHash(ciphersuite, O.from_hex(map_messages_to_scalar_messages[k]), DST_MAP_MESSAGES_TO_SCALAR)
    assert(output_scalar == BIG.new(O.from_hex(map_messages_to_scalar_test[k])), "Wrong scalar")
end

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

print('----------------------')
print("TEST: create_generators")

-- Section 7.5.2
local create_generators_test = {
    (O.from_hex('b57ec5e001c28d4063e0b6f5f0a6eee357b51b64d789a21cf18fd11e73e73577910182d421b5a61812f5d1ca751fa3f0')):zcash_topoint(),
    (O.from_hex('909573cbb9da401b89d2778e8a405fdc7d504b03f0158c31ba64cdb9b648cc35492b18e56088b44c8b4dc6310afb5e49')):zcash_topoint(),
    (O.from_hex('90248350d94fd550b472a54269e28b680757d8cbbe6bb2cb000742c07573138276884c2872a8285f4ecf10df6029be15')):zcash_topoint(),
    (O.from_hex('8fb7d5c43273a142b6fc445b76a8cdfc0f96c5fdac7cdd73314ac4f7ec4990a0a6f28e4ad97fb0a3a22efb07b386e3ff')):zcash_topoint(),
    (O.from_hex('8241e3e861aaac2a54a8d7093301143d7d3e9911c384a2331fcc232a3e64b4882498ce4d9da8904ffcbe5d6eadafc82b')):zcash_topoint(),
    (O.from_hex('99bb19d202a4019c14a36933264ae634659994076bf02a94135e1026ea309c7d3fd6da60c7929d30b656aeaba7c0dcec')):zcash_topoint(),
    (O.from_hex('81779fa5268e75a980799c0a01677a763e14ba82cbf0a66c653edc174057698636507ac58e73522a59585558dca80b42')):zcash_topoint(),
    (O.from_hex('98a3f9af71d391337bc6ae5d26980241b6317d5d71570829ce03d63c17e0d2164e1ad793645e1762bfcc049a17f5994b')):zcash_topoint(),
    (O.from_hex('aca6a84770bb1f515591b4b95d69777856ddc52d5439325839e31ce5b6237618a9bc01a04b0057d33eab14341504c7e9')):zcash_topoint(),
    (O.from_hex('b96e206d6cf32b51d2f4d543972d488a4c4cbc5d994f6ebb0bdffbc5459dcb9a8e5ab045c5949dc7eb33b0545b62aae3')):zcash_topoint(),
    (O.from_hex('8edf840b56ecf8d7c5a9c4a0aaf8a5525f3480df735743298dd2f4ae1cbb56f56ed6a04ef6fa7c92cd68d9101c7b8c8f')):zcash_topoint(),
    (O.from_hex('86d4ae04738dc082eb37e753bc8ec35a8d982e463559214d0f777599f71aa1f95780b3dccbdcae45e146e5c7623dfe7d')):zcash_topoint()
}
local count_test = 12

local function run_test_create_generators (test)
    local output_generators = bbs.create_generators(ciphersuite, count_test)
    for i = 1, count_test do
        print("Test case ".. i)
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
    local v = expand_message_xmd(SEED, O.from_string("BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_MOCK_RANDOM_SCALARS_DST_"), out_len)
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
    local v = expand_message_xof(SEED, O.from_string("BBS_BLS12381G1_XOF:SHAKE-256_SSWU_RO_MOCK_RANDOM_SCALARS_DST_"), out_len)
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
    '41b5e116922813fab50e1bcafd5a68f38c977fe4b01b3992424bc4ff1f1490bc',
    '57062c3eb0b030cbb45535bc7e8b3756288cfeee52ab6e2d1a56aedcfee668ba',
    '20a1f16c18342bc8650655783cd87b4491ce3986d0942e863d62053914bb3da1',
    '21ba43b4e1da365c6062b8cb00e3c22b0d49d68e30fae8a21ff9a476912a49ee',
    '2d34df08a57d8d7c6d3a8bdd34f45f0db539a4fc17b3e8948cb36360190248ed',
    '4840669faf2ab03e2b8a80d3ebc597cabfe35642680cec12f622daf63529be52',
    '3151326acfc6ec15b68ce67d52ce75abbe17d4224e78abb1c31f410f5664fc1a',
    '4cb74272bc2673959a3c72d992485057b1312cd8d2bf32747741324a92152c81',
    '2af0ebadecd3e43aefaafcfd3f426dca179140cdaf356a838381e584dfa0e4d1',
    '3aa6190cb2ae26ba433c3f6ff01504088cead97687f417f4bc80ac906201356c'
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

local SECRET_KEY = "4a39afffd624d69e81808b2e84385cc80bf86adadf764e030caa46c231f2a8d7"
local PUBLIC_KEY = "aaff983278257afc45fa9d44d156c454d716fb1a250dfed132d65b2009331f618c623c14efa16245f50cc92e60334051087f1ae92669b89690f5feb92e91568f95a8e286d110b011e9ac9923fd871238f57d1295395771331ff6edee43e4ccc6"
local HEADER = "11223344556677889900aabbccddeeff"
local SINGLE_MSG_ARRAY = { O.from_hex("9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02") }
local VALID_SIGNATURE = "8fb17415378ec4462bc167be75583989e0528913da142239848ae88309805bfb3656bcff322e5d8fd1a7e40a660a62266099f27fa81ff5010443f36285f6f0758e4d701c444b20447cded906a3f2001714087f165f760369b901ccbe5173438b32ad195b005e2747492cf002cf51e498"

-- FROM trinsic-id / bbs BRANCH update result.
-- 0x8fb17415378ec4462bc167be75583989e0528913da142239848ae88309805bfb3656bcff322e5d8fd1a7e40a660a62266099f27fa81ff5010443f36285f6f0758e4d701c444b20447cded906a3f2001714087f165f760369b901ccbe5173438b32ad195b005e2747492cf002cf51e498

local output_signature = bbs.sign(ciphersuite, BIG.new(O.from_hex(SECRET_KEY)), O.from_hex(PUBLIC_KEY), SINGLE_MSG_ARRAY, O.from_hex(HEADER))
assert(output_signature == O.from_hex(VALID_SIGNATURE))
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), output_signature, SINGLE_MSG_ARRAY, O.from_hex(HEADER)) == true)

print("Test case 2")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.1
local MODIFIED_MSG_ARR = { O.from_hex("c344136d9ab02da4dd5908bbba913ae6f58c2cc844b802a6f811f5fb075f9b80") }

assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), O.from_hex(VALID_SIGNATURE), MODIFIED_MSG_ARR, O.from_hex(HEADER)) == false)
-- RETURNS AN ERROR: fail signature validation due to the message value being different from what was signed.

print("Test case 3")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.2
local TWO_MESSAGES = {
    O.from_hex('9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02'),
    O.from_hex('87a8bd656d49ee07b8110e1d8fd4f1dcef6fb9bc368c492d9bc8c4f98a739ac6')
}

assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), O.from_hex(VALID_SIGNATURE),  TWO_MESSAGES, O.from_hex(HEADER)) == false)
-- fails signature validation due to an additional message being supplied that was not signed

print('----------------------')
print("TEST: Single message proof SHA 256")
print("Test case 1")

local PRESENTATION_HEADER = O.from_hex("bed231d880675ed101ead304512e043ade9958dd0241ea70b4b3957fba941501")

local PROOF_GEN_OUT = O.from_hex('99b6215be8357400353057b57b440e3998c259d34bce12e1d24dc7f9b63762122d4144cacefc5f3231172308907e3f2c8cf98d238dccf7e1eecf66441f27a7e140fc1a11788f24c634c5e4e6675c904670be71cdd44e613d1436f6badc4d9f31b6b575ab7a165dd120bb97d2b5a481f43e202477fdf5798af07c6ee639c80b3ec83c727cbe4a98da6c2966489524c26e3d84d7985370e3628271ec8cf5dafcb0e39de2d90f6fcdd2b72f2793e6cb985f60143f2a320e875036b5a0bb85e8548b531f2b60f3f9ed5b3d490eecd9ae44916098e8f293efeeeffe51ed4cac07bb46677b65f7de0ab3096f5ab39b4bcc187d25a14520bbf0cfe1c861bda63e0afdd2c030e4862b52cdaee5d6d9ace784493a576d96a3e0b29205aeaa2fea8bd5888eead49c7b06bba9c7d642260887756cd7')

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
    MULTI_MSG_ARRAY[i] = O.from_hex(map_messages_to_scalar_messages[i])
end

local VALID_MULTI_SIGNATURE = O.from_hex("b058678021dba2313c65fadc469eb4f030264719e40fb93bbf68bdf79079317a0a36193288b7dcb983fae0bc3e4c077f145f99a66794c5d0510cb0e12c0441830817822ad4ba74068eb7f34eb11ce3ee606d86160fecd844dda9d04bed759a676b0c8868d3f97fbe2e8b574169bd73a3")

local output_multi_signature = bbs.sign(ciphersuite, BIG.new(O.from_hex(SECRET_KEY)), O.from_hex(PUBLIC_KEY), MULTI_MSG_ARRAY, O.from_hex(HEADER))
assert( output_multi_signature == VALID_MULTI_SIGNATURE)
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), output_multi_signature, MULTI_MSG_ARRAY, O.from_hex(HEADER)) == true)

print("Test case 2")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.3
assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, TWO_MESSAGES, O.from_hex(HEADER)) == false)
-- fail signature validation due to missing messages that were originally present during the signing.

print("Test case 3")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.4
local REORDERED_MSGS = {
    O.from_hex('c344136d9ab02da4dd5908bbba913ae6f58c2cc844b802a6f811f5fb075f9b80'),
    O.from_hex('7372e9daa5ed31e6cd5c825eac1b855e84476a1d94932aa348e07b7320912416'),
    O.from_hex('77fe97eb97a1ebe2e81e4e3597a3ee740a66e9ef2412472c23364568523f8b91'),
    O.from_hex('496694774c5604ab1b2544eababcf0f53278ff5040c1e77c811656e8220417a2'),
    O.from_hex('515ae153e22aae04ad16f759e07237b43022cb1ced4c176e0999c6a8ba5817cc'),
    O.from_hex('d183ddc6e2665aa4e2f088af9297b78c0d22b4290273db637ed33ff5cf703151'),
    O.from_hex('ac55fb33a75909edac8994829b250779298aa75d69324a365733f16c333fa943'),
    O.from_hex('96012096adda3f13dd4adbe4eea481a4c4b5717932b73b00e31807d3c5894b90'),
    O.from_hex('87a8bd656d49ee07b8110e1d8fd4f1dcef6fb9bc368c492d9bc8c4f98a739ac6'),
    O.from_hex('9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02')
}

assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, REORDERED_MSGS, O.from_hex(HEADER)) == false)
-- fails signature validation due to messages being re-ordered from the order in which they were signed.

print("Test case 4")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.5 (WRONG SENTENCES THOUGH)
assert(bbs.verify(ciphersuite, bbs.sk2pk(bbs.keygen(O.from_hex('0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b'))), VALID_MULTI_SIGNATURE, MULTI_MSG_ARRAY, O.from_hex(HEADER)) == false)
-- fails signature validation due to public key used to verify is incorrect.

print("Test case 5")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.6
local WRONG_HEADER = 'ffeeddccbbaa00998877665544332211'

assert(bbs.verify(ciphersuite, O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, MULTI_MSG_ARRAY, O.from_hex(WRONG_HEADER)) == false)
-- fails signature validation due to header value being modified from what was originally signed.

print('----------------------')
print("TEST: Valid multi message proof SHA 256")
print("Test case 1 : disclose all messages")

local DISCLOSED_INDEXES = {1,2,3,4,5,6,7,8,9,10}

local PROOF_GEN_MULTI_OUT = O.from_hex('b95e27fc635eeb7e47bf2e488fca4b3f8930bb2f6343bf0c9d585abd8b8112160a540566417bac3c77ad40ff7d00cc4a85f5a98a9f1f1e57d4c1444830c5493108b393a2b309c4980071f71eda6fc84ce0432443d463b47fbcf0841be0f1e472b031e2564cd615d89e9e7ed344c7f87bddebe02ed8cd77dd91a06b0d2119f47a00220164e49117d5b3ee3c009f5e537b66502ea4435cb042ddea1e0fc4e9688f81b0568917205481eccef5443e4f45f33043eb3e70a442dce23c4247e8f0804b2396ead74bd44977f6425d02db3fc20860a4fa9531c98fb443f8cd9062dc90c4c2917a39f58cbce7c7a5dcff72b1afa35e6d0651a3968a5d6589967a601142e7a8085b9dfbb2335adb89ece7411e64812672bf715352c24e3c0c35796e7ae667ec8244b994324fcb928dc1288ffe6594')

local pg_multi_output = bbs.proof_gen(ciphersuite, O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, O.from_hex(HEADER), PRESENTATION_HEADER, MULTI_MSG_ARRAY, DISCLOSED_INDEXES)

assert(PROOF_GEN_MULTI_OUT == pg_multi_output)

print("Test ProofVerify")

assert( bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), pg_multi_output, O.from_hex(HEADER), PRESENTATION_HEADER, MULTI_MSG_ARRAY, DISCLOSED_INDEXES ) == true)

print("Test case 2 : disclose some messages")
--disclosed (messages in index 0, 2, 4 and 6, in that order)

local disclosed_some_indexes = {1,3,5,7}

local PROOF_GEN_MULTI_D_OUT = O.from_hex('8ee5a0c7fc62e6058bfac10b1489cb872283faee59c4132a076f01660eb3f28dd03fcf44fb8dadf8794e314a33b6b84cb95bfd630da6fe9f10b818b51f205d08143ea55bc05f6ad85a332b2acb3567c9134aeb29b9fa1e26ba8db63f956949ff846e9ff2cccfee820c4ffaf1aaa161cf04af8b7f27bede66c42f18c9289007972f0f0230f4cda28beb5885aa71bcbe9b27d4dca32aae82f02961e982bb7f50483924087180f9ca76efdd1b3534b5b393614b51070a6f5d088fb464ccb2d296ccb69e31ef0f84d25f286186a6ab36ce4a257eacf0c7e3ad362ae00738d876999f44228c085ffd0a97961280c05113ed21075115770819d9afbcb40d4fae6c40e3d66a324637d3b1b79e5abd86fb3a1a8d3404ffa0019cacdf988f065009fe8bb27fd99e804ab679c96fe559bbf2e3a95b2183b54eb4238c4a268e04c51036dd24139c6d001698614484d285e55e3911af18af4fc1b241f2f168565ffa74dc082aaf15d7b82cc598896ad34efe960bbcb06cea9ee551d65080cae87181e50463b9348cbfb05f5242174197b3d34efa56f513fc11cb31591d199e61af4f46bcbcca67d46cd16e2ec83694767780e0c8ccbc70d7fc61c0bda6209e22d17049e90e61c940104ca0cc69310393dc14b6c2b512219257782c19e185e3bbc85cfe0bc432a91082fd148044fbd14092702bd39e81')

local pg_multi_d_output = bbs.proof_gen(ciphersuite, O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, O.from_hex(HEADER), PRESENTATION_HEADER, MULTI_MSG_ARRAY, disclosed_some_indexes)

assert(PROOF_GEN_MULTI_D_OUT == pg_multi_d_output)

print("Test ProofVerify")
local DISC_MSG = {MULTI_MSG_ARRAY[1], MULTI_MSG_ARRAY[3],MULTI_MSG_ARRAY[5], MULTI_MSG_ARRAY[7]}
assert( bbs.proof_verify(ciphersuite, O.from_hex(PUBLIC_KEY), pg_multi_d_output, O.from_hex(HEADER), PRESENTATION_HEADER, DISC_MSG, disclosed_some_indexes) == true)

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
        assert(output_generators[i] == (O.from_hex(test[i])):zcash_topoint())
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


