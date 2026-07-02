/* Native BIP-340 witness tests against vendored vectors. */

#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

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

#include "circuits/bip340_witness_bridge.h"
#include "circuits/bip340_witness.h"
#include "secp256k1/secp256k1_curve.h"
#include "secp256k1/secp256k1_field.h"
#include "secp256k1/secp256k1_scalar.h"

using Field = niwi::FpSecp256k1Base;
using EC = niwi::Secp256k1;
using Scalar = niwi::FpSecp256k1Scalar;

static int failures = 0;

struct Vector {
    std::string index;
    std::string pk;
    std::string msg;
    std::string sig;
    std::string result;
};

static void check(bool cond, const char *msg) {
    if (!cond) {
        fprintf(stderr, "FAIL: %s\n", msg);
        failures++;
    }
}

static int hexval(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

static bool hex_to_bytes(const std::string& hex, uint8_t *out, size_t out_len) {
    if (hex.size() != out_len * 2) return false;
    for (size_t i = 0; i < out_len; ++i) {
        int hi = hexval(hex[2 * i]);
        int lo = hexval(hex[2 * i + 1]);
        if (hi < 0 || lo < 0) return false;
        out[i] = (uint8_t)((hi << 4) | lo);
    }
    return true;
}

static std::vector<std::string> split_csv_line(const std::string& line) {
    std::vector<std::string> cols;
    std::stringstream ss(line);
    std::string col;
    while (std::getline(ss, col, ',')) cols.push_back(col);
    if (!line.empty() && line.back() == ',') cols.emplace_back();
    return cols;
}

static std::string dirname_of(const char *path) {
    std::string p(path ? path : "");
    size_t pos = p.find_last_of('/');
    if (pos == std::string::npos) return ".";
    if (pos == 0) return "/";
    return p.substr(0, pos);
}

static std::vector<Vector> load_vectors(const char *argv0) {
    std::string exe_dir = dirname_of(argv0);
    std::string paths[] = {
        exe_dir + "/../../test/vectors/bip340_test_vectors.csv",
        "../../test/vectors/bip340_test_vectors.csv",
        "test/vectors/bip340_test_vectors.csv",
    };
    std::ifstream in;
    for (const std::string& path : paths) {
        in.open(path);
        if (in) break;
        in.clear();
    }
    if (!in) {
        fprintf(stderr, "FAIL: could not open vendored BIP-340 vectors\n");
        failures++;
        return {};
    }

    std::string line;
    std::getline(in, line); /* header */
    std::vector<Vector> vectors;
    while (std::getline(in, line)) {
        auto c = split_csv_line(line);
        if (c.size() < 7) continue;
        vectors.push_back(Vector{c[0], c[2], c[4], c[5], c[6]});
    }
    return vectors;
}

static bool is_zero_elt(const Field::Elt& e) {
    return e == niwi::secp256k1_base.zero();
}

static bool bit_is_boolean(const Field::Elt& e) {
    return e == niwi::secp256k1_base.zero() ||
           e == niwi::secp256k1_base.one();
}

static void check_scalar_binding(const niwi::Bip340Witness<EC, Scalar>& w) {
    auto e_nat = niwi::secp256k1_base.from_montgomery(w.e_challenge_);
    auto en_nat = niwi::secp256k1_base.from_montgomery(w.e_neg_);
    auto e = niwi::secp256k1_scalar.to_montgomery(e_nat);
    auto en = niwi::secp256k1_scalar.to_montgomery(en_nat);
    auto sum = niwi::secp256k1_scalar.addf(e, en);
    check(sum == niwi::secp256k1_scalar.zero(), "e_challenge + e_neg == n");
}

static void check_nontrivial_witness(const niwi::Bip340Witness<EC, Scalar>& w) {
    bool padded_nonzero = false;
    for (size_t i = 0; i < sizeof(w.sha_padded); ++i)
        padded_nonzero |= w.sha_padded[i] != 0;
    check(padded_nonzero, "SHA padded input is non-trivial");

    bool h_nonzero = false;
    for (size_t i = 0; i < 8; ++i) h_nonzero |= w.sha_h1[2][i] != 0;
    check(h_nonzero, "SHA final H1 is non-trivial");

    bool pre_nonzero = false;
    for (size_t i = 0; i < 8; ++i) pre_nonzero |= !is_zero_elt(w.pre_[i]);
    check(pre_nonzero, "precomputed table is non-trivial");
}

static void check_bits_and_parity(const niwi::Bip340Witness<EC, Scalar>& w) {
    for (size_t i = 0; i < 256; ++i) {
        check(bit_is_boolean(w.s_bits_[i]), "s bit is boolean");
        check(bit_is_boolean(w.e_bits_[i]), "e bit is boolean");
        check(bit_is_boolean(w.e_neg_bits_[i]), "e_neg bit is boolean");
        check(bit_is_boolean(w.pk_x_bits_[i]), "pk_x bit is boolean");
        check(bit_is_boolean(w.R_x_bits_[i]), "R_x bit is boolean");
        check(bit_is_boolean(w.msg_bits_[i]), "message bit is boolean");
    }
    check(w.ry_lsb_[0] == niwi::secp256k1_base.zero(), "R_y is even");
    check(w.py_lsb_[0] == niwi::secp256k1_base.zero(), "pk_y is even");
}

static void test_valid_vector(const Vector& v) {
    uint8_t pk[32], msg[32], sig[64], R[32], s[32], y[32];
    check(hex_to_bytes(v.pk, pk, sizeof(pk)), "public key hex parses");
    check(hex_to_bytes(v.msg, msg, sizeof(msg)), "message hex parses");
    check(hex_to_bytes(v.sig, sig, sizeof(sig)), "signature hex parses");
    memcpy(R, sig, 32);
    memcpy(s, sig + 32, 32);

    check(niwi_bip340_lift_x(pk, y) == 0, "lift_x succeeds for valid pk");
    check((y[31] & 1) == 0, "lift_x returns even y");

    niwi::Bip340Witness<EC, Scalar> w(niwi::secp256k1_base,
                                       niwi::secp256k1,
                                       niwi::secp256k1_scalar);
    check(w.compute(pk, R, s, msg), "valid vector computes witness");
    check(w.sha_num_blocks == 3, "tagged hash uses three SHA blocks");
    check_scalar_binding(w);
    check_nontrivial_witness(w);
    check_bits_and_parity(w);
}

static void test_invalid_wrong_message(const Vector& v) {
    uint8_t pk[32], msg[32], sig[64], R[32], s[32];
    check(hex_to_bytes(v.pk, pk, sizeof(pk)), "public key hex parses");
    check(hex_to_bytes(v.msg, msg, sizeof(msg)), "message hex parses");
    check(hex_to_bytes(v.sig, sig, sizeof(sig)), "signature hex parses");
    memcpy(R, sig, 32);
    memcpy(s, sig + 32, 32);
    msg[31] ^= 1;

    niwi::Bip340Witness<EC, Scalar> w(niwi::secp256k1_base,
                                       niwi::secp256k1,
                                       niwi::secp256k1_scalar);
    check(!w.compute(pk, R, s, msg), "wrong message rejects witness");
}

int main(int argc, char **argv) {
    (void)argc;
    auto vectors = load_vectors(argv[0]);
    check(vectors.size() >= 2, "loaded at least two BIP-340 vectors");
    if (vectors.size() >= 2) {
        check(vectors[0].result == "TRUE", "vector 0 is valid");
        check(vectors[1].result == "TRUE", "vector 1 is valid");
        test_valid_vector(vectors[0]);
        test_valid_vector(vectors[1]);
        test_invalid_wrong_message(vectors[0]);
    }

    if (failures) {
        fprintf(stderr, "%d BIP-340 witness test(s) failed\n", failures);
        return 1;
    }
    printf("=== lib/niwi BIP-340 witness tests passed ===\n");
    return 0;
}
