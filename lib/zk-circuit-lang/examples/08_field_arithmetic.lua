--[[
  Field Arithmetic Circuit
  
  Proves: "3x + 5y = 100" over the P-256 field
  
  Demonstrates working directly with field elements (not bits).
  This is more efficient for arithmetic-heavy computations.
--]]

ZK = require'longfellow'

print("=== Field Arithmetic: 3x + 5y = 100 ===\n")

local L = create_logic()

-- Mark boundary before adding inputs
L:get_circuit():private_input()

-- Create field constants
local three = L:elt(3)
local five = L:elt(5)
local hundred = L:elt(100)
print("Created field constants: 3, 5, 100")

-- Private field element inputs
local x = L:eltw_input()
local y = L:eltw_input()
print("Created field element inputs: x, y")

-- Compute 3x
local three_x = three * x
print("Computed: 3x")

-- Compute 5y
local five_y = five * y
print("Computed: 5y")

-- Compute 3x + 5y
local sum = three_x + five_y
print("Computed: 3x + 5y")

-- Create constant wire for 100
local target = L:konst(hundred)
print("Created constant wire: 100")

-- Assert equality
L:assert_eq(sum, target)
print("Added assertion: 3x + 5y == 100")

-- Compile
print("\n=== Compiling Circuit ===\n")
local circuit = L:get_circuit()
circuit:mkcircuit(1)

print("Circuit compiled successfully!")
print(string.format("  Inputs: %d (field elements)", circuit.ninput))
print(string.format("  Depth: %d", circuit.depth))
print(string.format("  Wires: %d", circuit.nwires))

print("\n=== Example Solutions ===")
print("Valid (x, y) pairs that satisfy 3x + 5y = 100:")
print("  x=0,  y=20  -> 0 + 100 = 100 ✓")
print("  x=10, y=14  -> 30 + 70 = 100 ✓")
print("  x=20, y=8   -> 60 + 40 = 100 ✓")
print("  x=30, y=2   -> 90 + 10 = 100 ✓")

print("\n=== Field Element vs Bit Vector ===")
print("Field elements (EltW):")
print("  ✓ More efficient for arithmetic")
print("  ✓ Natural for equations and polynomials")
print("  ✗ Cannot do bitwise operations")
print("  ✗ Harder to reason about ranges")
print("")
print("Bit vectors (BitVec<N>):")
print("  ✓ Support bitwise AND, OR, XOR")
print("  ✓ Easy range proofs (bounded by bit width)")
print("  ✓ Natural for boolean logic")
print("  ✗ Less efficient for pure arithmetic")

print("\n=== When to Use Field Arithmetic ===")
print("Prefer field elements when:")
print("  - Proving polynomial equations")
print("  - Doing modular arithmetic")
print("  - No need for bitwise operations")
print("  - Working with cryptographic signatures/hashes")
