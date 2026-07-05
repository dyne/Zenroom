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

#include "ec/p256k1.h"

namespace proofs {
const Fp256k1Base p256k1_base;

const Fp256k1Nat n256k1_order(
    "0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141");

const Fp256k1Scalar p256k1_scalar(n256k1_order);

const P256k1 p256k1(
    p256k1_base.zero(),         /* a = 0 */
    p256k1_base.of_string("7"), /* b = 7 */
    p256k1_base.of_string("0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959"
                          "F2815B16F81798"), /* Gx */
    p256k1_base.of_string("0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C"
                          "47D08FFB10D4B8"), /* Gy */
    p256k1_base);

}  // namespace proofs
