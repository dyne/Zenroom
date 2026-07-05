// Copyright 2026 Google LLC.
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

#ifndef PRIVACY_PROOFS_ZK_LIB_EC_P256K1_H_
#define PRIVACY_PROOFS_ZK_LIB_EC_P256K1_H_

/*
This file declares the one instance of the P256k1 curve and its related fields.
There should be only one instance of this curve in any program due to the
typing conventions.

This curve is also known as secp256k1.

It is defined over the base field F_p for
p = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f
= 2^256 - 2^32 - 977
= 115792089237316195423570985008687907853269984665640564039457584007908834671663

and has an order of
n = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141
= 115792089237316195423570985008687907852837564279074904382605163141518161494337
*/

#include "algebra/fp.h"
#include "algebra/fp_p256k1.h"
#include "ec/elliptic_curve.h"

namespace proofs {

using Fp256k1Base = Fp256k1<true>;
using Fp256k1Scalar = Fp<4, true>;
using Fp256k1Nat = Fp256k1Base::N;

// This is the base field of the curve.
extern const Fp256k1Base p256k1_base;

// Order of the curve.
extern const Fp256k1Nat n256k1_order;

// This field allows operations mod the order of the curve.
extern const Fp256k1Scalar p256k1_scalar;

typedef EllipticCurve<Fp256k1Base, 4, 256> P256k1;

extern const P256k1 p256k1;

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_EC_P256K1_H_
