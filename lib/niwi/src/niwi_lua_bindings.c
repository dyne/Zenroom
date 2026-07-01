/* lib/niwi/src/niwi_lua_bindings.c
 *
 * Lua bindings for lib/niwi using the plain Lua C API (no sol++).
 * Follows the pattern in lib/zk-circuit-lang/witness_bindings.cc.
 *
 * Production bindings:
 *   zkcore.prove_circuit_niwi(table opts)  → OCTET proof
 *   zkcore.verify_circuit_niwi(table opts) → boolean
 *   zkcore.niwi_profile()                  → table { version, protocol_id }
 *
 * Test-only bindings:
 *   zkcore.prove_with_observation_test(table opts) → OCTET proof, OCTET gamma
 *   zkcore.extract_from_gamma_test(table opts)     → OCTET witness
 */

#include "niwi.h"
#include "encoding.h"
#include "hash.h"
#include "npro.h"
#include "extract.h"
#include "commitment.h"

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <string.h>
#include <stdlib.h>

/* ---- OCTET helpers (from Zenroom's octet.h) -------------------------- */

/* These are the Zenroom OCTET API functions used by witness_bindings.
 * They are declared in octet_conversions.h. */
struct octet;
extern const char *o_val(const struct octet*);
extern size_t      o_len(const struct octet*);
extern struct octet* o_new(lua_State*, int);
extern const struct octet* o_arg(lua_State*, int);
extern struct octet* o_push(lua_State*, const char*, size_t);
extern void        o_free(lua_State*, const struct octet*);
extern void        lerror(lua_State*, const char*, ...);

/* ---- Helper: get an OCTET from a table field ------------------------- */

static const struct octet *table_get_octet(lua_State *L, int table_idx,
                                            const char *key) {
    /* Stack: ... table ... */
    lua_getfield(L, table_idx, key);
    const struct octet *o = o_arg(L, -1);
    lua_pop(L, 1);
    return o;
}

/* Helper: get an integer from a table field */
static int table_get_int(lua_State *L, int table_idx, const char *key,
                          int *val) {
    lua_getfield(L, table_idx, key);
    if (!lua_isnumber(L, -1)) {
        lua_pop(L, 1);
        return 0;
    }
    *val = (int)lua_tointeger(L, -1);
    lua_pop(L, 1);
    return 1;
}

/* ---- prove_circuit_niwi ---------------------------------------------- */

/*
 * Usage: proof = zkcore.prove_circuit_niwi({
 *     circuit = <circuit artifact>,
 *     inputs = <witness inputs>,
 *     seed = <optional OCTET seed>
 * })
 *
 * Returns: OCTET containing the NiwiProof.
 */
static int lua_prove_circuit_niwi(lua_State *L) {
    if (!lua_istable(L, 1)) {
        lerror(L, "prove_circuit_niwi: expected table argument");
        return 0;
    }

    /* Extract circuit artifact. */
    const struct octet *circuit_oct = table_get_octet(L, 1, "circuit");
    if (!circuit_oct) {
        lerror(L, "prove_circuit_niwi: missing 'circuit' field");
        return 0;
    }

    /* Extract inputs. */
    const struct octet *inputs_oct = table_get_octet(L, 1, "inputs");
    if (!inputs_oct) {
        lerror(L, "prove_circuit_niwi: missing 'inputs' field");
        return 0;
    }

    /* Extract optional seed. */
    const struct octet *seed_oct = table_get_octet(L, 1, "seed");

    /* Create NIWI context. */
    niwi_ctx_t *ctx = niwi_ctx_create(
        (const uint8_t *)o_val(circuit_oct), o_len(circuit_oct));
    if (!ctx) {
        lerror(L, "prove_circuit_niwi: failed to create context");
        return 0;
    }

    /* Prove. */
    uint8_t *proof_out = NULL;
    size_t proof_len = 0;

    /* For now, pass inputs as both public and private.
     * TODO: separate public/private from the inputs table. */
    int rc = niwi_prove(ctx,
                         (const uint8_t *)o_val(inputs_oct), o_len(inputs_oct),
                         (const uint8_t *)o_val(inputs_oct), o_len(inputs_oct),
                         &proof_out, &proof_len);

    const char *err = niwi_last_error(ctx);

    if (rc != 0) {
        if (err)
            lerror(L, "prove_circuit_niwi: %s", err);
        else
            lerror(L, "prove_circuit_niwi: unknown error");
        niwi_ctx_free(ctx);
        return 0;
    }

    /* Return proof as OCTET. */
    struct octet *out = o_push(L, (const char *)proof_out, proof_len);
    niwi_free_buffer(proof_out);
    niwi_ctx_free(ctx);

    /* The octet is on the stack; return it. */
    return 1;
}

/* ---- verify_circuit_niwi --------------------------------------------- */

/*
 * Usage: ok = zkcore.verify_circuit_niwi({
 *     circuit = <circuit artifact>,
 *     proof = <OCTET NiwiProof>,
 *     public_inputs = <OCTET public inputs>
 * })
 *
 * Returns: boolean.
 */
