local PVSS = require'crypto_pvss'

print('----------------- TEST PVSS ------------------')
print('----------------------------------------------')
print("TEST: DLEQ")

-- TODO: use secp256k1 somehow
local g1 = ECP.generator()
local g2 = g1 * (BIG.modrand(ECP.order()))
local g3 = g1 * (BIG.modrand(ECP.order()))
local g4 = g1 * (BIG.modrand(ECP.order()))

local alpha, h1, h2, h3, h4, c, r
for i=1,10 do
    print("Test case ".. i)
    alpha = BIG.modrand(ECP.order())
    h1 = g1 * alpha
    h2 = g2 * alpha
    local beta = BIG.modrand(ECP.order())
    h3 = g3 * beta
    h4 = g4 * beta

    c, r = PVSS.create_proof_DLEQ({{g1, h1, g2, h2}, {g3, h3, g4, h4}}, {alpha, beta})
    assert(PVSS.verify_proof_DLEQ({{g1, h1, g2, h2}, {g3, h3, g4, h4}}, c, r))
    assert( not (PVSS.verify_proof_DLEQ({{g1, h1, g2, h2}, {g3, h3, g4, h4}}, BIG.new(5), {c, c})))
end

-- print('----------------------------------------------')
-- print("TEST generators")
-- I.spy(PVSS.create_generators(10, ECP.prime(), ECP.order()))

print('----------------------------------------------')
print("Create and verify encrypted shares")
print("Test case 1")
local participants = 10
local thr = 6
local secret = BIG.modrand(ECP.order())
local g, G = table.unpack(PVSS.create_generators(2, ECP.prime(), ECP.order()))
local public_keys = {}
local secret_keys = {}
for i=1,participants do
    secret_keys[i] = PVSS.keygen()
    public_keys[i] = PVSS.sk2pk(G, secret_keys[i])
end

local commitments, encrypted_shares, challenge, responses, XXss, evals = PVSS.create_shares(secret, g, public_keys, thr, participants)
assert(PVSS.verify_shares(g, public_keys, thr, participants, commitments, encrypted_shares, challenge, responses))

print("Test failure 1")
-- This fails because there is one wrong encrypted share.
local temp = encrypted_shares[1]
encrypted_shares[1] = encrypted_shares[2]
assert( not PVSS.verify_shares(g, public_keys, thr, participants, commitments, encrypted_shares, challenge, responses))
encrypted_shares[1] = temp

print("Test failure 2")
-- This fails because we pass the wrong generator point.
assert( not PVSS.verify_shares(G, public_keys, thr, participants, commitments, encrypted_shares, challenge, responses))

print("Test failure 3")
-- This fails because there is one wrong public key.
temp = public_keys[1]
public_keys[1] = public_keys[2]
assert( not PVSS.verify_shares(g, public_keys, thr, participants, commitments, encrypted_shares, challenge, responses))
public_keys[1] = temp

print("Test failure 4")
-- This fails because there is one wrong commitment.
temp = commitments[1]
commitments[1] = commitments[2]
assert( not PVSS.verify_shares(g, public_keys, thr, participants, commitments, encrypted_shares, challenge, responses))
commitments[1] = temp

print('----------------------------------------------')
print("Test: decrypt shares")
local shares_proof = {}
for i = 1, participants do
    print("Test case ".. i)
    local table_dec = PVSS.decrypt_share(secret_keys[i], encrypted_shares[i][2], public_keys[i], G, i)
    table.insert(shares_proof, table_dec)
    local S = table.unpack(table_dec,1,1)
    assert(S == G*evals[i])
end

