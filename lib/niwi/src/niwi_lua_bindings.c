/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

#include "niwi.h"
#include "encoding.h"
#include "hash.h"
#include "npro.h"
#include "extract.h"
#include "commitment.h"
#include "pbsch_commitment.h"

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "zen_octet.h"

#include <string.h>
#include <stdlib.h>

/* ---- OCTET helpers (from Zenroom's octet.h) -------------------------- */

extern const char *o_val(const octet*);
extern size_t      o_len(const octet*);
extern void        lerror(lua_State*, const char*, ...);

static void push_octet_copy(lua_State *L, const uint8_t *buf, size_t len) {
    push_buffer_to_octet(L, (char *)buf, len);
}

/* ---- Helper: get an OCTET from a table field ------------------------- */

static const octet *table_get_octet(lua_State *L, int table_idx,
                                    const char *key) {
    /* Stack: ... table ... */
    lua_getfield(L, table_idx, key);
    if (lua_isnil(L, -1)) {
        lua_pop(L, 1);
        return NULL;
    }
    const octet *o = o_arg(L, -1);
    lua_pop(L, 1);
    return o;
}

static niwi_ctx_t *create_ctx_from_circuit(lua_State *L, const octet *circuit_oct,
                                           niwi_relation_id_t relation_id,
                                           const char *caller) {
    niwi_ctx_t *ctx = niwi_ctx_create_with_relation(
        (const uint8_t *)o_val(circuit_oct), o_len(circuit_oct),
        relation_id, NULL, NULL);
    if (!ctx) {
        lerror(L, "%s: failed to create context", caller);
        return NULL;
    }
    return ctx;
}

/* ---- prove_envelope_unchecked ---------------------------------------- */

/*
 * Usage: proof = zkcore.prove_envelope_unchecked({
 *     circuit = <circuit artifact>,
 *     inputs = <witness inputs>,
 *     public_inputs = <optional public statement inputs>,
 *     seed = <optional OCTET seed>
 * })
 *
 * Returns: OCTET containing the NiwiProof.
 */
static int lua_prove_envelope_unchecked(lua_State *L) {
    if (!lua_istable(L, 1)) {
        lerror(L, "prove_envelope_unchecked: expected table argument");
        return 0;
    }

    /* Extract circuit artifact. */
    const octet *circuit_oct = table_get_octet(L, 1, "circuit");
    if (!circuit_oct) {
        lerror(L, "prove_envelope_unchecked: missing 'circuit' field");
        return 0;
    }

    /* Extract inputs. */
    const octet *inputs_oct = table_get_octet(L, 1, "inputs");
    if (!inputs_oct) {
        o_free(L, circuit_oct);
        lerror(L, "prove_envelope_unchecked: missing 'inputs' field");
        return 0;
    }

    const octet *pub_oct = table_get_octet(L, 1, "public_inputs");
    if (!pub_oct) pub_oct = inputs_oct;

    /* Extract optional seed. */
    const octet *seed_oct = table_get_octet(L, 1, "seed");

    /* Create NIWI context. */
    niwi_ctx_t *ctx = niwi_ctx_create(
        (const uint8_t *)o_val(circuit_oct), o_len(circuit_oct));
    if (!ctx) {
        o_free(L, seed_oct);
        if (pub_oct != inputs_oct) o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        lerror(L, "prove_envelope_unchecked: failed to create context");
        return 0;
    }

    /* Prove. */
    uint8_t *proof_out = NULL;
    size_t proof_len = 0;

    int rc = niwi_envelope_prove_unchecked(
        ctx,
        (const uint8_t *)o_val(pub_oct), o_len(pub_oct),
        (const uint8_t *)o_val(inputs_oct), o_len(inputs_oct),
        &proof_out, &proof_len);

    const char *err = niwi_last_error(ctx);

    if (rc != 0) {
        niwi_ctx_free(ctx);
        o_free(L, seed_oct);
        if (pub_oct != inputs_oct) o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        if (err)
            lerror(L, "prove_envelope_unchecked: %s", err);
        else
            lerror(L, "prove_envelope_unchecked: unknown error");
        return 0;
    }

    /* Return proof as OCTET. */
    push_octet_copy(L, proof_out, proof_len);
    niwi_free_buffer(proof_out);
    niwi_ctx_free(ctx);
    o_free(L, seed_oct);
    if (pub_oct != inputs_oct) o_free(L, pub_oct);
    o_free(L, inputs_oct);
    o_free(L, circuit_oct);

    /* The octet is on the stack; return it. */
    return 1;
}

static int lua_prove_bip340_relation(lua_State *L) {
    if (!lua_istable(L, 1)) {
        lerror(L, "prove_bip340_relation: expected table argument");
        return 0;
    }

    const octet *circuit_oct = table_get_octet(L, 1, "circuit");
    const octet *inputs_oct = table_get_octet(L, 1, "inputs");
    const octet *pub_oct = table_get_octet(L, 1, "public_inputs");
    if (!circuit_oct || !inputs_oct || !pub_oct) {
        o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        lerror(L, "prove_bip340_relation: missing required fields");
        return 0;
    }

    niwi_ctx_t *ctx = create_ctx_from_circuit(
        L, circuit_oct, NIWI_RELATION_ZKCC_BIP340, "prove_bip340_relation");
    if (!ctx) {
        o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        return 0;
    }

    uint8_t *proof_out = NULL;
    size_t proof_len = 0;
    int rc = niwi_prove(ctx,
                        (const uint8_t *)o_val(pub_oct), o_len(pub_oct),
                        (const uint8_t *)o_val(inputs_oct), o_len(inputs_oct),
                        &proof_out, &proof_len);
    if (rc != 0) {
        const char *err = niwi_last_error(ctx);
        niwi_ctx_free(ctx);
        o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        lerror(L, "prove_bip340_relation: %s", err ? err : "unknown error");
        return 0;
    }

    push_octet_copy(L, proof_out, proof_len);
    niwi_free_buffer(proof_out);
    niwi_ctx_free(ctx);
    o_free(L, pub_oct);
    o_free(L, inputs_oct);
    o_free(L, circuit_oct);
    return 1;
}

