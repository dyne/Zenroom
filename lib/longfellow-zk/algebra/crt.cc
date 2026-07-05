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

#include "algebra/crt.h"

#include <cstdint>

namespace proofs {
namespace crt {

// ==========================================
// 17 primes for a CRT representation that can support p521.
// 9 or 13 can be used for smaller fields. Primes are in sorted order.
const uint64_t kPrimes17[kBasisSize] = {
    18446744072195407873ull, 18446744072237350913ull, 18446744072245739521ull,
    18446744072325431297ull, 18446744072589672449ull, 18446744072623226881ull,
    18446744072790999041ull, 18446744073113960449ull, 18446744073290121217ull,
    18446744073327869953ull, 18446744073332064257ull, 18446744073344647169ull,
    18446744073420144641ull, 18446744073457893377ull, 18446744073516613633ull,
    18446744073520807937ull, 18446744073692774401ull};

const uint64_t kOmega17[kBasisSize] = {
    436037131817ull,   2773676930123ull, 2768111518080ull,  34106487772798ull,
    1302264167001ull,  5572414085664ull, 4170236488818ull,  10930506752996ull,
    13447610733542ull, 366878793395ull,  10535270759408ull, 2630106726088ull,
    2766923619799ull,  6957320847870ull, 10540913985379ull, 15095618916269ull,
    3150424293220ull,
};

}  // namespace crt
}  // namespace proofs
