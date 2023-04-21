bbs = require'crypto_bbs'
hkdf_tests = {
    {
        ikm='0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b',
        salt='000102030405060708090a0b0c',
        info='f0f1f2f3f4f5f6f7f8f9',
        l=42,

        prk='077709362c2e32df0ddc3f0dc47bba6390b6c73bb50f9c3122ec844ad7c2b3e5',
        okm='3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865'
    },
    {
        ikm='000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f',
        salt='606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeaf',
        info='b0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff',
        l=82,

        prk='06a6b88c5853361a06104c9ceb35b45cef760014904671014a193f40c15fc244',
        okm='b11e398dc80327a1c8e7f78c596a49344f012eda2d4efad8a050cc4c19afa97c59045a99cac7827271cb41c65e590e09da3275600c2f09b8367793a9aca3db71cc30c58179ec3e87c14c01d5c1f3434f1d87'
    },
    {
        ikm='0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b',
        salt=O.empty(),
        info=O.empty(),
        l=42,

        prk='19ef24a32c717b167f33a91d6f648bdf96596776afdb6377ac434c1c293ccb04',
        okm='8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d9d201395faa4b61a96c8'
    },
}

local function run_test_hkdf(test)
    if type(test.salt) == 'string' then
        test.salt = O.from_hex(test.salt)
    end
    if type(test.info) == 'string' then
        test.info = O.from_hex(test.info)
    end
    prk = bbs.hkdf_extract(test.salt, O.from_hex(test.ikm))
    assert(O.from_hex(test.prk) == prk)
    okm = bbs.hkdf_expand(prk, test.info, test.l)
    assert(O.from_hex(test.okm) == okm)
end

print('----------------------')
print("TEST: hkdf (extract + expand)")
for k,v in pairs(hkdf_tests) do
    print("Test Case " .. k)
    run_test_hkdf(v)
end

-- Key Pair
local ikm = O.from_hex('746869732d49532d6a7573742d616e2d546573742d494b4d2d746f2d67656e65726174652d246528724074232d6b6579')
local key_info = O.from_hex('746869732d49532d736f6d652d6b65792d6d657461646174612d746f2d62652d757365642d696e2d746573742d6b65792d67656e')
local sk = bbs.keygen(ikm, key_info)
assert(sk == BIG.new(O.from_hex('4a39afffd624d69e81808b2e84385cc80bf86adadf764e030caa46c231f2a8d7')))
p=bbs.sk2pk(sk)

oct = O.from_hex('aaff983278257afc45fa9d44d156c454d716fb1a250dfed132d65b2009331f618c623c14efa16245f50cc92e60334051087f1ae92669b89690f5feb92e91568f95a8e286d110b011e9ac9923fd871238f57d1295395771331ff6edee43e4ccc6')
assert(bbs.sk2pk(sk) == ECP2.zcash_import(O.from_hex('aaff983278257afc45fa9d44d156c454d716fb1a250dfed132d65b2009331f618c623c14efa16245f50cc92e60334051087f1ae92669b89690f5feb92e91568f95a8e286d110b011e9ac9923fd871238f57d1295395771331ff6edee43e4ccc6')))

-- expand_message_xmd(SHA-256)
local DST_test = 'QUUX-V01-CS02-with-expander-SHA256-128'

