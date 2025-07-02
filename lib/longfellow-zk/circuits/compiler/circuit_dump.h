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

#ifndef PRIVACY_PROOFS_ZK_LIB_CIRCUITS_COMPILER_CIRCUIT_DUMP_H_
#define PRIVACY_PROOFS_ZK_LIB_CIRCUITS_COMPILER_CIRCUIT_DUMP_H_

#include <stddef.h>

#include "circuits/compiler/compiler.h"
#include "util/log.h"

// Debug printing routines for circuit tests.
namespace proofs {

template <class Field>
inline void dump_info(const char* name, size_t size,
                      const QuadCircuit<Field>& Q) {
  log(INFO, "Compiled circuit: %s[%zu]", name, size);
  dump_q(Q);
}

template <class Field>
inline void dump_info(const char* name, size_t sz0, size_t sz1,
                      const QuadCircuit<Field>& Q) {
  log(INFO, "Compiled circuit: %s[%zu][%zu]", name, sz0, sz1);
  dump_q(Q);
}

template <class Field>
inline void dump_info(const char* name, size_t sz0, size_t sz1, size_t sz2,
                      const QuadCircuit<Field>& Q) {
  log(INFO, "Compiled circuit: %s[%zu][%zu][%zu]", name, sz0, sz1, sz2);
  dump_q(Q);
}

template <class Field>
inline void dump_info(const char* name, const QuadCircuit<Field>& Q) {
  log(INFO, "Compiled circuit: %s", name);
  dump_q(Q);
}

template <class Field>
inline void dump_q(const QuadCircuit<Field>& Q) {
  log(INFO,
      " depth: %zu wires: %zu in: %zu out:%zu use:%zu ovh:%zu t:%zu cse:%zu "
      "notn:%zu",
      Q.depth_, Q.nwires_, Q.ninput_, Q.noutput_,
      Q.nwires_ - Q.nwires_overhead_, Q.nwires_overhead_, Q.nquad_terms_,
      Q.nwires_cse_eliminated_, Q.nwires_not_needed_);
}

}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_CIRCUITS_COMPILER_CIRCUIT_DUMP_H_
