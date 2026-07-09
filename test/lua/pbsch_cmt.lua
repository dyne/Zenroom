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
