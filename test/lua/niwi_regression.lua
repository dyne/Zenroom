-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2026 Dyne.org foundation
-- SPDX-License-Identifier: AGPL-3.0-or-later

local niwi = require('crypto_niwi')
assert(niwi, "niwi module not loaded")
local native_niwi = require('niwi')
assert(native_niwi, "native niwi module not loaded")

local circuit = O.from_string("dummy-circuit")
local inputs = O.from_string("private-inputs")
local public_inputs = O.from_string("public-inputs")
local wrong_public_inputs = O.from_string("wrong-public-inputs")

local p = niwi.niwi_profile()
assert(type(p) == "table", "niwi_profile must return a table")
assert(p.version == "niwi-v1", "expected version niwi-v1")
assert(p.protocol_id == 0, "expected protocol_id 0")
assert(niwi.PROTOCOL_VERSION == "niwi-v1", "PROTOCOL_VERSION mismatch")
print("PASS 1: niwi_profile")

local raw_production_ok = pcall(function()
    niwi.prove_circuit_niwi({
        circuit = circuit,
        inputs = inputs,
        public_inputs = public_inputs,
    })
end)
assert(raw_production_ok == false,
       "production prove_circuit_niwi must reject raw unchecked envelopes")
print("PASS 2: prove_circuit_niwi rejects raw unchecked envelope")

local proof = native_niwi.prove_envelope_unchecked({
    circuit = circuit,
    inputs = inputs,
    public_inputs = public_inputs,
})
assert(type(proof) == "zenroom.octet", "proof must be an octet")
assert(#proof > 0, "proof must be non-empty")
print("PASS 3: native unchecked envelope prove")

local ok = native_niwi.verify_envelope({
    circuit = circuit,
    proof = proof,
    public_inputs = public_inputs,
})
assert(ok == true, "expected NIWI proof to verify")
print("PASS 4: native unchecked envelope verify")

local wrong_ok = native_niwi.verify_envelope({
    circuit = circuit,
    proof = proof,
    public_inputs = wrong_public_inputs,
})
assert(wrong_ok == false, "wrong public inputs must not verify")
print("PASS 5: native unchecked verify rejects wrong public inputs")

local proof_obs, gamma = niwi.prove_with_observation_test({
    circuit = circuit,
    inputs = inputs,
    public_inputs = public_inputs,
})
assert(type(proof_obs) == "zenroom.octet", "observed proof must be octet")
assert(type(gamma) == "zenroom.octet", "gamma must be octet")
assert(#proof_obs > 0, "observed proof must be non-empty")
assert(#gamma > 0, "gamma must be non-empty")
print("PASS 6: prove_with_observation_test")

local witness = niwi.extract_from_gamma_test({
    proof = proof_obs,
    gamma = gamma,
    public_inputs = public_inputs,
})
assert(type(witness) == "zenroom.octet", "witness must be octet")
assert(witness:string() == inputs:string(), "extracted witness mismatch")
print("PASS 7: extract_from_gamma_test")

local extract_wrong_ok = pcall(niwi.extract_from_gamma_test, {
    proof = proof_obs,
    gamma = gamma,
    public_inputs = wrong_public_inputs,
})
assert(extract_wrong_ok == false, "wrong public inputs must not extract")
print("PASS 8: extract rejects wrong public inputs")

local missing_ok = pcall(niwi.prove_circuit_niwi, { inputs = inputs })
assert(missing_ok == false, "missing circuit should error")
print("PASS 9: prove_circuit_niwi missing circuit")

local type_ok = pcall(niwi.verify_circuit_niwi, 42)
assert(type_ok == false, "non-table verify should error")
print("PASS 10: verify_circuit_niwi non-table arg")

assert(type(niwi.prove_circuit_niwi) == "function")
assert(type(niwi.verify_circuit_niwi) == "function")
assert(type(niwi.niwi_profile) == "function")
assert(type(niwi.PROTOCOL_VERSION) == "string")
print("PASS 11: API shape")

assert(niwi.prove_envelope_unchecked == nil)
assert(niwi.verify_envelope == nil)
assert(type(native_niwi.prove_envelope_unchecked) == "function")
assert(type(native_niwi.verify_envelope) == "function")
assert(type(native_niwi.prove_envelope_with_observation_unchecked_test) == "function")
assert(type(native_niwi.extract_from_gamma_unchecked_test) == "function")
print("PASS 12: unchecked helpers stay native-only")

print("")
print("All NIWI regression tests passed")
