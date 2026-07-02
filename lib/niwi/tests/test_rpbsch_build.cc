/* RPBSch circuit build + compile test.
 * Builds the full RPBSch circuit, compiles it, and verifies
 * mkcircuit produces a valid artifact. Does NOT generate witnesses
 * or prove yet — that comes next. */

#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#include "util/log.h"
extern "C" {
    void *ZEN = nullptr;
    void lerror(void *L, const char *fmt, ...) {
        (void)L; va_list ap; va_start(ap,fmt); vfprintf(stderr,fmt,ap);
        va_end(ap); fprintf(stderr,"\n"); exit(1);
    }
}
namespace proofs {
void log(enum proofs::LogLevel, const char *fmt, ...) {
    va_list ap; va_start(ap,fmt); vfprintf(stderr,fmt,ap);
    va_end(ap); fprintf(stderr,"\n");
}
}

#include "circuits/compiler/compiler.h"
#include "circuits/logic/logic.h"
#include "custom_backend.h"

#include "secp256k1/secp256k1_field.h"
#include "secp256k1/secp256k1_curve.h"
#include "secp256k1/secp256k1_scalar.h"
#include "circuits/rpbsch_circuit.h"
#include "proto/circuit.h"

using Field  = niwi::FpSecp256k1Base;
using EC     = niwi::Secp256k1;
using Scalar = niwi::FpSecp256k1Scalar;
using Backend = proofs::CustomCompilerBackend<Field>;
using Logic  = proofs::Logic<Field, Backend>;
using Rpbsch = niwi::RpbschCircuit<Logic, EC, Scalar>;
using EltW   = typename Logic::EltW;

static int failures = 0;
static void check(bool cond, const char *msg) {
    if (!cond) { fprintf(stderr, "FAIL: %s\n", msg); failures++; }
}

int main() {
    printf("=== lib/niwi RPBSch circuit build test ===\n");

    proofs::QuadCircuit<Field> qc(niwi::secp256k1_base);
    Backend backend(&qc);
    Logic lc(&backend, niwi::secp256k1_base);
    Rpbsch rpbsch(lc, niwi::secp256k1, niwi::secp256k1_scalar);

    /* Build statement: dummy values for X, X', C, S */
    Rpbsch::Statement stmt;
    stmt.X_x  = lc.konst(niwi::secp256k1_base.zero());
    stmt.Xp_x = lc.konst(niwi::secp256k1_base.zero());
    stmt.C_x  = lc.konst(niwi::secp256k1_base.zero());
    stmt.S_x  = lc.konst(niwi::secp256k1_base.zero());

    EltW sel = lc.eltw_input();
    Rpbsch::Branch1Witness b1;
    Rpbsch::Branch2Witness b2;
    b1.input(lc);
    b2.input(lc);

    /* Build constraints */
    rpbsch.verify(stmt, sel, b1, b2);

    /* Compile circuit */
    size_t npub = 4; /* X_x, Xp_x, C_x, S_x are public */
    check(npub <= qc.nwires_, "public inputs ≤ total inputs");

    auto circuit = qc.mkcircuit(1);
    check(circuit != nullptr, "circuit compiled");

    printf("Circuit: nv=%zu nc=%zu npub=%zu ninputs=%zu nl=%zu nw=%zu\n",
           circuit->nv, circuit->nc, circuit->npub_in,
           circuit->ninputs, circuit->l.size(),
           qc.nwires_);

    /* Serialize */
    proofs::CircuitRep<Field> rep(niwi::secp256k1_base, proofs::SECP_ID);
    std::vector<uint8_t> bytes;
    rep.to_bytes(*circuit, bytes);
    printf("Serialized: %zu bytes\n", bytes.size());
    check(bytes.size() > 0, "serialized non-empty");

    /* Deserialize */
    proofs::ReadBuffer rb(&bytes[0], bytes.size());
    auto deser = rep.from_bytes(rb, false);
    check(deser != nullptr, "deserialized");
    if (deser) {
        check(deser->nv == circuit->nv, "nv matches");
        check(deser->nc == circuit->nc, "nc matches");
    }

    if (failures == 0) {
        printf("All tests passed.\n");
    } else {
        printf("%d tests FAILED.\n", failures);
    }
    return failures > 0 ? 1 : 0;
}
