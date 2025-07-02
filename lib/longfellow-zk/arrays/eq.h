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

#ifndef PRIVACY_PROOFS_ZK_LIB_ARRAYS_EQ_H_
#define PRIVACY_PROOFS_ZK_LIB_ARRAYS_EQ_H_

#include <stddef.h>

#include "arrays/affine.h"

namespace proofs {
template <class Field>
// EQ[i,j] is 2D sparse array EQ[i, j] = (i == j).
// This class contains a state-free version of EQ, which
// evaluates EQ[i, j] on the fly.  See Eqs for a stateful
// version that stores all the values of EQ[I, j] for fixed I
// and variable j.
class Eq {
  using Elt = typename Field::Elt;

 public:
  /*
    Bind EQ{logn,n} at I, J.

    We consider the diagonal matrix EQ[i,j] to be composed of
    N-1 diagonal elements A and one last diagonal element B, i.e.,
    EQ=diag([A A A A ... B]).  We bind one I variable and one J
    variable in one step, yielding a matrix of the same form
    with ceil(n/2) diagonal entries.

    Let I1J1=I[0]*J[0] and I0J0=(1-I[0])*(1-J[0]).

    Binding A is equivalent to binding the 2x2 block [A 0; 0 A],
    yielding A <- A*(I0J0+I1J1).

    If n is even, then the last 2x2 block is [A 0; 0 B], whose binding
    yields B <- A*I0J0 + B*I1J1.

    If n is odd, then the last 2x2 block is [B 0; 0 0], whose binding
    yields B <- B*I0J0.
  */
  static Elt eval(size_t logn, corner_t n, const Elt I[/*logn*/],
                  const Elt J[/*logn*/], const Field& F) {
    Elt a = F.one(), b = F.one();
    for (size_t round = 0; round < logn; round++) {
      Elt i1 = I[round], j1 = J[round];
      Elt i0 = F.subf(F.one(), i1), j0 = F.subf(F.one(), j1);
      Elt i0j0 = F.mulf(i0, j0);
      Elt i1j1 = F.mulf(i1, j1);
      if ((n & 1) == 0) {
        F.mul(b, i1j1);
        F.add(b, F.mulf(a, i0j0));
      } else {
        F.mul(b, i0j0);
      }
      F.mul(a, F.addf(i0j0, i1j1));
      n = (n + 1) / 2;
    }
    return b;
  }
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_ARRAYS_EQ_H_
