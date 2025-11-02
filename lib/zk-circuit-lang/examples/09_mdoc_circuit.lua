--[[
  mDoc Circuit Structure Demonstration
  
  This demonstrates the STRUCTURE of the mDoc verification circuit
  based on lib/longfellow-zk/circuits/mdoc/ implementation.
  
  Shows the two-circuit architecture with MAC linkage but uses
  placeholder constraints since full ECDSA/SHA-256/MAC circuits
  are not yet available in Lua bindings.
  
  Based on:
    - mdoc_signature.h: Signature verification circuit
    - mdoc_hash.h: Hash and CBOR parsing circuit
    - mdoc_constants.h: CBOR structure definitions
--]]

ZK = require'longfellow'

print("╔═══════════════════════════════════════════════════════════╗")
print("║  mDoc Circuit Structure (ISO 18013-5)                     ║")
print("╚═══════════════════════════════════════════════════════════╝\n")

local NUM_ATTR = 2
print(string.format("Configuration: %d attributes\n", NUM_ATTR))

-- =============================================================================
-- PART 1: SIGNATURE CIRCUIT (Fp256Base)
-- =============================================================================
print("PART 1: Signature Circuit (Fp256Base)")
print("--------------------------------------")
print("Verifies ECDSA signatures from issuer and device\n")

local logic_sig = create_logic()

-- Public inputs
print("Public Inputs:")
print("  • Issuer public key (pkX, pkY)")
local pkX = logic_sig:eltw_input()
local pkY = logic_sig:eltw_input()

print("  • Session transcript hash")
local hash_tr = logic_sig:eltw_input()

print("  • MAC tags (2×3 + 1 = 7 values)")
local mac_e1 = logic_sig:eltw_input()
local mac_e2 = logic_sig:eltw_input()
local mac_dpkx1 = logic_sig:eltw_input()
local mac_dpkx2 = logic_sig:eltw_input()
local mac_dpky1 = logic_sig:eltw_input()
local mac_dpky2 = logic_sig:eltw_input()
local a_v = logic_sig:eltw_input()

-- Mark private inputs boundary
local Q_sig = logic_sig:get_circuit()
Q_sig:private_input()

-- Private inputs
print("\nPrivate Inputs (Witnesses):")
print("  • Message digest e (SHA-256 of MSO)")
local e = logic_sig:eltw_input()

print("  • Device public key (dpkx, dpky)")
local dpkx = logic_sig:eltw_input()
local dpky = logic_sig:eltw_input()

print("  • ECDSA witnesses (placeholders)")
for i = 1, 4 do
    logic_sig:eltw_input()  -- Simplified signature witness
end

print("  • MAC witnesses (3 proofs)")
for i = 1, 3 do
    logic_sig:eltw_input()  -- MAC prover key shares
end

-- Constraints (placeholders)
print("\nConstraints:")
print("  1. verify_signature3(pkX, pkY, e, mdoc_sig)")
print("  2. verify_signature3(dpkx, dpky, hash_tr, dpk_sig)")
print("  3. verify_mac(e, mac_e, a_v, mac_witness[0])")
print("  4. verify_mac(dpkx, mac_dpkx, a_v, mac_witness[1])")
print("  5. verify_mac(dpky, mac_dpky, a_v, mac_witness[2])")

-- Placeholder constraint to make circuit valid
local check = pkX * pkY
local diff = check - hash_tr
logic_sig:assert0(diff)

Q_sig:mkcircuit(1)

print(string.format("\n✓ Signature Circuit: %d inputs, depth %d, %d wires\n",
                    Q_sig.ninput, Q_sig.depth, Q_sig.nwires))

-- =============================================================================
-- PART 2: HASH CIRCUIT (GF2_128 / Fp256)
-- =============================================================================
print("PART 2: Hash Circuit (GF2_128/Fp256)")
print("------------------------------------")
print("Verifies SHA-256 hashes and CBOR structure\n")

local logic_hash = create_logic()

-- Public inputs
print("Public Inputs:")
print(string.format("  • %d attributes (name + value + length)", NUM_ATTR))
for i = 1, NUM_ATTR do
    -- 32 bytes name
    for j = 1, 32 do
        logic_hash:vinput8()
    end
    -- 64 bytes value
    for j = 1, 64 do
        logic_hash:vinput8()
    end
    -- 1 byte length
    logic_hash:vinput8()
