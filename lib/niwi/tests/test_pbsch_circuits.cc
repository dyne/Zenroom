/* Compilation smoke test: all PBSch circuit templates instantiating
 * with FpSecp256k1Base. Catches regressions only; no proofs. */

#include "circuits/compiler/compiler.h"
#include "circuits/logic/logic.h"

#include "secp256k1/secp256k1_field.h"
#include "secp256k1/secp256k1_curve.h"
#include "secp256k1/secp256k1_scalar.h"
#include "circuits/secp256k1_circuit.h"
#include "circuits/bip340_circuit.h"
#include "circuits/bip340_witness.h"

using Field  = niwi::FpSecp256k1Base;
using EC     = niwi::Secp256k1;
using Scalar = niwi::FpSecp256k1Scalar;
using Logic  = proofs::Logic<proofs::QuadCircuit<Field>, Field>;

int main() {
    (void)niwi::secp256k1_base;
    (void)niwi::secp256k1;
    (void)niwi::secp256k1_scalar;

    proofs::QuadCircuit<Field> qc(niwi::secp256k1_base);
    Logic lc(&qc, niwi::secp256k1_base);

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

    return 0;
}