static int lua_verify_bip340_relation(lua_State *L) {
    if (!lua_istable(L, 1)) {
        lerror(L, "verify_bip340_relation: expected table argument");
        return 0;
    }

    const octet *circuit_oct = table_get_octet(L, 1, "circuit");
    const octet *proof_oct = table_get_octet(L, 1, "proof");
    const octet *pub_oct = table_get_octet(L, 1, "public_inputs");
    if (!circuit_oct || !proof_oct || !pub_oct) {
        o_free(L, pub_oct);
        o_free(L, proof_oct);
        o_free(L, circuit_oct);
        lerror(L, "verify_bip340_relation: missing required fields");
        return 0;
    }

    niwi_ctx_t *ctx = create_ctx_from_circuit(
        L, circuit_oct, NIWI_RELATION_ZKCC_BIP340, "verify_bip340_relation");
    if (!ctx) {
        o_free(L, pub_oct);
        o_free(L, proof_oct);
        o_free(L, circuit_oct);
        return 0;
    }

    int rc = niwi_verify(
        ctx,
        (const uint8_t *)o_val(proof_oct), o_len(proof_oct),
        (const uint8_t *)o_val(pub_oct), o_len(pub_oct));

    niwi_ctx_free(ctx);
    o_free(L, pub_oct);
    o_free(L, proof_oct);
    o_free(L, circuit_oct);

    lua_pushboolean(L, rc == 0);
    return 1;
}

static int lua_prove_zkcc_relation(lua_State *L) {
    if (!lua_istable(L, 1)) {
        lerror(L, "prove_zkcc_relation: expected table argument");
        return 0;
    }

    const octet *circuit_oct = table_get_octet(L, 1, "circuit");
    const octet *inputs_oct = table_get_octet(L, 1, "inputs");
    const octet *pub_oct = table_get_octet(L, 1, "public_inputs");
    if (!circuit_oct || !inputs_oct || !pub_oct) {
        o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        lerror(L, "prove_zkcc_relation: missing required fields");
        return 0;
    }

    niwi_ctx_t *ctx = create_ctx_from_circuit(
        L, circuit_oct, NIWI_RELATION_ZKCC_P256, "prove_zkcc_relation");
    if (!ctx) {
        o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        return 0;
    }

    uint8_t *proof_out = NULL;
    size_t proof_len = 0;
    int rc = niwi_prove(ctx,
                        (const uint8_t *)o_val(pub_oct), o_len(pub_oct),
                        (const uint8_t *)o_val(inputs_oct), o_len(inputs_oct),
                        &proof_out, &proof_len);
    if (rc != 0) {
        const char *err = niwi_last_error(ctx);
        niwi_ctx_free(ctx);
        o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        lerror(L, "prove_zkcc_relation: %s", err ? err : "unknown error");
        return 0;
    }

    push_octet_copy(L, proof_out, proof_len);
    niwi_free_buffer(proof_out);
    niwi_ctx_free(ctx);
    o_free(L, pub_oct);
    o_free(L, inputs_oct);
    o_free(L, circuit_oct);
    return 1;
}

static int lua_verify_zkcc_relation(lua_State *L) {
    if (!lua_istable(L, 1)) {
        lerror(L, "verify_zkcc_relation: expected table argument");
        return 0;
    }

    const octet *circuit_oct = table_get_octet(L, 1, "circuit");
    const octet *proof_oct = table_get_octet(L, 1, "proof");
    const octet *pub_oct = table_get_octet(L, 1, "public_inputs");
    if (!circuit_oct || !proof_oct || !pub_oct) {
        o_free(L, pub_oct);
        o_free(L, proof_oct);
        o_free(L, circuit_oct);
        lerror(L, "verify_zkcc_relation: missing required fields");
        return 0;
    }

    niwi_ctx_t *ctx = create_ctx_from_circuit(
        L, circuit_oct, NIWI_RELATION_ZKCC_P256, "verify_zkcc_relation");
    if (!ctx) {
        o_free(L, pub_oct);
        o_free(L, proof_oct);
        o_free(L, circuit_oct);
        return 0;
    }

    int rc = niwi_verify(
        ctx,
        (const uint8_t *)o_val(proof_oct), o_len(proof_oct),
        (const uint8_t *)o_val(pub_oct), o_len(pub_oct));

    niwi_ctx_free(ctx);
    o_free(L, pub_oct);
    o_free(L, proof_oct);
    o_free(L, circuit_oct);

    lua_pushboolean(L, rc == 0);
    return 1;
}

static int lua_prove_relation_common(lua_State *L, niwi_relation_id_t relation_id,
                                     const char *caller) {
    if (!lua_istable(L, 1)) {
        lerror(L, "%s: expected table argument", caller);
        return 0;
    }

    const octet *circuit_oct = table_get_octet(L, 1, "circuit");
    const octet *inputs_oct = table_get_octet(L, 1, "inputs");
    const octet *pub_oct = table_get_octet(L, 1, "public_inputs");
    if (!circuit_oct || !inputs_oct || !pub_oct) {
        o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        lerror(L, "%s: missing required fields", caller);
        return 0;
    }

    niwi_ctx_t *ctx = create_ctx_from_circuit(L, circuit_oct, relation_id, caller);
    if (!ctx) {
        o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        return 0;
    }

    uint8_t *proof_out = NULL;
    size_t proof_len = 0;
    int rc = niwi_prove(ctx,
                        (const uint8_t *)o_val(pub_oct), o_len(pub_oct),
                        (const uint8_t *)o_val(inputs_oct), o_len(inputs_oct),
                        &proof_out, &proof_len);
    if (rc != 0) {
        const char *err = niwi_last_error(ctx);
        niwi_ctx_free(ctx);
        o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        lerror(L, "%s: %s", caller, err ? err : "unknown error");
        return 0;
    }

    push_octet_copy(L, proof_out, proof_len);
    niwi_free_buffer(proof_out);
    niwi_ctx_free(ctx);
    o_free(L, pub_oct);
    o_free(L, inputs_oct);
    o_free(L, circuit_oct);
    return 1;
}

