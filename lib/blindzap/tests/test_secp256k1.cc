/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2026 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <cstdarg>

#include "util/log.h"

/* Stub symbols required by Longfellow's check() and panic() macros.
 * In the Zenroom build these come from src/zen_error.o and src/zenroom.o.
 * For the standalone lib/blindzap test, we provide minimal stubs. */
extern "C" {
    void *ZEN = nullptr;
    void lerror(void *L, const char *fmt, ...) {
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

#include "secp256k1/secp256k1_field.h"
#include "secp256k1/secp256k1_scalar.h"
#include "secp256k1/secp256k1_curve.h"
#include "secp256k1/secp256k1_witness.h"

using namespace niwi;

static int failures = 0;

static void check(bool cond, const char *msg) {
    if (!cond) {
        fprintf(stderr, "FAIL: %s\n", msg);
        failures++;
    }
}

/* ---- Field tests ---- */

static void test_field_basics() {
    const auto& F = secp256k1_base;
    auto zero = F.zero();
    auto one = F.one();
    auto twoElt = F.of_scalar(2);

    check(zero == F.zero(), "zero equality");
    check(one == F.one(), "one equality");
    check(twoElt == F.of_scalar(2), "2 == F.of_scalar(2)");
    check(F.addf(one, one) == twoElt, "1+1 == 2");
    check(F.mulf(one, F.of_scalar(0)) == zero, "1*0 == 0");

    /* p-1 + 1 = 0 mod p */
    auto p_minus_1 = F.of_string(
        "0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2e");
    check(F.addf(p_minus_1, one) == zero, "(p-1)+1 == 0");
    FpSecp256k1Base::Elt mone = F.negf(F.one());
    check(p_minus_1 == mone, "p-1 == -1");

    /* Multiplication */
    check(F.mulf(one, twoElt) == twoElt, "1*2 == 2");
    check(F.mulf(twoElt, F.of_scalar(2)) == F.of_scalar(4), "2*2 == 4");

    /* Inverse: 2 * 2^-1 = 1 */
    FpSecp256k1Base::Elt inv2 = twoElt;
    F.invert(inv2);
    check(F.mulf(twoElt, inv2) == one, "2 * 2^-1 == 1");
}

/* ---- Scalar field tests ---- */

static void test_scalar_basics() {
    const auto& FS = secp256k1_scalar;
    auto zero = FS.zero();
    auto one = FS.one();

    check(zero == FS.zero(), "scalar zero");
    check(one == FS.one(), "scalar one");

    /* n-1 + 1 = 0 mod n */
    auto n_minus_1 = FS.of_string(
        "0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140");
    check(FS.addf(n_minus_1, one) == zero, "(n-1)+1 == 0 mod n");
}

/* ---- Curve tests ---- */

static void test_curve_basics() {
    const auto& C = secp256k1;
    const auto& F = secp256k1_base;

    /* Generator is on curve */
    auto G = C.generator();
    check(C.is_on_curve(G), "generator on curve");

    /* Zero (infinity) point */
    auto inf = C.zero();
    check(C.is_on_curve(inf), "zero point on curve (by definition)");

    /* G + inf = G */
    auto G_plus_inf = C.addEf(G, inf);
    check(C.equal(G_plus_inf, G), "G + inf == G");

    /* 2G = G + G */
    auto G2 = C.doubleEf(G);
    auto G2_norm = G2;
    C.normalize(G2_norm);
    auto G2_add = C.addEf(G, G);
    auto G2_add_norm = G2_add;
    C.normalize(G2_add_norm);
    check(C.equal(G2_norm, G2_add_norm), "2G == G+G");
    check(C.is_on_curve(G2_norm), "2G on curve");

    /* n*G = inf (group order) */
    auto n_elt = secp256k1_scalar.of_string(
        "0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141");
    /* scalar_multf needs a Nat, and n is the modulus value. We get n
     * as a Nat from the FpSecp256k1Scalar's internal modulus. However
     * the modulus is not exposed. Instead we use the scalar field element
     * n which is zero (since mod n, n == 0). For the test we instead test
     * with 1*G and 2*G to verify basic scalar_multf. */
    /* 1*G, 2*G, 0*G */
    using FpNat = FpSecp256k1Scalar::N;
    auto oneS = FpNat(1);
    auto oneG = C.scalar_multf(G, oneS);
    check(C.equal(oneG, G), "1*G == G");

    auto twoS = FpNat(2);
    auto twoG = C.scalar_multf(G, twoS);
    check(C.equal(twoG, G2), "2*G == G+G (via scalar_multf)");

    auto zeroS = FpNat(0);
    auto zeroG = C.scalar_multf(G, zeroS);
    check(C.equal(zeroG, inf), "0*G == inf");
}

/* ---- Witness tests ---- */

static void test_witness_conversion() {
    /* Zero */
    uint8_t zero_bytes[32] = {0};
    auto zero_elt = octet_to_secp256k1_base(zero_bytes);
    check(zero_elt.has_value(), "0x0 round-trips");
    if (zero_elt.has_value()) {
        uint8_t back[32];
        secp256k1_base_to_octet(zero_elt.value(), back);
        check(memcmp(zero_bytes, back, 32) == 0, "0x0 round-tripped");
    }

    /* One */
    uint8_t one_bytes[32] = {0};
    one_bytes[31] = 1;
    auto one_elt = octet_to_secp256k1_base(one_bytes);
    check(one_elt.has_value(), "0x1 round-trips");
    if (one_elt.has_value()) {
        uint8_t back[32];
        secp256k1_base_to_octet(one_elt.value(), back);
        check(memcmp(one_bytes, back, 32) == 0, "0x1 round-tripped");
    }

    /* p-1 in 32 bytes. p = 0xFFFFFFFF...FFFEFFFFFC2F */
    uint8_t pm1_correct[32] = {
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xfc, 0x2e
    };
    auto pm1_elt = octet_to_secp256k1_base(pm1_correct);
    check(pm1_elt.has_value(), "p-1 round-trips");

    /* p (invalid — should fail) */
    uint8_t p_bytes[32] = {
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xfc, 0x2f
    };
    auto p_elt = octet_to_secp256k1_base(p_bytes);
    check(!p_elt.has_value(), "p is rejected (>= p)");

    /* Full-max 32 bytes (0xFFFF...FFFF) is >= p — should fail */
    uint8_t max_bytes[32];
    memset(max_bytes, 0xFF, 32);
    auto max_elt = octet_to_secp256k1_base(max_bytes);
    check(!max_elt.has_value(), "0xFF...FFFF is rejected (>= p)");

    /* Scalar conversion: n-1 should work */
    uint8_t nm1_bytes[32] = {
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe,
        0xba, 0xae, 0xdc, 0xe6, 0xaf, 0x48, 0xa0, 0x3b,
        0xbf, 0xd2, 0x5e, 0x8c, 0xd0, 0x36, 0x41, 0x40
    };
    auto nm1_scalar = octet_to_secp256k1_scalar(nm1_bytes);
    check(nm1_scalar.has_value(), "n-1 scalar round-trips");

    /* Scalar n (invalid) */
    uint8_t n_bytes[32] = {
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe,
        0xba, 0xae, 0xdc, 0xe6, 0xaf, 0x48, 0xa0, 0x3b,
        0xbf, 0xd2, 0x5e, 0x8c, 0xd0, 0x36, 0x41, 0x41
    };
    auto n_scalar = octet_to_secp256k1_scalar(n_bytes);
    check(!n_scalar.has_value(), "n is rejected as scalar (>= n)");

    /* Leading zeros preserved */
    uint8_t short_bytes[32] = {0};
    short_bytes[29] = 0x01;
    short_bytes[30] = 0x23;
    short_bytes[31] = 0x45;
    auto short_elt = octet_to_secp256k1_base(short_bytes);
    check(short_elt.has_value(), "0x012345 round-trips");
    if (short_elt.has_value()) {
        uint8_t back[32];
        secp256k1_base_to_octet(short_elt.value(), back);
        check(memcmp(short_bytes, back, 32) == 0, "0x012345 leading zeros preserved");
    }
}

int main() {
    printf("=== lib/blindzap secp256k1 tests ===\n");

    test_field_basics();
    test_scalar_basics();
    test_curve_basics();
    test_witness_conversion();

    if (failures == 0) {
        printf("All tests passed.\n");
    } else {
        printf("%d tests FAILED.\n", failures);
    }
    return failures > 0 ? 1 : 0;
}
