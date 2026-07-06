-- End-to-end BIP340 circuit coverage using the Lua-authored gadget circuit.
--
-- Lua authors the verification sequence via granular gadget primitives;
-- C++ emits the production-tested constraint formulas.
--
-- This test validates that the Lua-authored circuit:
--   1. produces the same input contract as the native monolithic circuit,
--   2. proves and verifies all valid Bitcoin BIP340 test vectors,
--   3. rejects tampered public inputs.

local zkcc = require'crypto_zkcc'
local S = require("secp")

local VECTOR_CSV = [[
index,secret key,public key,aux_rand,message,signature,verification result,comment
0,0000000000000000000000000000000000000000000000000000000000000003,F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9,0000000000000000000000000000000000000000000000000000000000000000,0000000000000000000000000000000000000000000000000000000000000000,E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA821525F66A4A85EA8B71E482A74F382D2CE5EBEEE8FDB2172F477DF4900D310536C0,TRUE,
1,B7E151628AED2A6ABF7158809CF4F3C762E7160F38B4DA56A784D9045190CFEF,DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659,0000000000000000000000000000000000000000000000000000000000000001,243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89,6896BD60EEAE296DB48A229FF71DFE071BDE413E6D43F917DC8DCF8C78DE33418906D11AC976ABCCB20B091292BFF4EA897EFCB639EA871CFA95F6DE339E4B0A,TRUE,
2,C90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B14E5C9,DD308AFEC5777E13121FA72B9CC1B7CC0139715309B086C960E18FD969774EB8,C87AA53824B4D7AE2EB035A2B5BBBCCC080E76CDC6D1692C4B0B62D798E6D906,7E2D58D8B3BCDF1ABADEC7829054F90DDA9805AAB56C77333024B9D0A508B75C,5831AAEED7B44BB74E5EAB94BA9D4294C49BCF2A60728D8B4C200F50DD313C1BAB745879A5AD954A72C45A91C3A51D3C7ADEA98D82F8481E0E1E03674A6F3FB7,TRUE,
3,0B432B2677937381AEF05BB02A66ECD012773062CF3FA2549E44F58ED2401710,25D1DFF95105F5253C4022F628A996AD3A0D95FBF21D468A1B33F8C160D8F517,FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,7EB0509757E246F19449885651611CB965ECC1A187DD51B64FDA1EDC9637D5EC97582B9CB13DB3933705B32BA982AF5AF25FD78881EBB32771FC5922EFC66EA3,TRUE,test fails if msg is reduced modulo p or n
4,,D69C3509BB99E412E68B0FE8544E72837DFA30746D8BE2AA65975F29D22DC7B9,,4DF3C3F68FCC83B27E9D42C90431A72499F17875C81A599B566C9889B9696703,00000000000000000000003B78CE563F89A0ED9414F5AA28AD0D96D6795F9C6376AFB1548AF603B3EB45C9F8207DEE1060CB71C04E80F593060B07D28308D7F4,TRUE,
5,,EEFDEA4CDB677750A420FEE807EACF21EB9898AE79B9768766E4FAA04A2D4A34,,243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89,6CFF5C3BA86C69EA4B7376F31A9BCB4F74C1976089B2D9963DA2E5543E17776969E89B4C5564D00349106B8497785DD7D1D713A8AE82B32FA79D5F7FC407D39B,FALSE,public key not on the curve
6,,DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659,,243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89,FFF97BD5755EEEA420453A14355235D382F6472F8568A18B2F057A14602975563CC27944640AC607CD107AE10923D9EF7A73C643E166BE5EBEAFA34B1AC553E2,FALSE,has_even_y(R) is false
7,,DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659,,243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89,1FA62E331EDBC21C394792D2AB1100A7B432B013DF3F6FF4F99FCB33E0E1515F28890B3EDB6E7189B630448B515CE4F8622A954CFE545735AAEA5134FCCDB2BD,FALSE,negated message
8,,DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659,,243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89,6CFF5C3BA86C69EA4B7376F31A9BCB4F74C1976089B2D9963DA2E5543E177769961764B3AA9B2FFCB6EF947B6887A226E8D7C93E00C5ED0C1834FF0D0C2E6DA6,FALSE,negated s value
9,,DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659,,243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89,0000000000000000000000000000000000000000000000000000000000000000123DDA8328AF9C23A94C1FEECFD123BA4FB73476F0D594DCB65C6425BD186051,FALSE,sG - eP is infinite. Test fails in single verification if has_even_y(inf) is defined as true and x(inf) as 0
10,,DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659,,243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89,00000000000000000000000000000000000000000000000000000000000000017615FBAF5AE28864013C099742DEADB4DBA87F11AC6754F93780D5A1837CF197,FALSE,sG - eP is infinite. Test fails in single verification if has_even_y(inf) is defined as true and x(inf) as 1
11,,DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659,,243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89,4A298DACAE57395A15D0795DDBFD1DCB564DA82B0F269BC70A74F8220429BA1D69E89B4C5564D00349106B8497785DD7D1D713A8AE82B32FA79D5F7FC407D39B,FALSE,sig[0:32] is not an X coordinate on the curve
12,,DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659,,243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89,FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F69E89B4C5564D00349106B8497785DD7D1D713A8AE82B32FA79D5F7FC407D39B,FALSE,sig[0:32] is equal to field size
13,,DFF1D77F2A671C5F36183726DB2341BE58FEAE1DA2DECED843240F7B502BA659,,243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89,6CFF5C3BA86C69EA4B7376F31A9BCB4F74C1976089B2D9963DA2E5543E177769FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141,FALSE,sig[32:64] is equal to curve order
14,,FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC30,,243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89,6CFF5C3BA86C69EA4B7376F31A9BCB4F74C1976089B2D9963DA2E5543E17776969E89B4C5564D00349106B8497785DD7D1D713A8AE82B32FA79D5F7FC407D39B,FALSE,public key is not a valid X coordinate because it exceeds the field size
15,0340034003400340034003400340034003400340034003400340034003400340,778CAA53B4393AC467774D09497A87224BF9FAB6F6E68B23086497324D6FD117,0000000000000000000000000000000000000000000000000000000000000000,,71535DB165ECD9FBBC046E5FFAEA61186BB6AD436732FCCC25291A55895464CF6069CE26BF03466228F19A3A62DB8A649F2D560FAC652827D1AF0574E427AB63,TRUE,message of size 0 (added 2022-12)
16,0340034003400340034003400340034003400340034003400340034003400340,778CAA53B4393AC467774D09497A87224BF9FAB6F6E68B23086497324D6FD117,0000000000000000000000000000000000000000000000000000000000000000,11,08A20A0AFEF64124649232E0693C583AB1B9934AE63B4C3511F3AE1134C6A303EA3173BFEA6683BD101FA5AA5DBC1996FE7CACFC5A577D33EC14564CEC2BACBF,TRUE,message of size 1 (added 2022-12)
17,0340034003400340034003400340034003400340034003400340034003400340,778CAA53B4393AC467774D09497A87224BF9FAB6F6E68B23086497324D6FD117,0000000000000000000000000000000000000000000000000000000000000000,0102030405060708090A0B0C0D0E0F1011,5130F39A4059B43BC7CAC09A19ECE52B5D8699D1A71E3C52DA9AFDB6B50AC370C4A482B77BF960F8681540E25B6771ECE1E5A37FD80E5A51897C5566A97EA5A5,TRUE,message of size 17 (added 2022-12)
18,0340034003400340034003400340034003400340034003400340034003400340,778CAA53B4393AC467774D09497A87224BF9FAB6F6E68B23086497324D6FD117,0000000000000000000000000000000000000000000000000000000000000000,99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999,403B12B0D8555A344175EA7EC746566303321E5DBFA8BE6F091635163ECA79A8585ED3E3170807E7C03B720FC54C7B23897FCBA0E9D0B4A06894CFD249F22367,TRUE,message of size 100 (added 2022-12)
]]