static int lua_verify_relation_common(lua_State *L, niwi_relation_id_t relation_id,
                                      const char *caller) {
    if (!lua_istable(L, 1)) {
        lerror(L, "%s: expected table argument", caller);
        return 0;
    }

    const octet *circuit_oct = table_get_octet(L, 1, "circuit");
    const octet *proof_oct = table_get_octet(L, 1, "proof");
    const octet *pub_oct = table_get_octet(L, 1, "public_inputs");
    if (!circuit_oct || !proof_oct || !pub_oct) {
        o_free(L, pub_oct);
        o_free(L, proof_oct);
        o_free(L, circuit_oct);
        lerror(L, "%s: missing required fields", caller);
        return 0;
    }

    niwi_ctx_t *ctx = create_ctx_from_circuit(L, circuit_oct, relation_id, caller);
    if (!ctx) {
        o_free(L, pub_oct);
        o_free(L, proof_oct);
        o_free(L, circuit_oct);
        return 0;
    }

    int rc = niwi_verify(ctx,
                         (const uint8_t *)o_val(proof_oct), o_len(proof_oct),
                         (const uint8_t *)o_val(pub_oct), o_len(pub_oct));
    niwi_ctx_free(ctx);
    o_free(L, pub_oct);
    o_free(L, proof_oct);
    o_free(L, circuit_oct);
    lua_pushboolean(L, rc == 0);
    return 1;
}

static int lua_prove_relation_observed_common(lua_State *L,
                                              niwi_relation_id_t relation_id,
                                              const char *caller) {
    if (!lua_istable(L, 1)) {
        lerror(L, "%s: expected table argument", caller);
        return 0;
    }

    const octet *circuit_oct = table_get_octet(L, 1, "circuit");
    const octet *inputs_oct = table_get_octet(L, 1, "inputs");
    const octet *pub_oct = table_get_octet(L, 1, "public_inputs");
    if (!circuit_oct || !inputs_oct || !pub_oct) {
        o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        lerror(L, "%s: missing required fields", caller);
        return 0;
    }

    niwi_ctx_t *ctx = create_ctx_from_circuit(L, circuit_oct, relation_id, caller);
    if (!ctx) {
        o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        return 0;
    }

    uint8_t *proof_out = NULL, *gamma_out = NULL;
    size_t proof_len = 0, gamma_len = 0;
    int rc = niwi_prove_observed(
        ctx,
        (const uint8_t *)o_val(pub_oct), o_len(pub_oct),
        (const uint8_t *)o_val(inputs_oct), o_len(inputs_oct),
        &proof_out, &proof_len, &gamma_out, &gamma_len);
    if (rc != 0) {
        const char *err = niwi_last_error(ctx);
        niwi_ctx_free(ctx);
        o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        lerror(L, "%s: %s", caller, err ? err : "unknown error");
        return 0;
    }

    push_octet_copy(L, proof_out, proof_len);
    push_octet_copy(L, gamma_out, gamma_len);
    niwi_free_buffer(proof_out);
    niwi_free_buffer(gamma_out);
    niwi_ctx_free(ctx);
    o_free(L, pub_oct);
    o_free(L, inputs_oct);
    o_free(L, circuit_oct);
    return 2;
}

static int lua_extract_relation_common(lua_State *L, niwi_relation_id_t relation_id,
                                       const char *caller) {
    if (!lua_istable(L, 1)) {
        lerror(L, "%s: expected table argument", caller);
        return 0;
    }

    const octet *circuit_oct = table_get_octet(L, 1, "circuit");
    const octet *proof_oct = table_get_octet(L, 1, "proof");
    const octet *gamma_oct = table_get_octet(L, 1, "gamma");
    const octet *pub_oct = table_get_octet(L, 1, "public_inputs");
    if (!circuit_oct || !proof_oct || !gamma_oct || !pub_oct) {
        o_free(L, pub_oct);
        o_free(L, gamma_oct);
        o_free(L, proof_oct);
        o_free(L, circuit_oct);
        lerror(L, "%s: missing required fields", caller);
        return 0;
    }

    niwi_ctx_t *ctx = create_ctx_from_circuit(L, circuit_oct, relation_id, caller);
    if (!ctx) {
        o_free(L, pub_oct);
        o_free(L, gamma_oct);
        o_free(L, proof_oct);
        o_free(L, circuit_oct);
        return 0;
    }

    uint8_t *witness = NULL;
    size_t witness_len = 0;
    int rc = niwi_extract(ctx,
                          (const uint8_t *)o_val(proof_oct), o_len(proof_oct),
                          (const uint8_t *)o_val(gamma_oct), o_len(gamma_oct),
                          (const uint8_t *)o_val(pub_oct), o_len(pub_oct),
                          &witness, &witness_len);
    if (rc != 0) {
        const char *err = niwi_last_error(ctx);
        niwi_ctx_free(ctx);
        o_free(L, pub_oct);
        o_free(L, gamma_oct);
        o_free(L, proof_oct);
        o_free(L, circuit_oct);
        lerror(L, "%s: %s", caller, err ? err : "unknown error");
        return 0;
    }

    push_octet_copy(L, witness, witness_len);
    niwi_free_buffer(witness);
    niwi_ctx_free(ctx);
    o_free(L, pub_oct);
    o_free(L, gamma_oct);
    o_free(L, proof_oct);
    o_free(L, circuit_oct);
    return 1;
}

static int lua_prove_rpbsch_relation(lua_State *L) {
    return lua_prove_relation_common(L, NIWI_RELATION_RPBSCH,
                                     "prove_rpbsch_relation");
}

static int lua_verify_rpbsch_relation(lua_State *L) {
    return lua_verify_relation_common(L, NIWI_RELATION_RPBSCH,
                                      "verify_rpbsch_relation");
}

static int lua_prove_rpbsch_relation_with_observation_test(lua_State *L) {
    return lua_prove_relation_observed_common(
        L, NIWI_RELATION_RPBSCH,
        "prove_rpbsch_relation_with_observation_test");
}

static int lua_extract_rpbsch_relation_from_gamma_test(lua_State *L) {
    return lua_extract_relation_common(
        L, NIWI_RELATION_RPBSCH,
        "extract_rpbsch_relation_from_gamma_test");
}

/* ---- verify_envelope -------------------------------------------------- */

/*
 * Usage: ok = zkcore.verify_envelope({
 *     circuit = <circuit artifact>,
 *     proof = <OCTET NiwiProof>,
 *     public_inputs = <OCTET public inputs>
 * })
 *
 * Returns: boolean.
 */