-- Test vectors originated from:
-- draft-irtf-cfrg-hash-to-curve, Appendix K.1
local expand_message_xmd_SHA_256_test = {
    {
      msg     = '',
      len_in_bytes = '0x20',
      DST_prime = '515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826', 
      msg_prime = '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
      uniform_bytes = '68a985b87eb6b46952128911f2a4412bbc302a9d759667f87f7a21d803f07235'
    },
    {
        msg  = 'abc',
        len_in_bytes = '0x20',
        DST_prime = '515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
        msg_prime = '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000616263002000515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
        uniform_bytes = 'd8ccab23b5985ccea865c6c97b6e5b8350e794e603b4b97902f53a8a0d605615',
    },
    {    
        msg  = 'abcdef0123456789',
        len_in_bytes = '0x20',
        DST_prime = '515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
        msg_prime = '0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000061626364656630313233343536373839002000515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
        uniform_bytes = 'eff31487c770a893cfb36f912fbfcbff40d5661771ca4b2cb4eafe524333f5c1'
    },
    {
        msg  = 'q128_qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq',
        len_in_bytes = '0x20',
        DST_prime = '515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
        msg_prime = '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000713132385f7171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171002000515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
        uniform_bytes = 'b23a1d2b4d97b2ef7785562a7e8bac7eed54ed6e97e29aa51bfe3f12ddad1ff9'
    },
    {
        msg  = 'a512_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        len_in_bytes = '0x20',
        DST_prime = '515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
        msg_prime = '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000613531325f6161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161002000515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
        uniform_bytes = '4623227bcc01293b8c130bf771da8c298dede7383243dc0993d2d94823958c4c'
    },
    {
        msg  = '',
        len_in_bytes = '0x80',
        DST_prime = '515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
        msg_prime = '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
        uniform_bytes = 'af84c27ccfd45d41914fdff5df25293e221afc53d8ad2ac06d5e3e29485dadbee0d121587713a3e0dd4d5e69e93eb7cd4f5df4cd103e188cf60cb02edc3edf18eda8576c412b18ffb658e3dd6ec849469b979d444cf7b26911a08e63cf31f9dcc541708d3491184472c2c29bb749d4286b004ceb5ee6b9a7fa5b646c993f0ced'
    },
    {
msg     = 'abc',
len_in_bytes = '0x80',
DST_prime = '515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
msg_prime = '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000616263008000515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
uniform_bytes = 'abba86a6129e366fc877aab32fc4ffc70120d8996c88aee2fe4b32d6c7b6437a647e6c3163d40b76a73cf6a5674ef1d890f95b664ee0afa5359a5c4e07985635bbecbac65d747d3d2da7ec2b8221b17b0ca9dc8a1ac1c07ea6a1e60583e2cb00058e77b7b72a298425cd1b941ad4ec65e8afc50303a22c0f99b0509b4c895f40'
    },
    {
msg     = 'abcdef0123456789',
len_in_bytes = '0x80',
DST_prime = '515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
msg_prime = '0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000061626364656630313233343536373839008000515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
uniform_bytes = 'ef904a29bffc4cf9ee82832451c946ac3c8f8058ae97d8d629831a74c6572bd9ebd0df635cd1f208e2038e760c4994984ce73f0d55ea9f22af83ba4734569d4bc95e18350f740c07eef653cbb9f87910d833751825f0ebefa1abe5420bb52be14cf489b37fe1a72f7de2d10be453b2c9d9eb20c7e3f6edc5a60629178d9478df'
    },
    {
msg  = 'q128_qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq',
len_in_bytes = '0x80',
DST_prime = '515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
msg_prime = '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000713132385f7171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171008000515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
uniform_bytes = '80be107d0884f0d881bb460322f0443d38bd222db8bd0b0a5312a6fedb49c1bbd88fd75d8b9a09486c60123dfa1d73c1cc3169761b17476d3c6b7cbbd727acd0e2c942f4dd96ae3da5de368d26b32286e32de7e5a8cb2949f866a0b80c58116b29fa7fabb3ea7d520ee603e0c25bcaf0b9a5e92ec6a1fe4e0391d1cdbce8c68a'

    },
    {
msg     = 'a512_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
len_in_bytes = '0x80',
DST_prime = '515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
msg_prime = '00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000613531325f6161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161008000515555582d5630312d435330322d776974682d657870616e6465722d5348413235362d31323826',
uniform_bytes = '546aff5444b5b79aa6148bd81728704c32decb73a3ba76e9e75885cad9def1d06d6792f8a7d12794e90efed817d96920d728896a4510864370c207f99bd4a608ea121700ef01ed879745ee3e4ceef777eda6d9e5e38b90c86ea6fb0b36504ba4a45d22e86f6db5dd43d98a294bebb9125d5b794e9d2a81181066eb954966a487'
    }

}

local function run_test_expand_message_xmd_SHA_256 (test)
    local output_bytes, output_DST, output_msg = bbs.expand_message_xmd(O.from_string(test.msg), O.from_string(DST_test), tonumber(test.len_in_bytes))
    assert(output_bytes:hex() == test.uniform_bytes, "Wrong output bytes")
    assert(output_DST:hex() == test.DST_prime, "Wrong dst prime")
    assert(output_msg:hex() == test.msg_prime, "Wrong msg_prime")
end

print('----------------------')
print("TEST: expand_message_xmd (SHA-256)")
for k,v in pairs(expand_message_xmd_SHA_256_test) do
    print("Test Case " .. k)
    run_test_expand_message_xmd_SHA_256(v)
end



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

