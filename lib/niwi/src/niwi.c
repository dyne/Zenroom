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
#include "commitment.h"
#include "hash.h"
#include "npro.h"

#include <stdlib.h>
#include <string.h>

#define NIWI_PROOF_HEADER_SIZE (4 + 4 + 4 + 32 + 32 + NIWI_KLP22_COMMIT_SIZE + NIWI_KLP22_OPENING_SIZE)
#define NIWI_PROOF_PARAM_SIZE (7 * 4)
#define NIWI_PROOF_WITNESS_TAG "WIT0"
#define NIWI_PROOF_WITNESS_DIGEST_SIZE 32

static void write_u32_be(uint8_t *out, uint32_t v) {
    out[0] = (uint8_t)((v >> 24) & 0xff);
    out[1] = (uint8_t)((v >> 16) & 0xff);
    out[2] = (uint8_t)((v >> 8) & 0xff);
    out[3] = (uint8_t)(v & 0xff);
}

static uint32_t read_u32_be(const uint8_t *in) {
    return ((uint32_t)in[0] << 24) |
           ((uint32_t)in[1] << 16) |
           ((uint32_t)in[2] << 8) |
           ((uint32_t)in[3]);
}

struct niwi_ctx {
    /* Placeholder: owned copy of the circuit artifact. */
    uint8_t *artifact;
    size_t   artifact_len;
    char     error[256];
};

