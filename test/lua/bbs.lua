local bbs = require'crypto_bbs'

bbs.init('sha256')

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
    local output_u = bbs.hash_to_field_m1_c2(O.from_string(test.msg), O.from_string(DST_hash_to_field))
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
    local output_P = bbs.hash_to_curve(O.from_string(test.msg), O.from_string(DST_hash_to_field))
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
    local output_scalar = bbs.MapMessageToScalarAsHash(O.from_hex(map_messages_to_scalar_messages[k]), DST_MAP_MESSAGES_TO_SCALAR)
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
assert(bbs.MapMessageToScalarAsHash(O.from_hex(INPUT_MSG_BBS_SHA_256), O.from_hex(DEFAULT_DST_HASH_TO_SCALAR)) == BIG.new(O.from_hex(BBS_SHA_256_H2S_TEST)))

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
    local output_generators = bbs.create_generators(count_test)
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
    local r = BIG.new(O.from_hex('73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001'))

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
    local r = BIG.new(O.from_hex('73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001'))

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
local SINGLE_MSG_ARRAY = { bbs.MapMessageToScalarAsHash(O.from_hex("9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02")) }
local VALID_SIGNATURE = "8fb17415378ec4462bc167be75583989e0528913da142239848ae88309805bfb3656bcff322e5d8fd1a7e40a660a62266099f27fa81ff5010443f36285f6f0758e4d701c444b20447cded906a3f2001714087f165f760369b901ccbe5173438b32ad195b005e2747492cf002cf51e498"

-- FROM trinsic-id / bbs BRANCH update result.
-- 0x8fb17415378ec4462bc167be75583989e0528913da142239848ae88309805bfb3656bcff322e5d8fd1a7e40a660a62266099f27fa81ff5010443f36285f6f0758e4d701c444b20447cded906a3f2001714087f165f760369b901ccbe5173438b32ad195b005e2747492cf002cf51e498

local output_signature = bbs.sign( BIG.new(O.from_hex(SECRET_KEY)), O.from_hex(PUBLIC_KEY), O.from_hex(HEADER), SINGLE_MSG_ARRAY)
assert(output_signature == O.from_hex(VALID_SIGNATURE))
assert(bbs.verify(O.from_hex(PUBLIC_KEY), output_signature, O.from_hex(HEADER), SINGLE_MSG_ARRAY) == true)

print("Test case 2")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.1
local MODIFIED_MSG_ARR = { bbs.MapMessageToScalarAsHash(O.from_hex("c344136d9ab02da4dd5908bbba913ae6f58c2cc844b802a6f811f5fb075f9b80"))
}

assert(bbs.verify(O.from_hex(PUBLIC_KEY), O.from_hex(VALID_SIGNATURE), O.from_hex(HEADER), MODIFIED_MSG_ARR) == false)
-- RETURNS AN ERROR: fail signature validation due to the message value being different from what was signed.

print("Test case 3")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.2
local TWO_MESSAGES = {
    bbs.MapMessageToScalarAsHash(O.from_hex('9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02')),
    bbs.MapMessageToScalarAsHash(O.from_hex('87a8bd656d49ee07b8110e1d8fd4f1dcef6fb9bc368c492d9bc8c4f98a739ac6'))
}

assert(bbs.verify(O.from_hex(PUBLIC_KEY), O.from_hex(VALID_SIGNATURE), O.from_hex(HEADER), TWO_MESSAGES) == false)
-- fails signature validation due to an additional message being supplied that was not signed

print('----------------------')
print("TEST: Single message proof SHA 256")
print("Test case 1")

local PRESENTATION_HEADER = O.from_hex("bed231d880675ed101ead304512e043ade9958dd0241ea70b4b3957fba941501")

