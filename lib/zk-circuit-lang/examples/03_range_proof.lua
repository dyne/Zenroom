--[[
  Range Proof Circuit
  
  Proves: "My value x is in the range [10, 100]"
  
  This demonstrates bounding a value from both sides.
--]]

ZK = require'longfellow'

print("=== Range Proof: 10 <= x <= 100 ===\n")

local L = create_logic()

-- Mark boundary before adding inputs
L:get_circuit():private_input()

-- Private input: the secret value
local x = L:vinput8()
print("Created private 8-bit input: x")

-- Define range bounds
local lower_bound = L:vbit8(10)
local upper_bound = L:vbit8(100)
print("Range bounds: [10, 100]")

-- Lower bound check: x >= 10
local satisfies_lower = L:vleq8(lower_bound, x)
L:assert1(satisfies_lower)
print("Added assertion: x >= 10")

-- Upper bound check: x <= 100  
local satisfies_upper = L:vleq8(x, upper_bound)
L:assert1(satisfies_upper)
print("Added assertion: x <= 100")

-- Compile
print("\n=== Compiling Circuit ===\n")
local circuit = L:get_circuit()
circuit:mkcircuit(1)

print("Circuit compiled successfully!")
print(string.format("  Inputs: %d", circuit.ninput))
print(string.format("  Depth: %d", circuit.depth))
print(string.format("  Wires: %d", circuit.nwires))

print("\n=== Use Cases ===")
print("Range proofs are used for:")
print("  - Proving income is within a bracket")
print("  - Proving age is between two values")
print("  - Proving a score meets minimum thresholds")
print("  - Confidential auctions (bid in valid range)")
print("")
print("Valid inputs: 10, 11, ..., 99, 100")
print("Invalid: 9, 101, 255")
