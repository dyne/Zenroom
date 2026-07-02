/* Native RPBSch witness builder — complete.
 *
 * Computes all native values for both branches using bridge functions.
 * Produces native Elt values and byte arrays matching circuit expectations.
 * Bit decompositions provided in both LE (range check) and BE (SHA) forms. */

#ifndef NIWI_RPBSCH_WITNESS_BUILDER_H
#define NIWI_RPBSCH_WITNESS_BUILDER_H

#include <cstddef>
#include <cstdint>
#include <cstring>

#include "secp256k1/secp256k1_field.h"
#include "secp256k1/secp256k1_curve.h"
#include "secp256k1/secp256k1_scalar.h"
#include "secp256k1/secp256k1_witness.h"
#include "pbsch_commitment.h"
#include "circuits/bip340_witness_bridge.h"
#include "circuits/rpbsch_ec_bridge.h"

namespace niwi {

template <class EC, class ScalarField>
class RpbschWitnessBuilder {
  using Field = typename EC::Field;
  using Elt   = typename Field::Elt;
  using Nat   = typename Field::N;
  static constexpr size_t kBits = EC::kBits;
  static constexpr uint8_t kScalarN[32] = {
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe,
    0xba, 0xae, 0xdc, 0xe6, 0xaf, 0x48, 0xa0, 0x3b,
    0xbf, 0xd2, 0x5e, 0x8c, 0xd0, 0x36, 0x41, 0x41
  };
  static constexpr uint8_t kGeneratorX[32] = {
    0x79, 0xbe, 0x66, 0x7e, 0xf9, 0xdc, 0xbb, 0xac,
    0x55, 0xa0, 0x62, 0x95, 0xce, 0x87, 0x0b, 0x07,
    0x02, 0x9b, 0xfc, 0xdb, 0x2d, 0xce, 0x28, 0xd9,
    0x59, 0xf2, 0x81, 0x5b, 0x16, 0xf8, 0x17, 0x98
  };
  static constexpr uint8_t kGeneratorY[32] = {
    0x48, 0x3a, 0xda, 0x77, 0x26, 0xa3, 0xc4, 0x65,
    0x5d, 0xa4, 0xfb, 0xfc, 0x0e, 0x11, 0x08, 0xa8,
    0xfd, 0x17, 0xb4, 0x48, 0xa6, 0x85, 0x54, 0x19,
    0x9c, 0x47, 0xd0, 0x8f, 0xfb, 0x10, 0xd4, 0xb8
  };

 public:
  struct Statement {
    uint8_t X[32], Xp[32];     /* x-only public keys */
    uint8_t C[33], S[33];      /* compressed Pedersen points */
  };

  struct Branch1 {
    uint8_t  X_y[32], R[32], R_y[32];
    uint8_t  Rp[32], Rp_y[32];      /* R' = R + αG + βX */
    uint8_t  T[33], T_y[32];        /* T = αG + βX */
    Elt alpha, beta, m, r_C;
    Elt c_scalar;
    uint8_t  e_hash[32];            /* Hq(R'_x, X_x, m) before β */
    int      overflow;              /* 0 or 1 for mod n */
    uint8_t  C_y[32], H_x[32], H_y[32];

    /* LE bits (range checks) */
    Elt m_bits[kBits], r_C_bits[kBits], alpha_bits[kBits], beta_bits[kBits];
    Elt c_bits[kBits], Rp_bits[kBits], X_bits[kBits];

    /* BE bits (SHA input) */
    Elt Rp_sha[kBits], X_sha[kBits], m_sha[kBits];
    Elt m_msg[256];                 /* 32-byte message as MSB-first bits */
  };

  struct Branch2 {
    Elt nu_u, nu_u_prime, nu_s, nu_inv, r_S;
    uint8_t S_y[32], H_x[32], H_y[32];
    uint8_t sig0[64], sig1[64];
    uint8_t msg0[32], msg1[32];

    Elt nu_u_bits[kBits], nu_up_bits[kBits], nu_s_bits[kBits];
    Elt nu_u_sha[kBits], nu_up_sha[kBits], nu_s_sha[kBits];
    Elt msg0_bits[256], msg1_bits[256];
  };