static int lua_verify_envelope(lua_State *L) {
    if (!lua_istable(L, 1)) {
        lerror(L, "verify_envelope: expected table argument");
        return 0;
    }

    const octet *circuit_oct = table_get_octet(L, 1, "circuit");
    const octet *proof_oct    = table_get_octet(L, 1, "proof");
    const octet *pub_oct      = table_get_octet(L, 1, "public_inputs");

    if (!circuit_oct) {
        lerror(L, "verify_envelope: missing 'circuit' field");
        return 0;
    }
    if (!proof_oct) {
        o_free(L, circuit_oct);
        lerror(L, "verify_envelope: missing 'proof' field");
        return 0;
    }
    if (!pub_oct) {
        o_free(L, proof_oct);
        o_free(L, circuit_oct);
        lerror(L, "verify_envelope: missing 'public_inputs' field");
        return 0;
    }

    niwi_ctx_t *ctx = niwi_ctx_create(
        (const uint8_t *)o_val(circuit_oct), o_len(circuit_oct));
    if (!ctx) {
        o_free(L, pub_oct);
        o_free(L, proof_oct);
        o_free(L, circuit_oct);
        lerror(L, "verify_envelope: failed to create context");
        return 0;
    }

    int rc = niwi_envelope_verify(
        ctx,
        (const uint8_t *)o_val(proof_oct), o_len(proof_oct),
        (const uint8_t *)o_val(pub_oct), o_len(pub_oct));

    niwi_ctx_free(ctx);
    o_free(L, pub_oct);
    o_free(L, proof_oct);
    o_free(L, circuit_oct);

    lua_pushboolean(L, rc == 0);
    return 1;
}

/* ---- niwi_profile ---------------------------------------------------- */

/*
 * Usage: profile = zkcore.niwi_profile()
 *
 * Returns: table { version = "niwi-v1", protocol_id = 0 }
 */
static int lua_niwi_profile(lua_State *L) {
    lua_newtable(L);

    lua_pushstring(L, niwi_protocol_version());
    lua_setfield(L, -2, "version");

    lua_pushinteger(L, 0);
    lua_setfield(L, -2, "protocol_id");

    return 1;
}

/* ---- prove_envelope_with_observation_unchecked_test (test-only) ------ */

/*
 * Usage: proof, gamma = zkcore.prove_envelope_with_observation_unchecked_test({
 *     circuit = <circuit artifact>,
 *     inputs = <witness inputs>,
 *     public_inputs = <optional public statement inputs>
 * })
 *
 * Returns: two OCTETs (proof, gamma).
 */
static int lua_prove_envelope_with_observation_unchecked_test(lua_State *L) {
    if (!lua_istable(L, 1)) {
        lerror(L, "prove_envelope_with_observation_unchecked_test: expected table argument");
        return 0;
    }

    const octet *circuit_oct = table_get_octet(L, 1, "circuit");
    const octet *inputs_oct  = table_get_octet(L, 1, "inputs");
    const octet *pub_oct     = NULL;

    if (!circuit_oct || !inputs_oct) {
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        lerror(L, "prove_envelope_with_observation_unchecked_test: missing required fields");
        return 0;
    }
    pub_oct = table_get_octet(L, 1, "public_inputs");
    if (!pub_oct) pub_oct = inputs_oct;

    niwi_ctx_t *ctx = niwi_ctx_create(
        (const uint8_t *)o_val(circuit_oct), o_len(circuit_oct));
    if (!ctx) {
        if (pub_oct != inputs_oct) o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        lerror(L, "prove_envelope_with_observation_unchecked_test: failed to create context");
        return 0;
    }

    uint8_t *proof_out = NULL, *gamma_out = NULL;
    size_t proof_len = 0, gamma_len = 0;

    int rc = niwi_envelope_prove_observed_unchecked(
        ctx,
        (const uint8_t *)o_val(pub_oct), o_len(pub_oct),
        (const uint8_t *)o_val(inputs_oct), o_len(inputs_oct),
        &proof_out, &proof_len,
        &gamma_out, &gamma_len);

    if (rc != 0) {
        const char *err = niwi_last_error(ctx);
        niwi_ctx_free(ctx);
        if (pub_oct != inputs_oct) o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        lerror(L, "prove_envelope_with_observation_unchecked_test: %s",
               err ? err : "unknown error");
        return 0;
    }

    /* Return proof and gamma as two OCTETs. */
    push_octet_copy(L, proof_out, proof_len);
    push_octet_copy(L, gamma_out, gamma_len);

    niwi_free_buffer(proof_out);
    niwi_free_buffer(gamma_out);
    niwi_ctx_free(ctx);
    if (pub_oct != inputs_oct) o_free(L, pub_oct);
    o_free(L, inputs_oct);
    o_free(L, circuit_oct);

    return 2;
}

static int lua_prove_bip340_relation_with_observation_test(lua_State *L) {
    if (!lua_istable(L, 1)) {
        lerror(L, "prove_bip340_relation_with_observation_test: expected table argument");
        return 0;
    }

    const octet *circuit_oct = table_get_octet(L, 1, "circuit");
    const octet *inputs_oct = table_get_octet(L, 1, "inputs");
    const octet *pub_oct = table_get_octet(L, 1, "public_inputs");
    if (!circuit_oct || !inputs_oct || !pub_oct) {
        o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        lerror(L, "prove_bip340_relation_with_observation_test: missing required fields");
        return 0;
    }

    niwi_ctx_t *ctx = create_ctx_from_circuit(
        L, circuit_oct, NIWI_RELATION_ZKCC_BIP340,
        "prove_bip340_relation_with_observation_test");
    if (!ctx) {
        o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        return 0;
    }

    uint8_t *proof_out = NULL, *gamma_out = NULL;
    size_t proof_len = 0, gamma_len = 0;
    int rc = niwi_prove_observed(
        ctx,
        (const uint8_t *)o_val(pub_oct), o_len(pub_oct),
        (const uint8_t *)o_val(inputs_oct), o_len(inputs_oct),
        &proof_out, &proof_len, &gamma_out, &gamma_len);
    if (rc != 0) {
        const char *err = niwi_last_error(ctx);
        niwi_ctx_free(ctx);
        o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        lerror(L, "prove_bip340_relation_with_observation_test: %s",
               err ? err : "unknown error");
        return 0;
    }

    push_octet_copy(L, proof_out, proof_len);
    push_octet_copy(L, gamma_out, gamma_len);
    niwi_free_buffer(proof_out);
    niwi_free_buffer(gamma_out);
    niwi_ctx_free(ctx);
    o_free(L, pub_oct);
    o_free(L, inputs_oct);
    o_free(L, circuit_oct);
    return 2;
}

