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

#ifndef PRIVACY_PROOFS_ZK_LIB_EC_P256_H_
#define PRIVACY_PROOFS_ZK_LIB_EC_P256_H_

/*
This file declares the one instance of the P256 curve and its related fields.
There should be only one instance of this curve in any program due to the
typing conventions.

This curve is also known as secp256r1 and prime256v1.

It is defined over the base field F_p for
p = 0xffffffff00000001000000000000000000000000ffffffffffffffffffffffff
= 115792089210356248762697446949407573530086143415290314195533631308867097853951

and has an order of
0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551
115792089210356248762697446949407573529996955224135760342422259061068512044369


*/

#include "algebra/fp.h"
#include "algebra/fp_p256.h"
#include "ec/elliptic_curve.h"

namespace proofs {

using Fp256Base = Fp256<true>;
using Fp256Scalar = Fp<4, true>;
using Fp256Nat = Fp256Base::N;

// This is the base field of the curve.
extern const Fp256Base p256_base;

// Order of the curve.
extern const Fp256Nat n256_order;

// This field allows operations mod the order of the curve.
extern const Fp256Scalar p256_scalar;

typedef EllipticCurve<Fp256Base, 4, 256> P256;

extern const P256 p256;
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_EC_P256_H_
