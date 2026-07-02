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
#include "circuits/rpbsch_ec_bridge.h"
#include "circuits/bip340_witness.h"
#include "circuits/bip340_witness_bridge.h"
#include "secp256k1/secp256k1_witness.h"
#include "pbsch_commitment.h"

using F  = niwi::FpSecp256k1Base;
using EC = niwi::Secp256k1;
using S  = niwi::FpSecp256k1Scalar;
using B  = niwi::RpbschWitnessBuilder<EC, S>;
using Elt = F::Elt;

static constexpr size_t kScalarMultWitnessSize = 8 + 256 + 3 * 255;
static constexpr size_t kPackedV32Size = 7;
static constexpr size_t kSha2WitnessSize = 2 * (48 + 64 + 64 + 8) * kPackedV32Size;
static constexpr size_t kSha3WitnessSize = 3 * (48 + 64 + 64 + 8) * kPackedV32Size;
static constexpr size_t kBip340WitnessSize =
    4 + kScalarMultWitnessSize + 2 + 5 * 256 + 2 * 8 +
    kSha3WitnessSize + 8 * 32;
static constexpr size_t kBranch1WitnessSize =
    17 + 2 * kScalarMultWitnessSize + kSha3WitnessSize + 11 * 256;
static constexpr size_t kBranch2WitnessSize =
    12 + 2 * kBip340WitnessSize + kScalarMultWitnessSize +
    2 * kSha2WitnessSize + 8 * 256;

static int failures = 0;
static void check(bool cond, const char *msg) {
    if (!cond) { fprintf(stderr, "FAIL: %s\n", msg); failures++; }
}

static void hex_to_bytes(const char *h, uint8_t *o, size_t n) {
    for (size_t i = 0; i < n; ++i) sscanf(h + 2*i, "%2hhx", o + i);
}

static const uint8_t kGx[32] = {
    0x79,0xbe,0x66,0x7e,0xf9,0xdc,0xbb,0xac,
    0x55,0xa0,0x62,0x95,0xce,0x87,0x0b,0x07,
    0x02,0x9b,0xfc,0xdb,0x2d,0xce,0x28,0xd9,
    0x59,0xf2,0x81,0x5b,0x16,0xf8,0x17,0x98
};
static const uint8_t kGy[32] = {
    0x48,0x3a,0xda,0x77,0x26,0xa3,0xc4,0x65,
    0x5d,0xa4,0xfb,0xfc,0x0e,0x11,0x08,0xa8,
    0xfd,0x17,0xb4,0x48,0xa6,0x85,0x54,0x19,
    0x9c,0x47,0xd0,0x8f,0xfb,0x10,0xd4,0xb8
};
static const uint8_t kN[32] = {
    0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
    0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xfe,
    0xba,0xae,0xdc,0xe6,0xaf,0x48,0xa0,0x3b,
    0xbf,0xd2,0x5e,0x8c,0xd0,0x36,0x41,0x41
};

static void add_be32_33(const uint8_t a[32], const uint8_t b[32], uint8_t out[33]) {
    unsigned carry = 0;
    for (int i = 31; i >= 0; --i) {
        unsigned s = (unsigned)a[i] + (unsigned)b[i] + carry;
        out[i + 1] = (uint8_t)(s & 0xffu);
        carry = s >> 8;
    }
    out[0] = (uint8_t)carry;
}

static void add_overflow_n_33(const uint8_t c[32], int overflow, uint8_t out[33]) {
    uint8_t on[32] = {0};
    if (overflow) memcpy(on, kN, 32);
    add_be32_33(c, on, out);
}

