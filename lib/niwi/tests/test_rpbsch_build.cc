/* RPBSch circuit build + compile/evaluation test.
 * Builds the full RPBSch circuit with four public statement inputs,
 * compiles it, and verifies mkcircuit produces a valid artifact.
 * Then evaluates the circuit with a native RPBSch witness. */

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
#include "arrays/dense.h"
#include "sumcheck/prover_layers.h"
#include "custom_backend.h"

#include "secp256k1/secp256k1_field.h"
#include "secp256k1/secp256k1_curve.h"
#include "secp256k1/secp256k1_scalar.h"
#include "circuits/rpbsch_circuit.h"
#include "circuits/rpbsch_witness_builder.h"
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

static void hex_to_bytes(const char *h, uint8_t *o, size_t n) {
    for (size_t i = 0; i < n; ++i) sscanf(h + 2*i, "%2hhx", o + i);
}

int main() {
    printf("=== lib/niwi RPBSch circuit build test ===\n");

    proofs::QuadCircuit<Field> qc(niwi::secp256k1_base);
    Backend backend(&qc);
    Logic lc(&backend, niwi::secp256k1_base);
    Rpbsch rpbsch(lc, niwi::secp256k1, niwi::secp256k1_scalar);

    /* Public statement: X, X', C, S. */
    size_t public_start = qc.ninput();
    Rpbsch::Statement stmt;
    stmt.X_x  = lc.eltw_input();
    stmt.Xp_x = lc.eltw_input();
    stmt.C_x  = lc.eltw_input();
    stmt.S_x  = lc.eltw_input();
    size_t public_end = qc.ninput();
    qc.private_input();

    EltW sel = lc.eltw_input();
    Rpbsch::Branch1Witness circuit_b1;
    Rpbsch::Branch2Witness circuit_b2;
    circuit_b1.input(lc);
    circuit_b2.input(lc);

    /* Build constraints */
    rpbsch.verify(stmt, sel, circuit_b1, circuit_b2);

    /* Compile circuit */
    auto circuit = qc.mkcircuit(1);
    check(circuit != nullptr, "circuit compiled");
    check(public_end - public_start == 4, "four public statement inputs");
    check(circuit->npub_in == public_end, "private boundary after statement");

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

    /* Evaluate the compiled circuit with both strict-mode branches valid. */
    using Builder = niwi::RpbschWitnessBuilder<EC, Scalar>;
    Builder builder(niwi::secp256k1_base, niwi::secp256k1,
                    niwi::secp256k1_scalar);
    Builder::Statement stmt_bytes;
    Builder::Branch1 native_b1;
    Builder::Branch2 native_b2;

    const char *pk_h  = "F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9";
    const char *R_h   = "E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA8215";
    const char *sig0_h = "890D0BEF80FC0B3B46A0B6EC12AE5B88998F64E30C962DBCDE6D0C028BB79C57FE1590B84BB8DE8663582E61C1D2758EB0F2EEEB11B555027AB1BC0CE3F94253";
    const char *sig1_h = "8D46A2C7B20ADF3269FC6E4A838572AA377129C8F230FAE8F357C2F2F016B12C70BDBCD2A2CD78045B8BB8525671536D0AB0B6831142E8801DCD013EE75EDD6A";

    uint8_t X[32], Xp[32], R[32], sig0[64], sig1[64];
    hex_to_bytes(pk_h, X, 32);
    hex_to_bytes(pk_h, Xp, 32);
    hex_to_bytes(R_h, R, 32);
    hex_to_bytes(sig0_h, sig0, 64);
    hex_to_bytes(sig1_h, sig1, 64);

    uint8_t m[32] = {0};     m[31] = 0x42;
    uint8_t alpha[32] = {0}; alpha[31] = 0x03;
    uint8_t beta[32] = {0};  beta[31] = 0x05;
    uint8_t rho_c[32] = {0}; rho_c[31] = 0x17;
    uint8_t nu_u[32] = {0};  nu_u[31] = 0x01;
    uint8_t nu_up[32] = {0}; nu_up[31] = 0x02;
    uint8_t nu_s[32] = {0};  nu_s[31] = 0x42;
    uint8_t rho_s[32] = {0}; rho_s[31] = 0x17;

    check(builder.build_branch1(X, Xp, m, alpha, beta, rho_c, R,
                                stmt_bytes, native_b1),
          "branch 1 witness builds");
    check(builder.build_branch2(X, Xp, sig0, sig1, nu_u, nu_up, nu_s, rho_s,
                                stmt_bytes, native_b2),
          "branch 2 witness builds");

    std::vector<Field::Elt> b1_witness;
    std::vector<Field::Elt> b2_witness;
    check(builder.fill_witness_branch1(stmt_bytes, native_b1, b1_witness) > 0,
          "branch 1 witness fills");
    check(builder.fill_witness_branch2(stmt_bytes, native_b2, b2_witness) > 0,
          "branch 2 witness fills");

    auto W = std::make_unique<proofs::Dense<Field>>(1, circuit->ninputs);
    proofs::DenseFiller<Field> fill(*W);
    for (size_t i = 0; i < public_start; ++i)
        fill.push_back(niwi::secp256k1_base.zero());
    fill.push_back(builder.elt_from_be32(stmt_bytes.X));
    fill.push_back(builder.elt_from_be32(stmt_bytes.Xp));
    fill.push_back(builder.elt_from_be32(stmt_bytes.C + 1));
    fill.push_back(builder.elt_from_be32(stmt_bytes.S + 1));
    fill.push_back(niwi::secp256k1_base.one()); /* selector */
    fill.push_back(b1_witness);
    fill.push_back(b2_witness);
    check(fill.size() == circuit->ninputs, "filled all circuit inputs");

    proofs::ProverLayers<Field> layers(niwi::secp256k1_base);
    proofs::ProverLayers<Field>::inputs layer_inputs;
    auto final = layers.eval_circuit(&layer_inputs, circuit.get(),
                                     std::move(W), niwi::secp256k1_base);
    check(final != nullptr, "RPBSch witness satisfies compiled circuit");

    if (failures == 0) {
        printf("All tests passed.\n");
    } else {
        printf("%d tests FAILED.\n", failures);
    }
    return failures > 0 ? 1 : 0;
}
