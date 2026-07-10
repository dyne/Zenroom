/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#ifndef NIWI_CIRCUITS_RPBSCH_HASH_CIRCUIT_H
#define NIWI_CIRCUITS_RPBSCH_HASH_CIRCUIT_H

#include <memory>

#include "circuits/compiler/compiler.h"
#include "circuits/logic/bit_plucker.h"
#include "circuits/logic/compiler_backend.h"
#include "circuits/logic/logic.h"
#include "circuits/sha/flatsha256_circuit.h"
#include "ec/p256k1.h"

namespace niwi::rpbsch {

using RpbschHashField = proofs::Fp256k1Base;

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

}  // namespace niwi::rpbsch

#endif /* NIWI_CIRCUITS_RPBSCH_HASH_CIRCUIT_H */
