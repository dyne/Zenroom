#!/usr/bin/env lua
-- Test ECDSA witness generation with OCTET

print("=== ECDSA Witness Test ===\n")

-- Load the ZK witness module
local ZK = require('zkcc')
local WIT = ZK.witness

print("Test 1: ECDSA witness creation")

P256 = require('es256')
local sk = P256.keygen()
local pk = P256.pubgen(sk)
local pkX = pk:sub(1,32)
local pkY = pk:sub(33,64)
local e = OCTET.random(32)
local sig = P256.sign(sk,e)
local r = sig:sub(1,32)
local s = sig:sub(33,64)
assert(P256.verify(pk,e,sig))

print("  Creating ECDSA witness...")
local witness = WIT.ecdsa_create_witness(pkX, pkY, e, r, s)
assert(witness, "Witness creation should succeed")
print("  ✓ Witness created successfully\n")

-- Test 2: Access witness components
print("Test 2: Access witness components")
local rx = witness:get_rx()
assert(rx, "Should get rx")
assert(#rx == 32, "rx should be 32 bytes")
print("  rx length:", #rx)
print("  rx hex:", rx:hex():sub(1, 16) .. "...")

local ry = witness:get_ry()
assert(ry, "Should get ry")
assert(#ry == 32, "ry should be 32 bytes")
print("  ry length:", #ry)
print("  ✓ Witness accessors work\n")

-- Test 3: Get inverse values
print("Test 3: Access inverse values")
local rx_inv = witness:get_rx_inv()
assert(rx_inv, "Should get rx_inv")
assert(#rx_inv == 32, "rx_inv should be 32 bytes")

local s_inv = witness:get_s_inv()
assert(s_inv, "Should get s_inv")
assert(#s_inv == 32, "s_inv should be 32 bytes")
print("  ✓ Inverse accessors work\n")

-- Test 4: Error handling - invalid OCTET size
print("Test 4: Error handling")
local short_octet = OCTET.from_hex("DEADBEEF")
local status, err = pcall(function()
    WIT.ecdsa_create_witness(short_octet, pkY, e, r, s)
end)
assert(not status, "Should fail with invalid OCTET size")
print("  ✓ Error handling works correctly\n")

-- Test 5: Type conversion utility
print("Test 5: Type conversion (nat_from_octet)")
local test_bytes = OCTET.from_hex("0000000000000000000000000000000000000000000000000000000000000001")
local nat = WIT.nat_from_octet(test_bytes)
assert(type(nat) == "table", "nat should be a table")
print("  ✓ Type conversion works\n")

print("=== All ECDSA tests passed! ===")