static int lua_prove_zkcc_relation_with_observation_test(lua_State *L) {
    if (!lua_istable(L, 1)) {
        lerror(L, "prove_zkcc_relation_with_observation_test: expected table argument");
        return 0;
    }

    const octet *circuit_oct = table_get_octet(L, 1, "circuit");
    const octet *inputs_oct = table_get_octet(L, 1, "inputs");
    const octet *pub_oct = table_get_octet(L, 1, "public_inputs");
    if (!circuit_oct || !inputs_oct || !pub_oct) {
        o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        lerror(L, "prove_zkcc_relation_with_observation_test: missing required fields");
        return 0;
    }

    niwi_ctx_t *ctx = create_ctx_from_circuit(
        L, circuit_oct, NIWI_RELATION_ZKCC_P256,
        "prove_zkcc_relation_with_observation_test");
    if (!ctx) {
        o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        return 0;
    }

    uint8_t *proof_out = NULL, *gamma_out = NULL;
    size_t proof_len = 0, gamma_len = 0;
    int rc = niwi_prove_observed(
        ctx,
        (const uint8_t *)o_val(pub_oct), o_len(pub_oct),
        (const uint8_t *)o_val(inputs_oct), o_len(inputs_oct),
        &proof_out, &proof_len, &gamma_out, &gamma_len);
    if (rc != 0) {
        const char *err = niwi_last_error(ctx);
        niwi_ctx_free(ctx);
        o_free(L, pub_oct);
        o_free(L, inputs_oct);
        o_free(L, circuit_oct);
        lerror(L, "prove_zkcc_relation_with_observation_test: %s",
               err ? err : "unknown error");
        return 0;
    }

    push_octet_copy(L, proof_out, proof_len);
    push_octet_copy(L, gamma_out, gamma_len);
    niwi_free_buffer(proof_out);
    niwi_free_buffer(gamma_out);
    niwi_ctx_free(ctx);
    o_free(L, pub_oct);
    o_free(L, inputs_oct);
    o_free(L, circuit_oct);
    return 2;
}

/* ---- extract_from_gamma_unchecked_test (test-only) ------------------- */

/*
 * Usage: witness = zkcore.extract_from_gamma_unchecked_test({
 *     proof = <OCTET NiwiProof>,
 *     gamma = <OCTET Gamma log>,
 *     public_inputs = <OCTET public inputs>
 * })
 *
 * Returns: OCTET witness.
 */
static int lua_extract_from_gamma_unchecked_test(lua_State *L) {
    if (!lua_istable(L, 1)) {
        lerror(L, "extract_from_gamma_unchecked_test: expected table argument");
        return 0;
    }

    const octet *proof_oct = table_get_octet(L, 1, "proof");
    const octet *gamma_oct = table_get_octet(L, 1, "gamma");
    const octet *pub_oct   = table_get_octet(L, 1, "public_inputs");

    if (!proof_oct || !gamma_oct || !pub_oct) {
        o_free(L, pub_oct);
        o_free(L, gamma_oct);
        o_free(L, proof_oct);
        lerror(L, "extract_from_gamma_unchecked_test: missing required fields");
        return 0;
    }

    niwi_extract_t *ex = niwi_extract_create(
        (const uint8_t *)o_val(proof_oct), o_len(proof_oct),
        (const uint8_t *)o_val(gamma_oct), o_len(gamma_oct),
        (const uint8_t *)o_val(pub_oct), o_len(pub_oct));

    if (!ex) {
        o_free(L, pub_oct);
        o_free(L, gamma_oct);
        o_free(L, proof_oct);
        lerror(L, "extract_from_gamma_unchecked_test: failed to create extractor");
        return 0;
    }

    const char *err = niwi_extract_error(ex);
    if (err) {
        niwi_extract_free(ex);
        o_free(L, pub_oct);
        o_free(L, gamma_oct);
        o_free(L, proof_oct);
        lerror(L, "extract_from_gamma_unchecked_test: %s", err);
        return 0;
    }

    size_t wlen = 0;
    int rc = niwi_extract_witness(ex, NULL, &wlen);
    if (rc != NIWI_EXTRACT_ERR_WITNESS || wlen == 0) {
        niwi_extract_free(ex);
        o_free(L, pub_oct);
        o_free(L, gamma_oct);
        o_free(L, proof_oct);
        lerror(L, "extract_from_gamma_unchecked_test: extraction failed");
        return 0;
    }

    uint8_t *witness_buf = (uint8_t *)malloc(wlen);
    if (!witness_buf) {
        niwi_extract_free(ex);
        o_free(L, pub_oct);
        o_free(L, gamma_oct);
        o_free(L, proof_oct);
        lerror(L, "extract_from_gamma_unchecked_test: out of memory");
        return 0;
    }

    size_t out_len = wlen;
    rc = niwi_extract_witness(ex, witness_buf, &out_len);

    niwi_extract_free(ex);
    o_free(L, pub_oct);
    o_free(L, gamma_oct);
    o_free(L, proof_oct);

    if (rc != NIWI_EXTRACT_OK || out_len != wlen) {
        free(witness_buf);
        lerror(L, "extract_from_gamma_unchecked_test: extraction failed");
        return 0;
    }

    push_octet_copy(L, witness_buf, wlen);
    free(witness_buf);
    return 1;
}

