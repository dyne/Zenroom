/* lib/niwi/src/hash.c — Domain-separated SHA-256 hashing.
 *
 * Built on Milagro's HASH256_* primitives, which are available through
 * amcl.h (linked via libamcl_core.a).
 */

#include "hash.h"

#include "amcl.h"

#include <stdlib.h>
#include <string.h>

/* ---- Hash context ---------------------------------------------------- */

struct niwi_hash_ctx {
    hash256 inner;
    int     finalized;
};

niwi_hash_ctx_t *niwi_hash_create(const char domain_tag[4]) {
    niwi_hash_ctx_t *ctx = (niwi_hash_ctx_t *)calloc(1, sizeof(*ctx));
    if (!ctx) return NULL;

    HASH256_init(&ctx->inner);
    ctx->finalized = 0;

    /* Feed the 4-byte domain tag as the first input. */
    int i;
    for (i = 0; i < 4; i++)
        HASH256_process(&ctx->inner, (int)(uint8_t)domain_tag[i]);

    return ctx;
}

void niwi_hash_free(niwi_hash_ctx_t *ctx) {
    if (ctx) free(ctx);
}

void niwi_hash_update(niwi_hash_ctx_t *ctx,
                       const uint8_t *data, size_t len) {
    if (!ctx || ctx->finalized) return;
    for (size_t i = 0; i < len; i++)
        HASH256_process(&ctx->inner, (int)data[i]);
}

void niwi_hash_final(niwi_hash_ctx_t *ctx, uint8_t digest_out[32]) {
    if (!ctx || ctx->finalized) return;
    ctx->finalized = 1;
    HASH256_hash(&ctx->inner, (char *)digest_out);
}

/* ---- One-shot convenience --------------------------------------------- */

void niwi_hash_one_shot(const char domain_tag[4],
                        const uint8_t *data, size_t len,
                        uint8_t digest_out[32]) {
    niwi_hash_ctx_t *ctx = niwi_hash_create(domain_tag);
    if (!ctx) {
        memset(digest_out, 0, 32);
        return;
    }
    niwi_hash_update(ctx, data, len);
    niwi_hash_final(ctx, digest_out);
    niwi_hash_free(ctx);
}

void niwi_hash_two_shot(const char domain_tag[4],
                        const uint8_t *data1, size_t len1,
                        const uint8_t *data2, size_t len2,
                        uint8_t digest_out[32]) {
    niwi_hash_ctx_t *ctx = niwi_hash_create(domain_tag);
    if (!ctx) {
        memset(digest_out, 0, 32);
        return;
    }
    niwi_hash_update(ctx, data1, len1);
    niwi_hash_update(ctx, data2, len2);
    niwi_hash_final(ctx, digest_out);
    niwi_hash_free(ctx);
}