  RpbschWitnessBuilder(const Field& F, const EC& ec, const ScalarField& Fn)
      : f_(F), ec_(ec), fn_(Fn) {}

  bool build_branch1(const uint8_t X[32],  const uint8_t Xp[32],
                     const uint8_t m_bytes[32],
                     const uint8_t alpha_bytes[32],
                     const uint8_t beta_bytes[32],
                     const uint8_t rho_bytes[32],
                     const uint8_t R_x[32],
                     Statement& stmt, Branch1& b1) {
    memcpy(stmt.X, X, 32); memcpy(stmt.Xp, Xp, 32);

    /* ---- Lift X ---- */
    if (niwi_bip340_lift_x(X, b1.X_y) != 0) return false;

    /* ---- Lift R ---- */
    memcpy(b1.R, R_x, 32);
    if (niwi_bip340_lift_x(R_x, b1.R_y) != 0) return false;

    /* ---- H generator ---- */
    if (niwi_pbsch_pedersen_h(b1.H_x) != 0) return false;
    if (niwi_bip340_lift_x(b1.H_x, b1.H_y) != 0) return false;

    /* ---- Scalars ---- */
    if (!scalar_bytes_valid(m_bytes) || !scalar_bytes_valid(alpha_bytes) ||
        !scalar_bytes_valid(beta_bytes) || !scalar_bytes_valid(rho_bytes))
      return false;
    b1.m     = scalar_bytes_to_base_elt(m_bytes);
    b1.alpha = scalar_bytes_to_base_elt(alpha_bytes);
    b1.beta  = scalar_bytes_to_base_elt(beta_bytes);
    b1.r_C   = scalar_bytes_to_base_elt(rho_bytes);

    /* ---- C = m·G + r_C·H ---- */
    if (niwi_pbsch_pedersen_commit(m_bytes, rho_bytes, stmt.C) != 0)
        return false;
    if (niwi_rpbsch_decompress(stmt.C + 1, stmt.C[0], b1.C_y) != 0)
        return false;

    /* ---- T = α·G + β·X ---- */
    {
        uint8_t aGx[32], aGy[32];
        if (niwi_rpbsch_ec_mul(kGeneratorX, kGeneratorY, alpha_bytes, aGx, aGy) != 0)
            return false;
        uint8_t bXx[32], bXy[32];
        if (niwi_rpbsch_ec_mul(X, b1.X_y, beta_bytes, bXx, bXy) != 0)
            return false;
        uint8_t Tx[32], Ty[32];
        if (niwi_rpbsch_ec_add(aGx, aGy, bXx, bXy, Tx, Ty) != 0)
            return false;
        b1.T[0] = Ty[31] & 1 ? 0x03 : 0x02;
        memcpy(b1.T + 1, Tx, 32);
        memcpy(b1.T_y, Ty, 32);
    }

    /* ---- R' = R + T ---- */
    {
        uint8_t Rp_x[32], Rp_y[32];
        if (niwi_rpbsch_ec_add(b1.R, b1.R_y, b1.T + 1, b1.T_y,
                                Rp_x, Rp_y) != 0) return false;
        memcpy(b1.Rp, Rp_x, 32);
        memcpy(b1.Rp_y, Rp_y, 32);
    }

    /* ---- e = Hq(R'_x, X_x, m) ---- */
    {
        uint8_t sha_tag[32];
        niwi_bip340_sha256((const uint8_t *)"BIP0340/challenge", 17, sha_tag);
        uint8_t pre[160];
        memcpy(pre, sha_tag, 32); memcpy(pre+32, sha_tag, 32);
        memcpy(pre+64, b1.Rp, 32);
        memcpy(pre+96, X, 32);
        memcpy(pre+128, m_bytes, 32);
        niwi_bip340_sha256(pre, 160, b1.e_hash);
    }

    /* ---- c = e + β mod n ---- */
    {
        if (!base_bytes_valid(b1.e_hash)) return false;
        uint8_t sum[33], c_bytes[32];
        add_be32_33(b1.e_hash, beta_bytes, sum);
        uint8_t two_n[33];
        double_n(two_n);
        if (cmp_be33(sum, two_n) >= 0) return false;  /* not representable by boolean overflow */
        b1.overflow = cmp_be33_n(sum) >= 0 ? 1 : 0;
        if (b1.overflow) {
            sub_n_from_be33(sum);
        }
        if (sum[0] != 0 || !scalar_bytes_valid(sum + 1)) return false;
        memcpy(c_bytes, sum + 1, 32);
        b1.c_scalar = scalar_bytes_to_base_elt(c_bytes);
    }

    /* ---- Bit decompositions ---- */
    compute_bits_le(b1.m,     b1.m_bits);
    compute_bits_le(b1.r_C,   b1.r_C_bits);
    compute_bits_le(b1.alpha, b1.alpha_bits);
    compute_bits_le(b1.beta,  b1.beta_bits);
    compute_bits_le(b1.c_scalar, b1.c_bits);
    compute_bits_le(base_bytes_to_elt(b1.Rp), b1.Rp_bits);
    compute_bits_le(base_bytes_to_elt(X), b1.X_bits);
    /* BE reversals */
    le_to_be(b1.m_bits,    b1.m_sha);
    le_to_be(b1.Rp_bits,   b1.Rp_sha);
    le_to_be(b1.X_bits,    b1.X_sha);
    /* m message bits for SHA (MSB-first per byte) */
    for (size_t i = 0; i < 32; ++i)
        for (size_t b = 0; b < 8; ++b)
            b1.m_msg[i*8 + b] = f_.of_scalar((m_bytes[i] >> (7-b)) & 1);

    (void)stmt.Xp; /* X' not used in branch 1 */
    return true;
  }

