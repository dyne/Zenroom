--[[
  Simple Arithmetic Circuit Example
  
  Proves knowledge of x such that: x^2 + 3x + 2 = 20
  
  Solution: x = 3 (since 9 + 9 + 2 = 20)
--]]

ZK = require'longfellow'

-- Create circuit using low-level API
local Q = create_quad_circuit()
local F = create_fp256_field()

print("=== Building Circuit: x^2 + 3x + 2 = 20 ===\n")

-- Public input: expected result (20)
local result_pub = Q:input_wire()
print("Created public input (result)")

-- Mark boundary between public and private inputs
Q:private_input()

-- Private input: x (the secret value)
local x = Q:input_wire()
print("Created private input (x)")

-- Compute x^2
local x_squared = x * x
print("Computed x^2")

-- Compute 3x
local three = F:of_scalar(3)
local three_x = three * x
print("Computed 3x")

-- Compute x^2 + 3x
local x2_plus_3x = x_squared + three_x
print("Computed x^2 + 3x")

-- Add constant 2
local two = F:of_scalar(2)
local polynomial = x2_plus_3x + two
print("Added constant 2")

-- Assert result equals public input
local difference = polynomial - result_pub
Q:assert0(difference)
print("Added constraint: polynomial == result_pub")

-- Compile the circuit
print("\n=== Compiling Circuit ===\n")
Q:mkcircuit(1)

-- Display metrics
print("Circuit compiled successfully!")
print(string.format("  Total inputs: %d", Q.ninput))
print(string.format("    Public:  %d", Q.npub_input))
print(string.format("    Private: %d", Q.ninput - Q.npub_input))
print(string.format("  Circuit depth: %d", Q.depth))
print(string.format("  Total wires: %d", Q.nwires))
print(string.format("  Quadratic terms: %d", Q.nquad_terms))

print("\n=== Verification ===")
print("This circuit proves:")
print("  'I know a secret value x such that x^2 + 3x + 2 = 20'")
print("  without revealing x (answer: x = 3)")