local PROOF_GEN_OUT = O.from_hex('99b6215be8357400353057b57b440e3998c259d34bce12e1d24dc7f9b63762122d4144cacefc5f3231172308907e3f2c8cf98d238dccf7e1eecf66441f27a7e140fc1a11788f24c634c5e4e6675c904670be71cdd44e613d1436f6badc4d9f31b6b575ab7a165dd120bb97d2b5a481f43e202477fdf5798af07c6ee639c80b3ec83c727cbe4a98da6c2966489524c26e3d84d7985370e3628271ec8cf5dafcb0e39de2d90f6fcdd2b72f2793e6cb985f60143f2a320e875036b5a0bb85e8548b531f2b60f3f9ed5b3d490eecd9ae44916098e8f293efeeeffe51ed4cac07bb46677b65f7de0ab3096f5ab39b4bcc187d25a14520bbf0cfe1c861bda63e0afdd2c030e4862b52cdaee5d6d9ace784493a576d96a3e0b29205aeaa2fea8bd5888eead49c7b06bba9c7d642260887756cd7')

--con PH empty
--local PROOF_GEN_OUT = O.from_hex('99b6215be8357400353057b57b440e3998c259d34bce12e1d24dc7f9b63762122d4144cacefc5f3231172308907e3f2c8cf98d238dccf7e1eecf66441f27a7e140fc1a11788f24c634c5e4e6675c904670be71cdd44e613d1436f6badc4d9f319380b42122f33e956e861ad5e01d1bb2355015cd3d510f9636a1a746f496142a709f9d4914cdaffdf1ca936e12244e4850c9bdb7570028bb16233a92c0c4af229e528b4074fba2266dfd3023ee622b0832e92251e1b29d356111cb50cffae36c88b11baaaceb02553b5dcd6b348eb88370c8d06c93b3b56f91d1c3d7969f732d1ffc7620c68936f2d0e04b515dda8e41661706b3f851e51d154a8efbd036acee9b5cbbfec266d45acd5fd9f2fe47c54b15b0e30ba2e0e26bae6228ffdb499beea962ec564dabc3010e6f4021340ad77b')

local pg_output = bbs.ProofGen(O.from_hex(PUBLIC_KEY), O.from_hex(VALID_SIGNATURE), O.from_hex(HEADER), PRESENTATION_HEADER, SINGLE_MSG_ARRAY, {1})

assert(PROOF_GEN_OUT == pg_output)

print("Test case 1 ProofVerify")

assert( bbs.ProofVerify(O.from_hex(PUBLIC_KEY), pg_output, O.from_hex(HEADER), PRESENTATION_HEADER, SINGLE_MSG_ARRAY, {1}) == true)


print("Test case 2 ProofVerify")
assert( bbs.ProofVerify(O.from_hex(PUBLIC_KEY), pg_output, O.from_hex(HEADER), PRESENTATION_HEADER, MODIFIED_MSG_ARR, {1}) == false)
-- Fails because of wrong message as input.

print("Test case 3 ProofVerify")
assert( bbs.ProofVerify(O.from_hex(PUBLIC_KEY), pg_output, O.from_hex(HEADER), PRESENTATION_HEADER, TWO_MESSAGES, {1,2}) == false)
-- Fails because of wrong messages as input.

print('----------------------')
print("TEST: multi message signature SHA 256")
print("Test case 1")

local MULTI_MSG_ARRAY = { }

for i = 1, 10 do
    MULTI_MSG_ARRAY[i] = BIG.new(O.from_hex(map_messages_to_scalar_test[i]))
end

local VALID_MULTI_SIGNATURE = O.from_hex("b058678021dba2313c65fadc469eb4f030264719e40fb93bbf68bdf79079317a0a36193288b7dcb983fae0bc3e4c077f145f99a66794c5d0510cb0e12c0441830817822ad4ba74068eb7f34eb11ce3ee606d86160fecd844dda9d04bed759a676b0c8868d3f97fbe2e8b574169bd73a3")

local output_multi_signature = bbs.sign( BIG.new(O.from_hex(SECRET_KEY)), O.from_hex(PUBLIC_KEY), O.from_hex(HEADER), MULTI_MSG_ARRAY)
assert( output_multi_signature == VALID_MULTI_SIGNATURE)
assert(bbs.verify(O.from_hex(PUBLIC_KEY), output_multi_signature, O.from_hex(HEADER), MULTI_MSG_ARRAY) == true)

