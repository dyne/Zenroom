/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#ifndef NIWI_RELATIONS_RPBSCH_RELATION_INTERNAL_H
#define NIWI_RELATIONS_RPBSCH_RELATION_INTERNAL_H

#include <stddef.h>
#include <stdint.h>

namespace niwi::rpbsch {

constexpr size_t kStatementSize = 258;
constexpr size_t kScalarSize = 32;
constexpr size_t kCommitmentSize = 33;
constexpr size_t kSignatureSize = 64;
constexpr size_t kBip340PublicSize = 4 * 32;
constexpr size_t kBip340PrivateSize = 2305 * 32;
constexpr size_t kBip340FullPublicSize = 3 * 32;
constexpr size_t kBip340FullPrivateSize = 8001 * 32;
constexpr size_t kBip340ChallengePreimageSize = 160;
constexpr size_t kTupleMessagePreimageSize =
    sizeof("Zenroom/RPBSch/tuple-message/v1") - 1 + 64;
constexpr size_t kStatementPhiPreimageSize =
    sizeof("Zenroom/RPBSch/phi/v1") - 1 + 6 * 32;

constexpr uint32_t kBranchHonest = 1;
constexpr uint32_t kBranchTrapdoor = 2;

struct Statement {
    const uint8_t *X;
    const uint8_t *X_prime;
    const uint8_t *R;
    const uint8_t *c;
    const uint8_t *C;
    const uint8_t *phi;
    const uint8_t *ck;
    const uint8_t *S;
};

struct Witness {
    uint32_t branch;
    const uint8_t *m;
    const uint8_t *alpha;
    const uint8_t *beta;
    const uint8_t *rho_c;
    const uint8_t *rho_s;
    const uint8_t *nu_s;
    const uint8_t *nu_u;
    const uint8_t *nu_u_prime;
    const uint8_t *sigma;
    const uint8_t *sigma0;
    const uint8_t *sigma1;
    uint32_t check_count;
    const uint8_t *check_pub[2];
    const uint8_t *check_priv[2];
    size_t check_pub_len[2];
    size_t check_priv_len[2];
};

bool parse_statement(const uint8_t *public_inputs, size_t pub_len,
                     Statement *st);

bool parse_witness(const uint8_t *private_inputs, size_t priv_len,
                   Witness *w);

bool encode_c_msg(const uint8_t *m, const uint8_t *alpha,
                  const uint8_t *beta, uint8_t out[32]);

void encode_s_msg(const uint8_t *sigma0, const uint8_t *sigma1,
                  const uint8_t *nu_u, const uint8_t *nu_u_prime,
                  const uint8_t *nu_s, uint8_t out[32]);

void tuple_message(const uint8_t *nu_s, const uint8_t *nu_u,
                   uint8_t out[32]);

void build_tuple_message_preimage(const uint8_t *nu_s, const uint8_t *nu_u,
                                  uint8_t out[kTupleMessagePreimageSize]);

void build_statement_phi_preimage(
    const uint8_t *m, const uint8_t *alpha, const uint8_t *beta,
    const uint8_t *nu_s, const uint8_t *nu_u, const uint8_t *nu_u_prime,
    uint8_t out[kStatementPhiPreimageSize]);

void statement_phi(const Witness& w, uint8_t out[32]);

void build_bip340_challenge_preimage(
    const uint8_t sig[64], const uint8_t pk[32],
    const uint8_t msg[32], uint8_t out[kBip340ChallengePreimageSize]);

void compute_bip340_challenge(const uint8_t sig[64], const uint8_t pk[32],
                              const uint8_t msg[32], uint8_t out[32]);

bool expected_bip340_public(const uint8_t sig[64], const uint8_t pk[32],
                            const uint8_t *msg, size_t msg_len,
                            uint8_t out[kBip340PublicSize]);

bool validate_bip340_check(const uint8_t *pub, size_t pub_len,
                           const uint8_t *priv, size_t priv_len,
                           const uint8_t sig[64], const uint8_t pk[32],
                           const uint8_t *msg, size_t msg_len);

bool validate_commitments(const Statement& st, const Witness& w);

bool validate_selected_branch(const Statement& st, const Witness& w);

}  // namespace niwi::rpbsch

#endif /* NIWI_RELATIONS_RPBSCH_RELATION_INTERNAL_H */