  bool build_branch2(const uint8_t X[32],  const uint8_t Xp[32],
                     const uint8_t sig0[64], const uint8_t sig1[64],
                     const uint8_t nu_u_bytes[32],
                     const uint8_t nu_up_bytes[32],
                     const uint8_t nu_s_bytes[32],
                     const uint8_t rho_bytes[32],
                     Statement& stmt, Branch2& b2) {
    memcpy(stmt.X, X, 32); memcpy(stmt.Xp, Xp, 32);

    /* ν scalars */
    if (!scalar_bytes_valid(nu_u_bytes) || !scalar_bytes_valid(nu_up_bytes) ||
        !scalar_bytes_valid(nu_s_bytes) || !scalar_bytes_valid(rho_bytes))
      return false;
    b2.nu_u       = scalar_bytes_to_base_elt(nu_u_bytes);
    b2.nu_u_prime = scalar_bytes_to_base_elt(nu_up_bytes);
    b2.nu_s       = scalar_bytes_to_base_elt(nu_s_bytes);
    b2.r_S        = scalar_bytes_to_base_elt(rho_bytes);

    /* ν_u ≠ ν_u': compute inverse in scalar field */
    {
        auto u  = fn_.to_montgomery(f_.from_montgomery(b2.nu_u));
        auto up = fn_.to_montgomery(f_.from_montgomery(b2.nu_u_prime));
        auto diff = fn_.subf(u, up);
        /* If diff == 0, these are equal — reject */
        if (diff == fn_.zero()) return false;
        auto inv = diff; fn_.invert(inv);
        b2.nu_inv = f_.to_montgomery(fn_.from_montgomery(inv));
    }

    /* H generator */
    if (niwi_pbsch_pedersen_h(b2.H_x) != 0) return false;
    if (niwi_bip340_lift_x(b2.H_x, b2.H_y) != 0) return false;

    /* S = ν_s·G + r_S·H */
    if (niwi_pbsch_pedersen_commit(nu_s_bytes, rho_bytes, stmt.S) != 0)
        return false;
    if (niwi_rpbsch_decompress(stmt.S + 1, stmt.S[0], b2.S_y) != 0)
        return false;

    /* BIP-340 signatures */
    memcpy(b2.sig0, sig0, 64);
    memcpy(b2.sig1, sig1, 64);

    /* msg0 = SHA-256(ν_s || ν_u), msg1 = SHA-256(ν_s || ν_u') */
    {
        uint8_t buf[64];
        memcpy(buf, nu_s_bytes, 32);
        memcpy(buf + 32, nu_u_bytes, 32);
        niwi_bip340_sha256(buf, 64, b2.msg0);
        memcpy(buf + 32, nu_up_bytes, 32);
        niwi_bip340_sha256(buf, 64, b2.msg1);
    }

    /* Bit decompositions */
    compute_bits_le(b2.nu_u,       b2.nu_u_bits);
    compute_bits_le(b2.nu_u_prime, b2.nu_up_bits);
    compute_bits_le(b2.nu_s,       b2.nu_s_bits);
    le_to_be(b2.nu_u_bits,  b2.nu_u_sha);
    le_to_be(b2.nu_up_bits, b2.nu_up_sha);
    le_to_be(b2.nu_s_bits,  b2.nu_s_sha);
    /* Message bits */
    for (size_t i = 0; i < 32; ++i) {
        for (size_t b = 0; b < 8; ++b) {
            b2.msg0_bits[i*8+b] = f_.of_scalar((b2.msg0[i]>>(7-b))&1);
            b2.msg1_bits[i*8+b] = f_.of_scalar((b2.msg1[i]>>(7-b))&1);
        }
    }

    return true;
  }

