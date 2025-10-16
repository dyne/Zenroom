// Copyright 2025 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_MAC_MAC_CIRCUIT_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_MAC_MAC_CIRCUIT_H_

// Implements a message authentication code in GF 2^k for a 256-bit message.
// The mac key is additively sampled by both the prover and verifier to ensure
// soundness and zk.
//
// The mac is defined as (a_pi+a_v)*x_i = mac_i where (x_1,x_2) are 128-bit
// portions of the hidden message. The verifier need only contribute one
// a_v for all MACs verified in the circuit. The prover needs to commit to
// separate a_p{i} for each portion of each message.
//
// The property that we need from this primitive is as follows:
// Assume the prover has committed to a_pi and x, i.e., fix a_pi, x.
// The probability over the verifier's random a_v that mac(x) = mac_(y)
// if x != y is at most 2^{-128}.

#include <algorithm>
#include <cstddef>

#include "circuits/compiler/compiler.h"
#include "circuits/logic/logic.h"
#include "gf2k/gf2_128.h"

namespace proofs {

static constexpr size_t kMACPluckerBits = 2u;

// MAC: implements a MAC in GF 2^k for a 256-bit message by simulating
// the arithmetic of the GF 2^k field. This implementation commits both
// the prover's a_p key as well as the bits of the message. This allows
// the MAC computation and the equality of the purported message to be verified
// in parallel to reduce depth.
// As an optimization, the MAC computed here is a.x instead of a.x + b. This
// MAC is unforgeable with vhp and hiding whenever x is non-zero. The caller
// must ensure that the MACed values are non-zero with very high probability.
// For example, in the case of the MAC of a hash of a randomly selected message,
// the probability of the hash being zero is quite small. This case applies for
// signatures of messages related to credentials. As another example, the
// device public key is an honestly-generated ECDSA key, and thus is unlikely
// to be zero for most curves. These cases add a small error to the
// zero-knowledge analysis of the scheme.
template <class Logic, class BitPlucker>
class MAC {
 public:
  using Field = typename Logic::Field;
  using Elt = typename Field::Elt;
  using EltW = typename Logic::EltW;
  using Nat = typename Field::N;
  using v8 = typename Logic::v8;
  using v128 = typename Logic::v128;
  using v256 = typename Logic::v256;
  using packed_v128 = typename BitPlucker::packed_v128;
  using packed_v256 = typename BitPlucker::packed_v256;

  BitPlucker bp_;

  class Witness {
   public:
    packed_v128 aa_[2];
    packed_v256 xx_;  // The value to be checked

    template <typename T>
    static T packed_input(QuadCircuit<typename Logic::Field>& Q) {
      T r;
      for (size_t i = 0; i < r.size(); ++i) {
        r[i] = Q.input();
      }
      return r;
    }

    void input(const Logic& LC, QuadCircuit<typename Logic::Field>& Q) {
      aa_[0] = packed_input<packed_v128>(Q);
      aa_[1] = packed_input<packed_v128>(Q);
      xx_ = packed_input<packed_v256>(Q);
    }
  };

  explicit MAC(const Logic& lc) : bp_(lc), lc_(lc) {}

  // Verifies a mac on the Field element value against the key (a_p + a_v).
  // This method can only be called when the field is at least 256 bits, e.g.,
  // with F_p256. In other cases, the caller should use a verify_mac method
  // that takes the message in bit-wise form. Additionally, the order parameter
  // is used to ensure that the message does not overflow the field.
  void verify_mac(EltW msg, const v128 mac[/*2*/], const v128& av,
                     const Witness& vw, Nat order) const {
    check(Field::kBits >= 256, "Field::kBits < 256");
    v128 msg2[2];
    unpack_msg(msg2, msg, order, vw);
    assert_mac(mac, av, msg2, vw);
  }

 private:
  // Checks mac[i] = (a_p + a_v)*xi[i] for i=0..1.
  void assert_mac(const v128 mac[/*2*/], const v128& av, const v128 xi[/*2*/],
                  const Witness& vw) const {
    v128 mv;
    for (size_t i = 0; i < 2; ++i) {
      v128 ap = bp_.template unpack<v128, packed_v128>(vw.aa_[i]);
      v128 key = lc_.vxor(&av, ap);
      lc_.gf2_128_mul(mv, key, xi[i]);
      lc_.vassert_eq(&mac[i], mv);
    }
  }

  void unpack_msg(v128 msg[/*2*/], EltW msgw, Nat order,
                  const Witness& vw) const {
    v256 x = bp_.template unpack<v256, packed_v256>(vw.xx_);
    std::copy(x.begin(), x.begin() + 128, msg[0].begin());
    std::copy(x.begin() + 128, x.end(), msg[1].begin());

    // Ensure that the incoming message does not overflow the field.
    v256 bits_n;
    for (size_t i = 0; i < 256; ++i) {
      bits_n[i] = lc_.bit(order.bit(i));
    }
    lc_.assert1(lc_.vlt(&x, bits_n));

    // Verify that the message bits in the witness correspond to msg.
    EltW te = lc_.konst(lc_.zero());
    Elt twok = lc_.one();
    for (size_t i = 0; i < 256; ++i) {
      te = lc_.axpy(&te, twok, lc_.eval(x[i]));
      lc_.f_.add(twok, twok);
    }
    lc_.assert_eq(&te, msgw);
  }

  const Logic& lc_;
};

// Same MAC computation for native GF2_128 field.
template <class Backend, class BitPlucker>
class MACGF2 {
 public:
  using Elt = typename Logic<GF2_128<>, Backend>::Elt;
  using EltW = typename Logic<GF2_128<>, Backend>::EltW;
  using BitW = typename Logic<GF2_128<>, Backend>::BitW;

  // In this specialization, 128 bits are stored in a native EltW.
  using v128 = EltW;

  // Message input types v8, v256 are still encoded bit-wise.
  using v8 = typename Logic<GF2_128<>, Backend>::v8;
  using v256 = typename Logic<GF2_128<>, Backend>::v256;

  explicit MACGF2(const Logic<GF2_128<>, Backend>& lc)
      : lc_(lc) {}
  class Witness {
   public:
    EltW aa_[2];

    void input(const Logic<GF2_128<>, Backend>& lc,
               QuadCircuit<GF2_128<>>& Q) {
      aa_[0] = Q.input();
      aa_[1] = Q.input();
    }
  };

  // Verify a mac on the 256-bit message msg.
  void verify_mac(const EltW mac[/*2*/], const EltW& av, const v256& msg,
                  const Witness& vw) const {
    // Check that mac[i] = (a_p + a_v)*mm[i] for i=0..1.
    for (size_t i = 0; i < 2; ++i) {
      EltW mm = pack(&msg[i * 128]);
      EltW key = lc_.add(&av, vw.aa_[i]);
      EltW got = lc_.mul(&key, mm);
      lc_.assert_eq(&mac[i], got);
    }
  }

 private:
  // Pack a 128-bit message into a GF(2^128) field element.
  EltW pack(const BitW msg[/*128*/]) const {
    Elt alpha = lc_.f_.x();
    Elt xi = lc_.f_.one();
    EltW m = lc_.konst(0);
    for (size_t i = 0; i < 128; ++i) {
      m = lc_.axpy(&m, xi, lc_.eval(msg[i]));
      xi = lc_.mulf(xi, alpha);
    }
    return m;
  }

  const Logic<GF2_128<>, Backend>& lc_;
};

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_MAC_MAC_CIRCUIT_H_
