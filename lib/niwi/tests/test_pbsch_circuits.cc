/* Compilation smoke test: all PBSch circuit templates instantiating
 * with FpSecp256k1Base. Catches regressions only; no proofs. */

#include <cstdarg>
#include <cstdio>
#include <cstdlib>

#include "util/log.h"

extern "C" {
    void *ZEN = nullptr;
    void lerror(void *L, const char *fmt, ...) {
        (void)L;
        va_list ap;
        va_start(ap, fmt);
        vfprintf(stderr, fmt, ap);
        va_end(ap);
        fprintf(stderr, "\n");
        exit(1);
    }
}

namespace proofs {
void log(enum proofs::LogLevel /*level*/, const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fprintf(stderr, "\n");
}
}  // namespace proofs

#include "circuits/compiler/compiler.h"
#include "circuits/logic/logic.h"
#include "custom_backend.h"

#include "secp256k1/secp256k1_field.h"
#include "secp256k1/secp256k1_curve.h"
#include "secp256k1/secp256k1_scalar.h"
#include "circuits/secp256k1_circuit.h"
#include "circuits/bip340_circuit.h"
#include "circuits/bip340_witness.h"

using Field  = niwi::FpSecp256k1Base;
using EC     = niwi::Secp256k1;
using Scalar = niwi::FpSecp256k1Scalar;
using Backend = proofs::CustomCompilerBackend<Field>;
using Logic  = proofs::Logic<Field, Backend>;

static void instantiate_bip340_verify(Logic& lc,
                                      niwi::Bip340Circuit<Logic, EC, Scalar>& bip) {
    auto pk_x = lc.eltw_input();
    auto R_x = lc.eltw_input();
    auto s = lc.eltw_input();
    niwi::Bip340Circuit<Logic, EC, Scalar>::Witness witness;
    witness.input(lc);
    bip.verify(pk_x, R_x, s, witness);
}

int main() {
    (void)niwi::secp256k1_base;
    (void)niwi::secp256k1;
    (void)niwi::secp256k1_scalar;

    proofs::QuadCircuit<Field> qc(niwi::secp256k1_base);
    Backend backend(&qc);
    Logic lc(&backend, niwi::secp256k1_base);

    /* Secp256k1Circuit */
    niwi::Secp256k1Circuit<Logic> secp(lc, niwi::secp256k1);
    (void)secp;

    /* Bip340Witness */
    niwi::Bip340Witness<EC, Scalar> w(niwi::secp256k1_base,
                                       niwi::secp256k1,
                                       niwi::secp256k1_scalar);
    (void)w;

    /* Bip340Circuit */
    niwi::Bip340Circuit<Logic, EC, Scalar> bip(lc, niwi::secp256k1,
                                                niwi::secp256k1_scalar);
    (void)bip;
    (void)&instantiate_bip340_verify;

    return 0;
}
