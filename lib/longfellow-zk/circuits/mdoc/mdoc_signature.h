// Copyright 2024 Google LLC.
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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_MDOC_MDOC_SIGNATURE_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_MDOC_MDOC_SIGNATURE_H_

#include <cstddef>

#include "circuits/compiler/compiler.h"
#include "circuits/ecdsa/verify_circuit.h"
#include "circuits/logic/bit_plucker.h"
#include "circuits/mac/mac_circuit.h"

namespace proofs {

// This class creates a circuit to verify the signatures in an MDOC.
// There are 2 signatures:
//    1. A signature on the MSO by the issuer of the MDOC: The public
//       key of the issuer is given as input for now. Later, it can be
//       one among a list of issuers.  While the signer is public, the
//       message is private, and thus its hash is committed in the witness.
//    2. A signature on the transcript provided during a "Show" operation:
//       the signature is under a device public key that is specified in the
//       MSO.  Thus, the signing key is private (and committed), but the
//       message is public.
template <class LogicCircuit, class Field, class EC>
class MdocSignature {
  using EltW = typename LogicCircuit::EltW;
  using Elt = typename LogicCircuit::Elt;
  using Nat = typename Field::N;
  using v128 = typename LogicCircuit::v128;
  using v256 = typename LogicCircuit::v256;
  using Ecdsa = VerifyCircuit<LogicCircuit, Field, EC>;
  using EcdsaWitness = typename Ecdsa::Witness;
  using MacBitPlucker = BitPlucker<LogicCircuit, kMACPluckerBits>;
  using packed_v256 = typename MacBitPlucker::packed_v256;
  using mac = MAC<LogicCircuit, MacBitPlucker>;
  using MACWitness = typename mac::Witness;

  const LogicCircuit& lc_;
  const EC& ec_;
  const Nat& order_;

 public:
  class Witness {
   public:
    EltW e_;
    EltW dpkx_, dpky_;

    EcdsaWitness mdoc_sig_;
    EcdsaWitness dpk_sig_;
    MACWitness macs_[3];

    void input(QuadCircuit<Field>& Q, const LogicCircuit& lc) {
      e_ = Q.input();
      dpkx_ = Q.input();
      dpky_ = Q.input();

      mdoc_sig_.input(Q);
      dpk_sig_.input(Q);
      for (size_t i = 0; i < 3; ++i) {
        macs_[i].input(lc, Q);
      }
    }
  };

  explicit MdocSignature(const LogicCircuit& lc, const EC& ec, const Nat& order)
      : lc_(lc), ec_(ec), order_(order) {}

  // This function is used to verify the signatures in an MDOC.
  // The circuit verifies the following claims:
  //    1. There exists a hash digest e and a signature (r,s) on e
  //       under the public key (pkX, pkY).
  //    2. The MAC of e under the secret mac key (a_v+a_pe) is mac_e.
  //    3. There exists a device public key (dpkX, dpky) and a signature (r,s)
  //       on the value hash_tr.
  //    4. The MAC of the device public key (dpkX, dpky) under the secret MAC
  //       key (a_v + apdk) is mac_dkpX and mac_dpkY respectively.
  void assert_signatures(EltW pkX, EltW pkY, EltW hash_tr, v128 mac_e[2],
                         v128 mac_dpkX[2], v128 mac_dpkY[2], v128 a_v,
                         Witness& vw) const {
    Ecdsa ecc(lc_, ec_, order_);
    mac macc(lc_);

    ecc.verify_signature3(pkX, pkY, vw.e_, vw.mdoc_sig_);
    ecc.verify_signature3(vw.dpkx_, vw.dpky_, hash_tr, vw.dpk_sig_);

    macc.verify_mac(vw.e_, mac_e, a_v, vw.macs_[0], order_);
    macc.verify_mac(vw.dpkx_, mac_dpkX, a_v, vw.macs_[1], order_);
    macc.verify_mac(vw.dpky_, mac_dpkY, a_v, vw.macs_[2], order_);
  }

  // This function is similar to assert_signatures, but it also hides the
  // public key of the issuer. Instead, it verifies that the issuer's public
  // key belongs in a list of 50 public keys that are supplied as input. The
  // issuer pk lists are assumed to be trusted inputs, i.e., it is the
  // caller's responsibility to ensure that (issuer_pkX[i], issuer_pkY[i]) is
  // a valid curve point for i=0..49.  The caller is also responsible for
  // ensuring that issuer_pkY[i] != -issuer_pkY[j] for i != j.
  // However, it is OK for the caller to repeat the same key in the list.
  void assert_signatures_with_issuer_list(
      EltW hash_tr, v128 mac_e[2], v128 mac_dpkX[2], v128 mac_dpkY[2], v128 a_v,
      EltW issuer_pkX[/*max_issuers*/], EltW issuer_pkY[/*max_issuers*/],
      size_t max_issuers,
      // private inputs begin here
      EltW pkX, EltW pkY, Witness& vw) const {
    assert_signatures(pkX, pkY, hash_tr, mac_e, mac_dpkX, mac_dpkY, a_v, vw);

    // Verify that the issuer's public key is one of the 50 keys in the list.
    // This is done by computing the difference between pkX and issuer_pkX[i]
    // for i=0..49, and asserting that the product of the differences is zero.
    //
    // We argue that it suffices to verify that pkX is on the list and pkY is
    // on the list independently.  Suppose a malicious prover sets pkX to be
    // equal to the j-th key in issuer_pkX and sets pkY to be the k-th key in
    // issuer_pkY, where j != k.   If (pkX, pkY) is not a curve point, then the
    // assert_signatures() routine will fail.  However, for each X on the curve,
    // there are only 2 possible Y values, namely, +-Y. By the constraints
    // imposed on issuer_pkY, we know that issuer_pkY[j] is on the curve, and
    // that -issuer_pkY[j] does not occur in the issuer_pkY list.  Thus, it is
    // not possible for a witness to pass all checks and for k != j.
    EltW goodXKey = lc_.mul(0, max_issuers, [&](size_t i) {
      return lc_.sub(&issuer_pkX[i], pkX);
    });
    lc_.assert0(goodXKey);

    EltW goodYKey = lc_.mul(0, max_issuers, [&](size_t i) {
      return lc_.sub(&issuer_pkY[i], pkY);
    });
    lc_.assert0(goodYKey);
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_MDOC_MDOC_SIGNATURE_H_