print('----------------------------------------------')
print("Test: verify decrypted shares")
local shares, indexes = PVSS.verify_decrypted_shares(shares_proof)
assert(#shares == participants)

print('----------------------------------------------')
print("Test: pooling the shares")
print("Test case 1")
local sec = PVSS.pooling_shares(shares, indexes, thr)
assert(sec == G*secret)

print("Test case 2")
local sec2 = PVSS.pooling_shares({shares[3], shares[1], shares[5], shares[8], shares[6], shares[2]}, {3,1,5,8,6,2}, thr)
assert(sec2 == G*secret)

print('----------------------------------------------')
print("Create deterministic shares")

-- We test our implementation with a deterministic variant of
-- https://github.com/darkrenaissance/darkfi/blob/master/script/research/pvss/pvss.sage


g = ECP.new(BIG.new(O.from_hex("07ef3f7f6123b2f5e1ce7c249e0a44c8b18b3671e11d5e233d15742cf538d068f94dfae3ac9966e626a3d6670d78b6ee")), BIG.new(O.from_hex("12d5c20e3ce7143c03491820a7b08c067f25bd9b724985cd95ec862f8cbb31c944f420e59f8f820bccf6e94b72236ca7")))
G = ECP.new(BIG.new(O.from_hex("0a17f5c7ea3abe3654c4b56d709efd293e17e79327e15b2a7eababd02b20edf33bba0a6ff2c801923399c3c9fd6a1718")), BIG.new(O.from_hex("12f6579b77dbc6485107e68fe181e0aeb680f665880c7ded1db5f84c0a3fdc152f299511e4e5f64f1422d21c276f848a")))

local t = 3
local n = 5
local s = BIG.new(123)
local sec_keys = {}
local pks = {}
local det_coefs = {s, BIG.new(5), BIG.new(6)}
for i=3,n+2 do
    table.insert(sec_keys, BIG.new(i))
    table.insert(pks, PVSS.sk2pk(G, sec_keys[i-2]))
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

-- TODO: decide if these elements, created by the concatenation ordered as in the original
-- Sage implementation, are worth keeping.
-- There is a difference in how we concatenate elements for the hash in DLEQ.

-- c = BIG.new(O.from_hex("e2014524b9e44a163fc111a57dea33876a21805f49771c4dbca1c57d4e71aeaf"))

-- r = {
--     BIG.new(O.from_hex("0x588f0de349af703f0e23db99f30c1c92268ca93189f9564943529f62f07e9170")),
--     BIG.new(O.from_hex("0x6b384134e6dbcdf054f63f255474745755dff528effbf72050c9e0f3e447dfe5")),
--     BIG.new(O.from_hex("0x502c3f468a7af41338ee37a7ac6cca3e11aaf8ede443883b86abe08e2abcfe3d")),
--     BIG.new(O.from_hex("0x76b0818348ce2a7ba0bc520faf51e4659edb48066d0099ae4f89e31c3ddec78")),
--     BIG.new(O.from_hex("0x4e242fd0eaf16f60b88bf9949af48758265cbe3779fd73d6bb019ddafaaaa97")),
--     }

c = BIG.new(O.from_hex("16089d0de84bd6d3767122f4a62cf5274f1a47d093fcbf58b378eab50bcab997"))
r = {
        BIG.new(O.from_hex("0x3da0c92aa24c46a534a7a4c1fee79df71981112089892f780eb52521d3e2db14")),
        BIG.new(O.from_hex("0x12914a3769f1eec65d64e0e73764f7844d1b2d6f3dcd6e7beed80ed9c4ac2e88")),
        BIG.new(O.from_hex("0x3ae36496cae1fcd6928201acc2ac5b49c6b2d8000233c954654ff81227f4ceeb")),
        BIG.new(O.from_hex("0x42a970f59b7ef38da0c52f0a971bf142328a6ccfd6bde402721ce0cbfdbcbc3c")),
        BIG.new(O.from_hex("0x29e36f53dbc8d2eb882e6900b4b3b96d90a1ebdebb6bbe86153ec9074603f67b")),
}

local commits, enc_shares, chall, resp, Xs = PVSS.create_shares(s, g, pks, t, n, det_coefs)


for k,v in pairs(commits) do
    assert(v:x() == C[k][1])
    assert(v:y() == C[k][2])
end

for k,v in pairs(enc_shares) do
    assert(v[2]:x() == Y[k][1])
    assert(v[2]:y() == Y[k][2])
end

for k,v in pairs(Xs) do
    assert(v:x() == X[k][1])
    assert(v:y() == X[k][2])
end

for k,v in pairs(resp) do
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
    -----------------------------
    { BIG.mod(BIG.new(O.from_hex("464bacedd523dd6091e30dace094685d163e42a6184ef022d46a609e3a95e9a5")), CURVE_ORDER),
    BIG.new(O.from_hex("0x429a424228490256522151649a93e69ba23fe1709ebf5371ae567d8415a85973")) },
    -----------------------------
    { BIG.mod(BIG.new(O.from_hex("064063ad7674764eb880ace296b1211e7b0361fb6a7d466c5b37f750cd04f608")), CURVE_ORDER),
    BIG.new(O.from_hex("0x54abb4efd9572dbe98b6779b182c326cecacba19eb8bfbe137e82b6afee731dd")) },
    -----------------------------
    { BIG.mod(BIG.new(O.from_hex("548d4a42202eef7b4290344f9eec1a91ebf96c1de33830e18b7fe37ba7ef5d7a")), CURVE_ORDER),
    BIG.new(O.from_hex("0x485487130ef9d58570bffe4a76a098af1adbab5baca6a6b1bb00ab151063cf2d")) },
    -----------------------------
    { BIG.mod(BIG.new(O.from_hex("c2106724026534096b1c2dbf275ccc27642524c0667b65d38d4eee0fdd7b265b")), CURVE_ORDER),
    BIG.new(O.from_hex("0x20b105e9e29d732078f0e026600c8b2c2fdfaee1328c872b22d77d84f1a1f393")) },
    -----------------------------
}

local valid_shares = {}

for i = 1, 5 do
    print("Test case ".. i)
    local reconstruction_table = PVSS.decrypt_share(sec_keys[i], enc_shares[i][2], pks[i], G, i,true)
    local S_decrypted, ch, response = table.unpack(reconstruction_table, 1, 3)
    table.insert(valid_shares, S_decrypted)
    assert(S_decrypted:x() == S_array[i][1])
    assert(S_decrypted:y() == S_array[i][2])
    assert(ch == sage_reconstruction_C_R[i][1])
    assert(response == sage_reconstruction_C_R[i][2])
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
assert(shared_secret == (G*s))

print("Test case 2")
assert(shared_secret == PVSS.pooling_shares({valid_shares[2], valid_shares[3], valid_shares[5]}, {2,3, 5}, t))

print('----------------------------------------------')