local function run_test_hash_to_field_m1_c2 (test)
    local output_u = bbs.hash_to_field_m1_c2(O.from_string(test.msg), O.from_string(DST_hash_to_field))
    assert(output_u[1] == BIG.new(O.from_hex(test.u_0)), "Wrong u_0")
    assert(output_u[2] == BIG.new(O.from_hex(test.u_1)), "Wrong u_1")
end

print('----------------------')
print("TEST: hash_to_field_m1_c2")
for k,v in pairs(hash_to_curve_test) do
    print("Test Case " .. k)
    run_test_hash_to_field_m1_c2(v)
end 

local function run_test_map_to_curve (test)
    local output_Q0 = bbs.map_to_curve(BIG.new(O.from_hex(test.u_0)))
    local output_Q1 = bbs.map_to_curve(BIG.new(O.from_hex(test.u_1)))
    assert(output_Q0:x() == BIG.new(O.from_hex(test.Q0_x)), "Wrong Q0_x")
    assert(output_Q0:y() == BIG.new(O.from_hex(test.Q0_y)), "Wrong Q0_y")
    assert(output_Q1:x() == BIG.new(O.from_hex(test.Q1_x)), "Wrong Q1_x")
    assert(output_Q1:y() == BIG.new(O.from_hex(test.Q1_y)), "Wrong Q1_y")
end

print('----------------------')
print("TEST: map_to_curve")
for k,v in pairs(hash_to_curve_test) do
    print("Test Case " .. k)
    run_test_map_to_curve(v)
end

local function run_test_hash_to_curve (test)
    local output_P = bbs.hash_to_curve(O.from_string(test.msg), O.from_string(DST_hash_to_field))
    assert(output_P:x() == BIG.new(O.from_hex(test.P_x)), "Wrong P_x")
    assert(output_P:y() == BIG.new(O.from_hex(test.P_y)), "Wrong P_y")
end

print('----------------------')
print("TEST: hash_to_curve (and clear_cofactor)")
for k,v in pairs(hash_to_curve_test) do
    print("Test Case " .. k)
    run_test_hash_to_curve(v)
end

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


print('----------------------')
print("TEST: MapMessageToScalarAsHash")
for k = 1, #map_messages_to_scalar_test do
    print("Test Case " .. k)
    local output_scalar = bbs.MapMessageToScalarAsHash(O.from_hex(map_messages_to_scalar_messages[k]), DST_MAP_MESSAGES_TO_SCALAR)
    assert(output_scalar == BIG.new(O.from_hex(map_messages_to_scalar_test[k])), "Wrong scalar")
end





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
local generator_seed_test = O.from_string("BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_MESSAGE_GENERATOR_SEED")
local seed_dst_test = O.from_string("BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_SIG_GENERATOR_SEED_")
local generator_dst_test = O.from_string("BBS_BLS12381G1_XMD:SHA-256_SSWU_RO_SIG_GENERATOR_DST_")

local function run_test_create_generators (test)
    local output_generators = bbs.create_generators(count_test, generator_seed_test, seed_dst_test, generator_dst_test)
    for i = 1, count_test do
        print("Test case ".. i)
        assert(output_generators[i] == test[i])
    end
end

print('----------------------')
print("TEST: create_generators")

run_test_create_generators(create_generators_test)


local SECRET_KEY = "4a39afffd624d69e81808b2e84385cc80bf86adadf764e030caa46c231f2a8d7"
local PUBLIC_KEY = "aaff983278257afc45fa9d44d156c454d716fb1a250dfed132d65b2009331f618c623c14efa16245f50cc92e60334051087f1ae92669b89690f5feb92e91568f95a8e286d110b011e9ac9923fd871238f57d1295395771331ff6edee43e4ccc6"
local HEADER = "11223344556677889900aabbccddeeff"
local SINGLE_MSG_ARRAY = { bbs.MapMessageToScalarAsHash(O.from_hex("9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02")) }
local VALID_SIGNATURE = "8fb17415378ec4462bc167be75583989e0528913da142239848ae88309805bfb3656bcff322e5d8fd1a7e40a660a62266099f27fa81ff5010443f36285f6f0758e4d701c444b20447cded906a3f2001714087f165f760369b901ccbe5173438b32ad195b005e2747492cf002cf51e498"

print('----------------------')
print("TEST: Valid single message signature SHA 256")
print("Test case 1")
local output_signature = bbs.sign( BIG.new(O.from_hex(SECRET_KEY)), O.from_hex(PUBLIC_KEY), O.from_hex(HEADER), SINGLE_MSG_ARRAY)
I.spy(output_signature)
I.spy(bbs.verify(O.from_hex(PUBLIC_KEY), output_signature, O.from_hex(HEADER), SINGLE_MSG_ARRAY))

