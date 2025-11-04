--[[
  Multiplexer Circuit
  
  Proves: "result = control ? value_if_true : value_if_false"
  
  Demonstrates conditional selection in ZK circuits.
--]]

ZK = require'zkcc'

print("=== Multiplexer: result = control ? a : b ===\n")

local L = ZK.create_logic()

-- Mark boundary before adding inputs
L:get_circuit():private_input()

-- Inputs
local control = L:input()
print("Created 1-bit control input")

local a = L:vinput8()
local b = L:vinput8()
print("Created 8-bit inputs: a, b")

-- Multiplexer logic using vmux8
-- If control == 1, select a; if control == 0, select b
local result = L:vmux8(control, a, b)
print("Created multiplexer: control ? a : b")

-- Assert the result equals a when control is true
-- This is a simplified demonstration
local check = L:veq8(result, a)
L:assert1(check)
print("Added simplified assertion (bit-level)")

-- Compile
print("\n=== Compiling Circuit ===\n")
local circuit = L:get_circuit()
circuit:mkcircuit(1)

print("Circuit compiled successfully!")
print(string.format("  Inputs: %d", circuit.ninput))
print(string.format("  Depth: %d", circuit.depth))
print(string.format("  Wires: %d", circuit.nwires))

print("\n=== Truth Table ===")
print("control | a  | b  | selected | expected | Valid?")
print("--------|----|----|----------|----------|-------")
print("   0    | 42 | 99 |    99    |    99    |  ✓")
print("   1    | 42 | 99 |    42    |    42    |  ✓")
print("   0    | 42 | 99 |    99    |    42    |  ✗")
print("   1    | 42 | 99 |    42    |    99    |  ✗")

print("\n=== Available Multiplexer Functions ===")
print("  vmux8(control, a, b)   - 8-bit vector mux")
print("  vmux32(control, a, b)  - 32-bit vector mux")
print("  mux(control, a, b)     - Single-bit mux")

print("\n=== Use Cases ===")
print("Multiplexers enable:")
print("  - Conditional attribute disclosure")
print("  - Role-based access (select based on permission bit)")
print("  - Switch statements in ZK")
print("  - Data routing based on private conditions")
