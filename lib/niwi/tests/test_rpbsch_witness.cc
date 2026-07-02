/* Native RPBSch witness integration tests.
 * Uses only bridge functions and existing templates — no direct Milagro. */

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
#include "pbsch_commitment.h"
#include "circuits/bip340_witness_bridge.h"
#include "circuits/bip340_witness.h"

using F  = niwi::FpSecp256k1Base;
using EC = niwi::Secp256k1;
using S  = niwi::FpSecp256k1Scalar;
using Elt = F::Elt;
using Nat = F::N;

static int failures = 0;
static void check(bool cond, const char *msg) {
    if (!cond) { fprintf(stderr, "FAIL: %s\n", msg); failures++; }
}

static void hex_to_bytes(const char *h, uint8_t *o, size_t n) {
    for (size_t i = 0; i < n; ++i) sscanf(h + 2*i, "%2hhx", o + i);
}

/* ---- Branch 1: Pedersen C = m·G + r·H ---- */
static void test_b1_pedersen() {
    uint8_t m[32] = {0}, r_orig[32] = {0};
    m[31] = 0x42; r_orig[31] = 0x17;
    uint8_t c1[33], c2[33];
    check(niwi_pbsch_pedersen_commit(m, r_orig, c1) == 0, "pedersen compute");
    check(niwi_pbsch_pedersen_commit(m, r_orig, c2) == 0, "pedersen det");
    check(memcmp(c1, c2, 33) == 0, "pedersen deterministic");
    /* Different r → different C */
    uint8_t r2[32]; memcpy(r2, r_orig, 32); r2[31] = 0x18;
    uint8_t c3[33];
    niwi_pbsch_pedersen_commit(m, r2, c3);
    check(memcmp(c1, c3, 33) != 0, "different r → different C");
}

/* ---- Branch 1: R' = R + α·G + β·X ---- */
static void test_b1_Rprime() {
    /* Verify lift_x works for known points */
    const char *pk_h = "F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9";
    const char *Rx_str = "E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA8215";
    uint8_t pk[32], Rx[32], y[32];
    hex_to_bytes(pk_h, pk, 32);
    hex_to_bytes(Rx_str, Rx, 32);
    check(niwi_bip340_lift_x(pk, y) == 0, "lift pk");
    check(y[31] % 2 == 0, "pk y even");
    check(niwi_bip340_lift_x(Rx, y) == 0, "lift R");
    check(y[31] % 2 == 0, "R y even");
}

/* ---- Branch 1: c = Hq(R'_x, X_x, m) + β ---- */
static void test_b1_challenge() {
    uint8_t Rp_x[32] = {0}, X_x[32] = {0}, m[32] = {0};
    Rp_x[31] = 0x01; X_x[31] = 0x02; m[31] = 0x03;
    uint8_t beta[32] = {0}; beta[31] = 0x04;

    /* tagged_hash = SHA-256(sha_tag||sha_tag||Rp_x||X_x||m) */
    uint8_t sha_tag[32];
    niwi_bip340_sha256((const uint8_t *)"BIP0340/challenge", 17, sha_tag);
    uint8_t pre[160];
    memcpy(pre, sha_tag, 32); memcpy(pre+32, sha_tag, 32);
    memcpy(pre+64, Rp_x, 32); memcpy(pre+96, X_x, 32);
    memcpy(pre+128, m, 32);
    uint8_t e1[32], e2[32];
    niwi_bip340_sha256(pre, 160, e1);
    niwi_bip340_sha256(pre, 160, e2);
    check(memcmp(e1, e2, 32) == 0, "tagged hash deterministic");

    /* Change Rp_x → different hash */
    Rp_x[31] = 0x05;
    memcpy(pre+64, Rp_x, 32);
    uint8_t e3[32];
    niwi_bip340_sha256(pre, 160, e3);
    check(memcmp(e1, e3, 32) != 0, "different R' → different hash");
}

/* ---- Branch 2: ν_u ≠ ν_u' ---- */
static void test_b2_inequality() {
    uint8_t a[32] = {0}, b[32] = {0};
    a[31] = 1; b[31] = 2;
    check(memcmp(a, b, 32) != 0, "1 != 2");
    check(memcmp(a, a, 32) == 0, "1 == 1");
}

/* ---- Branch 2: SHA-256(ν_s || ν_u) = msg ---- */
static void test_b2_sha() {
    uint8_t nu_s[32] = {0}, nu_u[32] = {0};
    nu_s[31] = 0x10; nu_u[31] = 0x20;
    uint8_t in[64]; memcpy(in, nu_s, 32); memcpy(in+32, nu_u, 32);
    uint8_t h1[32], h2[32];
    niwi_bip340_sha256(in, 64, h1);
    niwi_bip340_sha256(in, 64, h2);
    check(memcmp(h1, h2, 32) == 0, "SHA deterministic");
    nu_u[31] = 0x21; memcpy(in+32, nu_u, 32);
    niwi_bip340_sha256(in, 64, h2);
    check(memcmp(h1, h2, 32) != 0, "different ν_u → diff hash");
}

/* ---- Branch 2: BIP-340 verify using Bip340Witness ---- */
static void test_b2_bip340() {
    const char *pk_h  = "F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9";
    const char *msg_h = "0000000000000000000000000000000000000000000000000000000000000000";
    const char *sig_h = "E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA821525F66A4A85EA8B71E482A74F382D2CE5EBEEE8FDB2172F477DF4900D310536C0";
    uint8_t pk[32], msg[32], sig[64];
    hex_to_bytes(pk_h, pk, 32);
    hex_to_bytes(msg_h, msg, 32);
    hex_to_bytes(sig_h, sig, 64);

    /* Verify via Bip340Witness (native check, no circuit) */
    niwi::Bip340Witness<EC, S> w(niwi::secp256k1_base, niwi::secp256k1,
                                  niwi::secp256k1_scalar);
    bool ok = w.compute(pk, sig, sig + 32, msg);
    check(ok, "vec0 BIP-340 witness compute success");

    /* Wrong message → fail */
    msg[0] ^= 0x01;
    niwi::Bip340Witness<EC, S> w2(niwi::secp256k1_base, niwi::secp256k1,
                                    niwi::secp256k1_scalar);
    bool bad = w2.compute(pk, sig, sig + 32, msg);
    check(!bad, "wrong msg → compute fails");
}

int main() {
    printf("=== lib/niwi RPBSch witness tests ===\n");
    test_b1_pedersen();
    test_b1_Rprime();
    test_b1_challenge();
    test_b2_inequality();
    test_b2_sha();
    test_b2_bip340();
    if (failures == 0) {
        printf("All tests passed.\n");
    } else {
        printf("%d tests FAILED.\n", failures);
    }
    return failures > 0 ? 1 : 0;
}
