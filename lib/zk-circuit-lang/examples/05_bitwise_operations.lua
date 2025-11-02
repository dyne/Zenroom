--[[
  Bitwise Operations Circuit: (a AND b) XOR c = d
  
  Demonstrates boolean algebra in ZK circuits.
--]]

ZK = require'longfellow'

print("=== Bitwise Operations: (a AND b) XOR c = d ===\n")

local L = create_logic()

-- Mark boundary before adding inputs
L:get_circuit():private_input()

-- Create four 8-bit inputs
local a = L:vinput8()
local b = L:vinput8()
local c = L:vinput8()
local d = L:vinput8()
print("Created four 8-bit inputs: a, b, c, d")

-- Compute (a AND b)
local a_and_b = a & b
print("Computed: a AND b")

-- Compute (a AND b) XOR c
local result = a_and_b ^ c
print("Computed: (a AND b) XOR c")

-- Assert result equals d
local equals_d = result == d
L:assert1(equals_d)
print("Added assertion: result == d")

-- Compile
print("\n=== Compiling Circuit ===\n")
local circuit = L:get_circuit()
circuit:mkcircuit(1)

print("Circuit compiled successfully!")
print(string.format("  Inputs: %d", circuit.ninput))
print(string.format("  Depth: %d", circuit.depth))
print(string.format("  Wires: %d", circuit.nwires))

print("\n=== Example Calculation ===")
-- Lua 5.1/5.2 compatible: using decimal instead of binary literals
local a_val = 204  -- Binary: 11001100
local b_val = 170  -- Binary: 10101010
local c_val = 240  -- Binary: 11110000

-- Bitwise operations for Lua 5.1/5.2 compatibility
local function band(a, b)
    local result = 0
    local bit = 1
    while a > 0 or b > 0 do
        if (a % 2 == 1) and (b % 2 == 1) then
            result = result + bit
        end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        bit = bit * 2
    end
    return result
end

local function bxor(a, b)
    local result = 0
    local bit = 1
    while a > 0 or b > 0 do
        if (a % 2) ~= (b % 2) then
            result = result + bit
        end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        bit = bit * 2
    end
    return result
end

local and_result = band(a_val, b_val)
local xor_result = bxor(and_result, c_val)

print(string.format("a = %d (binary: 11001100)", a_val))
print(string.format("b = %d (binary: 10101010)", b_val))
print(string.format("c = %d (binary: 11110000)", c_val))
print(string.format("a AND b = %d", and_result))
print(string.format("(a AND b) XOR c = %d", xor_result))
print(string.format("\nTo satisfy the circuit, d must be: %d", xor_result))

print("\n=== Supported Bitwise Operations ===")
print("  AND  - Bitwise conjunction")
print("  OR   - Bitwise disjunction")
print("  XOR  - Bitwise exclusive-or")
print("  NOT  - Bitwise negation")
print("")
print("Available for 8-bit and 32-bit vectors.")