--[[
local PRESENTATION_HEADER = O.from_hex("bed231d880675ed101ead304512e043ade9958dd0241ea70b4b3957fba941501")


print('----------------------')
print("TEST: Valid single message proof SHA 256")
print("Test case 1")
I.spy(bbs.ProofGen(O.from_hex(PUBLIC_KEY), O.from_hex(VALID_SIGNATURE), O.from_hex(HEADER), PRESENTATION_HEADER, SINGLE_MSG_ARRAY))
--]]

-- I.spy(bbs.verify(O.from_hex(PUBLIC_KEY), O.from_hex(VALID_SIGNATURE), O.from_hex(HEADER), SINGLE_MSG_ARRAY))
-- assert( output_signature == I.spy(O.from_hex(VALID_SIGNATURE)))

local MULTI_MSG_ARRAY = { }

for i = 1, 10 do
    MULTI_MSG_ARRAY[i] = BIG.new(O.from_hex(map_messages_to_scalar_test[i]))
end

print('----------------------')
print("TEST: Valid multi message signature SHA 256")
print("Test case 1")
local output_multi_signature = bbs.sign( BIG.new(O.from_hex(SECRET_KEY)), O.from_hex(PUBLIC_KEY), O.from_hex(HEADER), MULTI_MSG_ARRAY)
I.spy(output_multi_signature)
I.spy(bbs.verify(O.from_hex(PUBLIC_KEY), output_multi_signature, O.from_hex(HEADER), MULTI_MSG_ARRAY))
-- assert( output_multi_signature == I.spy(O.from_hex("b058678021dba2313c65fadc469eb4f030264719e40fb93bbf68bdf79079317a0a36193288b7dcb983fae0bc3e4c077f145f99a66794c5d0510cb0e12c0441830817822ad4ba74068eb7f34eb11ce3ee606d86160fecd844dda9d04bed759a676b0c8868d3f97fbe2e8b574169bd73a3")))

-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Sections 3.2.2, 7.2, {7.3} 7.5
-- local HEADER = '11223344556677889900aabbccddeeff'
-- local SINGLE_MESSAGE = '9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02'
-- local SK_VALUE = '4a39afffd624d69e81808b2e84385cc80bf86adadf764e030caa46c231f2a8d7'
-- local PK_VALUE = 'aaff983278257afc45fa9d44d156c454d716fb1a250dfed132d65b2009331f618c623c14efa16245f50cc92e60334051087f1ae92669b89690f5feb92e91568f95a8e286d110b011e9ac9923fd871238f57d1295395771331ff6edee43e4ccc6'
-- local VALID_SINGLE_MESSAGE_SIGNATURE_TEST_SHA_256 = '8fb17415378ec4462bc167be75583989e0528913da142239848ae88309805bfb3656bcff322e5d8fd1a7e40a660a62266099f27fa81ff5010443f36285f6f0758e4d701c444b20447cded906a3f2001714087f165f760369b901ccbe5173438b32ad195b005e2747492cf002cf51e498'-- 'a7386ffaa4e70a9a44483adccc202a658e1c1f02190fb95bfd0f826a0188d73ab910c556fb3c1d9e212dea3c5e9989271a5e578c4625d290a0e7f2355eabe7584af5eb822c72319e588b2c20cd1e8256698d6108f599c2e48cf1be8e4ebfaf7ae397a5733a498d3d466b843c027311bb'

--[[
print('----------------------')
I.spy( bbs.sign( BIG.new(O.from_hex(SK_VALUE)), O.from_hex(PK_VALUE), nil, { bbs.MapMessageToScalarAsHash(O.from_hex(SINGLE_MESSAGE)) } ) )
print("Random call bbs.verify")
I.spy(bbs.verify(O.from_hex(PK_VALUE), bbs.sign( BIG.new(O.from_hex(SK_VALUE)), O.from_hex(PK_VALUE), O.from_hex(HEADER), { bbs.MapMessageToScalarAsHash(O.from_hex(SINGLE_MESSAGE)) } ), O.from_hex(HEADER), { bbs.MapMessageToScalarAsHash(O.from_hex(SINGLE_MESSAGE)) }))
I.spy(bbs.verify(O.from_hex(PK_VALUE), bbs.sign( BIG.new(O.from_hex(SK_VALUE)), O.from_hex(PK_VALUE), nil, { bbs.MapMessageToScalarAsHash(O.from_hex(SINGLE_MESSAGE)) } ), nil, { bbs.MapMessageToScalarAsHash(O.from_hex(SINGLE_MESSAGE)) }))
--]]