static int lua_extract_bip340_relation_from_gamma_test(lua_State *L) {
    if (!lua_istable(L, 1)) {
        lerror(L, "extract_bip340_relation_from_gamma_test: expected table argument");
        return 0;
    }

    const octet *circuit_oct = table_get_octet(L, 1, "circuit");
    const octet *proof_oct = table_get_octet(L, 1, "proof");
    const octet *gamma_oct = table_get_octet(L, 1, "gamma");
    const octet *pub_oct = table_get_octet(L, 1, "public_inputs");
    if (!circuit_oct || !proof_oct || !gamma_oct || !pub_oct) {
        o_free(L, pub_oct);
        o_free(L, gamma_oct);
        o_free(L, proof_oct);
        o_free(L, circuit_oct);
        lerror(L, "extract_bip340_relation_from_gamma_test: missing required fields");
        return 0;
    }

    niwi_ctx_t *ctx = create_ctx_from_circuit(
        L, circuit_oct, NIWI_RELATION_ZKCC_BIP340,
        "extract_bip340_relation_from_gamma_test");
    if (!ctx) {
        o_free(L, pub_oct);
        o_free(L, gamma_oct);
        o_free(L, proof_oct);
        o_free(L, circuit_oct);
        return 0;
    }

    uint8_t *witness = NULL;
    size_t witness_len = 0;
    int rc = niwi_extract(ctx,
                          (const uint8_t *)o_val(proof_oct), o_len(proof_oct),
                          (const uint8_t *)o_val(gamma_oct), o_len(gamma_oct),
                          (const uint8_t *)o_val(pub_oct), o_len(pub_oct),
                          &witness, &witness_len);
    if (rc != 0) {
        const char *err = niwi_last_error(ctx);
        niwi_ctx_free(ctx);
        o_free(L, pub_oct);
        o_free(L, gamma_oct);
        o_free(L, proof_oct);
        o_free(L, circuit_oct);
        lerror(L, "extract_bip340_relation_from_gamma_test: %s",
               err ? err : "unknown error");
        return 0;
    }

    push_octet_copy(L, witness, witness_len);
    niwi_free_buffer(witness);
    niwi_ctx_free(ctx);
    o_free(L, pub_oct);
    o_free(L, gamma_oct);
    o_free(L, proof_oct);
    o_free(L, circuit_oct);
    return 1;
}

static int lua_extract_zkcc_relation_from_gamma_test(lua_State *L) {
    if (!lua_istable(L, 1)) {
        lerror(L, "extract_zkcc_relation_from_gamma_test: expected table argument");
        return 0;
    }

    const octet *circuit_oct = table_get_octet(L, 1, "circuit");
    const octet *proof_oct = table_get_octet(L, 1, "proof");
    const octet *gamma_oct = table_get_octet(L, 1, "gamma");
    const octet *pub_oct = table_get_octet(L, 1, "public_inputs");
    if (!circuit_oct || !proof_oct || !gamma_oct || !pub_oct) {
        o_free(L, pub_oct);
        o_free(L, gamma_oct);
        o_free(L, proof_oct);
        o_free(L, circuit_oct);
        lerror(L, "extract_zkcc_relation_from_gamma_test: missing required fields");
        return 0;
    }

    niwi_ctx_t *ctx = create_ctx_from_circuit(
        L, circuit_oct, NIWI_RELATION_ZKCC_P256,
        "extract_zkcc_relation_from_gamma_test");
    if (!ctx) {
        o_free(L, pub_oct);
        o_free(L, gamma_oct);
        o_free(L, proof_oct);
        o_free(L, circuit_oct);
        return 0;
    }

    uint8_t *witness = NULL;
    size_t witness_len = 0;
    int rc = niwi_extract(ctx,
                          (const uint8_t *)o_val(proof_oct), o_len(proof_oct),
                          (const uint8_t *)o_val(gamma_oct), o_len(gamma_oct),
                          (const uint8_t *)o_val(pub_oct), o_len(pub_oct),
                          &witness, &witness_len);
    if (rc != 0) {
        const char *err = niwi_last_error(ctx);
        niwi_ctx_free(ctx);
        o_free(L, pub_oct);
        o_free(L, gamma_oct);
        o_free(L, proof_oct);
        o_free(L, circuit_oct);
        lerror(L, "extract_zkcc_relation_from_gamma_test: %s",
               err ? err : "unknown error");
        return 0;
    }

    push_octet_copy(L, witness, witness_len);
    niwi_free_buffer(witness);
    niwi_ctx_free(ctx);
    o_free(L, pub_oct);
    o_free(L, gamma_oct);
    o_free(L, proof_oct);
    o_free(L, circuit_oct);
    return 1;
}

/* ---- PBSch Pedersen primitives --------------------------------------- */

/* niwi_pbsch_pedersen_h() -> OCTET (32 bytes) */
static int lua_pbsch_pedersen_h(lua_State *L) {
    uint8_t h_x[32];
    if (niwi_pbsch_pedersen_h(h_x) != 0) {
        lerror(L, "pbsch_pedersen_h: H derivation failed");
        return 0;
    }
    push_octet_copy(L, h_x, 32);
    return 1;
}

/* niwi_pbsch_pedersen_commit(msg: OCTET(32), rho: OCTET(32)) -> OCTET(33) */
static int lua_pbsch_pedersen_commit(lua_State *L) {
    const octet *msg = o_arg(L, 1);
    const octet *rho = o_arg(L, 2);
    if (!msg || o_len(msg) != 32) {
        o_free(L, rho);
        o_free(L, msg);
        lerror(L, "pbsch_pedersen_commit: msg must be 32 bytes");
        return 0;
    }
    if (!rho || o_len(rho) != 32) {
        o_free(L, rho);
        o_free(L, msg);
        lerror(L, "pbsch_pedersen_commit: rho must be 32 bytes");
        return 0;
    }

    uint8_t c[33];
    if (niwi_pbsch_pedersen_commit((const uint8_t *)o_val(msg),
                                    (const uint8_t *)o_val(rho), c) != 0) {
        o_free(L, rho);
        o_free(L, msg);
        lerror(L, "pbsch_pedersen_commit: failed");
        return 0;
    }
    push_octet_copy(L, c, 33);
    o_free(L, rho);
    o_free(L, msg);
    return 1;
}

/* niwi_pbsch_pedersen_verify(c: OCTET(33), msg: OCTET(32), rho: OCTET(32)) -> bool */
static int lua_pbsch_pedersen_verify(lua_State *L) {
    const octet *c   = o_arg(L, 1);
    const octet *msg = o_arg(L, 2);
    const octet *rho = o_arg(L, 3);
    if (!c || o_len(c) != 33) {
        o_free(L, rho);
        o_free(L, msg);
        o_free(L, c);
        lerror(L, "pbsch_pedersen_verify: c must be 33 bytes");
        return 0;
    }
    if (!msg || o_len(msg) != 32) {
        o_free(L, rho);
        o_free(L, msg);
        o_free(L, c);
        lerror(L, "pbsch_pedersen_verify: msg must be 32 bytes");
        return 0;
    }
    if (!rho || o_len(rho) != 32) {
        o_free(L, rho);
        o_free(L, msg);
        o_free(L, c);
        lerror(L, "pbsch_pedersen_verify: rho must be 32 bytes");
        return 0;
    }

    int ok = niwi_pbsch_pedersen_verify((const uint8_t *)o_val(c),
                                         (const uint8_t *)o_val(msg),
                                         (const uint8_t *)o_val(rho));
    o_free(L, rho);
    o_free(L, msg);
    o_free(L, c);
    lua_pushboolean(L, ok == 0);
    return 1;
}

