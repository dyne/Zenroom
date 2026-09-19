/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#ifndef NIWI_CIRCUITS_RPBSCH_HASH_CIRCUIT_H
#define NIWI_CIRCUITS_RPBSCH_HASH_CIRCUIT_H

#include <memory>
#include <string.h>

#include "circuits/bip340/bip340_gadgets.h"
#include "circuits/bip340/bip340_verify.h"
#include "circuits/compiler/compiler.h"
#include "circuits/logic/bit_plucker.h"
#include "circuits/logic/compiler_backend.h"
#include "circuits/logic/logic.h"
#include "circuits/sha/flatsha256_circuit.h"
#include "ec/p256k1.h"

namespace niwi::rpbsch {

using RpbschHashField = proofs::Fp256k1Base;

/* RPBSch LZK v1 circuit contract.
 *
 * Public statement bytes are exactly:
 *   X || X_prime || R || c || C || phi || ck || S
 * with field sizes:
 *   32 || 32      || 32 || 32 || 33 || 32  || 32 || 33.
 *
 * Private witness bytes must follow the native RPBSch relation profile:
 *   selector,
 *   m, alpha, beta, rho_c, rho_s, nu_s, nu_u, nu_u_prime,
 *   sigma, sigma0, sigma1,
 *   C/S hash witnesses,
 *   C/S Pedersen opening witnesses,
 *   fixed-size full BIP340 branch-check witnesses.
 *
 * This v1 profile uses fixed 32-byte messages and the current binding
 * Pedersen Cmt profile. It is the circuit contract for the checked RPBSch
 * LZK0 body, not a paper-exact RPBSch claim by itself.
 */
namespace detail {

template <size_t MaxBlocks>
inline std::unique_ptr<proofs::Circuit<RpbschHashField>>
build_sha256_digest_circuit(void) {
    using Field = RpbschHashField;
    using Backend = proofs::CompilerBackend<Field>;
    using Logic = proofs::Logic<Field, Backend>;
    using BitPlucker = proofs::BitPlucker<Logic, 4>;
    using FlatSha = proofs::FlatSHA256Circuit<Logic, BitPlucker>;

    proofs::QuadCircuit<Field> q(proofs::p256k1_base);
    const Backend backend(&q);
    const Logic logic(&backend, proofs::p256k1_base);
    const FlatSha sha(logic);

    typename Logic::v256 target = logic.template vinput<256>();
    q.private_input();

    typename Logic::v8 preimage[MaxBlocks * 64];
    for (size_t i = 0; i < MaxBlocks * 64; ++i) {
        preimage[i] = logic.template vinput<8>();
    }

    typename FlatSha::BlockWitness bw[MaxBlocks];
    for (size_t i = 0; i < MaxBlocks; ++i) {
        bw[i].input(logic);
    }

    typename Logic::v8 blocks;
    logic.bits(8, blocks.data(), MaxBlocks);
    sha.assert_message_hash(MaxBlocks, blocks, preimage, target, bw);
    return q.mkcircuit(1);
}

inline void bip340_tag_hash(uint8_t out[32]) {
    static const char tag[] = "BIP0340/challenge";
    proofs::SHA256 sha;
    sha.Update(reinterpret_cast<const uint8_t *>(tag), strlen(tag));
    sha.DigestData(out);
}

}  // namespace detail

/** Build the SHA-256 relation for an RPBSch tuple-message preimage. */
inline std::unique_ptr<proofs::Circuit<RpbschHashField>>
build_tuple_message_sha_circuit(void) {
    return detail::build_sha256_digest_circuit<2>();
}

/** Build the SHA-256 relation for an RPBSch C commitment message preimage. */
inline std::unique_ptr<proofs::Circuit<RpbschHashField>>
build_c_message_sha_circuit(void) {
    return detail::build_sha256_digest_circuit<2>();
}

/** Build the SHA-256 relation for an RPBSch S commitment message preimage. */
inline std::unique_ptr<proofs::Circuit<RpbschHashField>>
build_s_message_sha_circuit(void) {
    return detail::build_sha256_digest_circuit<4>();
}

/** Build the SHA-256 relation for an RPBSch statement phi preimage. */
inline std::unique_ptr<proofs::Circuit<RpbschHashField>>
build_statement_phi_sha_circuit(void) {
    return detail::build_sha256_digest_circuit<4>();
}

/**
 * Build the fixed-message BIP340 branch-check relation used by RPBSch.
 *
 * Public inputs are one, R.x, and P.x. Private inputs then provide the
 * challenge scalar, SHA-256 challenge digest/preimage witness, and the
 * Longfellow BIP340 verification witness.
 */
inline std::unique_ptr<proofs::Circuit<RpbschHashField>>
build_bip340_full_challenge_circuit(void) {
    using Field = RpbschHashField;
    using Backend = proofs::CompilerBackend<Field>;
    using Logic = proofs::Logic<Field, Backend>;
    using BitPlucker = proofs::BitPlucker<Logic, 4>;
    using FlatSha = proofs::FlatSHA256Circuit<Logic, BitPlucker>;
    using Bip340Gadgets = proofs::Bip340Gadgets<Logic, Field, proofs::P256k1>;
    using Bip340Verify = proofs::Bip340Verify<Logic, Field, proofs::P256k1>;
    constexpr size_t kBlocks = 3;
    constexpr size_t kPaddedBytes = kBlocks * 64;

    proofs::QuadCircuit<Field> q(proofs::p256k1_base);
    const Backend backend(&q);
    const Logic logic(&backend, proofs::p256k1_base);
    const FlatSha sha(logic);
    const Bip340Gadgets gadgets(logic, proofs::p256k1);
    const Bip340Verify verifier(logic, proofs::p256k1);

    auto rx = logic.eltw_input();
    auto px = logic.eltw_input();
    q.private_input();

    auto e = logic.eltw_input();
    typename Logic::v256 digest = logic.template vinput<256>();
    typename Logic::v8 preimage[kPaddedBytes];
    uint8_t tag_hash[32];
    detail::bip340_tag_hash(tag_hash);
    for (size_t i = 0; i < 32; ++i) {
        preimage[i] = logic.template vbit<8>(tag_hash[i]);
        preimage[32 + i] = logic.template vbit<8>(tag_hash[i]);
    }
    for (size_t i = 64; i < kPaddedBytes; ++i) {
        preimage[i] = logic.template vinput<8>();
    }
    typename FlatSha::BlockWitness sha_blocks[kBlocks];
    for (size_t i = 0; i < kBlocks; ++i) {
        sha_blocks[i].input(logic);
    }
    typename Bip340Verify::Witness witness;
    witness.input(logic);

    typename Logic::v256 rx_bits;
    typename Logic::v256 px_bits;
    for (size_t i = 0; i < proofs::P256k1::kBits; ++i) {
        rx_bits[i] = preimage[64 + 31 - i / 8][i % 8];
        px_bits[i] = preimage[96 + 31 - i / 8][i % 8];
    }
    gadgets.assert_field_from_bits_lsb(rx_bits, rx);
    gadgets.assert_field_from_bits_lsb(px_bits, px);

    typename Logic::v8 blocks;
    logic.bits(8, blocks.data(), kBlocks);
    sha.assert_message_hash(kBlocks, blocks, preimage, digest, sha_blocks);
    gadgets.assert_challenge_scalar_from_digest(digest, e);
    verifier.assert_verify(rx, px, e, witness);
    return q.mkcircuit(1);
}

}  // namespace niwi::rpbsch

#endif /* NIWI_CIRCUITS_RPBSCH_HASH_CIRCUIT_H */