end

print("  • Current time 'now' (20 bytes)")
for i = 1, 20 do
    logic_hash:vinput8()
end

print("  • MAC tags (7 values, same as signature circuit)")
for i = 1, 7 do
    logic_hash:eltw_input()
end

-- Mark private inputs boundary
local Q_hash = logic_hash:get_circuit()
Q_hash:private_input()

-- Private inputs
print("\nPrivate Inputs (Witnesses):")
print("  • Shared values (e, dpkx, dpky) bound by MACs")
local e_hash = logic_hash:eltw_input()
local dpkx_hash = logic_hash:eltw_input()
local dpky_hash = logic_hash:eltw_input()

print("  • MSO content (up to 832 bytes)")
print("    - Block number indicator")
logic_hash:vinput8()

print("    - MSO bytes (simplified: 100 bytes)")
for i = 1, 100 do
    logic_hash:vinput8()
end

print("  • SHA-256 witnesses (simplified)")
for i = 1, 10 do
    logic_hash:eltw_input()
end

print("  • CBOR parsing indices")
print("    - validFrom, validUntil, deviceKeyInfo, valueDigests")
for i = 1, 4 do
    logic_hash:vinput16()
end

print(string.format("  • Per-attribute witnesses (%d attributes)", NUM_ATTR))
for ai = 1, NUM_ATTR do
    -- Attribute data (128 bytes)
    for i = 1, 128 do
        logic_hash:vinput8()
    end
    -- CBOR indices (5 values)
    for i = 1, 5 do
        logic_hash:vinput16()
    end
end

print("  • MAC witnesses (3)")
for i = 1, 3 do
    logic_hash:eltw_input()
end

-- Constraints (placeholders)
print("\nConstraints:")
print("  1. SHA-256(MSO) = e")
print("  2. validFrom <= now <= validUntil")
print("  3. Extract dpkx, dpky from MSO deviceKeyInfo")
print(string.format("  4. Verify %d attribute hashes", NUM_ATTR))
print("  5. Verify MACs bind circuits")

-- Placeholder constraint
local check_hash = e_hash * dpkx_hash
local diff_hash = check_hash - dpky_hash
logic_hash:assert0(diff_hash)

Q_hash:mkcircuit(1)

print(string.format("\n✓ Hash Circuit: %d inputs, depth %d, %d wires\n",
                    Q_hash.ninput, Q_hash.depth, Q_hash.nwires))

-- =============================================================================
-- SUMMARY
-- =============================================================================
print("╔═══════════════════════════════════════════════════════════╗")
print("║  Circuit Summary                                          ║")
print("╚═══════════════════════════════════════════════════════════╝\n")

print("TWO-CIRCUIT ARCHITECTURE:")
print(string.format("  Signature: %d inputs, %d wires",
                    Q_sig.ninput, Q_sig.nwires))
print(string.format("  Hash:      %d inputs, %d wires",
                    Q_hash.ninput, Q_hash.nwires))
print("\nLINKAGE: MAC binds (e, dpkx, dpky) across both circuits")

print("\nREAL CIRCUIT (from C++):")
print("  For 1 attribute:")
print("    Signature: ~11k inputs, ~50k gates, depth ~30")
print("    Hash:      ~25k inputs, ~400k gates, depth ~200")
print("\n  Components not yet in Lua:")
print("    ✗ ECDSA (VerifyCircuit)")
print("    ✗ SHA-256 (FlatSHA256Circuit)")
print("    ✗ MAC (over GF2_128)")
print("    ✗ Bit plucker, Routing, Memcmp")

print("\nSTATUS:")
print("  This demo shows circuit STRUCTURE using placeholders")
print("  Full implementation requires C++ or extended Lua bindings")

print("\nREFERENCE:")
print("  lib/longfellow-zk/circuits/mdoc/")
print("  ISO/IEC 18013-5:2021")
print("  https://eprint.iacr.org/2024/2010")
print("\n" .. string.rep("=", 64))