static void scalar_to_be32(const Elt& e, uint8_t out[32]) {
    niwi::secp256k1_base_to_octet(e, out);
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

    check(niwi_pbsch_pedersen_verify(stmt.C, m, rho) == 0, "C verifies");

    uint8_t aGx[32], aGy[32], bXx[32], bXy[32], Tx[32], Ty[32];
    check(niwi_rpbsch_ec_mul(kGx, kGy, a, aGx, aGy) == 0, "alpha*G");
    check(niwi_rpbsch_ec_mul(X, b1.X_y, b, bXx, bXy) == 0, "beta*X");
    check(niwi_rpbsch_ec_add(aGx, aGy, bXx, bXy, Tx, Ty) == 0, "T native");
    check(memcmp(Tx, b1.T + 1, 32) == 0, "T_x matches");
    check(memcmp(Ty, b1.T_y, 32) == 0, "T_y matches");

    uint8_t Rpx[32], Rpy[32];
    check(niwi_rpbsch_ec_add(R, b1.R_y, b1.T + 1, b1.T_y, Rpx, Rpy) == 0, "R plus T");
    check(memcmp(Rpx, b1.Rp, 32) == 0, "R'_x matches");
    check(memcmp(Rpy, b1.Rp_y, 32) == 0, "R'_y matches");

    uint8_t c_bytes[32], lhs[33], rhs[33];
    scalar_to_be32(b1.c_scalar, c_bytes);
    add_overflow_n_33(c_bytes, b1.overflow, lhs);
    add_be32_33(b1.e_hash, b, rhs);
    check(memcmp(lhs, rhs, 33) == 0, "c + overflow*n == e + beta");

    std::vector<Elt> witness;
    size_t n = builder.fill_witness_branch1(stmt, b1, witness);
    check(n == kBranch1WitnessSize, "branch 1 witness size");
    check(witness.size() == kBranch1WitnessSize, "branch 1 vector size");
}

static void test_b1_overflow() {
    B builder(niwi::secp256k1_base, niwi::secp256k1, niwi::secp256k1_scalar);
    B::Statement stmt;
    B::Branch1 b1;

    const char *pk_h = "F9308A019258C31049344F85F89D5229B531C845836F99B08601F113BCE036F9";
    const char *R_h  = "E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA8215";
    uint8_t X[32], Xp[32], R[32];
    hex_to_bytes(pk_h, X,  32);
    hex_to_bytes(pk_h, Xp, 32);
    hex_to_bytes(R_h,  R,  32);

    uint8_t m[32]  = {0}; m[31]  = 0x42;
    uint8_t a[32]  = {0}; a[31]  = 0x03;
    uint8_t beta[32]; memcpy(beta, kN, 32); beta[31] -= 1; /* n - 1 */
    uint8_t rho[32]= {0}; rho[31]= 0x17;

    bool ok = builder.build_branch1(X, Xp, m, a, beta, rho, R, stmt, b1);
    check(ok, "branch 1 overflow build succeeds");
    check(b1.overflow == 1, "overflow detected for beta=n-1");

    uint8_t c_bytes[32], lhs[33], rhs[33];
    scalar_to_be32(b1.c_scalar, c_bytes);
    add_overflow_n_33(c_bytes, b1.overflow, lhs);
    add_be32_33(b1.e_hash, beta, rhs);
    check(memcmp(lhs, rhs, 33) == 0, "overflow equation holds");
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
    auto u = niwi::secp256k1_scalar.to_montgomery(niwi::secp256k1_base.from_montgomery(b2.nu_u));
    auto up = niwi::secp256k1_scalar.to_montgomery(niwi::secp256k1_base.from_montgomery(b2.nu_u_prime));
    auto inv = niwi::secp256k1_scalar.to_montgomery(niwi::secp256k1_base.from_montgomery(b2.nu_inv));
    auto diff = niwi::secp256k1_scalar.subf(u, up);
    check(niwi::secp256k1_scalar.mulf(diff, inv) == niwi::secp256k1_scalar.one(),
          "nu_inv*(nu_u-nu_u') == 1");
    check(niwi_pbsch_pedersen_verify(stmt.S, nu_s, rho) == 0, "S verifies");
    check(memcmp(b2.msg0, b2.msg1, 32) != 0, "msg0 != msg1");

    std::vector<Elt> witness;
    size_t n = builder.fill_witness_branch2(stmt, b2, witness);
    check(n == kBranch2WitnessSize, "branch 2 witness size");
    check(witness.size() == kBranch2WitnessSize, "branch 2 vector size");
}

int main() {
    printf("=== lib/niwi RPBSch builder test ===\n");
    test_b1_complete();
    test_b1_overflow();
    test_b2_complete();
    if (failures == 0) {
        printf("All tests passed.\n");
    } else {
        printf("%d tests FAILED.\n", failures);
    }
    return failures > 0 ? 1 : 0;
}
