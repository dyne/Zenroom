local ZK = require'crypto_longfellow'

local function expect_error(fn, needle)
    local ok, err = pcall(fn)
    assert(not ok, "expected failure containing: "..needle)
    assert(string.find(err, needle, 1, true), err)
end

local function expect_native_failure(fn)
    local ok, res = pcall(fn)
    assert(ok, res)
    assert(res == nil, "expected native failure to return nil")
end

local circuit = {
    compressed = O.zero(1),
    zkspec = BIG.new(1),
}
local proof = {
    zk = O.zero(1),
    zkspec = BIG.new(1),
}
local pkx = O.zero(32)
local pky = O.zero(32)
local transcript = O.zero(32)
local attributes = {{ id = 'age_over_18', value = ZK.yes }}
local now = O.from_string('2024-01-30T09:00:00Z')
local doc_type = O.from_string('org.iso.18013.5.1.mDL')

local ok = pcall(function()
    ZK.mdoc_prover(circuit, O.zero(64), pkx, pky, transcript, attributes, now)
end)
assert(ok, 'structurally valid Longfellow prover inputs should pass Lua guards')

ok = pcall(function()
    ZK.mdoc_verifier(circuit, proof, pkx, pky, transcript, attributes, now, doc_type)
end)
assert(ok, 'structurally valid Longfellow verifier inputs should pass Lua guards')

expect_error(function()
    ZK.mdoc_prover('bad-circuit', O.zero(64), pkx, pky, transcript, attributes, now)
end, 'Invalid circuit not a table')

expect_error(function()
    ZK.mdoc_prover(circuit, 'bad-mdoc', pkx, pky, transcript, attributes, now)
end, 'Invalid MDOC either too small or not an octet')

expect_error(function()
    ZK.mdoc_verifier(
        circuit,
        { zkspec = proof.zkspec, zk = 'bad-proof' },
        pkx,
        pky,
        transcript,
        attributes,
        now,
        doc_type
    )
end, 'Invalid proof does not contain a ZK octet')

expect_native_failure(function()
    return ZK.mdoc_prover(
        circuit,
        O.zero(64),
        pkx,
        pky,
        transcript,
        {{ id = string.rep('a', 33), value = ZK.yes }},
        now
    )
end)

expect_native_failure(function()
    return ZK.mdoc_prover(
        circuit,
        O.zero(64),
        pkx,
        pky,
        transcript,
        {{ id = 'age_over_18', value = O.zero(65) }},
        now
    )
end)

expect_native_failure(function()
    return ZK.mdoc_prover(
        { compressed = O.zero(1), zkspec = BIG.new(0) },
        O.zero(64),
        pkx,
        pky,
        transcript,
        attributes,
        now
    )
end)

print('longfellow guard regressions OK')
