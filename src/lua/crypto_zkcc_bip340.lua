-- BIP340 / secp256k1 circuit helpers for zkcc.
-- Loaded via require("crypto_zkcc_bip340").setup(zkcc_module)
-- from crypto_zkcc.lua.  Do NOT require("crypto_zkcc") here —
-- Zenroom's custom loader doesn't handle circular requires.

local M = {}

-- ===========================================================================
-- Native (monolithic) BIP340 circuit
-- ===========================================================================

function M.setup(zkcc)

    --- Load or build the production native BIP340 circuit artifact.
    function zkcc.bip340_circuit()
        local artifact = zkcc.native.bip340_circuit_native()
        return zkcc.wrap_artifact(artifact, zkcc.make_bip340_schema(artifact))
    end

    if zkcc.load_circuit_artifact_bip340 then
        local native_load_bip340 = zkcc.load_circuit_artifact_bip340
        zkcc.load_circuit_artifact_bip340 = function(octet)
            local artifact = native_load_bip340(octet)
            return zkcc.wrap_artifact(artifact, zkcc.make_bip340_schema(artifact))
        end
    end

    if zkcc.witness and zkcc.native.bip340_compute_inputs_native then
        zkcc.witness.bip340_compute_inputs = function(circuit, sig, pk, msg)
            local raw_circuit = zkcc.is_named_artifact(circuit) and circuit:raw() or circuit
            local inputs, public_inputs =
                zkcc.native.bip340_compute_inputs_native(raw_circuit, sig, pk, msg)
            return {
                inputs = inputs,
                public_inputs = public_inputs,
            }
        end
    end

    if zkcc.witness and zkcc.native.bip340_compute_full_challenge_inputs_native then
        --- Build BIP340 inputs for the full challenge-bound native relation.
        -- This helper intentionally supports 32-byte messages only because it
        -- mirrors the current native BIP340/RPBSch circuit shape.
        zkcc.witness.bip340_compute_full_challenge_inputs = function(sig, pk, msg)
            local inputs, public_inputs =
                zkcc.native.bip340_compute_full_challenge_inputs_native(sig, pk, msg)
            return {
                inputs = inputs,
                public_inputs = public_inputs,
            }
        end
    end

    -- =======================================================================
    -- Lua-authored BIP340 circuit helpers
    -- =======================================================================

    --- Convert multi-return (x, y, z) from gadget calls into a point table.
    function zkcc.bip340_point(x, y, z)
        return { x = x, y = y, z = z }
    end

    --- Declare all BIP340 witness wires on a named logic.
    function zkcc.declare_bip340_witness(L)
        local rx = L:public_input{ name = "rx", desc = "R.x (x-only)", type = "field" }
        local px = L:public_input{ name = "px", desc = "P.x (x-only public key)", type = "field" }
        local e  = L:public_input{ name = "e",  desc = "Fiat-Shamir challenge", type = "field" }

        local bits_s, int_sx, int_sy, int_sz = {}, {}, {}, {}
        for i = 1, 256 do
            bits_s[i] = L:private_input{
                name = string.format("bits_s_%03d", i),
                desc = string.format("s bit %d (MSB-first)", i),
                type = "field",
            }
            if i < 256 then
                int_sx[i] = L:private_input{
                    name = string.format("int_sx_%03d", i),
                    desc = string.format("s·G intermediate x %d", i),
                    type = "field",
                }
                int_sy[i] = L:private_input{
                    name = string.format("int_sy_%03d", i),
                    desc = string.format("s·G intermediate y %d", i),
                    type = "field",
                }
                int_sz[i] = L:private_input{
                    name = string.format("int_sz_%03d", i),
                    desc = string.format("s·G intermediate z %d", i),
                    type = "field",
                }
            end
        end

        local bits_e, int_ex, int_ey, int_ez = {}, {}, {}, {}
        for i = 1, 256 do
            bits_e[i] = L:private_input{
                name = string.format("bits_e_%03d", i),
                desc = string.format("e bit %d (MSB-first)", i),
                type = "field",
            }
            if i < 256 then
                int_ex[i] = L:private_input{
                    name = string.format("int_ex_%03d", i),
                    desc = string.format("e·P intermediate x %d", i),
                    type = "field",
                }
                int_ey[i] = L:private_input{
                    name = string.format("int_ey_%03d", i),
                    desc = string.format("e·P intermediate y %d", i),
                    type = "field",
                }
                int_ez[i] = L:private_input{
                    name = string.format("int_ez_%03d", i),
                    desc = string.format("e·P intermediate z %d", i),
                    type = "field",
                }
            else
                int_ex[i] = bits_e[i]
                int_ey[i] = bits_e[i]
                int_ez[i] = bits_e[i]
            end
        end

        local py = L:private_input{
            name = "py", desc = "P.y (even square root)", type = "field",
        }
        local ry = L:private_input{
            name = "ry", desc = "R.y (affine, even)", type = "field",
        }
        local rz_inv = L:private_input{
            name = "rz_inv", desc = "R.z inverse", type = "field",
        }

        local bits_ry = {}
        for i = 1, 256 do
            bits_ry[i] = L:private_input{
                name = string.format("bits_ry_%03d", i),
                desc = string.format("ry bit %d (MSB-first)", i),
                type = "field",
            }
        end

        return {
            rx = rx, px = px, e = e,
            bits_s = bits_s,
            int_s = { x = int_sx, y = int_sy, z = int_sz },
            bits_e = bits_e,
            int_e = { x = int_ex, y = int_ey, z = int_ez },
            py = py, ry = ry, rz_inv = rz_inv,
            bits_ry = bits_ry,
        }
    end

    --- Build named witness inputs from a native bip340_compute result.
    function zkcc.bip340_witness_named(witness_result)
        local named = {
            rx = witness_result.rx,
            px = witness_result.px,
            e  = witness_result.e,
        }
        for i = 1, 256 do
            named[string.format("bits_s_%03d", i)] = witness_result.bits_s[i]
            if i < 256 then
                named[string.format("int_sx_%03d", i)] = witness_result.int_sx[i]
                named[string.format("int_sy_%03d", i)] = witness_result.int_sy[i]
                named[string.format("int_sz_%03d", i)] = witness_result.int_sz[i]
            end
        end
        for i = 1, 256 do
            named[string.format("bits_e_%03d", i)] = witness_result.bits_e[i]
            if i < 256 then
                named[string.format("int_ex_%03d", i)] = witness_result.int_ex[i]
                named[string.format("int_ey_%03d", i)] = witness_result.int_ey[i]
                named[string.format("int_ez_%03d", i)] = witness_result.int_ez[i]
            end
        end
        named.py = witness_result.py
        named.ry = witness_result.ry
        named.rz_inv = witness_result.rz_inv
        for i = 1, 256 do
            named[string.format("bits_ry_%03d", i)] = witness_result.bits_ry[i]
        end
        return named
    end

    --- Compile the Lua-authored BIP340 verification circuit.
    --- Returns a compiled NamedArtifact ready for zkcc.prove_circuit /
    --- zkcc.verify_circuit.
    function zkcc.bip340_circuit_compile()
        local L = zkcc.named_logic("bip340")
        L:set_version("1.0.0")
        L:set_author("Lua-authored BIP340 gadget circuit")

        local w = zkcc.declare_bip340_witness(L)
        L:bind_inputs()

        local Gx = L:bip340_gx()
        local Gy = L:bip340_gy()
        local one = L:konst(L:one())
        local zero = L:konst(L:zero())

        L:bip340_assert_field_from_bits_msb(w.bits_e, w.e)
        L:bip340_assert_scalar_lt_order(w.bits_s)
        L:bip340_assert_point_on_curve(w.px, w.py)

        local sG_x, sG_y, sG_z = L:bip340_scalar_mult(
            Gx, Gy, one,
            w.bits_s, w.int_s.x, w.int_s.y, w.int_s.z)

        local eP_x, eP_y, eP_z = L:bip340_scalar_mult(
            w.px, w.py, one,
            w.bits_e, w.int_e.x, w.int_e.y, w.int_e.z)

        local neg_eP_y = L:sub(zero, eP_y)
        local R_x, R_y, R_z = L:bip340_addE(
            sG_x, sG_y, sG_z,
            eP_x, neg_eP_y, eP_z)

        L:bip340_assert_point_on_curve(w.rx, w.ry)
        L:assert_eq(L:mul(R_z, w.rz_inv), one)
        L:assert_eq(R_x, L:mul(w.rx, R_z))
        L:assert_eq(R_y, L:mul(w.ry, R_z))
        L:bip340_assert_ry_bitness_and_even(w.bits_ry, w.ry)

        return L:compile()
    end

    --- (deprecated alias)
    zkcc.bip340_lua_circuit_compile = zkcc.bip340_circuit_compile
end

return M