print("Test case 2")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.3
assert(bbs.verify(O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, O.from_hex(HEADER), TWO_MESSAGES) == false)
-- fail signature validation due to missing messages that were originally present during the signing.

print("Test case 3")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.4
local REORDERED_MSGS = {
    bbs.MapMessageToScalarAsHash(O.from_hex('c344136d9ab02da4dd5908bbba913ae6f58c2cc844b802a6f811f5fb075f9b80')),
    bbs.MapMessageToScalarAsHash(O.from_hex('7372e9daa5ed31e6cd5c825eac1b855e84476a1d94932aa348e07b7320912416')),
    bbs.MapMessageToScalarAsHash(O.from_hex('77fe97eb97a1ebe2e81e4e3597a3ee740a66e9ef2412472c23364568523f8b91')),
    bbs.MapMessageToScalarAsHash(O.from_hex('496694774c5604ab1b2544eababcf0f53278ff5040c1e77c811656e8220417a2')),
    bbs.MapMessageToScalarAsHash(O.from_hex('515ae153e22aae04ad16f759e07237b43022cb1ced4c176e0999c6a8ba5817cc')),
    bbs.MapMessageToScalarAsHash(O.from_hex('d183ddc6e2665aa4e2f088af9297b78c0d22b4290273db637ed33ff5cf703151')),
    bbs.MapMessageToScalarAsHash(O.from_hex('ac55fb33a75909edac8994829b250779298aa75d69324a365733f16c333fa943')),
    bbs.MapMessageToScalarAsHash(O.from_hex('96012096adda3f13dd4adbe4eea481a4c4b5717932b73b00e31807d3c5894b90')),
    bbs.MapMessageToScalarAsHash(O.from_hex('87a8bd656d49ee07b8110e1d8fd4f1dcef6fb9bc368c492d9bc8c4f98a739ac6')),
    bbs.MapMessageToScalarAsHash(O.from_hex('9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02'))
}

assert(bbs.verify(O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, O.from_hex(HEADER), REORDERED_MSGS) == false)
-- fails signature validation due to messages being re-ordered from the order in which they were signed.

print("Test case 4")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.5 (WRONG SENTENCES THOUGH)
assert(bbs.verify(bbs.sk2pk(bbs.keygen(O.from_hex('0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b'))), VALID_MULTI_SIGNATURE, O.from_hex(HEADER), MULTI_MSG_ARRAY) == false)
-- fails signature validation due to public key used to verify is incorrect.
--]]

print("Test case 5")
-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.6
local WRONG_HEADER = 'ffeeddccbbaa00998877665544332211'

assert(bbs.verify(O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, O.from_hex(WRONG_HEADER), MULTI_MSG_ARRAY) == false)
-- fails signature validation due to header value being modified from what was originally signed.

print('----------------------')
print("TEST: Valid multi message proof SHA 256")
print("Test case 1 : disclose all messages")

local DISCLOSED_INDEXES = {1,2,3,4,5,6,7,8,9,10}

local PROOF_GEN_MULTI_OUT = O.from_hex('b95e27fc635eeb7e47bf2e488fca4b3f8930bb2f6343bf0c9d585abd8b8112160a540566417bac3c77ad40ff7d00cc4a85f5a98a9f1f1e57d4c1444830c5493108b393a2b309c4980071f71eda6fc84ce0432443d463b47fbcf0841be0f1e472b031e2564cd615d89e9e7ed344c7f87bddebe02ed8cd77dd91a06b0d2119f47a00220164e49117d5b3ee3c009f5e537b66502ea4435cb042ddea1e0fc4e9688f81b0568917205481eccef5443e4f45f33043eb3e70a442dce23c4247e8f0804b2396ead74bd44977f6425d02db3fc20860a4fa9531c98fb443f8cd9062dc90c4c2917a39f58cbce7c7a5dcff72b1afa35e6d0651a3968a5d6589967a601142e7a8085b9dfbb2335adb89ece7411e64812672bf715352c24e3c0c35796e7ae667ec8244b994324fcb928dc1288ffe6594')