niwi_ctx_t *niwi_ctx_create(const uint8_t *circuit_artifact, size_t len) {
    if (!circuit_artifact && len != 0) return NULL;

    niwi_ctx_t *ctx = (niwi_ctx_t *)calloc(1, sizeof(*ctx));
    if (!ctx) return NULL;
    if (len != 0) {
        ctx->artifact = (uint8_t *)malloc(len);
        if (!ctx->artifact) {
            free(ctx);
            return NULL;
        }
        memcpy(ctx->artifact, circuit_artifact, len);
    }
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

static int build_proof(niwi_ctx_t *ctx,
                       const uint8_t *public_inputs, size_t pub_len,
                       const uint8_t *private_inputs, size_t priv_len,
                       uint8_t **proof_out, size_t *proof_len) {
    if (!ctx || !proof_out || !proof_len) return -1;
    if (!public_inputs && pub_len != 0) return -1;
    if (!private_inputs && priv_len != 0) return -1;
    if (priv_len > UINT32_MAX) return -1;

    uint8_t circuit_digest[32];
    uint8_t statement_digest[32];
    uint8_t witness_digest[32];
    uint8_t commitment[NIWI_KLP22_COMMIT_SIZE];
    uint8_t opening[NIWI_KLP22_OPENING_SIZE];

    niwi_hash_one_shot(NIWI_TAG_PROTO, ctx->artifact, ctx->artifact_len,
                       circuit_digest);
    niwi_hash_one_shot(NIWI_TAG_STMT, public_inputs, pub_len,
                       statement_digest);
    niwi_hash_one_shot(NIWI_TAG_LEAF, private_inputs, priv_len,
                       witness_digest);

    uint8_t commit_preimage[64];
    uint8_t commit_message[32];
    memcpy(commit_preimage, statement_digest, 32);
    memcpy(commit_preimage + 32, witness_digest, 32);
    niwi_hash_one_shot(NIWI_TAG_EXTR, commit_preimage, sizeof(commit_preimage),
                       commit_message);
    if (niwi_klp22_commit(commit_message, sizeof(commit_message),
                          commitment, opening) != 0) {
        set_error(ctx, "niwi_prove: failed to commit challenge share");
        return -1;
    }

    size_t len = NIWI_PROOF_HEADER_SIZE + NIWI_PROOF_PARAM_SIZE +
                 4 + 4 + NIWI_PROOF_WITNESS_DIGEST_SIZE;
    uint8_t *proof = (uint8_t *)calloc(1, len);
    if (!proof) {
        set_error(ctx, "niwi_prove: out of memory");
        return -1;
    }

    size_t off = 0;
    memcpy(proof + off, "NIWI", 4); off += 4;
    write_u32_be(proof + off, 0x00010000); off += 4;
    write_u32_be(proof + off, 0); off += 4;
    memcpy(proof + off, circuit_digest, 32); off += 32;
    memcpy(proof + off, statement_digest, 32); off += 32;
    memcpy(proof + off, commitment, NIWI_KLP22_COMMIT_SIZE);
    off += NIWI_KLP22_COMMIT_SIZE;
    memcpy(proof + off, opening, NIWI_KLP22_OPENING_SIZE);
    off += NIWI_KLP22_OPENING_SIZE;

    /* Minimal parameter block accepted by the extractor scaffold. */
    write_u32_be(proof + off, 1); off += 4; /* block */
    write_u32_be(proof + off, 1); off += 4; /* dblock */
    write_u32_be(proof + off, 1); off += 4; /* r */
    write_u32_be(proof + off, 1); off += 4; /* block_enc */
    write_u32_be(proof + off, 4); off += 4; /* nrow */
    write_u32_be(proof + off, 1); off += 4; /* nreq */
    write_u32_be(proof + off, 0); off += 4; /* mc_pathlen */

    memcpy(proof + off, NIWI_PROOF_WITNESS_TAG, 4); off += 4;
    write_u32_be(proof + off, NIWI_PROOF_WITNESS_DIGEST_SIZE); off += 4;
    memcpy(proof + off, witness_digest, NIWI_PROOF_WITNESS_DIGEST_SIZE);
    off += NIWI_PROOF_WITNESS_DIGEST_SIZE;

    *proof_out = proof;
    *proof_len = off;
    ctx->error[0] = '\0';
    return 0;
}

static int verify_proof_envelope(niwi_ctx_t *ctx,
                                 const uint8_t *proof, size_t proof_len,
                                 const uint8_t *public_inputs, size_t pub_len) {
    if (!ctx || !proof || (!public_inputs && pub_len != 0)) return -1;
    if (proof_len < NIWI_PROOF_HEADER_SIZE + NIWI_PROOF_PARAM_SIZE +
                    4 + 4 + NIWI_PROOF_WITNESS_DIGEST_SIZE) {
        set_error(ctx, "niwi_verify: proof too short");
        return -1;
    }

    size_t off = 0;
    if (memcmp(proof + off, "NIWI", 4) != 0) {
        set_error(ctx, "niwi_verify: invalid proof magic");
        return -1;
    }
    off += 4;
    if (read_u32_be(proof + off) != 0x00010000) {
        set_error(ctx, "niwi_verify: unsupported proof version");
        return -1;
    }
    off += 4;
    if (read_u32_be(proof + off) != 0) {
        set_error(ctx, "niwi_verify: unsupported protocol id");
        return -1;
    }
    off += 4;

    uint8_t expected_circuit[32];
    uint8_t expected_statement[32];
    niwi_hash_one_shot(NIWI_TAG_PROTO, ctx->artifact, ctx->artifact_len,
                       expected_circuit);
    niwi_hash_one_shot(NIWI_TAG_STMT, public_inputs, pub_len,
                       expected_statement);

    if (memcmp(proof + off, expected_circuit, 32) != 0) {
        set_error(ctx, "niwi_verify: circuit digest mismatch");
        return -1;
    }
    off += 32;
    if (memcmp(proof + off, expected_statement, 32) != 0) {
        set_error(ctx, "niwi_verify: statement digest mismatch");
        return -1;
    }
    off += 32;

    const uint8_t *commitment = proof + off;
    off += NIWI_KLP22_COMMIT_SIZE;
    const uint8_t *opening = proof + off;
    off += NIWI_KLP22_OPENING_SIZE;

    off += NIWI_PROOF_PARAM_SIZE;
    if (off + 8 + 32 > proof_len || memcmp(proof + off, NIWI_PROOF_WITNESS_TAG, 4) != 0) {
        set_error(ctx, "niwi_verify: missing witness section");
        return -1;
    }
    off += 4;
    uint32_t witness_len = read_u32_be(proof + off); off += 4;
    if (witness_len != NIWI_PROOF_WITNESS_DIGEST_SIZE ||
        off + witness_len != proof_len) {
        set_error(ctx, "niwi_verify: non-canonical witness section length");
        return -1;
    }

    uint8_t commit_preimage[64];
    uint8_t commit_message[32];
    memcpy(commit_preimage, expected_statement, 32);
    memcpy(commit_preimage + 32, proof + off, 32);
    niwi_hash_one_shot(NIWI_TAG_EXTR, commit_preimage, sizeof(commit_preimage),
                       commit_message);
    if (niwi_klp22_verify(commitment, commit_message, sizeof(commit_message),
                          opening) != 0) {
        set_error(ctx, "niwi_verify: invalid KLP22 opening");
        return -1;
    }

    ctx->error[0] = '\0';
    return 0;
}

int niwi_prove(niwi_ctx_t *ctx,
               const uint8_t *public_inputs, size_t pub_len,
               const uint8_t *private_inputs, size_t priv_len,
               uint8_t **proof_out, size_t *proof_len) {
    return build_proof(ctx, public_inputs, pub_len, private_inputs, priv_len,
                       proof_out, proof_len);
}

int niwi_prove_observed(niwi_ctx_t *ctx,
                        const uint8_t *public_inputs, size_t pub_len,
                        const uint8_t *private_inputs, size_t priv_len,
                        uint8_t **proof_out, size_t *proof_len,
                        uint8_t **gamma_out, size_t *gamma_len) {
    if (!gamma_out || !gamma_len) return -1;
    if (build_proof(ctx, public_inputs, pub_len, private_inputs, priv_len,
                    proof_out, proof_len) != 0)
        return -1;

    niwi_npro_t *npro = niwi_npro_create(1);
    if (!npro) {
        niwi_free_buffer(*proof_out);
        *proof_out = NULL;
        *proof_len = 0;
        set_error(ctx, "niwi_prove_observed: failed to create NPRO");
        return -1;
    }
    uint8_t leaf_digest[32];
    if (niwi_npro_query(npro, NIWI_TAG_LEAF, private_inputs, priv_len,
                        leaf_digest) != 0) {
        niwi_npro_free(npro);
        niwi_free_buffer(*proof_out);
        *proof_out = NULL;
        *proof_len = 0;
        set_error(ctx, "niwi_prove_observed: failed to record witness leaf");
        return -1;
    }
    niwi_npro_set_cutoff(npro);
    size_t gs = niwi_npro_gamma_size(npro);
    uint8_t *gamma = (uint8_t *)malloc(gs);
    if (!gamma || niwi_npro_serialize_gamma(npro, gamma, gs) != gs) {
        free(gamma);
        niwi_npro_free(npro);
        niwi_free_buffer(*proof_out);
        *proof_out = NULL;
        *proof_len = 0;
        set_error(ctx, "niwi_prove_observed: failed to serialize Gamma");
        return -1;
    }
    niwi_npro_free(npro);
    *gamma_out = gamma;
    *gamma_len = gs;
    ctx->error[0] = '\0';
    return 0;
}

int niwi_verify(niwi_ctx_t *ctx,
                const uint8_t *proof, size_t proof_len,
                const uint8_t *public_inputs, size_t pub_len) {
    return verify_proof_envelope(ctx, proof, proof_len, public_inputs, pub_len);
}

int niwi_extract(niwi_ctx_t *ctx,
                 const uint8_t *proof, size_t proof_len,
                 const uint8_t *gamma, size_t gamma_len,
                 const uint8_t *public_inputs, size_t pub_len,
                 uint8_t **witness_out, size_t *witness_len) {
    if (!ctx || !gamma || !witness_out || !witness_len) return -1;
    if (verify_proof_envelope(ctx, proof, proof_len, public_inputs, pub_len) != 0)
        return -1;
    if (gamma_len == 0) {
        set_error(ctx, "niwi_extract: missing Gamma");
        return -1;
    }

    size_t off = NIWI_PROOF_HEADER_SIZE + NIWI_PROOF_PARAM_SIZE;
    off += 4;
    uint32_t wl = read_u32_be(proof + off); off += 4;
    if (wl != NIWI_PROOF_WITNESS_DIGEST_SIZE || off + wl != proof_len) {
        set_error(ctx, "niwi_extract: invalid witness section");
        return -1;
    }
    niwi_npro_t *npro = niwi_npro_deserialize_gamma(gamma, gamma_len);
    if (!npro) {
        set_error(ctx, "niwi_extract: failed to parse Gamma");
        return -1;
    }

    size_t recovered_len = 0;
    if (!niwi_npro_lookup(npro, NIWI_TAG_LEAF, proof + off,
                          NULL, &recovered_len)) {
        niwi_npro_free(npro);
        set_error(ctx, "niwi_extract: missing witness query in Gamma");
        return -1;
    }

    uint8_t *out = (uint8_t *)malloc(recovered_len ? recovered_len : 1);
    if (!out) {
        niwi_npro_free(npro);
        set_error(ctx, "niwi_extract: out of memory");
        return -1;
    }
    size_t out_cap = recovered_len;
    if (!niwi_npro_lookup(npro, NIWI_TAG_LEAF, proof + off,
                          out, &out_cap) || out_cap != recovered_len) {
        free(out);
        niwi_npro_free(npro);
        set_error(ctx, "niwi_extract: failed to copy witness query");
        return -1;
    }
    niwi_npro_free(npro);
    *witness_out = out;
    *witness_len = recovered_len;
    ctx->error[0] = '\0';
    return 0;
}

void niwi_free_buffer(uint8_t *buf) {
    free(buf);
}
