-- PBSch extractable Cmt profile tests.
--
-- Vector source: deterministic local values derived with SHA-256 tags and the
-- native secp256k1 Pedersen primitive. These are implementation vectors for
-- the current Pedersen-backed extractable opening profile.

local pbsch = require("crypto_pbsch")
assert(pbsch)

local function flip_last_nibble(oct)
    local hex = oct:hex()
    local prefix = hex:sub(1, #hex - 1)
    local last = tonumber(hex:sub(#hex, #hex), 16)
    return OCTET.from_hex(prefix .. string.format("%x", last ~ 1))
end

local m = sha256("PBSch/Cmt/test/message")
local rho = sha256("PBSch/Cmt/test/rho")
local wrong_m = sha256("PBSch/Cmt/test/wrong-message")
local wrong_rho = sha256("PBSch/Cmt/test/wrong-rho")

local record = pbsch.cmt_commit(m, rho)
assert(record.profile == pbsch.CMT_PROFILE)
assert(#record.ck:str() == 32)
assert(#record.commitment:str() == pbsch.C_SIZE)
assert(#record.opening:str() == pbsch.CMT_OPENING_SIZE)
assert(pbsch.cmt_verify(record.commitment, record.opening),
       "valid extractable Cmt opening rejected")

local extracted = pbsch.cmt_extract(record.commitment, record.opening)
assert(extracted, "valid extractable Cmt did not extract")
assert(extracted.message:string() == m:string(), "extracted message mismatch")
assert(extracted.rho:string() == rho:string(), "extracted randomness mismatch")

local proof = pbsch.cmt2_prove(record.commitment, m, rho)
assert(#proof:str() == pbsch.CMT2_PROOF_SIZE, "unexpected CMT2 proof size")
assert(pbsch.cmt2_verify(record.commitment, proof),
       "valid CMT2 opening proof rejected")
assert(not pbsch.cmt2_verify(flip_last_nibble(record.commitment), proof),
       "CMT2 proof accepted for wrong commitment")
assert(not pbsch.cmt2_verify(record.commitment, flip_last_nibble(proof)),
       "mutated CMT2 proof accepted")

local cmt2_record = pbsch.cmt2_commit(m, rho)
assert(cmt2_record.profile == pbsch.CMT2_PROFILE)
assert(cmt2_record.commitment:string() == record.commitment:string(),
       "CMT2 commitment point mismatch")
assert(pbsch.cmt2_verify(cmt2_record.commitment, cmt2_record.proof),
       "CMT2 commit proof rejected")

assert(pbsch.CMT3_PROFILE == "pbsch-cmt-pedersen-fischlin05-v1",
       "unexpected CMT3 profile")
assert(pbsch.CMT3_PROOF_SIZE == 1027, "unexpected CMT3 proof size")
assert(pbsch.CMT3_B == 9 and pbsch.CMT3_T == 12 and
       pbsch.CMT3_R == 10 and pbsch.CMT3_S == 10,
       "unexpected CMT3 Fischlin parameters")

local function blank_cmt3_proof()
    return OCTET.from_string("CMT3") ..
           OCTET.from_hex("01") ..
           pbsch.commitment_key() ..
           OCTET.zero(33 * pbsch.CMT3_R) ..
           OCTET.zero(2 * pbsch.CMT3_R) ..
           OCTET.zero(32 * pbsch.CMT3_R) ..
           OCTET.zero(32 * pbsch.CMT3_R)
end

local malformed_cmt3 = blank_cmt3_proof()
assert(#malformed_cmt3:str() == pbsch.CMT3_PROOF_SIZE,
       "test CMT3 proof has wrong size")
assert(pbsch.cmt3_verify(record.commitment, malformed_cmt3) == false,
       "blank CMT3 proof accepted")
assert(pbsch.cmt3_verify(record.commitment,
                         OCTET.from_string("BAD3") ..
                         malformed_cmt3:sub(5, pbsch.CMT3_PROOF_SIZE)) == false,
       "bad CMT3 tag accepted")
assert(pbsch.cmt3_verify(record.commitment,
                         malformed_cmt3:sub(1, 4) ..
                         OCTET.from_hex("02") ..
                         malformed_cmt3:sub(6, pbsch.CMT3_PROOF_SIZE)) == false,
       "bad CMT3 profile byte accepted")
assert(pbsch.cmt3_verify(record.commitment,
                         malformed_cmt3:sub(1, pbsch.CMT3_PROOF_SIZE - 1)) == false,
       "truncated CMT3 proof accepted")

local sigma_a = sha256("PBSch/CMT3/test/a")
local sigma_b = sha256("PBSch/CMT3/test/b")
local sigma_ch = 37
local scalar_three = OCTET.from_hex(string.rep("0", 63) .. "3")
local scalar_five = OCTET.from_hex(string.rep("0", 63) .. "5")
local scalar_div = SECP.bip340_scalar_div(SECP.bip340_scalar_mul(scalar_three,
                                                                 scalar_five),
                                          scalar_five)
assert(scalar_div:string() == scalar_three:string(),
       "SECP scalar division did not invert multiplication modulo n")
local zero_divisor_ok = pcall(function()
    SECP.bip340_scalar_div(scalar_three, OCTET.zero(32))
end)
assert(zero_divisor_ok == false, "SECP scalar division accepted zero divisor")
local sigma_A = pbsch.cmt3_sigma_commit(sigma_a, sigma_b)
local sigma_z_m, sigma_z_r =
    pbsch.cmt3_sigma_respond(sigma_a, sigma_b, sigma_ch, m, rho)
assert(pbsch.cmt3_sigma_verify(record.commitment, sigma_A, sigma_ch,
                               sigma_z_m, sigma_z_r),
       "valid CMT3 Sigma transcript rejected")
assert(not pbsch.cmt3_sigma_verify(flip_last_nibble(record.commitment),
                                   sigma_A, sigma_ch, sigma_z_m, sigma_z_r),
       "CMT3 Sigma accepted wrong commitment")
assert(not pbsch.cmt3_sigma_verify(record.commitment,
                                   flip_last_nibble(sigma_A),
                                   sigma_ch, sigma_z_m, sigma_z_r),
       "CMT3 Sigma accepted wrong A")
assert(not pbsch.cmt3_sigma_verify(record.commitment, sigma_A,
                                   sigma_ch + 1, sigma_z_m, sigma_z_r),
       "CMT3 Sigma accepted wrong challenge")
assert(not pbsch.cmt3_sigma_verify(record.commitment, sigma_A, sigma_ch,
                                   flip_last_nibble(sigma_z_m), sigma_z_r),
       "CMT3 Sigma accepted wrong z_m")
assert(not pbsch.cmt3_sigma_verify(record.commitment, sigma_A, sigma_ch,
                                   sigma_z_m, flip_last_nibble(sigma_z_r)),
       "CMT3 Sigma accepted wrong z_r")
local secp_order = OCTET.from_hex(
    "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141")
assert(not pbsch.cmt3_sigma_verify(record.commitment, sigma_A, 4096,
                                   sigma_z_m, sigma_z_r),
       "CMT3 Sigma accepted challenge 4096")
assert(not pbsch.cmt3_sigma_verify(record.commitment, sigma_A, 65535,
                                   sigma_z_m, sigma_z_r),
       "CMT3 Sigma accepted challenge 65535")
assert(not pbsch.cmt3_sigma_verify(record.commitment, sigma_A, sigma_ch,
                                   secp_order, sigma_z_r),
       "CMT3 Sigma accepted z_m equal to order")
assert(not pbsch.cmt3_sigma_verify(record.commitment, sigma_A, sigma_ch,
                                   sigma_z_m, secp_order),
       "CMT3 Sigma accepted z_r equal to order")
assert(not pbsch.cmt3_sigma_verify(record.commitment, OCTET.zero(33),
                                   sigma_ch, sigma_z_m, sigma_z_r),
       "CMT3 Sigma accepted invalid A point")
assert(not pbsch.cmt3_sigma_verify(OCTET.zero(33), sigma_A,
                                   sigma_ch, sigma_z_m, sigma_z_r),
       "CMT3 Sigma accepted invalid commitment point")

local native_cmt3_proof = pbsch.cmt3_prove(record.commitment, m, rho, {
    seed = sha256("PBSch/CMT3/test/native-proof"),
})
assert(#native_cmt3_proof:str() == pbsch.CMT3_PROOF_SIZE,
       "unexpected native CMT3 proof size")
assert(pbsch.cmt3_verify(record.commitment, native_cmt3_proof),
       "valid native CMT3 proof rejected")

local cmt3_proof, cmt3_queries = pbsch.cmt3_prove_with_observation_test(record.commitment, m, rho, {
    seed = sha256("PBSch/CMT3/test/proof"),
})
assert(#cmt3_proof:str() == pbsch.CMT3_PROOF_SIZE,
       "unexpected CMT3 proof size")
assert(#cmt3_queries > pbsch.CMT3_R,
       "observed CMT3 proof did not record alternate queries")
assert(pbsch.cmt3_verify(record.commitment, cmt3_proof),
       "valid CMT3 proof rejected")
assert(not pbsch.cmt3_verify(flip_last_nibble(record.commitment), cmt3_proof),
       "CMT3 proof accepted for wrong commitment")
assert(not pbsch.cmt3_verify(record.commitment, flip_last_nibble(cmt3_proof)),
       "mutated CMT3 proof accepted")
local bad_cmt3_A = cmt3_proof:sub(1, 37) ..
                   flip_last_nibble(cmt3_proof:sub(38, 70)) ..
                   cmt3_proof:sub(71, pbsch.CMT3_PROOF_SIZE)
assert(not pbsch.cmt3_verify(record.commitment, bad_cmt3_A),
       "CMT3 proof accepted mutated A")
local bad_cmt3_ch = cmt3_proof:sub(1, 367) ..
                    OCTET.from_hex("1000") ..
                    cmt3_proof:sub(370, pbsch.CMT3_PROOF_SIZE)
assert(not pbsch.cmt3_verify(record.commitment, bad_cmt3_ch),
       "CMT3 proof accepted challenge 4096")

local cmt3_extracted =
    pbsch.cmt3_extract_from_queries(record.commitment, cmt3_proof, cmt3_queries)
assert(cmt3_extracted, "valid observed CMT3 proof did not extract")
assert(cmt3_extracted.message:string() == m:string(),
       "CMT3 extracted message mismatch")
assert(cmt3_extracted.rho:string() == rho:string(),
       "CMT3 extracted randomness mismatch")

local selected_only = {}
for _, q in ipairs(cmt3_queries) do
    if q.selected then table.insert(selected_only, q) end
end
assert(not pbsch.cmt3_extract_from_queries(record.commitment, cmt3_proof,
                                           selected_only),
       "CMT3 extraction accepted without alternate challenges")

local corrupted_queries = {}
local corrupted = false
for _, q in ipairs(cmt3_queries) do
    if q.selected then
        table.insert(corrupted_queries, q)
    elseif not corrupted then
        table.insert(corrupted_queries, {
            commitment = q.commitment,
            ck = q.ck,
            all_A = q.all_A,
            i = q.i,
            ch = q.ch,
            z_m = flip_last_nibble(q.z_m),
            z_r = q.z_r,
            h = q.h,
        })
        corrupted = true
    end
end
assert(not pbsch.cmt3_extract_from_queries(record.commitment, cmt3_proof,
                                           corrupted_queries),
       "CMT3 extraction accepted corrupted alternate query")

local noisy_queries = {{
    commitment = flip_last_nibble(cmt3_queries[1].commitment),
    ck = cmt3_queries[1].ck,
    all_A = cmt3_queries[1].all_A,
    i = cmt3_queries[1].i,
    ch = cmt3_queries[1].ch,
    z_m = cmt3_queries[1].z_m,
    z_r = cmt3_queries[1].z_r,
    h = cmt3_queries[1].h,
}}
for _, q in ipairs(cmt3_queries) do table.insert(noisy_queries, q) end
assert(pbsch.cmt3_extract_from_queries(record.commitment, cmt3_proof,
                                       noisy_queries),
       "CMT3 extraction rejected valid queries with irrelevant noise")

assert(not pbsch.cmt_verify(record.commitment, pbsch.cmt_opening(wrong_m, rho)),
       "wrong message opening accepted")
assert(not pbsch.cmt_verify(record.commitment, pbsch.cmt_opening(m, wrong_rho)),
       "wrong randomness opening accepted")
assert(not pbsch.cmt_verify(flip_last_nibble(record.commitment), record.opening),
       "malformed commitment accepted")
assert(not pbsch.cmt_verify(record.commitment, flip_last_nibble(record.opening)),
       "wrong ck/opening material accepted")
assert(pbsch.cmt_extract(record.commitment, OCTET.from_string("missing")) == nil,
       "missing extraction data accepted")

local order = OCTET.from_hex(
    "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141")
local ok = pcall(function()
    pbsch.cmt_commit(order, rho)
end)
assert(ok == false, "non-canonical message scalar accepted")
ok = pcall(function()
    pbsch.cmt_commit(m, order)
end)
assert(ok == false, "non-canonical randomness scalar accepted")

print("✓ PBSch extractable Cmt profile tests passed")
