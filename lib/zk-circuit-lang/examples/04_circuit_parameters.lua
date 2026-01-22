-- Example: Accessing circuit parameters and diagnostics
print("=== Circuit Parameters Example ===")

local ZK = require'zkcc'

-- Create a logic circuit
local L = ZK.create_logic()

-- Build a simple circuit
print("Building circuit...")
local a = L:input()
local b = L:input()
local c = L:land(a, b)
L:assert1(c)

-- Ensure the circuit is compiled before accessing metrics
L:get_circuit():mkcircuit(1)

-- Test individual metric getters
print("\n--- Individual Metrics ---")
print("Inputs:", tostring(L:get_ninput()))
print("Outputs:", tostring(L:get_noutput()))
print("Depth:", tostring(L:get_depth()))
print("Wires:", tostring(L:get_nwires()))
print("Quad terms:", tostring(L:get_nquad_terms()))
print("CSE eliminated:", tostring(L:get_nwires_cse_eliminated()))
print("Wires not needed:", tostring(L:get_nwires_not_needed()))
print("Subfield boundary:", tostring(L:get_subfield_boundary()))

-- Test comprehensive statistics
print("\n--- Comprehensive Statistics ---")
local stats = L:get_stats()
for k, v in pairs(stats) do
    print(string.format("%-25s: %s", k, tostring(v)))
end

-- Test wire ID debugging
print("\n--- Wire IDs ---")
print("Wire ID for a:", tostring(L:get_wire_id(a)))
print("Wire ID for b:", tostring(L:get_wire_id(b)))
print("Wire ID for c:", tostring(L:get_wire_id(c)))

-- Test circuit ID
print("\n--- Circuit Identification ---")
local circuit_id = L:get_circuit_id()
-- Check if circuit_id is not empty and not all zeros
local is_valid = false
if #circuit_id == 32 then
    for i = 1, #circuit_id do
        if circuit_id:byte(i) ~= 0 then
            is_valid = true
            break
        end
    end
end

if is_valid then
    print("Circuit ID (hex):", circuit_id:gsub(".", function(c) 
        return string.format("%02x", string.byte(c)) 
    end))
else
    print("Circuit ID: Not available (circuit not compiled properly)")
end

-- Test with QuadCircuit directly
print("\n--- QuadCircuit Direct Access ---")
local Q = ZK.create_quad_circuit()
local w1 = Q:input_wire()
local w2 = Q:input_wire()
local w3 = Q:add(w1, w2)
Q:assert0(w3)

-- Compile the circuit to ensure metrics are populated
Q:mkcircuit(1)

local q_stats = Q:get_stats()
print("QuadCircuit inputs:", tostring(q_stats.ninput))
print("QuadCircuit depth:", tostring(q_stats.depth))

print("\n=== Circuit Parameters Example Complete ===")
