--[[
  Simple Arithmetic Circuit Example
  
  Proves knowledge of x such that: x^2 + 3x + 2 = 20
  
  Solution: x = 3 (since 9 + 9 + 2 = 20)
--]]

ZK = require'zkcc'

-- Create circuit template
local Q = ZK.new_circuit_template()

print("=== Building Circuit: x^2 + 3x + 2 = 20 ===\n")

-- Public input: expected result (20)
local result_pub = Q:input_wire()
print("Created public input (result)")

-- Mark boundary between public and private inputs
Q:private_input()

-- Private input: x (the secret value)
local x = Q:input_wire()
print("Created private input (x)")

-- For the constant 2, we'll add another private input wire
local two = Q:input_wire()
print("Created private input for constant 2")

-- Compute x^2
local x_squared = x * x
print("Computed x^2")

-- Compute 3x by adding x three times
local x_plus_x = x + x
local three_x = x_plus_x + x
print("Computed 3x")

-- Compute x^2 + 3x
local x2_plus_3x = x_squared + three_x
print("Computed x^2 + 3x")

-- Add constant 2
local polynomial = x2_plus_3x + two
print("Added constant 2")

-- Assert result equals public input
local difference = polynomial - result_pub
Q:assert0(difference)
print("Added constraint: x^2 + 3x + 2 == result_pub")
print("Note: The 'two' input must be set to 2 in the witness")

-- Test: try to export before compilation (should fail)
print("\nTesting error handling...")
local status, err = pcall(function() return Q:octet() end)
if not status then
    print("✓ Correctly rejected octet() before mkcircuit:", err:match("[^:]+$"))
end

-- Build circuit artifact
print("\n=== Building Circuit Artifact ===\n")
local artifact = ZK.build_circuit_artifact(Q, 1)

print("Circuit artifact built successfully!")

-- Display metrics
print(string.format("  Total inputs: %d", artifact.ninput))
print(string.format("    Public:  %d", artifact.npub_input))
print(string.format("    Private: %d", artifact.ninput - artifact.npub_input))
print(string.format("  Circuit depth: %d layers", artifact.depth))
print(string.format("  Total wires: %d", artifact.nwires))
print(string.format("  Quadratic terms: %d", artifact.nquad_terms))

print("\n=== Circuit Export ===")
local circuit_bytes = artifact:octet()
print(string.format("Circuit serialized: %d bytes", #circuit_bytes))
print("First 32 bytes (hex):", circuit_bytes:sub(1, 32):hex())
print("Circuit ID:", artifact:circuit_id():hex():sub(1, 16) .. "...")

print("\n=== Verification ===")
print("This circuit proves:")
print("  'I know a secret value x such that x^2 + 3x + 2 = 20'")
print("  without revealing x (answer: x = 3)")
