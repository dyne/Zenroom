-- RPBSch NIWI prepared-context benchmark.
--
-- Context preparation is intentionally measured once and never subtracted from
-- a proof or verification interval. Proof compression is randomized, so proof
-- length is reported for every sample.

local rpbsch = require'crypto_rpbsch'
local zkcc = require'crypto_zkcc'
local niwi = require'crypto_niwi'

assert(rpbsch and zkcc and niwi, 'RPBSch NIWI modules are required')

local PROVE_ITERATIONS = 3
local VERIFY_ITERATIONS = 10

local function now_ms()
    return os.clock() * 1000
end

local function sorted_copy(samples)
    local out = {}
    for i, value in ipairs(samples) do out[i] = value end
    table.sort(out)
    return out
end

local function median(samples)
    local ordered = sorted_copy(samples)
    local middle = math.floor((#ordered + 1) / 2)
    if (#ordered % 2) == 1 then return ordered[middle] end
    return (ordered[middle] + ordered[middle + 1]) / 2
end

local function render_samples(samples)
    local out = {}
    for i, value in ipairs(samples) do
        out[i] = string.format('%.3f', value)
    end
    return table.concat(out, ',')
end

local function print_row(op, samples, bytes_out, proof_bytes)
    local total = 0
    for _, value in ipairs(samples) do total = total + value end
    local suffix = string.format(
        'BENCH niwi_full op=%s iterations=%d total_ms=%.3f per_ms=%.3f median_ms=%.3f min_ms=%.3f samples_ms=%s bytes_out=%d',
        op, #samples, total, total / #samples, median(samples),
        sorted_copy(samples)[1], render_samples(samples), bytes_out or 0)
    if proof_bytes then suffix = suffix .. ' proof_bytes=' .. proof_bytes end
    print(suffix)
end

print('BENCH niwi_full meta target=native timer=os.clock proof_bytes=serialized_only')

-- The legacy BIP340 fixture circuit is needed to assemble the branch witness.
-- It is deliberately outside the RPBSch runtime preparation measurement.
local circuit = zkcc.bip340_circuit()
local fixture = rpbsch.fixture()

local setup_start = now_ms()
local context = rpbsch.prepare_relation_context()
local setup_ms = now_ms() - setup_start
print(string.format(
    'BENCH niwi_full op=rpbsch_context_prepare iterations=1 total_ms=%.3f per_ms=%.3f median_ms=%.3f min_ms=%.3f samples_ms=%.3f bytes_out=0',
    setup_ms, setup_ms, setup_ms, setup_ms, setup_ms))

local witness_samples = {}
local witness
for _ = 1, PROVE_ITERATIONS do
    local start = now_ms()
    witness = assert(rpbsch.branch_relation_witness(
        circuit, fixture, rpbsch.BRANCH_HONEST))
    witness_samples[#witness_samples + 1] = now_ms() - start
end
print_row('rpbsch_witness_build', witness_samples, #witness:str())

-- Prime caches and validate that the prepared public path is usable before
-- recording warm samples.
local warmup = niwi.prove_rpbsch_relation_prepared(
    context, witness, fixture.statement)
assert(niwi.verify_rpbsch_relation_prepared(context, warmup, fixture.statement),
       'prepared warm-up proof rejected')

local prove_samples = {}
local proof_lengths = {}
local proof
for _ = 1, PROVE_ITERATIONS do
    local start = now_ms()
    proof = niwi.prove_rpbsch_relation_prepared(context, witness, fixture.statement)
    prove_samples[#prove_samples + 1] = now_ms() - start
    assert(niwi.verify_rpbsch_relation_prepared(context, proof, fixture.statement),
           'prepared proof rejected')
    proof_lengths[#proof_lengths + 1] = #proof:str()
end
print_row('niwi_prove_rpbsch_warm', prove_samples, proof_lengths[#proof_lengths],
          table.concat(proof_lengths, ','))

local public_samples = {}
for _ = 1, PROVE_ITERATIONS do
    local start = now_ms()
    proof = rpbsch.prove_branch_relation(circuit, fixture, rpbsch.BRANCH_HONEST)
    public_samples[#public_samples + 1] = now_ms() - start
    assert(rpbsch.verify_branch_relation(proof, fixture.statement),
           'high-level proof rejected')
end
print_row('rpbsch_prove_branch_relation_warm', public_samples,
          #proof:str(), #proof:str())

local verify_samples = {}
for _ = 1, VERIFY_ITERATIONS do
    local start = now_ms()
    assert(niwi.verify_rpbsch_relation_prepared(context, proof, fixture.statement),
           'prepared verification rejected')
    verify_samples[#verify_samples + 1] = now_ms() - start
end
print_row('niwi_verify_rpbsch_warm', verify_samples, #proof:str(), #proof:str())
