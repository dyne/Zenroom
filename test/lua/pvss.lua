local PVSS = require'crypto_pvss'

print('----------------- TEST PVSS ------------------')
print('----------------------------------------------')
print("TEST: DLEQ")

local g1 = ECP.generator()
local g2 = g1 * (BIG.modrand(ECP.order()))
local g3 = g1 * (BIG.modrand(ECP.order()))
local g4 = g1 * (BIG.modrand(ECP.order()))

local alpha, h1, h2, h3, h4, c, r, proof
for i=1,10 do
    print("Test case ".. i)
    alpha = BIG.modrand(ECP.order())
    h1 = g1 * alpha
    h2 = g2 * alpha
    local beta = BIG.modrand(ECP.order())
    h3 = g3 * beta
    h4 = g4 * beta

    proof = PVSS.create_proof_DLEQ({{g1, h1, g2, h2}, {g3, h3, g4, h4}}, {alpha, beta})
    assert(PVSS.verify_proof_DLEQ({{g1, h1, g2, h2}, {g3, h3, g4, h4}}, proof))
    assert(not (PVSS.verify_proof_DLEQ({{g1, h1, g2, h2}, {g3, h3, g4, h4}}, {BIG.new(5), proof[1], proof[2]})))
end

print('----------------------------------------------')
print("Create and verify encrypted shares")
print("Test case 1")
local participants = 10
local thr = 6
local secret = BIG.modrand(ECP.order())
local GENERATORS = PVSS.set_generators()
local public_keys = {}
local secret_keys = {}
for i=1,participants do
    secret_keys[i] = PVSS.keygen()
    public_keys[i] = PVSS.sk2pk(GENERATORS, secret_keys[i])
end

local issuer_shares, XXss, evals = PVSS.create_shares(GENERATORS, secret, public_keys, thr, participants)
assert(PVSS.verify_shares(GENERATORS, thr, participants, issuer_shares))

print("Test failure 1")
-- This fails because there is one wrong encrypted share.
local temp = issuer_shares.encrypted_shares[1]
issuer_shares.encrypted_shares[1] = issuer_shares.encrypted_shares[2]
assert( not PVSS.verify_shares(GENERATORS, thr, participants, issuer_shares))
issuer_shares.encrypted_shares[1] = temp

print("Test failure 2")
-- This fails because we pass the wrong generator point.
local temp_generators = PVSS.set_generators(true)
assert( not PVSS.verify_shares(temp_generators, thr, participants, issuer_shares))

print("Test failure 3")
-- This fails because there is one wrong public key.
temp = issuer_shares.public_keys[1]
issuer_shares.public_keys[1] = issuer_shares.public_keys[2]
assert( not PVSS.verify_shares(GENERATORS, thr, participants, issuer_shares))
issuer_shares.public_keys[1] = temp

print("Test failure 4")
-- This fails because there is one wrong commitment.
temp = issuer_shares.commitments[1]
issuer_shares.commitments[1] = issuer_shares.commitments[2]
assert( not PVSS.verify_shares(GENERATORS, thr, participants, issuer_shares))
issuer_shares.commitments[1] = temp

print('----------------------------------------------')
print("Test: decrypt shares")
local dec_shares = {}
local participants_shares = {}
for i = 1, participants do
    print("Test case ".. i)
    local table_dec = PVSS.decrypt_share(GENERATORS, secret_keys[i], public_keys[i], issuer_shares)
    table.insert(dec_shares, table_dec["dec_share"])
    table.insert(participants_shares, table_dec)
    local S = dec_shares[i]
    assert(S == GENERATORS.G*evals[i])
end