local function split_csv_line(line)
    local fields = {}
    for field in (line .. ","):gmatch("(.-),") do
        fields[#fields + 1] = field
    end
    return fields
end

local function load_vectors()
    local rows = {}
    local first = true
    for line in VECTOR_CSV:gmatch("[^\r\n]+") do
        if first then
            first = false
        elseif #line > 0 then
            local fields = split_csv_line(line)
            rows[#rows + 1] = {
                index = tonumber(fields[1]),
                secret_key = fields[2],
                public_key = fields[3],
                aux_rand = fields[4],
                message = fields[5],
                signature = fields[6],
                expect_valid = fields[7] == "TRUE",
                comment = fields[8] or "",
            }
        end
    end
    return rows
end

local function octet_from_hex(hex)
    if hex == nil or hex == "" then
        return OCTET.empty()
    end
    return OCTET.from_hex(hex)
end

local function octet_flip_last_nibble(octet)
    local hex = octet:hex()
    local prefix = hex:sub(1, #hex - 1)
    local last = tonumber(hex:sub(#hex, #hex), 16)
    return OCTET.from_hex(prefix .. string.format("%x", (last ~ 1) & 0xf))
end

-- ===========================================================================
-- BIP-340 Schnorr verification using the existing SECP module.
-- (Same as zkcc_bip340.lua — used for accept/reject classification.)
-- ===========================================================================

local G = S.generator()

local function bip340_verify(sig_oct, pk_oct, msg_oct)
    if #sig_oct ~= 64 or #pk_oct ~= 32 then
        return false
    end
    local r_hex = sig_oct:hex():sub(1, 64)
    local s_hex = sig_oct:hex():sub(65, 128)
    local r_oct = OCTET.from_hex(r_hex)
    local s_oct = OCTET.from_hex(s_hex)

    local ok_r, Rp = pcall(function() return S.bip340_lift_x(r_oct) end)
    if not ok_r or not Rp then return false end

    if not S.bip340_seckey_valid(s_oct) then
        if s_oct:hex() ~= "0000000000000000000000000000000000000000000000000000000000000000" then
            return false
        end
    end

    local ok_pk, P = pcall(function() return S.bip340_lift_x(pk_oct) end)
    if not ok_pk or not P then return false end

    local e_hash = S.bip340_tagged_hash("BIP0340/challenge", r_oct .. pk_oct .. msg_oct)
    local e = S.bip340_challenge_reduce(e_hash)

    local sG = G * s_oct
    local eP = P * e
    local R = sG - eP

    if R:isinf() then return false end
    if R:compressed():hex():sub(1,2) ~= "02" then return false end
    if R:xonly():hex() ~= r_oct:hex() then return false end

    return true
end

-- ===========================================================================
-- Build the Lua-authored BIP340 gadget circuit
-- ===========================================================================

print("=== Building Lua-authored BIP340 circuit ===")

local lua_circuit = zkcc.bip340_lua_circuit_compile()
local schema = lua_circuit.schema

print(string.format("  template: %s", schema.template))
print(string.format("  field_id: %d", schema.field_id))
print(string.format("  total inputs: %d", schema.total))
print(string.format("  public inputs: %d", schema.npub))
print(string.format("  private inputs: %d", schema.counts.private))

-- Verify schema matches expected BIP340 input contract
assert(schema.template == "bip340", "expected bip340 template")
assert(schema.field_id == 10, "expected secp256k1 field id")
assert(schema.total == 2304, string.format("unexpected total: %d", schema.total))
assert(schema.npub == 3, string.format("unexpected public count: %d", schema.npub))

-- ===========================================================================
-- Compare metrics: native vs Lua-authored circuits
-- ===========================================================================

print("=== Comparing circuit metrics ===")

local native_circuit = zkcc.bip340_circuit()
local native_schema = native_circuit.schema

print(string.format("  Native:       total=%d  public=%d",
    native_schema.total, native_schema.npub))
print(string.format("  Lua-authored: total=%d  public=%d",
    schema.total, schema.npub))

assert(schema.total == native_schema.total,
    string.format("total input count mismatch: native=%d lua=%d",
        native_schema.total, schema.total))
assert(schema.npub == native_schema.npub,
    string.format("public input count mismatch: native=%d lua=%d",
        native_schema.npub, schema.npub))

-- ===========================================================================
-- Prove and verify all valid Bitcoin vectors
-- ===========================================================================

print("=== BIP340 vector sweep (Lua-authored circuit) ===")

local vectors = load_vectors()
assert(#vectors > 0, "missing BIP340 test vectors")

local valid_count = 0
local invalid_count = 0
local proof_count = 0
local tamper_rx_checked = false
local tamper_px_checked = false
local tamper_e_checked = false
local witness_tamper_checked = false

for _, vec in ipairs(vectors) do
    local sig = octet_from_hex(vec.signature)
    local pk = octet_from_hex(vec.public_key)
    local msg = octet_from_hex(vec.message)

    local is_valid = bip340_verify(sig, pk, msg)

    if vec.expect_valid then
        assert(is_valid, string.format("vector %d should verify: %s", vec.index, vec.comment))
        valid_count = valid_count + 1

        -- Build witness and named inputs
        local witness = zkcc.witness.bip340_compute(sig, pk, msg)
        local named = zkcc.bip340_witness_named(witness)

        local witness_inputs = zkcc.build_witness_inputs{
            circuit = lua_circuit,
            inputs = named,
        }
        local public_inputs = zkcc.build_witness_inputs{
            circuit = lua_circuit,
            public_inputs = { rx = witness.rx, px = witness.px, e = witness.e },
        }

        local seed = OCTET.from_hex(string.format("%064x", vec.index + 1))

        local proof = zkcc.prove_circuit{
            circuit = lua_circuit,
            inputs = witness_inputs,
            seed = seed,
        }
        assert(proof and #proof > 0,
            string.format("vector %d proof generation failed", vec.index))

        local verify_ok = zkcc.verify_circuit{
            circuit = lua_circuit,
            proof = proof,
            public_inputs = public_inputs,
            seed = seed,
        }
        assert(verify_ok, string.format("vector %d verification failed", vec.index))
        proof_count = proof_count + 1

        -- Tamper checks on first valid vector
        if not tamper_rx_checked then
            -- Mutate rx
            local bad_rx = zkcc.build_witness_inputs{
                circuit = lua_circuit,
                public_inputs = {
                    rx = octet_flip_last_nibble(witness.rx),
                    px = witness.px,
                    e = witness.e,
                },
            }
            assert(not zkcc.verify_circuit{
                circuit = lua_circuit,
                proof = proof,
                public_inputs = bad_rx,
                seed = seed,
            }, "tampered rx should fail verification")
            tamper_rx_checked = true
        elseif not tamper_px_checked then
            -- Mutate px
            local bad_px = zkcc.build_witness_inputs{
                circuit = lua_circuit,
                public_inputs = {
                    rx = witness.rx,
                    px = octet_flip_last_nibble(witness.px),
                    e = witness.e,
                },
            }
            assert(not zkcc.verify_circuit{
                circuit = lua_circuit,
                proof = proof,
                public_inputs = bad_px,
                seed = seed,
            }, "tampered px should fail verification")
            tamper_px_checked = true
        elseif not tamper_e_checked then
            -- Mutate e
            local bad_e = zkcc.build_witness_inputs{
                circuit = lua_circuit,
                public_inputs = {
                    rx = witness.rx,
                    px = witness.px,
                    e = octet_flip_last_nibble(witness.e),
                },
            }
            assert(not zkcc.verify_circuit{
                circuit = lua_circuit,
                proof = proof,
                public_inputs = bad_e,
                seed = seed,
            }, "tampered e should fail verification")
            tamper_e_checked = true
        elseif not witness_tamper_checked then
            -- Mutate a private witness bit (flip bits_s[1]) before proving
            local tampered_witness = zkcc.witness.bip340_compute(sig, pk, msg)
            tampered_witness.bits_s[1] =
                octet_flip_last_nibble(tampered_witness.bits_s[1])
            local tampered_named = zkcc.bip340_witness_named(tampered_witness)
            local tampered_inputs = zkcc.build_witness_inputs{
                circuit = lua_circuit,
                inputs = tampered_named,
            }
            local tampered_public = zkcc.build_witness_inputs{
                circuit = lua_circuit,
                public_inputs = { rx = witness.rx, px = witness.px, e = witness.e },
            }
            local ok_bad, bad_proof = pcall(zkcc.prove_circuit, {
                circuit = lua_circuit,
                inputs = tampered_inputs,
                seed = seed,
            })
            -- With a mutated witness, proof generation should fail (pcall returns false)
            -- or if it somehow succeeds, verification must reject.
            if ok_bad and bad_proof and #bad_proof > 0 then
                assert(not zkcc.verify_circuit{
                    circuit = lua_circuit,
                    proof = bad_proof,
                    public_inputs = tampered_public,
                    seed = seed,
                }, "mutated witness should fail verification")
            end
            -- If bad_proof is nil, that's also a pass (proof generation rejected)
            witness_tamper_checked = true
        end
    else
        assert(not is_valid, string.format("vector %d should be rejected: %s", vec.index, vec.comment))
        invalid_count = invalid_count + 1
    end
end

assert(valid_count > 0, "expected valid BIP340 vectors")
assert(invalid_count > 0, "expected invalid BIP340 vectors")
assert(proof_count > 0, "expected at least one proof")
assert(tamper_rx_checked, "expected rx tamper verification check")
assert(tamper_px_checked, "expected px tamper verification check")
assert(tamper_e_checked, "expected e tamper verification check")
assert(witness_tamper_checked, "expected witness tamper verification check")

print(string.format("  Lua-authored circuit: valid=%d proved=%d invalid=%d  ✓",
    valid_count, proof_count, invalid_count))
print("ALL BIP340 LUA CIRCUIT TESTS PASSED")