/* niwi_pbsch_pedersen_commit_lf(msg: OCTET(32), rho: OCTET(32)) -> OCTET(33) */
static int lua_pbsch_pedersen_commit_lf(lua_State *L) {
    const octet *msg = o_arg(L, 1);
    const octet *rho = o_arg(L, 2);
    if (!msg || o_len(msg) != 32) {
        o_free(L, rho);
        o_free(L, msg);
        lerror(L, "pbsch_pedersen_commit_lf: msg must be 32 bytes");
        return 0;
    }
    if (!rho || o_len(rho) != 32) {
        o_free(L, rho);
        o_free(L, msg);
        lerror(L, "pbsch_pedersen_commit_lf: rho must be 32 bytes");
        return 0;
    }

    uint8_t c[33];
    if (niwi_pbsch_pedersen_commit_lf((const uint8_t *)o_val(msg),
                                       (const uint8_t *)o_val(rho), c) != 0) {
        o_free(L, rho);
        o_free(L, msg);
        lerror(L, "pbsch_pedersen_commit_lf: failed");
        return 0;
    }
    push_octet_copy(L, c, 33);
    o_free(L, rho);
    o_free(L, msg);
    return 1;
}

/* niwi_pbsch_pedersen_verify_lf(c: OCTET(33), msg: OCTET(32), rho: OCTET(32)) -> bool */
static int lua_pbsch_pedersen_verify_lf(lua_State *L) {
    const octet *c   = o_arg(L, 1);
    const octet *msg = o_arg(L, 2);
    const octet *rho = o_arg(L, 3);
    if (!c || o_len(c) != 33) {
        o_free(L, rho);
        o_free(L, msg);
        o_free(L, c);
        lerror(L, "pbsch_pedersen_verify_lf: c must be 33 bytes");
        return 0;
    }
    if (!msg || o_len(msg) != 32) {
        o_free(L, rho);
        o_free(L, msg);
        o_free(L, c);
        lerror(L, "pbsch_pedersen_verify_lf: msg must be 32 bytes");
        return 0;
    }
    if (!rho || o_len(rho) != 32) {
        o_free(L, rho);
        o_free(L, msg);
        o_free(L, c);
        lerror(L, "pbsch_pedersen_verify_lf: rho must be 32 bytes");
        return 0;
    }

    int ok = niwi_pbsch_pedersen_verify_lf((const uint8_t *)o_val(c),
                                            (const uint8_t *)o_val(msg),
                                            (const uint8_t *)o_val(rho));
    o_free(L, rho);
    o_free(L, msg);
    o_free(L, c);
    lua_pushboolean(L, ok == 0);
    return 1;
}

/* niwi_pbsch_cmt3_prove_seeded(c: OCTET(33), msg: OCTET(32), rho: OCTET(32), seed: OCTET(32)) -> OCTET(1027) */
static int lua_pbsch_cmt3_prove_seeded(lua_State *L) {
    const octet *c = o_arg(L, 1);
    const octet *msg = o_arg(L, 2);
    const octet *rho = o_arg(L, 3);
    const octet *seed = o_arg(L, 4);
    if (!c || o_len(c) != 33) {
        o_free(L, seed); o_free(L, rho); o_free(L, msg); o_free(L, c);
        lerror(L, "pbsch_cmt3_prove_seeded: c must be 33 bytes");
        return 0;
    }
    if (!msg || o_len(msg) != 32) {
        o_free(L, seed); o_free(L, rho); o_free(L, msg); o_free(L, c);
        lerror(L, "pbsch_cmt3_prove_seeded: msg must be 32 bytes");
        return 0;
    }
    if (!rho || o_len(rho) != 32) {
        o_free(L, seed); o_free(L, rho); o_free(L, msg); o_free(L, c);
        lerror(L, "pbsch_cmt3_prove_seeded: rho must be 32 bytes");
        return 0;
    }
    if (!seed || o_len(seed) != 32) {
        o_free(L, seed); o_free(L, rho); o_free(L, msg); o_free(L, c);
        lerror(L, "pbsch_cmt3_prove_seeded: seed must be 32 bytes");
        return 0;
    }

    uint8_t proof[NIWI_PBSCH_CMT3_PROOF_SIZE];
    if (niwi_pbsch_cmt3_prove_seeded(
            (const uint8_t *)o_val(c), (const uint8_t *)o_val(msg),
            (const uint8_t *)o_val(rho), (const uint8_t *)o_val(seed),
            proof) != 0) {
        o_free(L, seed); o_free(L, rho); o_free(L, msg); o_free(L, c);
        lerror(L, "pbsch_cmt3_prove_seeded: failed");
        return 0;
    }
    push_octet_copy(L, proof, sizeof(proof));
    o_free(L, seed); o_free(L, rho); o_free(L, msg); o_free(L, c);
    return 1;
}

/* niwi_pbsch_cmt3_prove_seeded_observed(c, msg, rho, seed) -> proof, queries */
static int lua_pbsch_cmt3_prove_seeded_observed(lua_State *L) {
    const octet *c = o_arg(L, 1);
    const octet *msg = o_arg(L, 2);
    const octet *rho = o_arg(L, 3);
    const octet *seed = o_arg(L, 4);
    if (!c || o_len(c) != 33) {
        o_free(L, seed); o_free(L, rho); o_free(L, msg); o_free(L, c);
        lerror(L, "pbsch_cmt3_prove_seeded_observed: c must be 33 bytes");
        return 0;
    }
    if (!msg || o_len(msg) != 32) {
        o_free(L, seed); o_free(L, rho); o_free(L, msg); o_free(L, c);
        lerror(L, "pbsch_cmt3_prove_seeded_observed: msg must be 32 bytes");
        return 0;
    }
    if (!rho || o_len(rho) != 32) {
        o_free(L, seed); o_free(L, rho); o_free(L, msg); o_free(L, c);
        lerror(L, "pbsch_cmt3_prove_seeded_observed: rho must be 32 bytes");
        return 0;
    }
    if (!seed || o_len(seed) != 32) {
        o_free(L, seed); o_free(L, rho); o_free(L, msg); o_free(L, c);
        lerror(L, "pbsch_cmt3_prove_seeded_observed: seed must be 32 bytes");
        return 0;
    }

    uint8_t proof[NIWI_PBSCH_CMT3_PROOF_SIZE];
    uint8_t queries[NIWI_PBSCH_CMT3_QUERY_MAX_SIZE];
    size_t queries_len = 0;
    if (niwi_pbsch_cmt3_prove_seeded_observed(
            (const uint8_t *)o_val(c), (const uint8_t *)o_val(msg),
            (const uint8_t *)o_val(rho), (const uint8_t *)o_val(seed),
            proof, queries, &queries_len) != 0) {
        o_free(L, seed); o_free(L, rho); o_free(L, msg); o_free(L, c);
        lerror(L, "pbsch_cmt3_prove_seeded_observed: failed");
        return 0;
    }
    push_octet_copy(L, proof, sizeof(proof));
    push_octet_copy(L, queries, queries_len);
    o_free(L, seed); o_free(L, rho); o_free(L, msg); o_free(L, c);
    return 2;
}

