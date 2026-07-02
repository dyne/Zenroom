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

#include <stdlib.h>
#include <string.h>

struct niwi_ctx {
    /* Placeholder: owned copy of the circuit artifact. */
    uint8_t *artifact;
    size_t   artifact_len;
    char     error[256];
};

niwi_ctx_t *niwi_ctx_create(const uint8_t *circuit_artifact, size_t len) {
    niwi_ctx_t *ctx = (niwi_ctx_t *)calloc(1, sizeof(*ctx));
    if (!ctx) return NULL;
    ctx->artifact = (uint8_t *)malloc(len);
    if (!ctx->artifact) {
        free(ctx);
        return NULL;
    }
    memcpy(ctx->artifact, circuit_artifact, len);
    ctx->artifact_len = len;
    ctx->error[0] = '\0';
    return ctx;
}

void niwi_ctx_free(niwi_ctx_t *ctx) {
    if (!ctx) return;
    free(ctx->artifact);
    free(ctx);
}

static void set_error(niwi_ctx_t *ctx, const char *msg) {
    if (ctx && msg) {
        strncpy(ctx->error, msg, sizeof(ctx->error) - 1);
        ctx->error[sizeof(ctx->error) - 1] = '\0';
    }
}

const char *niwi_last_error(niwi_ctx_t *ctx) {
    if (!ctx) return "null context";
    return ctx->error[0] ? ctx->error : NULL;
}

const char *niwi_protocol_version(void) {
    return "niwi-v1";
}

/* ---- Stubs ---------------------------------------------------------- */

int niwi_prove(niwi_ctx_t *ctx,
               const uint8_t *public_inputs, size_t pub_len,
               const uint8_t *private_inputs, size_t priv_len,
               uint8_t **proof_out, size_t *proof_len) {
    (void)public_inputs;
    (void)pub_len;
    (void)private_inputs;
    (void)priv_len;
    (void)proof_out;
    (void)proof_len;
    set_error(ctx, "niwi_prove: not yet implemented");
    return -1;
}

int niwi_prove_observed(niwi_ctx_t *ctx,
                        const uint8_t *public_inputs, size_t pub_len,
                        const uint8_t *private_inputs, size_t priv_len,
                        uint8_t **proof_out, size_t *proof_len,
                        uint8_t **gamma_out, size_t *gamma_len) {
    (void)public_inputs;
    (void)pub_len;
    (void)private_inputs;
    (void)priv_len;
    (void)proof_out;
    (void)proof_len;
    (void)gamma_out;
    (void)gamma_len;
    set_error(ctx, "niwi_prove_observed: not yet implemented");
    return -1;
}

int niwi_verify(niwi_ctx_t *ctx,
                const uint8_t *proof, size_t proof_len,
                const uint8_t *public_inputs, size_t pub_len) {
    (void)proof;
    (void)proof_len;
    (void)public_inputs;
    (void)pub_len;
    set_error(ctx, "niwi_verify: not yet implemented");
    return -1;
}

int niwi_extract(niwi_ctx_t *ctx,
                 const uint8_t *proof, size_t proof_len,
                 const uint8_t *gamma, size_t gamma_len,
                 const uint8_t *public_inputs, size_t pub_len,
                 uint8_t **witness_out, size_t *witness_len) {
    (void)proof;
    (void)proof_len;
    (void)gamma;
    (void)gamma_len;
    (void)public_inputs;
    (void)pub_len;
    (void)witness_out;
    (void)witness_len;
    set_error(ctx, "niwi_extract: not yet implemented");
    return -1;
}

void niwi_free_buffer(uint8_t *buf) {
    free(buf);
}
