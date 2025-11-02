--[[
  Sum Verification Circuit
  
  Proves: "a + b + c + d = 200" without revealing individual values.
  
  Use case: Prove total expenses equal a budget without revealing
  individual expense amounts.
--]]

ZK = require'longfellow'

print("=== Sum Verification: a + b + c + d = 200 ===\n")

local L = create_logic()

-- Mark boundary before adding inputs
L:get_circuit():private_input()

-- Four private 8-bit inputs
local a = L:vinput8()
local b = L:vinput8()
local c = L:vinput8()
local d = L:vinput8()
print("Created four private 8-bit inputs: a, b, c, d")

-- Compute sum incrementally
local sum_ab = a + b
print("Computed: a + b")

local sum_abc = sum_ab + c
print("Computed: (a + b) + c")

local sum_abcd = sum_abc + d
print("Computed: ((a + b) + c) + d")

-- Target sum (constant)
local target = L:vbit8(200)
print("Created constant: target = 200")

-- Assert sum equals target
local sum_equals_target = sum_abcd == target
L:assert1(sum_equals_target)
print("Added assertion: sum == 200")

-- Compile
print("\n=== Compiling Circuit ===\n")
local circuit = L:get_circuit()
circuit:mkcircuit(1)

print("Circuit compiled successfully!")
print(string.format("  Inputs: %d (all private)", circuit.ninput))
print(string.format("  Depth: %d", circuit.depth))
print(string.format("  Wires: %d", circuit.nwires))

print("\n=== Example Solutions ===")
print("Valid witness values (all sum to 200):")
print("  a=50, b=50, c=50, d=50")
print("  a=100, b=60, c=30, d=10")
print("  a=200, b=0, c=0, d=0")
print("  a=1, b=2, c=3, d=194")

print("\n=== Use Cases ===")
print("This pattern enables:")
print("  - Budget compliance without revealing line items")
print("  - Vote tallying with secret ballots")
print("  - Aggregate statistics with individual privacy")
print("  - Proof of reserves (total assets) without revealing accounts")

print("\n=== Note ===")
print("Using 8-bit arithmetic means values are modulo 256.")
print("For example: 100 + 100 + 100 + 100 = 144 (wraps around)")
print("To avoid overflow, use 32-bit vectors (vinput32, vadd32)")
