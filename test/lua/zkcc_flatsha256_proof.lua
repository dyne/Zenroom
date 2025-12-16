-- FlatSHA256 prover/verifier demo using positional inputs (no named_logic).
-- Mirrors lib/longfellow-zk/circuits/sha/flatsha256_circuit.h.

local zkcc = require'crypto_zkcc'

local L = zkcc.logic()
local BA = L:create_bit_adder32()

local MAX_BLOCKS = 1

local K <const> = {
  0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,
  0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
  0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,
  0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
  0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,
  0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
  0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,
  0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
  0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,
  0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
  0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,
  0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
  0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,
  0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
  0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,
  0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2,
}
-- Optimized: precompute K constants as bit32 values
local K_const <const> = {}
for t = 1, 64 do K_const[t] = L:vbit32(K[t]) end

local H0_CONST <const> = {
  0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,
  0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19,
}
local H0 <const> = {}
for i = 1, 8 do H0[i] = L:vbit32(H0_CONST[i]) end

local function oct_field(x)
  return OCTET.from_hex(string.format('%064x', x & 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff))
end

local function oct_bit(b)
  return b and oct_field(1) or oct_field(0)
end

-- Optimized: cache bit decomposition results
local bits_cache = {}
local function bits_le(value, nbits)
  local key = string.format('%x_%d', value, nbits)
  if bits_cache[key] then
    return bits_cache[key]
  end
  local t = {}
  for i = 0, nbits - 1 do
    t[i + 1] = (value >> i) & 1
  end
  bits_cache[key] = t
  return t
end

-- Public inputs
local nb_bits = L:vinput8()     -- number of blocks (must be 1)
local hash_bits = L:vinput256() -- target digest
L:private_inputs()

-- Private inputs
local msg_bytes = {}
for i = 1, 64 * MAX_BLOCKS do msg_bytes[i] = L:vinput8() end
local outw, oute, outa = {}, {}, {}
for i = 1, 48 do outw[i] = L:vinput32() end
for i = 1, 64 do
  oute[i] = L:vinput32()
  outa[i] = L:vinput32()
end
local h1 = {}
for i = 1, 8 do h1[i] = L:vinput32() end

local function Sigma0(x)
  return L:vxor3_32(L:vrotr32(x, 2),
                    L:vrotr32(x, 13),
                    L:vrotr32(x, 22))
end
local function Sigma1(x)
  return L:vxor3_32(L:vrotr32(x, 6),
                    L:vrotr32(x, 11),
                    L:vrotr32(x, 25))
end
local function sigma0(x)
  return L:vxor3_32(L:vrotr32(x, 7),
                    L:vrotr32(x, 18),
                    L:vshr32(x, 3, 0))
end
local function sigma1(x)
  return L:vxor3_32(L:vrotr32(x, 17),
                    L:vrotr32(x, 19),
                    L:vshr32(x, 10, 0))
end

local function bytes_to_words(bytes, block_index)
  local base = (block_index - 1) * 64
  local words = {}
  for i = 1, 16 do
    local idx = base + (i - 1) * 4
    local low16 = L:vappend_8_8(bytes[idx + 4], bytes[idx + 3])
    local high16 = L:vappend_8_8(bytes[idx + 2], bytes[idx + 1])
    words[i] = L:vappend_16_16(low16, high16)
  end
  return words
end

local function assert_transform_block(in_words, witness)
  local w = {}
  for i = 1, 16 do w[i] = in_words[i] end
  -- Optimized: use precomputed W values as witnesses with simple equality checks
  for i = 17, 64 do
    w[i] = witness.outw[i - 16]
    local terms = {sigma1(w[i - 2]), w[i - 7], sigma0(w[i - 15]), w[i - 16]}
    BA:assert_eqmod(w[i], BA:add(terms), 4)
  end

  local a, b, c, d = H0[1], H0[2], H0[3], H0[4]
  local e, f, g, h = H0[5], H0[6], H0[7], H0[8]


  for t = 1, 64 do
    -- Optimized: use precomputed boolean operations
    local e_sigma1 = Sigma1(e)
    local e_ch = L:vCh32(e, f, g)
    local a_sigma0 = Sigma0(a)
    local a_maj = L:vMaj32(a, b, c)

    local t1 = BA:add{h, e_sigma1, e_ch, K_const[t], w[t]}
    local t2 = BA:add_eltw(BA:as_field_element(a_sigma0), BA:as_field_element(a_maj))

    h, g, f = g, f, e
    e = witness.oute[t]
    BA:assert_eqmod(e, BA:add_eltw(t1, BA:as_field_element(d)), 6)
    d, c, b = c, b, a
    a = witness.outa[t]
    BA:assert_eqmod(a, BA:add_eltw(t1, t2), 7)
  end

  local final <const> = {a, b, c, d, e, f, g, h}
  for i = 1, 8 do
    BA:assert_eqmod(witness.h1[i], BA:add_v32(H0[i], final[i]), 2)
  end