--[[
print('----------------------')
print("TEST: Valid single message signature SHA 256")
print("Test case 1")
local output_signature = bbs.sign( BIG.new(O.from_hex(SK_VALUE)), O.from_hex(PK_VALUE), O.from_hex(HEADER), { bbs.MapMessageToScalarAsHash(O.from_hex(SINGLE_MESSAGE)) } )
I.spy(output_signature)
assert( output_signature == O.from_hex(VALID_SINGLE_MESSAGE_SIGNATURE_TEST_SHA_256), "WRONG SIGNATURE")
-- Test is of the form
-- sign(SK_VALUE, PK_VALUE, HEADER, {SINGLE_MESSAGE}) == VALID_SINGLE_MESSAGE_SIGNATURE_TEST_SHA_256
--]]
local VALID_MULTIMSG_SIGNATURE_TEST_SHA_256 = 'b058678021dba2313c65fadc469eb4f030264719e40fb93bbf68bdf79079317a0a36193288b7dcb983fae0bc3e4c077f145f99a66794c5d0510cb0e12c0441830817822ad4ba74068eb7f34eb11ce3ee606d86160fecd844dda9d04bed759a676b0c8868d3f97fbe2e8b574169bd73a3'

-- local output_multi_msg_signature = bbs.sign( BIG.new(O.from_hex(SK_VALUE)), O.from_hex(PK_VALUE), O.from_hex(HEADER), mapped_messages)
-- I.spy(output_multi_msg_signature)

-- Test is of the form
-- sign(SK_VALUE, PK_VALUE, HEADER, map_messages_to_scalar_messages) == VALID_MULTIMSG_SIGNATURE_TEST_SHA_256


---
---
---

-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.1
local MODIFIED_MSG_SIGNATURE_SHA_256 = '8fb17415378ec4462bc167be75583989e0528913da142239848ae88309805bfb3656bcff322e5d8fd1a7e40a660a62266099f27fa81ff5010443f36285f6f0758e4d701c444b20447cded906a3f2001714087f165f760369b901ccbe5173438b32ad195b005e2747492cf002cf51e498'

-- Test is of the form
-- verify(PK_VALUE, MODIFIED_MSG_SIGNATURE_SHA_256, HEADER, {SINGLE_MESSAGE})
-- RETURNS AN ERROR: fail signature validation due to the message value being different from what was signed.

-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.2
local TWO_MESSAGES = {
    '9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02',
    '87a8bd656d49ee07b8110e1d8fd4f1dcef6fb9bc368c492d9bc8c4f98a739ac6'
}

local EXTRA_UNSIGNED_MSG_SIGNATURE_SHA_256 = '8fb17415378ec4462bc167be75583989e0528913da142239848ae88309805bfb3656bcff322e5d8fd1a7e40a660a62266099f27fa81ff5010443f36285f6f0758e4d701c444b20447cded906a3f2001714087f165f760369b901ccbe5173438b32ad195b005e2747492cf002cf51e498'

-- Test is of the form
-- verify(PK_VALUE, EXTRA_UNSIGNED_MSG_SIGNATURE_SHA_256, HEADER, TWO_MESSAGES)
-- fails signature validation due to an additional message being supplied that was not signed

-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.3
local MISSING_MESSAGE_SIGNATURE_SHA_256 = 'b058678021dba2313c65fadc469eb4f030264719e40fb93bbf68bdf79079317a0a36193288b7dcb983fae0bc3e4c077f145f99a66794c5d0510cb0e12c0441830817822ad4ba74068eb7f34eb11ce3ee606d86160fecd844dda9d04bed759a676b0c8868d3f97fbe2e8b574169bd73a3'

-- Test is of the form
-- verify(PK_VALUE, MISSING_MESSAGE_SIGNATURE_SHA_256, HEADER, TWO_MESSAGES)
-- fail signature validation due to missing messages that were originally present during the signing.