local pg_multi_output = bbs.ProofGen(O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, O.from_hex(HEADER), PRESENTATION_HEADER, MULTI_MSG_ARRAY, DISCLOSED_INDEXES)

assert(PROOF_GEN_MULTI_OUT == pg_multi_output)

print("Test ProofVerify")

assert( bbs.ProofVerify(O.from_hex(PUBLIC_KEY), pg_multi_output, O.from_hex(HEADER), PRESENTATION_HEADER, MULTI_MSG_ARRAY, DISCLOSED_INDEXES ) == true)

print("Test case 2 : disclose some messages")
--disclosed (messages in index 0, 2, 4 and 6, in that order)

local disclosed_some_indexes = {1,3,5,7}

local PROOF_GEN_MULTI_D_OUT = O.from_hex('8ee5a0c7fc62e6058bfac10b1489cb872283faee59c4132a076f01660eb3f28dd03fcf44fb8dadf8794e314a33b6b84cb95bfd630da6fe9f10b818b51f205d08143ea55bc05f6ad85a332b2acb3567c9134aeb29b9fa1e26ba8db63f956949ff846e9ff2cccfee820c4ffaf1aaa161cf04af8b7f27bede66c42f18c9289007972f0f0230f4cda28beb5885aa71bcbe9b27d4dca32aae82f02961e982bb7f50483924087180f9ca76efdd1b3534b5b393614b51070a6f5d088fb464ccb2d296ccb69e31ef0f84d25f286186a6ab36ce4a257eacf0c7e3ad362ae00738d876999f44228c085ffd0a97961280c05113ed21075115770819d9afbcb40d4fae6c40e3d66a324637d3b1b79e5abd86fb3a1a8d3404ffa0019cacdf988f065009fe8bb27fd99e804ab679c96fe559bbf2e3a95b2183b54eb4238c4a268e04c51036dd24139c6d001698614484d285e55e3911af18af4fc1b241f2f168565ffa74dc082aaf15d7b82cc598896ad34efe960bbcb06cea9ee551d65080cae87181e50463b9348cbfb05f5242174197b3d34efa56f513fc11cb31591d199e61af4f46bcbcca67d46cd16e2ec83694767780e0c8ccbc70d7fc61c0bda6209e22d17049e90e61c940104ca0cc69310393dc14b6c2b512219257782c19e185e3bbc85cfe0bc432a91082fd148044fbd14092702bd39e81')

local pg_multi_d_output = bbs.ProofGen(O.from_hex(PUBLIC_KEY), VALID_MULTI_SIGNATURE, O.from_hex(HEADER), PRESENTATION_HEADER, MULTI_MSG_ARRAY, disclosed_some_indexes)

assert(PROOF_GEN_MULTI_D_OUT == pg_multi_d_output)

print("Test ProofVerify")
local DISC_MSG = {MULTI_MSG_ARRAY[1], MULTI_MSG_ARRAY[3],MULTI_MSG_ARRAY[5], MULTI_MSG_ARRAY[7]}
assert( bbs.ProofVerify(O.from_hex(PUBLIC_KEY), pg_multi_d_output, O.from_hex(HEADER), PRESENTATION_HEADER, DISC_MSG, disclosed_some_indexes) == true)


bbs.calculate_random_scalars = seeded_random_scalars_xof

bbs.calculate_random_scalars = old_random

print('----------------------')
print("TEST: ProofGen is random")
I.spy(bbs.ProofGen(O.from_hex(PUBLIC_KEY), O.from_hex(VALID_SIGNATURE), O.from_hex(HEADER), PRESENTATION_HEADER, SINGLE_MSG_ARRAY, {1}))
I.spy(bbs.ProofGen(O.from_hex(PUBLIC_KEY), O.from_hex(VALID_SIGNATURE), O.from_hex(HEADER), PRESENTATION_HEADER, SINGLE_MSG_ARRAY, {1}))

bbs.destroy()
