#include <zenroom.h>
#include <zen_error.h>
#include <lua_functions.h>
#include <zen_octet.h>

#include "../lib/pqclean/kyber512/kyber_larkg.h"
#include "../lib/pqclean/kyber512/skem.h"
#include "../lib/pqclean/kyber512/params.h"
#include "../lib/pqclean/kyber512/polyvec.h"
#include "../lib/pqclean/kyber512/verify.h"

#define LARKG_SK_BYTES KYBER_LARKG_SECRETKEYBYTES
#define LARKG_PK_BYTES KYBER_INDCPA_PUBLICKEYBYTES
#define LARKG_CRED_BYTES (sizeof(larkg_cred_t))
/* Only this versioned, parameter-tagged format crosses the Lua boundary. */
#define LARKG_WIRE_MAGIC 0x4cU
#define LARKG_WIRE_VERSION 1U
#define LARKG_WIRE_PARAMETER_KYBER512 1U
#define LARKG_WIRE_HEADER_BYTES 4U
#define LARKG_WIRE_PUBLIC 1U
#define LARKG_WIRE_SECRET 2U
#define LARKG_WIRE_CREDENTIAL 3U
#define LARKG_PUBLIC_BYTES (LARKG_WIRE_HEADER_BYTES + 1U + LARKG_PK_BYTES)
#define LARKG_SECRET_BYTES (LARKG_WIRE_HEADER_BYTES + LARKG_SK_BYTES + KYBER_SYMBYTES)
#define LARKG_CREDENTIAL_BYTES (LARKG_WIRE_HEADER_BYTES + 1U + KYBER_SYMBYTES + LARKG_CRED_BYTES)

static int wire_payload(const octet *wire, uint8_t type, size_t length,
                        const uint8_t **payload) {
    if (!wire || (size_t)wire->len != LARKG_WIRE_HEADER_BYTES + length ||
        (uint8_t)wire->val[0] != LARKG_WIRE_MAGIC ||
        (uint8_t)wire->val[1] != LARKG_WIRE_VERSION ||
        (uint8_t)wire->val[2] != LARKG_WIRE_PARAMETER_KYBER512 ||
        (uint8_t)wire->val[3] != type) return 0;
    *payload = (const uint8_t *)wire->val + LARKG_WIRE_HEADER_BYTES;
    return 1;
}
static void wire_header(octet *wire, uint8_t type) {
    wire->val[0] = LARKG_WIRE_MAGIC; wire->val[1] = LARKG_WIRE_VERSION;
    wire->val[2] = LARKG_WIRE_PARAMETER_KYBER512; wire->val[3] = type;
}
static int canonical_polyvec(const uint8_t bytes[KYBER_POLYVECBYTES]) {
    polyvec poly; uint8_t encoded[KYBER_POLYVECBYTES];
    PQCLEAN_KYBER512_CLEAN_polyvec_frombytes(&poly, bytes);
    PQCLEAN_KYBER512_CLEAN_polyvec_tobytes(encoded, &poly);
    return PQCLEAN_KYBER512_CLEAN_verify(bytes, encoded, sizeof(encoded)) == 0;
}
static int public_from_wire(const octet *wire, const uint8_t **pk, uint8_t *generation) {
    const uint8_t *payload;
    if (!wire_payload(wire, LARKG_WIRE_PUBLIC, 1U + LARKG_PK_BYTES, &payload)) return 0;
    *generation = payload[0]; *pk = payload + 1;
    return canonical_polyvec(*pk);
}
static int secret_from_wire(const octet *wire, const uint8_t **sk,
                            const uint8_t **rho, uint8_t *generation) {
    const uint8_t *payload;
    if (!wire_payload(wire, LARKG_WIRE_SECRET, LARKG_SK_BYTES + KYBER_SYMBYTES, &payload)) return 0;
    *sk = payload; *rho = payload + LARKG_SK_BYTES;
    return PQCLEAN_KYBER512_CLEAN_skem_secret_depth(*sk, generation);
}
static int credential_from_wire(const octet *wire, larkg_cred_t *credential,
                                const uint8_t **rho, uint8_t *generation) {
    const uint8_t *payload;
    if (!wire_payload(wire, LARKG_WIRE_CREDENTIAL,
                      1U + KYBER_SYMBYTES + LARKG_CRED_BYTES, &payload)) return 0;
    *generation = payload[0]; *rho = payload + 1;
    memcpy(credential->B_prime, payload + 1 + KYBER_SYMBYTES, KYBER_POLYVECBYTES);
    memcpy(credential->c, payload + 1 + KYBER_SYMBYTES + KYBER_POLYVECBYTES, KYBER_POLYCOMPRESSEDBYTES);
    memcpy(credential->mu,
           payload + 1 + KYBER_SYMBYTES + KYBER_POLYVECBYTES +
               KYBER_POLYCOMPRESSEDBYTES,
           KYBER_SSBYTES);
    return canonical_polyvec(credential->B_prime);
}
static void context_from_rho(skem_context *ctx, const uint8_t *rho) {
    PQCLEAN_KYBER512_CLEAN_skem_init(ctx, rho);
}