-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.4
local REORDERED_MSGS = {
    'c344136d9ab02da4dd5908bbba913ae6f58c2cc844b802a6f811f5fb075f9b80',
    '7372e9daa5ed31e6cd5c825eac1b855e84476a1d94932aa348e07b7320912416',
    '77fe97eb97a1ebe2e81e4e3597a3ee740a66e9ef2412472c23364568523f8b91',
    '496694774c5604ab1b2544eababcf0f53278ff5040c1e77c811656e8220417a2',
    '515ae153e22aae04ad16f759e07237b43022cb1ced4c176e0999c6a8ba5817cc',
    'd183ddc6e2665aa4e2f088af9297b78c0d22b4290273db637ed33ff5cf703151',
    'ac55fb33a75909edac8994829b250779298aa75d69324a365733f16c333fa943',
    '96012096adda3f13dd4adbe4eea481a4c4b5717932b73b00e31807d3c5894b90',
    '87a8bd656d49ee07b8110e1d8fd4f1dcef6fb9bc368c492d9bc8c4f98a739ac6',
    '9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02'
}

local REORDERED_MSG_SIGNATURE_SHA_256 = 'b058678021dba2313c65fadc469eb4f030264719e40fb93bbf68bdf79079317a0a36193288b7dcb983fae0bc3e4c077f145f99a66794c5d0510cb0e12c0441830817822ad4ba74068eb7f34eb11ce3ee606d86160fecd844dda9d04bed759a676b0c8868d3f97fbe2e8b574169bd73a3'


-- Test is of the form
-- verify(PK_VALUE, REORDERED_MSG_SIGNATURE_SHA_256, HEADER, REORDERED_MSGS)
-- fails signature validation due to messages being re-ordered from the order in which they were signed.

-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.5

local WRONG_PUBLIC_KEY_SIGNATURE_SHA_256 = 'b058678021dba2313c65fadc469eb4f030264719e40fb93bbf68bdf79079317a0a36193288b7dcb983fae0bc3e4c077f145f99a66794c5d0510cb0e12c0441830817822ad4ba74068eb7f34eb11ce3ee606d86160fecd844dda9d04bed759a676b0c8868d3f97fbe2e8b574169bd73a3'

-- Test is of the form
-- verify(PK_VALUE, WRONG_PUBLIC_KEY_SIGNATURE_SHA_256, HEADER, map_messages_to_scalar_messages)
-- fails signature validation due to public key used to verify is incorrect.

-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.6

local WRONG_HEADER = 'ffeeddccbbaa00998877665544332211'

local WRONG_HEADER_SIGNATURE_SHA_256 = 'b058678021dba2313c65fadc469eb4f030264719e40fb93bbf68bdf79079317a0a36193288b7dcb983fae0bc3e4c077f145f99a66794c5d0510cb0e12c0441830817822ad4ba74068eb7f34eb11ce3ee606d86160fecd844dda9d04bed759a676b0c8868d3f97fbe2e8b574169bd73a3'

-- Test is of the form
-- verify(PK_VALUE, WRONG_HEADER_SIGNATURE_SHA_256, WRONG_HEADER, map_messages_to_scalar_messages)
-- fails signature validation due to header value being modified from what was originally signed.

-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Appendix C.2.7

local INPUT_MSG_BBS_SHA_256 = '9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02'

local DEFAULT_DST_HASH_TO_SCALAR = '4242535f424c53313233383147315f584d443a5348412d3235365f535357555f524f5f4832535f'

local BBS_SHA_256_H2S_TEST = '669e7db2fcd926d6ec6ff14cbb3143f50cce0242627f1389d58b5cccbc0ef927'

print('----------------------')
print("TEST: MapMessageToScalarAsHash (BBS paper, C.2.7)")
print("(literally only first test vector of the above test with same name)")
print('Test case 1')
assert(bbs.MapMessageToScalarAsHash(O.from_hex(INPUT_MSG_BBS_SHA_256), O.from_hex(DEFAULT_DST_HASH_TO_SCALAR)) == BIG.new(O.from_hex(BBS_SHA_256_H2S_TEST)))


-- Test vectors originated from
-- draft-irtf-cfrg-bbs-signatures-latest Section 7.5.4

local SEED_RANDOM_SCALAR = O.from_hex("332e313431353932363533353839373933323338343632363433333833323739")

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
    local output_mocked = bbs.seeded_random_scalars(SEED_RANDOM_SCALAR, 10)
    for i = 1, 10 do
        print("Test case ".. i)
        assert(output_mocked[i] == BIG.new(O.from_hex(test[i])))
    end
end

print('----------------------')
print("TEST: Mocked/Seeded random scalars")

run_test_mocked_random(MOCKED_RANDOM_SCALARS_TEST)

