--[[
  Age Verification Circuit
  
  Proves: "I am at least 18 years old" without revealing exact age.
  
  This is a simple range proof using 8-bit arithmetic.
--]]

ZK = require'longfellow'

print("=== Age Verification Circuit ===\n")

-- Create circuit using high-level Logic API
local L = create_logic()

-- Mark boundary before adding inputs
L:get_circuit():private_input()

-- Private input: actual age (8 bits)
local age = L:vinput8()
print("Created private 8-bit input: age")

-- Constant: minimum required age
local min_age = L:vbit8(18)
print("Created constant: min_age = 18")

-- Check if age >= 18
-- Using vleq8(min_age, age) which checks if min_age <= age
-- With operators, we can use: age >= min_age
-- But since vleq8(a, b) means a <= b, we need to use vleq8(min_age, age)
local is_adult = L:vleq8(min_age, age)
print("Created comparison: age >= 18")

-- Assert the condition must be true
L:assert1(is_adult)
print("Added assertion: age must be >= 18")

-- Compile circuit
print("\n=== Compiling Circuit ===\n")
local circuit = L:get_circuit()
circuit:mkcircuit(1)

-- Display metrics
print("Circuit compiled successfully!")
print(string.format("  Total inputs: %d (all private)", circuit.ninput))
print(string.format("  Circuit depth: %d", circuit.depth))
print(string.format("  Total wires: %d", circuit.nwires))

print("\n=== Use Case ===")
print("This circuit allows someone to prove they are an adult")
print("without revealing their exact age.")
print("")
print("Examples:")
print("  age = 18  -> Valid proof")
print("  age = 25  -> Valid proof")
print("  age = 17  -> Proof fails (assertion violated)")
print("  age = 255 -> Valid proof (maximum 8-bit value)")