static int lua_verify_circuit_niwi(lua_State *L) {
    if (!lua_istable(L, 1)) {
        lerror(L, "verify_circuit_niwi: expected table argument");
        return 0;
    }

    const struct octet *circuit_oct = table_get_octet(L, 1, "circuit");
    const struct octet *proof_oct    = table_get_octet(L, 1, "proof");
    const struct octet *pub_oct      = table_get_octet(L, 1, "public_inputs");

    if (!circuit_oct) {
        lerror(L, "verify_circuit_niwi: missing 'circuit' field");
        return 0;
    }
    if (!proof_oct) {
        lerror(L, "verify_circuit_niwi: missing 'proof' field");
        return 0;
    }
    if (!pub_oct) {
        lerror(L, "verify_circuit_niwi: missing 'public_inputs' field");
        return 0;
    }

    niwi_ctx_t *ctx = niwi_ctx_create(
        (const uint8_t *)o_val(circuit_oct), o_len(circuit_oct));
    if (!ctx) {
        lerror(L, "verify_circuit_niwi: failed to create context");
        return 0;
    }

    int rc = niwi_verify(ctx,
                          (const uint8_t *)o_val(proof_oct), o_len(proof_oct),
                          (const uint8_t *)o_val(pub_oct), o_len(pub_oct));

    niwi_ctx_free(ctx);

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

/* ---- prove_with_observation_test (test-only) ------------------------- */

/*
 * Usage: proof, gamma = zkcore.prove_with_observation_test({
 *     circuit = <circuit artifact>,
 *     inputs = <witness inputs>
 * })
 *
 * Returns: two OCTETs (proof, gamma).
 */
static int lua_prove_with_observation_test(lua_State *L) {
    if (!lua_istable(L, 1)) {
        lerror(L, "prove_with_observation_test: expected table argument");
        return 0;
    }

    const struct octet *circuit_oct = table_get_octet(L, 1, "circuit");
    const struct octet *inputs_oct  = table_get_octet(L, 1, "inputs");

    if (!circuit_oct || !inputs_oct) {
        lerror(L, "prove_with_observation_test: missing required fields");
        return 0;
    }

    niwi_ctx_t *ctx = niwi_ctx_create(
        (const uint8_t *)o_val(circuit_oct), o_len(circuit_oct));
    if (!ctx) {
        lerror(L, "prove_with_observation_test: failed to create context");
        return 0;
    }

    uint8_t *proof_out = NULL, *gamma_out = NULL;
    size_t proof_len = 0, gamma_len = 0;

    int rc = niwi_prove_observed(ctx,
                                  (const uint8_t *)o_val(inputs_oct), o_len(inputs_oct),
                                  (const uint8_t *)o_val(inputs_oct), o_len(inputs_oct),
                                  &proof_out, &proof_len,
                                  &gamma_out, &gamma_len);

    if (rc != 0) {
        const char *err = niwi_last_error(ctx);
        lerror(L, "prove_with_observation_test: %s",
               err ? err : "unknown error");
        niwi_ctx_free(ctx);
        return 0;
    }

    /* Return proof and gamma as two OCTETs. */
    struct octet *p = o_push(L, (const char *)proof_out, proof_len);
    struct octet *g = o_push(L, (const char *)gamma_out, gamma_len);

    niwi_free_buffer(proof_out);
    niwi_free_buffer(gamma_out);
    niwi_ctx_free(ctx);

    return 2;
}

/* ---- extract_from_gamma_test (test-only) ----------------------------- */

/*
 * Usage: witness = zkcore.extract_from_gamma_test({
 *     proof = <OCTET NiwiProof>,
 *     gamma = <OCTET Gamma log>,
 *     public_inputs = <OCTET public inputs>
 * })
 *
 * Returns: OCTET witness.
 */
static int lua_extract_from_gamma_test(lua_State *L) {
    if (!lua_istable(L, 1)) {
        lerror(L, "extract_from_gamma_test: expected table argument");
        return 0;
    }

    const struct octet *proof_oct = table_get_octet(L, 1, "proof");
    const struct octet *gamma_oct = table_get_octet(L, 1, "gamma");
    const struct octet *pub_oct   = table_get_octet(L, 1, "public_inputs");

    if (!proof_oct || !gamma_oct || !pub_oct) {
        lerror(L, "extract_from_gamma_test: missing required fields");
        return 0;
    }

    niwi_extract_t *ex = niwi_extract_create(
        (const uint8_t *)o_val(proof_oct), o_len(proof_oct),
        (const uint8_t *)o_val(gamma_oct), o_len(gamma_oct),
        (const uint8_t *)o_val(pub_oct), o_len(pub_oct));

    if (!ex) {
        lerror(L, "extract_from_gamma_test: failed to create extractor");
        return 0;
    }

    const char *err = niwi_extract_error(ex);
    if (err) {
        lerror(L, "extract_from_gamma_test: %s", err);
        niwi_extract_free(ex);
        return 0;
    }

    uint8_t witness_buf[65536];
    size_t wlen = sizeof(witness_buf);
    int rc = niwi_extract_witness(ex, witness_buf, &wlen);

    niwi_extract_free(ex);

    if (rc != NIWI_EXTRACT_OK) {
        lerror(L, "extract_from_gamma_test: extraction failed");
        return 0;
    }

    struct octet *out = o_push(L, (const char *)witness_buf, wlen);
    return 1;
}

/* ---- Module registration --------------------------------------------- */

static const luaL_Reg niwi_functions[] = {
    {"prove_circuit_niwi",          lua_prove_circuit_niwi},
    {"verify_circuit_niwi",         lua_verify_circuit_niwi},
    {"niwi_profile",                lua_niwi_profile},
    {"prove_with_observation_test", lua_prove_with_observation_test},
    {"extract_from_gamma_test",     lua_extract_from_gamma_test},
    {NULL, NULL}
};

int luaopen_niwi(lua_State *L) {
    luaL_newlib(L, niwi_functions);

    /* Add protocol information */
    lua_pushstring(L, niwi_protocol_version());
    lua_setfield(L, -2, "PROTOCOL_VERSION");

    return 1;
}