end

local function assert_hash(target, h_words)
  -- Optimized: direct word comparison (8 comparisons instead of 256 bit comparisons)
  for j = 1, 8 do
    local offset = (8 - j) * 32
    local target_word = L:vbit32(0)
    for k = 1, 32 do
      target_word:set(k, target:get(offset + k))
    end
    L:assert1(L:veq32(h_words[j], target_word))
  end
end

local function build_assertions()
  -- nb == 1
  L:assert1(L:veq8_const(nb_bits, MAX_BLOCKS))
  local words = bytes_to_words(msg_bytes, 1)
  assert_transform_block(words,
                         {outw = outw,
                          oute = oute,
                          outa = outa,
                          h1 = h1})
  assert_hash(hash_bits, h1)
end

build_assertions()

local artifact = L:compile(1)
print(string.format('Circuit: inputs=%d (public=%d) depth=%d wires=%d',
  artifact.ninput - 1, artifact.npub_input - 1, artifact.depth, artifact.nwires))

-- Build witness inputs from concrete values (positional indices)
local function set_bits(inputs, start_idx, bits)
  for i = 1, #bits do
    inputs[start_idx + i - 1] = oct_bit(bits[i] == 1)
  end
  return start_idx + #bits
end

local function set_bits_from_int(inputs, start_idx, value, nbits)
  return set_bits(inputs, start_idx, bits_le(value, nbits))
end

local message = OCTET.from_string('abc')
local witness_data = zkcc.witness.sha256_compute_message(message, MAX_BLOCKS)
local bw = witness_data.witnesses[1]
local padded = witness_data.padded_input:str()

local inputs = {}

-- nb = 1
local idx = 1
idx = set_bits_from_int(inputs, idx, MAX_BLOCKS, 8)

-- message bytes (private)
-- reserve hash bits in public section first
idx = set_bits(inputs, idx, {}) -- placeholder (hash filled below)
local hash_start = idx
-- hash bits occupy 256 slots
idx = hash_start + 256

for i = 1, 64 do
  idx = set_bits_from_int(inputs, idx, string.byte(padded, i), 8)
end

-- witness values
for i = 1, 48 do
  idx = set_bits_from_int(inputs, idx, bw.outw[i], 32)
end
for i = 1, 64 do
  idx = set_bits_from_int(inputs, idx, bw.oute[i], 32)
  idx = set_bits_from_int(inputs, idx, bw.outa[i], 32)
end
for i = 1, 8 do
  idx = set_bits_from_int(inputs, idx, bw.h1[i], 32)
end

-- public hash derived from h1 (word-order big-endian, bit little-endian per word)
for j = 1, 8 do
  local word = bw.h1[j]
  local word_bits = bits_le(word, 32)
  local offset = (8 - j) * 32
  for k = 1, 32 do
    inputs[hash_start + offset + k - 1] = oct_bit(word_bits[k] == 1)
  end
end

local seed = OCTET.from_hex(string.rep('07', 32))

local prover_witness = zkcc.build_witness_inputs{
  circuit = artifact,
  inputs = inputs,
}

local proof = zkcc.prove_circuit{
  circuit = artifact,
  inputs = prover_witness,
  seed = seed,
}
assert(proof, 'proof generation failed')

-- Public-only inputs (hash + nb)
local public_inputs = {}
local pidx = 1
pidx = set_bits_from_int(public_inputs, pidx, MAX_BLOCKS, 8)
local phash_start = pidx
phash_start = phash_start -- clarity
for j = 1, 8 do
  local word_bits = bits_le(bw.h1[j], 32)
  local offset = (8 - j) * 32
  for k = 1, 32 do
    public_inputs[phash_start + offset + k - 1] = oct_bit(word_bits[k] == 1)
  end
end

local public_witness = zkcc.build_witness_inputs{
  circuit = artifact,
  inputs = public_inputs,
}

local ok = zkcc.verify_circuit{
  circuit = artifact,
  proof = proof,
  public_inputs = public_witness,
  seed = seed,
}
assert(ok, 'verification failed')

print('✓ Verified FlatSHA256 preimage with positional inputs (public hash + nb)')