print('----------------------------------------------')
print("Test: verify decrypted shares")
local shares, indexes = PVSS.verify_decrypted_shares(GENERATORS, participants_shares)
assert(#shares == participants)

print('----------------------------------------------')
print("Test: pooling the shares")
print("Test case 1")
local sec = PVSS.pooling_shares(shares, indexes, thr)
assert(sec == GENERATORS.G*secret)

print("Test case 2")
local sec2 = PVSS.pooling_shares({shares[3], shares[1], shares[5], shares[8], shares[6], shares[2]}, {3,1,5,8,6,2}, thr)
assert(sec2 == GENERATORS.G*secret)

print('----------------------------------------------')
print("Create deterministic shares")

-- We test our implementation with a deterministic variant of
-- https://github.com/darkrenaissance/darkfi/blob/master/script/research/pvss/pvss.sage

local t = 3
local n = 5
local s = BIG.new(123)
local sec_keys = {}
local pks = {}
local det_coefs = {s, BIG.new(5), BIG.new(6)}
for i=3,n+2 do
    table.insert(sec_keys, BIG.new(i))
    table.insert(pks, PVSS.sk2pk(GENERATORS, sec_keys[i-2]))
end

local C = {
    { BIG.new(O.from_hex("0x17d6bf26a5b9126d12a8d634cb6380189a0109dca203a8261c24cfd7d7a7e4933f5b872d829d89aa01135df2984480ce")), BIG.new(O.from_hex("0x13bf6f900360d414ef7b9f7cabf4615b2b40849872337f140c9096f13c2d803a858babc382787877b039493baccf71bc")) },
    { BIG.new(O.from_hex("0x31ceaeb02cf3a1340aaafa0c197e8d3927e12d6da669be89f7387eccedb80293eb1f97e1ddde77e3b4185a63f6f438d")), BIG.new(O.from_hex("0x12a212fc1f710c9a2aad88c4d4f3cda613a72d86d605e0e881af6128e7647e3ca5a5a16134c3b7e8b2cdd4e52e181369")) },
    { BIG.new(O.from_hex("0xcbc11550ebdf89d346d6310380b500056ec1d438e597241467b26c6e199b52d955f7bf14f374cf7e85fde61828017b0")), BIG.new(O.from_hex("0x10d08cf5a98e4b24cbcccf0f549168808ec3cdabf63b1a18c4dfab8ce6e2c605907f2272b2701215bf0583affb5d6c3e")) }
    }

local Y = {
    { BIG.new(O.from_hex("0x94ec4f09b8dea8eb4db5f03fa3e3745f4d05c9135877545c31bfd80cb1120dcb8fc309d5466afc7a108e450531757bd")), BIG.new(O.from_hex("0x1839ee6a89cff08392332782e4a1687807bf87af6757f2debad4c714f38d0ed2e6a431bad9052e1275f4367a63457b76")) },
    { BIG.new(O.from_hex("0xaa5a7897702be085d6583fcf373dc582234d473cf7cbccf5ceeef81ca4634809481ee3410b9cca075f1f25d3dd97379")), BIG.new(O.from_hex("0x7315e5678a52a222e65b2790e105621b507b8aba6205fee6367156d2513d89692a8542eeda62fd81860ad108b147c91")) },
    { BIG.new(O.from_hex("0x91c865a3380733972f46efaf0c7a5f4468ae285aeb4dc88e0a7b00617fab3b820a074588e60136d1598829e9db093a5")), BIG.new(O.from_hex("0x7d8f852d6e312c7689c1d6efd413cbc4a0e7ef48f7594d2aa7eabb4080d93be11f68e86725e42250cad5667545a61a6")) },
    { BIG.new(O.from_hex("0x4c4b284c4f5182365e1c8d8c921b6668c90a04defd8f37be7a684d8dd65bd2291ae49a0dfbd2c441f5c342e41c61b69")), BIG.new(O.from_hex("0xbbce2bd0d8f0ef696371b24f8ca57d6c4dd1738a3c830f673ff15ea3c1a4610e6edeb25de4421effaf738aaf133e352")) },
    { BIG.new(O.from_hex("0x16e203ad35d69c48c9f74b1a6ee009c0499f3128a376e982eefac64167daf96d954970c8f1f3907b09bfa03b3bc053cb")), BIG.new(O.from_hex("0x1211321140a845b14f1143677c97bf19b652f14cbaef6a5ae9d9feff20125284626a42610e2be1a09f07cb57e42e85e6")) }
    }

local X = {
    { BIG.new(O.from_hex("0x1924f136c2b7ad58d3a87ff4e150ef936776f213b3c452204efe01f94836e8b9fbe9533280dc55f276f5a52ac68385c4")), BIG.new(O.from_hex("0x8a021f68437d9250e2fcc45ed21fc9c2a94760b562258a352420e52daad482ecce947b78d286a1164c3e40c4d033924")) },
    { BIG.new(O.from_hex("0x73049dcf8c7fe39f37cb817bd741fd740abd4fc4952c6276749523409a3c4289949b881182214d9bb6df485fe3719d0")), BIG.new(O.from_hex("0x36babf19c8996a0eaa2381f4038793444c1f8c39dbac40142a10acd9a0c604c4ab5f7e07bed45fdd0f28207e84a77d6")) },
    { BIG.new(O.from_hex("0xffa49dacf4b9cfce471c880ca5de0adfcd3b2e2442f061407bd24de961af3d157d5b20a9dff7f3efbcc0e9fbcd01a18")), BIG.new(O.from_hex("0x71270538bb1ef1a2bd9a852f5fdada1f76f63738b48d8325a4fd48bc9dd85f8f93e7dc6b8de2258999156172a2aa500")) },
    { BIG.new(O.from_hex("0x9a8ded1e81cad97948a452b34c00db742ac6b7e6f66ed25b9504f22dfa7f2460273626e55bbd742c680f6a44f430fc7")), BIG.new(O.from_hex("0x1ce662d4e8d002d088cbfdafb36fc3c1e2192b325da5b3ffc197248180d66ae0b87bb55e743f863a3ac42c788f5d044")) },
    { BIG.new(O.from_hex("0x15cc9059f0aa90f1df0446694eabdd7c807bbaf79baa67d58f38d7034daffeb3f87a25842fbea651fd9df6ec6cf7d2e8")), BIG.new(O.from_hex("0xd469d8865fe52ab699cd885f098ba9e7452d92abddfec0fc4e3390f92e0e32428ce35319a42bbe52c2b1eab77eb1b2f")) }
    }

c = BIG.new(O.from_hex("16089d0de84bd6d3767122f4a62cf5274f1a47d093fcbf58b378eab50bcab997"))
r = {
        BIG.new(O.from_hex("0x3da0c92aa24c46a534a7a4c1fee79df71981112089892f780eb52521d3e2db14")),
        BIG.new(O.from_hex("0x12914a3769f1eec65d64e0e73764f7844d1b2d6f3dcd6e7beed80ed9c4ac2e88")),
        BIG.new(O.from_hex("0x3ae36496cae1fcd6928201acc2ac5b49c6b2d8000233c954654ff81227f4ceeb")),
        BIG.new(O.from_hex("0x42a970f59b7ef38da0c52f0a971bf142328a6ccfd6bde402721ce0cbfdbcbc3c")),
        BIG.new(O.from_hex("0x29e36f53dbc8d2eb882e6900b4b3b96d90a1ebdebb6bbe86153ec9074603f67b")),
}
local w_arr = {BIG.new(4),  BIG.new(5), BIG.new(6), BIG.new(7), BIG.new(8)} 
local det_issuer_shares, Xs = PVSS.create_shares(GENERATORS, s, pks, t, n, {det_coefs,w_arr})


for k,v in pairs(det_issuer_shares["commitments"]) do
    assert(v:x() == C[k][1])
    assert(v:y() == C[k][2])
end

for k,v in pairs(det_issuer_shares["encrypted_shares"]) do
    assert(v:x() == Y[k][1])
    assert(v:y() == Y[k][2])
end

for k,v in pairs(Xs) do
    assert(v:x() == X[k][1])
    assert(v:y() == X[k][2])
end

local chall = table.remove(det_issuer_shares.proof,1)
for k,v in pairs(det_issuer_shares.proof) do
    assert(v == r[k])
end

assert(chall == c)

print('----------------------------------------------')

print("Reconstruction proofs")

local S_array = {
    { BIG.new(O.from_hex("0x591ce63050db62dd89f3e8189ca7ed8c5c6d73d302f4ea580bdc207ffdb3308885f2fdea679e581ca56cacbe83c7431")), BIG.new(O.from_hex("0xa16b47ced104df569a97e542c5c7ca814a2dd47446890fa4650360aac784392eca88ed6b389ee5f15493c4d03f93b79")) },
    { BIG.new(O.from_hex("0x1504c48c316a134a03d540e38ca7dcb8ff51c8240d632bdb7ceb989b9d74b692930bb4688c505bc7756af7b714a0f037")), BIG.new(O.from_hex("0x400c9dfd599cd2da728cbe3346a5c3f0714ca545ab88878e7cd53caef9a8fd46f174280c288d3f8123b6008e1cb0a9d")) },
    { BIG.new(O.from_hex("0x9778d7ec1f84e0750bae6ea0affb9bbd14dece9bac704f0de3e38394a84d14847af65af4f07a9fa6c2a8942f79fdeda")), BIG.new(O.from_hex("0x55ecdabfe9b2900ae19ccf45356684b4721fb51db85bf641d68cc518d531b337aa518144b7c03e30b5f5f11617c4d05")) },
    { BIG.new(O.from_hex("0x7acb009c4c6146748e1b2392506f455b678079b74e6f2f61e71fda7265d54c08fdfa9bb28213419b1e7b476cae78b8f")), BIG.new(O.from_hex("0x454a77ea751fa7e3db30c9d20f1c1282f23b83fdbcb79cad78176953da63f72631c8edfa2470b185d35fbea6f07df33")) },
    { BIG.new(O.from_hex("0x126106cce5d249f23905be9ae0b3882132a1f481fd7f4db9296ddf88c0a1ee5d3421a168e7499bc2655e620627ed05d")), BIG.new(O.from_hex("0x513974b628a21781212b953bc0b2fd518bb40e136087220a6801da88c48174001ec68a2d7481017bc957c652e5ffc4a")) }
}

local CURVE_ORDER = ECP.order()

local sage_reconstruction_C_R = {
    { BIG.mod(BIG.new(O.from_hex("766ec76de80675d660173a251a7ae42db56f03bed4e745576cdaed6cef7eb702")), CURVE_ORDER),
    BIG.new(O.from_hex("0x6c6a4702ee62939daca1b1b0d716b38c2ea984cf81439ff5b96f37b53183db02")) },
    { BIG.mod(BIG.new(O.from_hex("464bacedd523dd6091e30dace094685d163e42a6184ef022d46a609e3a95e9a5")), CURVE_ORDER),
    BIG.new(O.from_hex("0x429a424228490256522151649a93e69ba23fe1709ebf5371ae567d8415a85973")) },
    { BIG.mod(BIG.new(O.from_hex("064063ad7674764eb880ace296b1211e7b0361fb6a7d466c5b37f750cd04f608")), CURVE_ORDER),
    BIG.new(O.from_hex("0x54abb4efd9572dbe98b6779b182c326cecacba19eb8bfbe137e82b6afee731dd")) },
    { BIG.mod(BIG.new(O.from_hex("548d4a42202eef7b4290344f9eec1a91ebf96c1de33830e18b7fe37ba7ef5d7a")), CURVE_ORDER),
    BIG.new(O.from_hex("0x485487130ef9d58570bffe4a76a098af1adbab5baca6a6b1bb00ab151063cf2d")) },
    { BIG.mod(BIG.new(O.from_hex("c2106724026534096b1c2dbf275ccc27642524c0667b65d38d4eee0fdd7b265b")), CURVE_ORDER),
    BIG.new(O.from_hex("0x20b105e9e29d732078f0e026600c8b2c2fdfaee1328c872b22d77d84f1a1f393")) },
}

local valid_shares = {}

for i = 1, 5 do
    print("Test case ".. i)
    local reconstruction_table = PVSS.decrypt_share(GENERATORS, sec_keys[i], pks[i], det_issuer_shares, {BIG.new(4)})
    local S_decrypted = reconstruction_table["dec_share"]
    proof = reconstruction_table["proof"]
    table.insert(valid_shares, S_decrypted)
    assert(S_decrypted:x() == S_array[i][1])
    assert(S_decrypted:y() == S_array[i][2])
    assert(proof[1] == sage_reconstruction_C_R[i][1])
    assert(proof[2] == sage_reconstruction_C_R[i][2])
end

print('----------------------------------------------')
print("Test pooling shares")

local sage_secret = {
    BIG.new(O.from_hex("0x1589ff4a362290d5a3784d3b0f60e92818e12d32348bec3477fc975d03c608a7b626c840ecf2cf596b4547b7e47f86ff")),
    BIG.new(O.from_hex("0x3c7a0388a44653a4f64e2feacf25f92dbd02600db7ca95669ed03a08a1ae78793bb8cb9ed16400adbd388ba0202efc2"))
}

print("Test case 1")
local shared_secret = PVSS.pooling_shares(valid_shares, {1,2,3,4,5}, t)
assert(shared_secret:x() == sage_secret[1])
assert(shared_secret:y() == sage_secret[2])
assert(shared_secret == (GENERATORS.G*s))

print("Test case 2")
assert(shared_secret == PVSS.pooling_shares({valid_shares[2], valid_shares[3], valid_shares[5]}, {2,3, 5}, t))

print('----------------------------------------------')


print("TEST sage 2")

-- SECRET KEYS
local sage_secret_keys = {
    BIG.new(O.from_hex("0x541945c9a80aff78ad101d29370f56661035f108a53292f92e826cb5afe0f7bb")),
    BIG.new(O.from_hex("0x58761bb3a41593ad3c9161656f89143b3ea1df79b59db86901b552024a6d320a")),
    BIG.new(O.from_hex("0x0c38e44f57de7cc0d3b103201cd8b294c5b80fea88591c32c26fcbdda254c5dc")),
    BIG.new(O.from_hex("0x23d24a231ae14e142a3652e64889af518760c7008b838415294ad135f1d3d777")),
    BIG.new(O.from_hex("0x5ddcb66bd07d1c1c4f68cd67153eda92f0f30b030188818e3f496a0e5fe512a9")),
}
-- PUBLIC KEYS
local sage_public_keys = {
    { BIG.new(O.from_hex("0x0e9bc85e97f9bb2d32a2fe6caecd345e5d30da85c1512e5f4d166fe15552e789dc118fcdb280510413a5293bfcb9a649")), BIG.new(O.from_hex("0x097761dc398787de573d9284b49bde4be3f1dbf647df41d8bd69549463937f89b908223b77d1d8ed04188f46000e1c6e"))},
    { BIG.new(O.from_hex("0x0658f6d7a7c70e16c6bff84ba8d6c6c51fcab34ac83c21641f8e9bc1e148d75d10841a9c96110dd17ea4ddb01426a558")), BIG.new(O.from_hex("0x183c760f84e8f772a5e0df7a5cd3e562612697716b4e5ae7188cc923c4a54a54e8e9b40364c0abd128fd954d499c9ada"))},
    { BIG.new(O.from_hex("0x0d85965bf7ab23dc29961715bbd43e53873698e61ca80bd952633bfb74d97471fb6470113054a9590301495a64e37def")), BIG.new(O.from_hex("0x17d8507c3efb791206ce9b908b828694204346661ab6a6d590790944eeaf8f856c3fb8bc29d13fc0da7896273bad636a"))},
    { BIG.new(O.from_hex("0x192b1099ec575e9a081446155cb4969c57a0a168eba6092303770286d3a2948b72aefd1ca8a774a74f74c6f95233b8af")), BIG.new(O.from_hex("0x83ccea405b2d3f62ecc0d8dc52812ec8f41711519e82c6dbf40983a5b0bafd01421b9dcfece46c1ce855558a258474"))},
    { BIG.new(O.from_hex("0x099719eb6a28782717e921ec80e1818f7e62137b73be84921fb00cd38cc19a1eb70f3b377ee19b5206e1d7ba8d2dc094")), BIG.new(O.from_hex("0x014bfba1e27e84d6425130cb99578116f7dd9e0e5c11edee005ce7429fb43b909b15d57ea3687252a2b6b9c59462431f"))},
}

-- Secret exponent
local sage_secret_exp = BIG.new(O.from_hex("0x06c055adb278b84dd2bba597f7c5829c8e7fb0cf0e32f704c3c3cdd87344b95b"))
-- POLYNOMIAL COEFFICIENTS
local sage_poly_coeff = {
    BIG.new(O.from_hex("0x06c055adb278b84dd2bba597f7c5829c8e7fb0cf0e32f704c3c3cdd87344b95b")),
    BIG.new(O.from_hex("0x12d130bc1bdc9bfd19cbbe3444f3eeedc9b5fb93fbcbe52b7dcc1e4af7abaf17")),
    BIG.new(O.from_hex("0x279aa4e866f49c8bbfa3fcd57673e2409db09ce6d7c92980b4251e82e1ccd70b")),
}

-- COMMITMENTS
local sage_commitments = {
    { BIG.new(O.from_hex("0x01e9f57a36b8f02f720a4f4374d4812d7275819667643abcf511808d2409d7788bbb66767591924ab0b82ab19614f0ec")), BIG.new(O.from_hex("0x714be238da4ced495c8308c01428d3792c8770128c5a9c9a533576c54fc502235c33cb07ce6dd03911f35c2a7977bd"))},
    { BIG.new(O.from_hex("0x0f5de8b28302e38262c7468272dd037bf0adbd4ffdd1bd916e5aa77f4064c3a790a60e493792082b0447e51d93f0d575")), BIG.new(O.from_hex("0x0932e35b664f51e0c8d999a9e598af66d76a2df07eea670a34f55a026b9c10a79f88e12c8814360059cd60a1742ffe53"))},
    { BIG.new(O.from_hex("0x0b4029b6ca3f6bf49d3639d029fe802ed56a540ecabc89425c8589681b030de56d45cc85f11b0016b3c4d9281780991e")), BIG.new(O.from_hex("0x144a64e2c8608230f1c3b429ce659a678e6fdbda193fc72d1b950a9d8e60ba152fac54e9374b222b4f3811df31eee041"))},
}
-- ENCRYPTED SHARES
local sage_enc_shares = {
    { BIG.new(O.from_hex("0x1273e1ba81c17f5dfc9e3bb8384122f81544cbc411ac48105f9e08b00cdc14681225e1f283ba2f77adf6fb52e63f3b89")), BIG.new(O.from_hex("0x0f31a64179fbfa78f52a81cd4561c8284361a8defeeb2c5851ec783ec206092492534a34be9dd5f736c7aa77dc060433"))},
    { BIG.new(O.from_hex("0x130ada028ceffe4aabf7e4d30046b319020c3db31faad5dcb7625b87f075f8624a9a2eee01e0151e7b500d6eba8e1b34")), BIG.new(O.from_hex("0x1056fe3645036df1604da4fdd32417282bcca153531f7386d994fe0c4bac12c693566bd56f9ba492647991107b7a528a"))},
    { BIG.new(O.from_hex("0x1805207555ea10fff2be3767f0bf5c79520dbff6140158e955d4024774ae0a57e4247ca702d0698d94acc16c95265c6c")), BIG.new(O.from_hex("0x03b16ed1f629d1e07a30e56a63547d655eda80dd2dc960dded1ce63bb7c4192e1d3e305936a6845eee334602c91ca270"))},
    { BIG.new(O.from_hex("0x19df91ca7361fa487b336387f67d60b6b1d23cbcde12462e9c0cb646f776e1315d5e462d06cb47f3a4d16be355801082")), BIG.new(O.from_hex("0x0fc6b2bfe36725f54437bddb26acb49fc1760d01513ad8d39c4632f52b542bd2a80f71305ea6b512794eaa566ae17be1"))},
    { BIG.new(O.from_hex("0x17ee39cde13d2e969956c69ec2d20d8a1eb87e9d802864a8ba63d1b631dec2924698de1b11418258dbe6953c04e1abac")), BIG.new(O.from_hex("0x10f0050c97defb2acd4ebff5899978282f6035f431ed259886237288e383ba591f057f3ee275bd02acfeaa9dbd753ec3"))},
}
-- Xs
local sage_Xs = {
    { BIG.new(O.from_hex("0x135d3e3db0d6d4fd30afc632e5eaa5361a73db20e55e947a6462018e4007b3a6e3a8c25d378fe6c80f2e408dd118ddba")), BIG.new(O.from_hex("0x0deab429a4d121d0c324ce521c81301e1f578eb6465f9c31f946ec19cbd28cba90084214cec9fb86d7cc43a931087952"))},
    { BIG.new(O.from_hex("0x100fbd868e7611ea475a916ba175d645ee770e4f011ea2dd9ccfa8edcd94eba4593a96d0b713f4ddba75796b64dff525")), BIG.new(O.from_hex("0x05f1f984bd09eb452586fe31f724f32d39377b98cba3ced922d5657199cb0b4925120f21d28d71866b47deb0e409b2b9"))},
    { BIG.new(O.from_hex("0x18a9e6367b4a2af252f8e8430386a1bf3afb638a97ed70f7b52cb2067cb2207fd47f9529c4ca66bf3551a6bd2a1f8b92")), BIG.new(O.from_hex("0x164c89b45b00a6ecb4275739ec1fbcd24c6b23f0b070a47531bc1c96d1f58a887f6fc8390345e0efb0ec865faaf3c8f5"))},
    { BIG.new(O.from_hex("0x098857270cf706637bdce0a09fa7842b3915c61c2236963e9d08e19979ca4b7ff6af0d305c3468846c7209a06d92f625")), BIG.new(O.from_hex("0x06fa690a0f3e1879e8606e8f765d7af87f392009b48c5593fa7e597ec8839a6fea731975032b61c536754fed3926b9cc"))},
    { BIG.new(O.from_hex("0x024f88ee97af82930bd9ed2b1749d64c4a01bae8a25134fe862e43147dc94923a956b65ebd87a03e04ae2741a84315c5")), BIG.new(O.from_hex("0x1ecbcf4f9f5d235fbb802c51c724674a44b7e9409fce1613caa77c94108dfc86c7e656e98ff0c03ff57560db84551a"))},
}
-----------------------------
-- RANDOM CHALLENGES
local sage_rand_chall = {
    BIG.new(O.from_hex("0x6471fbdba941e5cb33cc3121ce7b21cc494b52a6276fa27550af317a782b1c10")),
    BIG.new(O.from_hex("0x358752c0c07c76777e159fef06a9820de3fddfc41fd9278f04fd3d43a1979856")),
    BIG.new(O.from_hex("0x3bc31da805d56fa0fd47a62e6a9cc9ef74e78fa5cc04f5aea108a6b21f82bdac")),
    BIG.new(O.from_hex("0x09da01bee9df26ef224630d3d466974493d160fdf76cb5ddbbc1a1762792e1ed")),
    BIG.new(O.from_hex("0x17eaba7ad13772a1264adea81736b216e6bdde99802704b62da894151f878aad")),
}
-- challenge
local sage_challenge = BIG.new(O.from_hex("4f89feed9cf31fcfa666e0bc2c9b06e79c9a155d69e9810a0555bfee728d0b04"))
-- RESPONSES
local sage_responses = {
    BIG.new(O.from_hex("0x2ef44d23fc3abe2b520c5fc8152724f3ea90fdb4e018cdb64dafcfaea32ecea9")),
    BIG.new(O.from_hex("0x2e823b9a2161b2f3e6fa2583d3cd6b67bc4293343e9c2284e238c2e79f482a2d")),
    BIG.new(O.from_hex("0x6cac9289b37ab713cbbd378a209b2abc327e7cf58b72581ef2f2763c48b12960")),
    BIG.new(O.from_hex("0x083a4fccf97aa2ea3dffaac6cc0028bf915015a89216bb8f16cd1d5dd510221c")),
    BIG.new(O.from_hex("0x61257d7fab3a4746dd6ece12bc6fdd8626353020309ca16d26491ecfaa2499f7")),
}
-----------------------------
-- RECONTRUCTION PHASE
-- decrypted shares
local sage_dec_shares = {
    { BIG.new(O.from_hex("0x108f9975e7b0e97c6b770ccadb5932958ead267cbbce7479ebd44618f029ae3965291d0a7875afdd7a8e7294c44ede")), BIG.new(O.from_hex("0x02c90d876ca9cb224a29fe772815fe7adc026ee92c89e5f671382fcbfa7901e107780b1e2bcad742a1c6d2dafda29fbb"))},
    { BIG.new(O.from_hex("0x09fcba5844824ced49adec6e561ac95d066bcee5d2b8e23215bfb4b49f12dcd4502ee662ff503400114b1e031736a47d")), BIG.new(O.from_hex("0x142d52923e07a5aeb8c629c6509a3c836ca91b63bb11afc2b62c9c3d8be9a512aada1dd5d9d27ea1e50f6d25664d6494"))},
    { BIG.new(O.from_hex("0x0fb3750fdd97285df4abc46bcde350bb29d7ddd5e77223729c3ce6bd4f9eecec3dad2ee96b0aa52d88f7dad579491a52")), BIG.new(O.from_hex("0x19e04e2f0286027c8d5926a309a333a9624d57c6fa831c739c6e1509db6c4d17e870b03d16d2ca6f8a9c63a06c1eb7ce"))},
    { BIG.new(O.from_hex("0x9b3ad7acd575ecf5c6d1f48aa21e24456f065d5050dfe9b51edd85275f412cb9c5e36e23c16ce82444daef2b8270c9")), BIG.new(O.from_hex("0x05bb4b5f4f527d0256713ff120935938a9767c14ab3195d72dd38e1b2c27a961ec3f23341c7e941014ec7276a693fc7e"))},
    { BIG.new(O.from_hex("0x1678d4b2188195733e946cd18aa61ab5633f0bc1155925685e1c757fc8d83345cdade89956effcbdc2ab502b4f0c75e5")), BIG.new(O.from_hex("0x128c7f6b07109c454361f0ddc521ee7aea52d6ad58c7cfa0d55600188d76e10225c20d023cdff5162ca272fac6b97c75"))},
}
-- Reconstruction proofs
local sage_reconstruction_proof = {
    { BIG.mod(BIG.new(O.from_hex("1d96adcd84c94457c232a22c03f3fbf8e620eae8ec00000abe9874e70df74e6f")), CURVE_ORDER),
    BIG.new(O.from_hex("0x6f1fa77a374a11f7e12aabeb2c2d5565166a449154e457880ed8e1b1f1f28380")) },
    { BIG.mod(BIG.new(O.from_hex("5039889fc2b46fb532c298ac2af7f1f84d02f4510021f221b6ef2792e987def2")), CURVE_ORDER),
    BIG.new(O.from_hex("0x3cb9ec142140c8442fcbdf359bd7cd8ad1ffd0531c559d296af8d2d5d24068a2")) },
    { BIG.mod(BIG.new(O.from_hex("a4d393d247872d4da07b4affa3e1174796335e792b8b6bf59fc5e70b7665b36c")), CURVE_ORDER),
    BIG.new(O.from_hex("0x3734f2f7077c84a54cb6279c762e0639651fb4bce9115f7ce4c740adaf7cf11e")) },
    { BIG.mod(BIG.new(O.from_hex("4abc71c3991fc2b3d687b95bcf8e9a48b4a3cf1262a5ade87e02661024a6e370")), CURVE_ORDER),
    BIG.new(O.from_hex("0x6c106cba0b99029f3ed517c683ac3ce9d67db6a00e7f59096f615fdf172b6fb1")) },
    { BIG.mod(BIG.new(O.from_hex("770b1e856e57c050048da68aa5a987689e2d75f5adb87ac4127d2aa0a62f80a7")), CURVE_ORDER),
    BIG.new(O.from_hex("0x554131fb7a820aa60e960f4e4e2b2b208c52164fa62d80fffca1cd5890476a62")) },
}
-- w_array
local sage_w_array = {
    BIG.new(O.from_hex("0x371361caaeb63473dcf08b670ab95bc77f61070bc8ed4b6856906fc66de7dcf7")),
    BIG.new(O.from_hex("0x28d6513b2d7f609244d91362d338ede7495e363d77b93d6207751e701e3b07a4")),
    BIG.new(O.from_hex("0x01104fbc4621177d960f9faa4ac31389eb39b6626885bf8d701013e15f70b042")),
    BIG.new(O.from_hex("0x19f3b1e3d747595f9e70a9a88b16824a63314a419a383f97386eba72369d1392")),
    BIG.new(O.from_hex("0x19d16fd9de3fbf88f6b34a405d7bd714127a003626f72881fd41fca138727065")),
}

-- recontructed secret
local sage_rec_sec = { BIG.new(O.from_hex("0x180118272372899e521eece0bb7dd43bb9ef58127b89b6e2a8721ddfea5b35808d60cff4ab6d85e30ea007149d8ceea6")), BIG.new(O.from_hex("0x54a343fe9928bf61a510a74c243d63a9d3b5e4dad0d6823666ea3b19f7fec504fb1b2b89a9055847fdcef122c7995b"))}

local points_pub_keys = {}
for i = 1,n do
    points_pub_keys[i] = ECP.new(sage_public_keys[i][1], sage_public_keys[i][2])
end

print("Test: create shares")
det_issuer_shares, Xs = PVSS.create_shares(GENERATORS, sage_secret_exp, points_pub_keys, t, n, {sage_poly_coeff, sage_rand_chall})

for k,v in pairs(det_issuer_shares["commitments"]) do
    assert(v:x() == sage_commitments[k][1])
    assert(v:y() == sage_commitments[k][2])
end

for k,v in pairs(det_issuer_shares["encrypted_shares"]) do
    assert(v:x() == sage_enc_shares[k][1])
    assert(v:y() == sage_enc_shares[k][2])
end

for k,v in pairs(Xs) do
    assert(v:x() == sage_Xs[k][1])
    assert(v:y() == sage_Xs[k][2])
end
chall = table.remove(det_issuer_shares["proof"],1)
for k,v in pairs(det_issuer_shares["proof"]) do
    assert(v == sage_responses[k])
end

assert(chall == sage_challenge)
print('----------------------------------------------')
print("Test: verify shares")
valid_shares = {}

for i = 1, 5 do
    print("Test case ".. i)
    local reconstruction_table = PVSS.decrypt_share(GENERATORS, sage_secret_keys[i], points_pub_keys[i], det_issuer_shares, {sage_w_array[i]})
    local S_decrypted = reconstruction_table["dec_share"]
    proof = reconstruction_table["proof"]
    table.insert(valid_shares, S_decrypted)
    assert(S_decrypted:x() == sage_dec_shares[i][1])
    assert(S_decrypted:y() == sage_dec_shares[i][2])
    assert(proof[1] == sage_reconstruction_proof[i][1])
    assert(proof[2] == sage_reconstruction_proof[i][2])
end

print('----------------------------------------------')
print("Test pooling shares")

print("Test case 1")
shared_secret = PVSS.pooling_shares(valid_shares, {1,2,3,4,5}, t)
assert(shared_secret:x() == sage_rec_sec[1])
assert(shared_secret:y() == sage_rec_sec[2])
assert(shared_secret == (GENERATORS.G*sage_secret_exp))

print("Test case 2")
assert(shared_secret == PVSS.pooling_shares({valid_shares[2], valid_shares[3], valid_shares[5]}, {2,3, 5}, t))

print('----------------------------------------------')
