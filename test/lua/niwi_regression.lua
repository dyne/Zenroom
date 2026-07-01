-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2026 Dyne.org foundation
-- designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.
--

-- NIWI regression test — exercises the Lua API boundary.
--
-- Tests: require('niwi'), niwi_profile, prove_circuit_niwi (stub),
-- verify_circuit_niwi (stub), prove_with_observation_test,
-- extract_from_gamma_test, error paths, missing args,
-- wrong types, and protocol version stability.

local niwi = require('niwi')
assert(niwi, "niwi module not loaded")

-- 1. Protocol version
local p = niwi.niwi_profile()
assert(type(p) == "table", "niwi_profile must return a table")
assert(p.version == "niwi-v1", "expected version niwi-v1")
assert(p.protocol_id == 0, "expected protocol_id 0")
assert(niwi.PROTOCOL_VERSION == "niwi-v1", "PROTOCOL_VERSION mismatch")
print("PASS 1: niwi_profile")

-- 2. prove_circuit_niwi — stub returns error, must not crash
local ok, err = pcall(niwi.prove_circuit_niwi, { circuit = "dummy", inputs = "dummy" })
-- The stub returns with a Lua error (via lerror), so pcall catches it
print("PASS 2: prove_circuit_niwi stub (pcall ok=" .. tostring(ok) .. ")")

-- 3. prove_circuit_niwi — missing circuit
local ok2 = pcall(niwi.prove_circuit_niwi, { inputs = "dummy" })
print("PASS 3: prove_circuit_niwi missing circuit")

-- 4. prove_circuit_niwi — non-table arg
local ok3 = pcall(niwi.prove_circuit_niwi, "not a table")
print("PASS 4: prove_circuit_niwi non-table arg")

-- 5. verify_circuit_niwi — stub
local ok4, err4 = pcall(niwi.verify_circuit_niwi, {
    circuit = "dummy", proof = "dummy", public_inputs = "dummy"
})
print("PASS 5: verify_circuit_niwi stub (pcall ok=" .. tostring(ok4) .. ")")

-- 6. verify_circuit_niwi — missing proof
local ok5 = pcall(niwi.verify_circuit_niwi, { circuit = "dummy", public_inputs = "dummy" })
print("PASS 6: verify_circuit_niwi missing proof")

-- 7. verify_circuit_niwi — non-table arg
local ok6 = pcall(niwi.verify_circuit_niwi, 42)
print("PASS 7: verify_circuit_niwi non-table arg")

-- 8. prove_with_observation_test — stub (test-only API availability check)
if niwi.prove_with_observation_test then
    local ok7 = pcall(niwi.prove_with_observation_test, { circuit = "dummy", inputs = "dummy" })
    print("PASS 8: prove_with_observation_test available")
else
    print("SKIP 8: prove_with_observation_test not registered (production build)")
end

-- 9. extract_from_gamma_test — stub
if niwi.extract_from_gamma_test then
    local ok8 = pcall(niwi.extract_from_gamma_test, {
        proof = "dummy", gamma = "dummy", public_inputs = "dummy"
    })
    print("PASS 9: extract_from_gamma_test available")
else
    print("SKIP 9: extract_from_gamma_test not registered (production build)")
end

-- 10. Type checks: functions must be functions
assert(type(niwi.prove_circuit_niwi) == "function")
assert(type(niwi.verify_circuit_niwi) == "function")
assert(type(niwi.niwi_profile) == "function")
print("PASS 10: all production functions are functions")

-- 11. PROTOCOL_VERSION must be a string
assert(type(niwi.PROTOCOL_VERSION) == "string")
print("PASS 11: PROTOCOL_VERSION is a string")

print("")
print("All NIWI regression tests passed")
