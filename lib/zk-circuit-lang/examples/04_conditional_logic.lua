--[[
  Conditional Logic Circuit
  
  Proves: "IF flag is set, THEN a must equal b"
  
  This demonstrates boolean implication in ZK circuits.
--]]

ZK = require'zkcc'

print("=== Conditional Logic: flag => (a == b) ===\n")

local L = ZK.create_logic()

-- Mark boundary before adding inputs
L:get_circuit():private_input()

-- Inputs
local flag = L:input()
print("Created 1-bit input: flag")

local a = L:vinput8()
print("Created 8-bit input: a")

local b = L:vinput8()
print("Created 8-bit input: b")

-- Check equality of a and b
local a_equals_b = L:veq8(a, b)
print("Created equality check: a == b")

-- Implication: flag => a_equals_b
-- This is logically equivalent to: (!flag) OR (a == b)
local condition = L:limplies(flag, a_equals_b)
print("Created implication: flag => (a == b)")

-- Assert the condition must hold
L:assert1(condition)
print("Added assertion: condition must be true")

-- Compile
print("\n=== Compiling Circuit ===\n")
local circuit = L:get_circuit()
circuit:mkcircuit(1)

print("Circuit compiled successfully!")
print(string.format("  Inputs: %d", circuit.ninput))
print(string.format("  Depth: %d", circuit.depth))
print(string.format("  Wires: %d", circuit.nwires))

print("\n=== Truth Table ===")
print("flag | a | b | a==b | flag=>(a==b) | Valid?")
print("-----|---|---|------|--------------|-------")
print("  0  | * | * |  *   |      1       |  ✓")
print("  1  | 5 | 5 |  1   |      1       |  ✓")
print("  1  | 5 | 7 |  0   |      0       |  ✗")
print("")
print("Use cases:")
print("  - Conditional disclosure (if consent, then reveal attribute)")
print("  - Role-based constraints (if admin, then value must match)")
print("  - Optional validations")
