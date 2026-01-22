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

#include "ec/p256.h"

namespace proofs {
const Fp256Base p256_base;

const Fp256Nat n256_order(
    "0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551");

const Fp256Scalar p256_scalar(n256_order);

const P256 p256(
    p256_base.of_string("115792089210356248762697446949407573530086143415290314"
                        "195533631308867097853948"), /* a for curve*/
    p256_base.of_string("410583637251521421293261297800472684091144410159937255"
                        "54835256314039467401291"), /* b for curve*/
    p256_base.of_string("484395612939064517590525852527979142027629495260417479"
                        "95844080717082404635286"), /* generator x coordinate */
    p256_base.of_string("361342509567497957985851279195878819566111066729850150"
                        "71877198253568414405109"), /* generator y coordinate */
    p256_base);

}  // namespace proofs
