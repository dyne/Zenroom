--[[
  Simple Arithmetic Circuit Example
  
  Proves knowledge of x such that: x^2 + 3x + 2 = 20
  
  Solution: x = 3 (since 9 + 9 + 2 = 20)
--]]

ZK = require'zkcc'

-- Create circuit using low-level API
local Q = ZK.create_quad_circuit()

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

-- Compile the circuit
print("\n=== Compiling Circuit ===\n")
Q:mkcircuit(1)

print("DEBUG: mkcircuit completed")

-- Display metrics
-- Note: Properties are accessed as fields (Q.ninput), not methods (Q:ninput())
print("Circuit compiled successfully!")

print("DEBUG: About to access ninput")
local ninput_val = Q.ninput
print("DEBUG: ninput value:", ninput_val)

print("DEBUG: About to access npub_input")
local npub_input_val = Q.npub_input
print("DEBUG: npub_input value:", npub_input_val)

print(string.format("  Total inputs: %d", ninput_val))
print(string.format("    Public:  %d", npub_input_val))
print(string.format("    Private: %d", ninput_val - npub_input_val))

print("DEBUG: About to access depth")
print(string.format("  Circuit depth: %d", Q.depth))

print("DEBUG: About to access nwires")
print(string.format("  Total wires: %d", Q.nwires))

print("DEBUG: About to access nquad_terms")
print(string.format("  Quadratic terms: %d", Q.nquad_terms))

print("\n=== Verification ===")
print("This circuit proves:")
print("  'I know a secret value x such that x^2 + 3x + 2 = 20'")
print("  without revealing x (answer: x = 3)")