/* niwi_pbsch_cmt3_hash_value(ck, c, all_A, i, ch, z_m, z_r) -> integer */
static int lua_pbsch_cmt3_hash_value(lua_State *L) {
    const octet *ck = o_arg(L, 1);
    const octet *c = o_arg(L, 2);
    const octet *all_A = o_arg(L, 3);
    lua_Integer i = luaL_checkinteger(L, 4);
    lua_Integer ch = luaL_checkinteger(L, 5);
    const octet *z_m = o_arg(L, 6);
    const octet *z_r = o_arg(L, 7);
    if (!ck || o_len(ck) != 32 || !c || o_len(c) != 33 ||
        !all_A || o_len(all_A) != 10 * NIWI_PBSCH_CMP_SIZE ||
        i < 1 || i > 10 || ch < 0 || ch >= 4096 ||
        !z_m || o_len(z_m) != 32 || !z_r || o_len(z_r) != 32) {
        o_free(L, z_r); o_free(L, z_m); o_free(L, all_A);
        o_free(L, c); o_free(L, ck);
        lua_pushnil(L);
        return 1;
    }
    uint16_t h = niwi_pbsch_cmt3_hash_value(
        (const uint8_t *)o_val(ck), (const uint8_t *)o_val(c),
        (const uint8_t *)o_val(all_A), (uint16_t)i, (uint16_t)ch,
        (const uint8_t *)o_val(z_m), (const uint8_t *)o_val(z_r));
    o_free(L, z_r); o_free(L, z_m); o_free(L, all_A);
    o_free(L, c); o_free(L, ck);
    lua_pushinteger(L, h);
    return 1;
}

/* niwi_pbsch_cmt3_verify(c: OCTET(33), proof: OCTET(1027)) -> bool */
static int lua_pbsch_cmt3_verify(lua_State *L) {
    const octet *c = o_arg(L, 1);
    const octet *proof = o_arg(L, 2);
    if (!c || o_len(c) != 33 || !proof ||
        o_len(proof) != NIWI_PBSCH_CMT3_PROOF_SIZE) {
        o_free(L, proof); o_free(L, c);
        lua_pushboolean(L, 0);
        return 1;
    }
    int ok = niwi_pbsch_cmt3_verify((const uint8_t *)o_val(c),
                                    (const uint8_t *)o_val(proof));
    o_free(L, proof);
    o_free(L, c);
    lua_pushboolean(L, ok == 0);
    return 1;
}

/* ---- Module registration --------------------------------------------- */

static const luaL_Reg niwi_functions[] = {
    {"prove_envelope_unchecked",                         lua_prove_envelope_unchecked},
    {"prove_zkcc_relation",                              lua_prove_zkcc_relation},
    {"verify_zkcc_relation",                             lua_verify_zkcc_relation},
    {"prove_bip340_relation",                            lua_prove_bip340_relation},
    {"verify_bip340_relation",                           lua_verify_bip340_relation},
    {"prove_rpbsch_relation",                            lua_prove_rpbsch_relation},
    {"verify_rpbsch_relation",                           lua_verify_rpbsch_relation},
    {"verify_envelope",                                  lua_verify_envelope},
    {"niwi_profile",                                     lua_niwi_profile},
    {"prove_envelope_with_observation_unchecked_test",   lua_prove_envelope_with_observation_unchecked_test},
    {"prove_zkcc_relation_with_observation_test",        lua_prove_zkcc_relation_with_observation_test},
    {"prove_bip340_relation_with_observation_test",      lua_prove_bip340_relation_with_observation_test},
    {"prove_rpbsch_relation_with_observation_test",      lua_prove_rpbsch_relation_with_observation_test},
    {"extract_from_gamma_unchecked_test",                lua_extract_from_gamma_unchecked_test},
    {"extract_zkcc_relation_from_gamma_test",            lua_extract_zkcc_relation_from_gamma_test},
    {"extract_bip340_relation_from_gamma_test",          lua_extract_bip340_relation_from_gamma_test},
    {"extract_rpbsch_relation_from_gamma_test",          lua_extract_rpbsch_relation_from_gamma_test},
    {"pbsch_pedersen_h",                                 lua_pbsch_pedersen_h},
    {"pbsch_pedersen_commit",                            lua_pbsch_pedersen_commit},
    {"pbsch_pedersen_verify",                            lua_pbsch_pedersen_verify},
    {"pbsch_pedersen_commit_lf",                         lua_pbsch_pedersen_commit_lf},
    {"pbsch_pedersen_verify_lf",                         lua_pbsch_pedersen_verify_lf},
    {"pbsch_cmt3_prove_seeded",                          lua_pbsch_cmt3_prove_seeded},
    {"pbsch_cmt3_prove_seeded_observed",                 lua_pbsch_cmt3_prove_seeded_observed},
    {"pbsch_cmt3_hash_value",                             lua_pbsch_cmt3_hash_value},
    {"pbsch_cmt3_verify",                                lua_pbsch_cmt3_verify},
    {NULL, NULL}
};

int luaopen_niwi(lua_State *L) {
    luaL_newlib(L, niwi_functions);

    /* Add protocol information */
    lua_pushstring(L, niwi_protocol_version());
    lua_setfield(L, -2, "PROTOCOL_VERSION");

    return 1;
}
