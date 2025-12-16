#!/usr/bin/env lua
-- Test SHA-256 witness generation with OCTET

print("=== SHA-256 Witness Test ===\n")

-- Load the ZKCC module
local zkcc = require('zkcc')

-- Test 1: Empty message
print("Test 1: Empty message")
local empty = OCTET.new(0)
local result = zkcc.witness.sha256_compute_message(empty, 1)
assert(result.num_blocks == 1, "Expected 1 block for empty message")
assert(#result.padded_input == 64, "Expected 64 bytes padded input")
print("  num_blocks: ".. result.num_blocks)
print("  padded_input length: ".. #result.padded_input)
print("  ✓ Empty message test passed\n")

-- Test 2: "abc" - standard test vector
print("Test 2: Message 'abc'")
local abc = OCTET.from_string("abc")
local result2 = zkcc.witness.sha256_compute_message(abc, 1)
assert(result2.num_blocks == 1, "Expected 1 block")
assert(#result2.padded_input == 64, "Expected 64 bytes")

-- Expected SHA-256("abc") = 
-- ba7816bf 8f01cfea 414140de 5dae2223 b00361a3 96177a9c b410ff61 f20015ad
local h1 =result2.witnesses[1].h1
string.format("  Hash: %08x %08x %08x %08x %08x %08x %08x %08x",
    h1[1], h1[2], h1[3], h1[4], h1[5], h1[6], h1[7], h1[8])

assert(h1[1] == 0xba7816bf, "Hash word 0 mismatch")
assert(h1[2] == 0x8f01cfea, "Hash word 1 mismatch")
assert(h1[3] == 0x414140de, "Hash word 2 mismatch")
assert(h1[4] == 0x5dae2223, "Hash word 3 mismatch")
assert(h1[5] == 0xb00361a3, "Hash word 4 mismatch")
assert(h1[6] == 0x96177a9c, "Hash word 5 mismatch")
assert(h1[7] == 0xb410ff61, "Hash word 6 mismatch")
assert(h1[8] == 0xf20015ad, "Hash word 7 mismatch")
print("  ✓ Hash matches expected value\n")

-- Test 3: Longer message requiring multiple blocks
print("Test 3: Long message (100 'a' characters)")
local long_msg = OCTET.random(100)
local result3 = zkcc.witness.sha256_compute_message(long_msg, 4)
print("  num_blocks: ".. result3.num_blocks)
assert(result3.num_blocks == 2, "Expected 2 blocks for 100 bytes")
print("  ✓ Multi-block message test passed\n")

-- Test 4: Check witness structure
print("Test 4: Witness structure validation")
local w = result2.witnesses[1]
assert(type(w.outw) == "table", "outw should be a table")
assert(#w.outw == 48, "outw should have 48 elements")
assert(type(w.oute) == "table", "oute should be a table")
assert(#w.oute == 64, "oute should have 64 elements")
assert(type(w.outa) == "table", "outa should be a table")
assert(#w.outa == 64, "outa should have 64 elements")
assert(type(w.h1) == "table", "h1 should be a table")
assert(#w.h1 == 8, "h1 should have 8 elements")
print("  ✓ Witness structure is correct\n")

-- Test 5: Error handling - invalid max_blocks
print("Test 5: Error handling")
local status, err = pcall(function()
	  zkcc.witness.sha256_compute_message(abc, 0)
end)

assert(not status, "Should fail with max_blocks = 0")
print("  ✓ Error handling works correctly\n")

print("=== All SHA-256 tests passed! ===")