static int larkg_keygen(lua_State *L) {
    BEGIN(); char *failed_msg = NULL; lua_createtable(L, 0, 3);
    zenroom_t *Z = zen_get_context(L); zenroom_t *rng_previous = NULL;
    octet *secret = o_new(L, LARKG_SECRET_BYTES);
    SAFE_GOTO(secret, "Could not allocate LARKG secret key");
    lua_setfield(L, -2, "private");
    octet *public = o_new(L, LARKG_PUBLIC_BYTES);
    SAFE_GOTO(public, "Could not allocate LARKG public key");
    lua_setfield(L, -2, "public");
    octet *rho = o_new(L, KYBER_SYMBYTES);
    SAFE_GOTO(rho, "Could not allocate LARKG rho seed");
    lua_setfield(L, -2, "rho");
    SAFE_GOTO(zen_rng_fill(Z, rho->val, KYBER_SYMBYTES) == 0, "LARKG key generation failed to obtain randomness");
    rho->len = KYBER_SYMBYTES;
    skem_context ctx;
    uint8_t *secret_payload = (uint8_t *)secret->val + LARKG_WIRE_HEADER_BYTES;
    context_from_rho(&ctx, (const uint8_t *)rho->val);
    rng_previous = zen_rng_scope_push(Z);
    int keygen_ret = PQCLEAN_KYBER512_CLEAN_skem_keygen(
        (uint8_t *)public->val + LARKG_WIRE_HEADER_BYTES + 1,
        secret_payload, &ctx);
    zen_rng_scope_pop(rng_previous); rng_previous = NULL;
    SAFE_GOTO(keygen_ret == 0, "LARKG key generation failed");
    wire_header(public, LARKG_WIRE_PUBLIC); public->val[LARKG_WIRE_HEADER_BYTES] = 0; public->len = LARKG_PUBLIC_BYTES;
    wire_header(secret, LARKG_WIRE_SECRET);
    memcpy(secret_payload + LARKG_SK_BYTES, rho->val, KYBER_SYMBYTES);
    secret->len = LARKG_SECRET_BYTES;
end:
    if (rng_previous) zen_rng_scope_pop(rng_previous);
    if (failed_msg) { THROW(failed_msg); } END(1);
}
static int larkg_derive_pk(lua_State *L) {
    BEGIN(); char *failed_msg = NULL; const octet *public = o_arg(L, 1); const octet *rho = o_arg(L, 2);
    zenroom_t *Z = zen_get_context(L); zenroom_t *rng_previous = NULL;
    const uint8_t *pk; uint8_t generation;
    SAFE_GOTO(public && rho, "Could not read LARKG public parameters");
    SAFE_GOTO(public_from_wire(public, &pk, &generation), "Invalid LARKG public key encoding, version, or parameter");
#if LARKG_MAX_SUPPORTED_DEPTH == 0
    (void)generation;
    SAFE_GOTO(0, "LARKG experimental construction does not support derivation");
#else
    SAFE_GOTO(generation < LARKG_MAX_SUPPORTED_DEPTH, "LARKG generation is stale; create a fresh key");
#endif
    SAFE_GOTO(rho->len == KYBER_SYMBYTES, "Invalid LARKG rho seed length");
    SAFE_GOTO(PQCLEAN_KYBER512_CLEAN_verify((const uint8_t *)rho->val,
                                           pk + KYBER_POLYVECBYTES,
                                           KYBER_SYMBYTES) == 0,
              "LARKG rho does not match the public key");
    lua_createtable(L, 0, 2);
    octet *next = o_new(L, LARKG_PUBLIC_BYTES);
    SAFE_GOTO(next, "Could not allocate LARKG next public key");
    lua_setfield(L, -2, "next_public");
    octet *credential = o_new(L, LARKG_CREDENTIAL_BYTES);
    SAFE_GOTO(credential, "Could not allocate LARKG credential");
    lua_setfield(L, -2, "credential");
    skem_context ctx; larkg_cred_t raw; context_from_rho(&ctx, (const uint8_t *)rho->val);
    rng_previous = zen_rng_scope_push(Z);
    int derive_ret = PQCLEAN_KYBER512_CLEAN_larkg_derive_pk(
        (uint8_t *)next->val + LARKG_WIRE_HEADER_BYTES + 1,
        &raw, pk, &ctx);
    zen_rng_scope_pop(rng_previous); rng_previous = NULL;
    SAFE_GOTO(derive_ret == 0, "LARKG derive_pk failed");
    wire_header(next, LARKG_WIRE_PUBLIC);
    next->val[LARKG_WIRE_HEADER_BYTES] = (char)(generation + 1U);
    next->len = LARKG_PUBLIC_BYTES;
    wire_header(credential, LARKG_WIRE_CREDENTIAL);
    uint8_t *out = (uint8_t *)credential->val + LARKG_WIRE_HEADER_BYTES;
    out[0] = generation;
    memcpy(out + 1, rho->val, KYBER_SYMBYTES); memcpy(out + 1 + KYBER_SYMBYTES, raw.B_prime, KYBER_POLYVECBYTES);
    memcpy(out + 1 + KYBER_SYMBYTES + KYBER_POLYVECBYTES, raw.c, KYBER_POLYCOMPRESSEDBYTES);
    memcpy(out + 1 + KYBER_SYMBYTES + KYBER_POLYVECBYTES +
               KYBER_POLYCOMPRESSEDBYTES,
           raw.mu, KYBER_SSBYTES);
    credential->len = LARKG_CREDENTIAL_BYTES;
end:
    if (rng_previous) zen_rng_scope_pop(rng_previous);
    o_free(L, rho); o_free(L, public); if (failed_msg) { THROW(failed_msg); } END(1);
}
static int larkg_derive_sk(lua_State *L) {
    BEGIN(); char *failed_msg = NULL; const octet *secret = o_arg(L, 1); const octet *wire = o_arg(L, 2);
    const uint8_t *sk, *secret_rho, *credential_rho;
    uint8_t secret_generation, credential_generation;
    larkg_cred_t credential;
    SAFE_GOTO(secret && wire, "Could not read LARKG secret key or credential");
    SAFE_GOTO(secret_from_wire(secret, &sk, &secret_rho, &secret_generation),
              "Invalid LARKG secret key encoding, version, parameter, or depth");
    SAFE_GOTO(credential_from_wire(wire, &credential, &credential_rho,
                                   &credential_generation),
              "Invalid LARKG credential encoding, version, or parameter");
    SAFE_GOTO(secret_generation == credential_generation &&
                  PQCLEAN_KYBER512_CLEAN_verify(secret_rho, credential_rho,
                                                KYBER_SYMBYTES) == 0,
              "LARKG credential rejected; derive a fresh public key and credential");
    octet *next = o_new(L, LARKG_SECRET_BYTES); SAFE_GOTO(next, "Could not allocate LARKG next secret key");
    uint8_t *out = (uint8_t *)next->val + LARKG_WIRE_HEADER_BYTES;
    int ret = PQCLEAN_KYBER512_CLEAN_larkg_derive_sk(out, sk, &credential);
    SAFE_GOTO(ret != LARKG_REJECTED, "LARKG credential rejected; derive a fresh public key and credential");
    SAFE_GOTO(ret != LARKG_PARAMETER_MISMATCH, "LARKG generation is stale; create a fresh key");
    SAFE_GOTO(ret == 0, "LARKG authentication failed");
    wire_header(next, LARKG_WIRE_SECRET);
    memcpy(out + LARKG_SK_BYTES, secret_rho, KYBER_SYMBYTES);
    next->len = LARKG_SECRET_BYTES;
end:
    o_free(L, wire); o_free(L, secret); if (failed_msg) { THROW(failed_msg); } END(1);
}
static int larkg_sk_check(lua_State *L) {
    BEGIN(); const octet *wire = o_arg(L, 1);
    SAFE(wire, "Could not read LARKG secret key");
    const uint8_t *sk, *rho; uint8_t generation;
    lua_pushboolean(L, secret_from_wire(wire, &sk, &rho, &generation));
    o_free(L, wire); END(1);
}
static int larkg_pk_check(lua_State *L) {
    BEGIN(); const octet *wire = o_arg(L, 1);
    SAFE(wire, "Could not read LARKG public key");
    const uint8_t *pk; uint8_t generation;
    lua_pushboolean(L, public_from_wire(wire, &pk, &generation));
    o_free(L, wire); END(1);
}
static int larkg_cred_check(lua_State *L) {
    BEGIN(); const octet *wire = o_arg(L, 1);
    SAFE(wire, "Could not read LARKG credential");
    const uint8_t *rho; uint8_t generation; larkg_cred_t credential;
    lua_pushboolean(L, credential_from_wire(wire, &credential, &rho,
                                            &generation));
    o_free(L, wire); END(1);
}
static int larkg_rho_check(lua_State *L) {
    BEGIN(); const octet *rho = o_arg(L, 1);
    SAFE(rho, "Could not read LARKG rho seed");
    lua_pushboolean(L, rho->len == KYBER_SYMBYTES);
    o_free(L, rho); END(1);
}
int luaopen_larkg(lua_State *L) {
    (void)L;
    const struct luaL_Reg functions[] = {
        {"keygen", larkg_keygen}, {"derive_pk", larkg_derive_pk},
        {"derive_sk", larkg_derive_sk}, {"seccheck", larkg_sk_check},
        {"pubcheck", larkg_pk_check}, {"credcheck", larkg_cred_check},
        {"rhocheck", larkg_rho_check}, {NULL, NULL}
    };
    const struct luaL_Reg methods[] = {{NULL, NULL}};
    zen_add_class(L, "larkg", functions, methods);
    return 1;
}
