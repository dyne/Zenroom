--[[
  Circuit Save/Load Example
  
  Demonstrates:
  1. Building a circuit
  2. Compiling and exporting to OCTET
  3. Loading the circuit from OCTET
  4. Inspecting loaded circuit properties
--]]

ZK = require'zkcc'

print("=== Circuit Save/Load Example ===\n")

-- PART 1: Build and save a circuit
print("--- Part 1: Building Circuit ---")

local Q = ZK.new_circuit_template()

-- Build a simple circuit: x^2 + y = z
local z = Q:input_wire()  -- public output
print("Created public input (z)")

Q:private_input()  -- boundary

local x = Q:input_wire()  -- private
local y = Q:input_wire()  -- private
print("Created private inputs (x, y)")

-- Compute x^2 + y
local x_squared = x * x
local result = x_squared + y
print("Built circuit: x^2 + y")

-- Assert result equals z
local diff = result - z
Q:assert0(diff)
print("Added constraint: x^2 + y == z")

-- Build circuit artifact
print("\nBuilding circuit artifact...")
local artifact = ZK.build_circuit_artifact(Q, 1)

print("Circuit artifact metrics:")
print(string.format("  Inputs: %d (public: %d, private: %d)", 
    artifact.ninput, artifact.npub_input, artifact.ninput - artifact.npub_input))
print(string.format("  Depth: %d layers", artifact.depth))
print(string.format("  Wires: %d", artifact.nwires))
print(string.format("  Constraints: %d", artifact.nquad_terms))

-- Get circuit ID
local circuit_id = artifact:circuit_id()
print(string.format("  Circuit ID: %s...", circuit_id:hex():sub(1, 16)))

-- Export to OCTET
print("\nExporting circuit...")
local circuit_bytes = artifact:octet()
print(string.format("  Serialized: %d bytes", #circuit_bytes))

-- PART 2: Load the circuit
print("\n--- Part 2: Loading Circuit ---")

local artifact2 = ZK.load_circuit_artifact(circuit_bytes)
print("Circuit artifact loaded successfully!")

-- Verify loaded circuit properties
print("\nLoaded circuit metrics:")
print(string.format("  Inputs: %d (public: %d, private: %d)", 
    artifact2.ninput, artifact2.npub_input, artifact2.ninput - artifact2.npub_input))
print(string.format("  Depth: %d layers", artifact2.depth))
print(string.format("  Wires: %d", artifact2.nwires))
print(string.format("  Constraints: %d", artifact2.nquad_terms))

-- Verify circuit ID matches
local circuit_id2 = artifact2:circuit_id()
print(string.format("  Circuit ID: %s...", circuit_id2:hex():sub(1, 16)))

if circuit_id:hex() == circuit_id2:hex() then
    print("\n✓ Circuit IDs match! Save/load successful.")
else
    print("\n✗ Circuit IDs don't match!")
end

-- Test that templates can be reused
print("\n--- Part 3: Template Reusability ---")
print("Templates can be reused to build multiple artifacts")
local artifact3 = ZK.build_circuit_artifact(Q, 1)
print("✓ Built another artifact from same template")

-- Part 4: Set inputs and validate
print("\n--- Part 4: Setting Inputs ---")
print("Circuit expects: x^2 + y = z")
print("Setting: x=3, y=7, z=16 (because 3^2 + 7 = 16)")

-- Set public input (z = 16)
local z_value = OCTET.from_hex("0000000000000000000000000000000000000000000000000000000000000010")  -- 16 in hex
artifact2:set_input(0, z_value)
print(string.format("  Set input[0] (public z) = %d", 16))

-- Set private inputs (x=3, y=7)
local x_value = OCTET.from_hex("0000000000000000000000000000000000000000000000000000000000000003")  -- 3
local y_value = OCTET.from_hex("0000000000000000000000000000000000000000000000000000000000000007")  -- 7
artifact2:set_input(2, x_value)  -- Skip index 1 (private boundary marker)
artifact2:set_input(3, y_value)
print(string.format("  Set input[2] (private x) = %d", 3))
print(string.format("  Set input[3] (private y) = %d", 7))

-- Verify we can read back
local z_read = artifact2:get_input(0)
print(string.format("  Read back input[0] = %s...", z_read:hex():sub(1, 8)))

print("\n=== Example Complete ===")
print("\nUse case:")
print("1. Build circuit template once")
print("2. Compile to artifact and distribute as OCTET")
print("3. Load on verifier/prover")
print("4. Set public/private inputs")
print("5. Execute proving/verification (not yet implemented)")
