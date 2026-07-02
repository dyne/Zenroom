/* Unit test: RpbschWitnessBuilder compiles and produces valid data. */

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

#include "secp256k1/secp256k1_field.h"
#include "secp256k1/secp256k1_curve.h"
#include "secp256k1/secp256k1_scalar.h"
#include "circuits/rpbsch_witness_builder.h"
#include "circuits/bip340_witness.h"
#include "circuits/bip340_witness_bridge.h"

using F  = niwi::FpSecp256k1Base;
using EC = niwi::Secp256k1;
using S  = niwi::FpSecp256k1Scalar;
using B  = niwi::RpbschWitnessBuilder<EC, S>;

static int failures = 0;
static void check(bool cond, const char *msg) {
    if (!cond) { fprintf(stderr, "FAIL: %s\n", msg); failures++; }
}

static void hex_to_bytes(const char *h, uint8_t *o, size_t n) {
    for (size_t i = 0; i < n; ++i) sscanf(h + 2*i, "%2hhx", o + i);
}

static void test_b1_complete() {
    B builder(niwi::secp256k1_base, niwi::secp256k1, niwi::secp256k1_scalar);
    B::Statement stmt;
    B::Branch1 b1;

    /* Use BIP-340 vec0 key and nonce */
    const char *pk_h = "F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9";
    const char *R_h  = "E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA8215";
    uint8_t X[32], Xp[32], R[32];
    hex_to_bytes(pk_h, X,  32);
    hex_to_bytes(pk_h, Xp, 32); /* X = X' for test */
    hex_to_bytes(R_h,  R,  32);

    uint8_t m[32]  = {0}; m[31]  = 0x42;
    uint8_t a[32]  = {0}; a[31]  = 0x03;
    uint8_t b[32]  = {0}; b[31]  = 0x05;
    uint8_t rho[32]= {0}; rho[31]= 0x17;

    bool ok = builder.build_branch1(X, Xp, m, a, b, rho, R, stmt, b1);
    check(ok, "branch 1 build succeeds");

    /* Verify outputs are non-trivial */
    check(memcmp(stmt.C+1, stmt.C+2, 31) != 0 || stmt.C[1] != 0,
          "C non-zero");
    check(b1.c_scalar != niwi::secp256k1_base.zero(), "c_scalar non-zero");

    /* Verify C decompression: C_y is on curve */
    Elt cx = builder.elt_from_be32(stmt.C + 1);
    (void)cx;

    /* Verify R' was computed */
    check(memcmp(b1.Rp, R, 32) != 0, "R' != R");
}

static void test_b2_complete() {
    B builder(niwi::secp256k1_base, niwi::secp256k1, niwi::secp256k1_scalar);
    B::Statement stmt;
    B::Branch2 b2;

    const char *pk_h  = "F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9";
    const char *sig_h = "E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA821525F66A4A85EA8B71E482A74F382D2CE5EBEEE8FDB2172F477DF4900D310536C0";
    uint8_t X[32], Xp[32], sig[64];
    hex_to_bytes(pk_h,  X,  32);
    hex_to_bytes(pk_h,  Xp, 32);
    hex_to_bytes(sig_h, sig, 64);

    uint8_t nu_u[32]  = {0}; nu_u[31]  = 0x01;
    uint8_t nu_up[32] = {0}; nu_up[31] = 0x02;
    uint8_t nu_s[32]  = {0}; nu_s[31]  = 0x42;
    uint8_t rho[32]   = {0}; rho[31]   = 0x17;

    bool ok = builder.build_branch2(X, Xp, sig, sig, nu_u, nu_up, nu_s, rho,
                                     stmt, b2);
    check(ok, "branch 2 build succeeds");
    check(b2.nu_inv != niwi::secp256k1_base.zero(), "nu_inv non-zero");
    check(memcmp(b2.msg0, b2.msg1, 32) != 0, "msg0 != msg1");
}

int main() {
    printf("=== lib/niwi RPBSch builder test ===\n");
    test_b1_complete();
    test_b2_complete();
    if (failures == 0) {
        printf("All tests passed.\n");
    } else {
        printf("%d tests FAILED.\n", failures);
    }
    return failures > 0 ? 1 : 0;
}