  /* Public helper for tests */
  Elt elt_from_be32(const uint8_t b[32]) const {
      return base_bytes_to_elt(b);
  }

 private:
  const Field& f_;
  const EC& ec_;
  const ScalarField& fn_;

  static bool bytes_less_be32(const uint8_t a[32], const uint8_t b[32]) {
      return memcmp(a, b, 32) < 0;
  }

  static bool scalar_bytes_valid(const uint8_t b[32]) {
      return bytes_less_be32(b, kScalarN);
  }

  bool base_bytes_valid(const uint8_t b[32]) const {
      return octet_to_secp256k1_base(b).has_value();
  }

  Elt base_bytes_to_elt(const uint8_t b[32]) const {
      auto v = octet_to_secp256k1_base(b);
      return v.value();
  }

  Elt scalar_bytes_to_base_elt(const uint8_t b[32]) const {
      uint8_t le[32];
      for (int i = 0; i < 32; ++i) le[i] = b[31 - i];
      return f_.to_montgomery(Nat::of_bytes(le));
  }

  static void add_be32_33(const uint8_t a[32], const uint8_t b[32],
                          uint8_t out[33]) {
      unsigned carry = 0;
      for (int i = 31; i >= 0; --i) {
          unsigned s = (unsigned)a[i] + (unsigned)b[i] + carry;
          out[i + 1] = (uint8_t)(s & 0xffu);
          carry = s >> 8;
      }
      out[0] = (uint8_t)carry;
  }

  static int cmp_be33(const uint8_t a[33], const uint8_t b[33]) {
      return memcmp(a, b, 33);
  }

  static int cmp_be33_n(const uint8_t a[33]) {
      uint8_t n33[33] = {0};
      memcpy(n33 + 1, kScalarN, 32);
      return cmp_be33(a, n33);
  }

  static void sub_n_from_be33(uint8_t a[33]) {
      unsigned borrow = 0;
      for (int i = 32; i >= 1; --i) {
          unsigned sub = (unsigned)kScalarN[i - 1] + borrow;
          if ((unsigned)a[i] >= sub) {
              a[i] = (uint8_t)((unsigned)a[i] - sub);
              borrow = 0;
          } else {
              a[i] = (uint8_t)(256u + (unsigned)a[i] - sub);
              borrow = 1;
          }
      }
      a[0] = (uint8_t)((unsigned)a[0] - borrow);
  }

  static void double_n(uint8_t out[33]) {
      unsigned carry = 0;
      for (int i = 31; i >= 0; --i) {
          unsigned v = ((unsigned)kScalarN[i] << 1) | carry;
          out[i + 1] = (uint8_t)(v & 0xffu);
          carry = v >> 8;
      }
      out[0] = (uint8_t)carry;
  }

  void compute_bits_le(const Elt& e, Elt* out) const {
      Nat n = f_.from_montgomery(e);
      for (size_t i = 0; i < kBits; ++i)
          out[i] = f_.of_scalar(n.bit(i) ? 1 : 0);
  }

  void le_to_be(const Elt* le, Elt* be) const {
      for (size_t i = 0; i < kBits; ++i) be[i] = le[kBits - 1 - i];
  }
};

}  // namespace niwi

#endif  // NIWI_RPBSCH_WITNESS_BUILDER_H
