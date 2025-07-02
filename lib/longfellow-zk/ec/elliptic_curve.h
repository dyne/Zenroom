// Copyright 2024 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef PRIVACY_PROOFS_ZK_LIB_EC_ELLIPTIC_CURVE_H_
#define PRIVACY_PROOFS_ZK_LIB_EC_ELLIPTIC_CURVE_H_

#include <cstddef>
#include <cstdint>

#include "algebra/nat.h"
#include "util/panic.h"

namespace proofs {
// Elliptic curve class that supports basic operations such as addition,
// doubling. The algorithms are described in
// https://eprint.iacr.org/2015/1060.pdf.
// The const Field parameter is meant as a type check to keep different
// elliptic curves from interacting. The convention is to use the last 5
// digits of the coordinate field prime in base-10 to name a curve.
// The kN template parameter describes the number of bits in the curve
// order, e.g., to handle curves like P-521, K-283, etc.
template <class Field_, size_t W, size_t kN>
class EllipticCurve {
 public:
  using Field = Field_;
  using Elt = typename Field::Elt;
  using N = Nat<W>;

  static constexpr const size_t kBits = kN; /* # bits in size of the group */

  const Field& f_;
  Elt a_;
  Elt b_;
  Elt gx_, gy_, gz_;  // generator of the group
  const Elt k2, k3, k8, k3b, k9b, k24b;

  struct ECPoint {
    Elt x;
    Elt y;
    Elt z;

    ECPoint() = default;
    ECPoint(const Elt& x, const Elt& y, const Elt& z) : x(x), y(y), z(z) {}
  };

  EllipticCurve(const Elt& a, const Elt& b, const Elt& gX, const Elt& gY,
                const Field_& F)
      : f_(F),
        a_(a),
        b_(b),
        gx_(gX),
        gy_(gY),
        gz_(F.one()),
        k2(F.of_scalar(2)),
        k3(F.of_scalar(3)),
        k8(F.of_scalar(8)),
        k3b(F.mulf(k3, b_)),
        k9b(F.mulf(F.of_scalar(9), b_)),
        k24b(F.mulf(F.of_scalar(24), b_)) {
    is_minus_3_a_ = (a_ == F.negf(k3));
    is_zero_a_ = (a_ == F.zero());
  }

  // This equality method makes no assumptions about whether the inputs
  // are valid points on the curve. Just verifying cross-mult is not
  // enough if one of the points is invalid. This method is not constant
  // time and can return early if any point is infinity.
  bool equal(const ECPoint& p, const ECPoint& q) const {
    // handle inf point, then point equality, and finally projective eq
    if (q.x == f_.zero() && q.z == f_.zero() && q.y != f_.zero() &&
        p.x == f_.zero() && p.z == f_.zero() && p.y != f_.zero()) {
      return true;
    }
    if (q.x == p.x && q.z == p.z && q.y == p.y) {
      return true;
    }

    return (f_.mulf(p.x, q.z) == f_.mulf(q.x, p.z) &&
            f_.mulf(p.y, q.z) == f_.mulf(q.y, p.z));
  }

  // This method assumes a point is either zero or has z=1 coordinate,
  // so it does not implement the full mathematical notion of Jacobian-form
  // ec point.
  bool is_on_curve(const ECPoint& p) const {
    if (equal(p, zero())) {
      return true;
    }
    // Do not support Jacobian coordinate with z != 1"
    if (p.z != f_.one()) {
      return false;
    }
    return is_on_curve(p.x, p.y);
  }

  // This caller of the constructor must first verify that (x,y) is on the
  // curve using the isOnCurve() method.
  ECPoint point(const Elt& x, const Elt& y) const {
    ECPoint p(x, y, f_.one());
    check(is_on_curve(p), "Invalid curve point");
    return p;
  }

  void normalize(ECPoint& p) const {
    if (p.z == f_.zero()) return;
    f_.invert(p.z);
    f_.mul(p.x, p.z);
    f_.mul(p.y, p.z);
    p.z = f_.one();
  }

  void addE(ECPoint& p3, const ECPoint& p2) const {
    addE(p3.x, p3.y, p3.z, p3.x, p3.y, p3.z, p2.x, p2.y, p2.z);
  }

  void doubleE(ECPoint& p3) const {
    doubleE(p3.x, p3.y, p3.z, p3.x, p3.y, p3.z);
  }

  // Functional interface.
  ECPoint addEf(ECPoint p1, const ECPoint& p2) const {
    addE(p1, p2);
    return p1;
  }

  ECPoint doubleEf(ECPoint p1) const {
    doubleE(p1);
    return p1;
  }

  // Computes the elliptic curve point p * scalar.
  // This method is not constant time, but that is not necessary in the current
  // zk implementation.
  ECPoint scalar_multf(const ECPoint& p, const N& scalar) const {
    ECPoint x = p;
    ECPoint p3 = zero();
    for (size_t d = 0; d < N::kLimbs; ++d) {
      auto nd = scalar.limb_[d];
      for (size_t i = 0; i < N::kBitsPerLimb; ++i) {
        if (nd & 1) {
          addE(p3, x);
        }
        doubleE(x);
        nd >>= 1;
      }
    }
    return p3;
  }

  // Computes the multi-scalar elliptic curve point multiplication.
  // Input: p1, p2, ..., pn, and scalars s1, s2, ..., sn
  // Output: p1 * s1 + p2 * s2 + ... + pn * sn
  // This method is not a constant time operation.
  ECPoint scalar_multf(size_t n, ECPoint p[/*n*/], N scalar[/*n*/]) const {
    if (n == 0) {
      return zero();
    } else if (n == 1) {
      return scalar_multf(p[0], scalar[0]);
    } else {
      return bos_coster(n, p, scalar);
    }
  }

  ECPoint zero() const { return ECPoint(f_.zero(), f_.one(), f_.zero()); }
  ECPoint generator() const { return ECPoint(gx_, gy_, gz_); }

  // Check whether Y^2 = X^3 + aX + b.
  bool is_on_curve(const Elt& X, const Elt& Y) const {
    Elt left = f_.mulf(Y, Y);
    Elt X3 = f_.mulf(X, f_.mulf(X, X));
    Elt right = f_.addf(f_.addf(X3, f_.mulf(a_, X)), b_);
    return left == right;
  }

  void addE(Elt& X3o, Elt& Y3o, Elt& Z3o, const Elt& X1, const Elt& Y1,
            const Elt& Z1, const Elt& X2, const Elt& Y2, const Elt& Z2) const {
    // Optimized special cases.
    if (is_zero_a_) return addEZeroA(X3o, Y3o, Z3o, X1, Y1, Z1, X2, Y2, Z2);
    if (is_minus_3_a_)
      return addEMinus3A(X3o, Y3o, Z3o, X1, Y1, Z1, X2, Y2, Z2);

    /*
    Source: 1998 Cohen–Miyaji–Ono "Efficient elliptic curve exponentiation using
    mixed coordinates", formula (3), plus common-subexpression elimination.
    These equations are taken from the Hyperelliptic curve formula database.
    This could have special short-cuts for addition with inf and self-addition,
    which speeds up all multi-exponentiation computations that involve a lot of
    small exponents.
    */
    if (X1 == f_.zero() && Z1 == f_.zero()) {
      X3o = X2;
      Y3o = Y2;
      Z3o = Z2;
      return;
    }

    if (X2 == f_.zero() && Z2 == f_.zero()) {
      X3o = X1;
      Y3o = Y1;
      Z3o = Z1;
      return;
    }

    Elt Y1Z2 = f_.mulf(Y1, Z2);
    Elt X1Z2 = f_.mulf(X1, Z2);
    Elt u = f_.subf(f_.mulf(Y2, Z1), Y1Z2);
    Elt v = f_.subf(f_.mulf(X2, Z1), X1Z2);
    if (u == f_.zero()) {
      doubleE(X3o, Y3o, Z3o, X1, Y1, Z1);
      return;
      // Self addition, invoke Double method.
    }
    /* This check occurs after the u check.
    If u!=0, but v=0, then the points are inverses.
    */
    if (v == f_.zero()) {
      X3o = f_.zero();
      Y3o = f_.one();
      Z3o = f_.zero();
      return;
    }

    Elt Z1Z2 = f_.mulf(Z1, Z2);
    Elt uu = f_.mulf(u, u);
    Elt vv = f_.mulf(v, v);
    Elt vvv = f_.mulf(v, vv);
    Elt R = f_.mulf(vv, X1Z2);
    Elt A = f_.subf(f_.subf(f_.mulf(uu, Z1Z2), vvv), f_.mulf(k2, R));
    Elt X3 = f_.mulf(v, A);
    Elt Y3 = f_.subf(f_.mulf(u, f_.subf(R, A)), f_.mulf(vvv, Y1Z2));
    Elt Z3 = f_.mulf(vvv, Z1Z2);

    X3o = X3;
    Y3o = Y3;
    Z3o = Z3;
  }

  void doubleE(Elt& X3o, Elt& Y3o, Elt& Z3o, const Elt& X, const Elt& Y,
               const Elt& Z) const {
    // Optimized special cases.
    if (is_zero_a_) return doubleEZeroA(X3o, Y3o, Z3o, X, Y, Z);
    if (is_minus_3_a_) return doubleEMinus3A(X3o, Y3o, Z3o, X, Y, Z);

    /*
    // 1998 Cohen–Miyaji–Ono "Efficient elliptic curve exponentiation using
    mixed coordinates", formula (4), This version of the double formula trades
    general mults for mults by 2,4,8 which can be implemented with additions.
    This results in savings of 200ns on double.
    */
    if (X == f_.zero() && Z == f_.zero()) {
      X3o = X;
      Y3o = f_.one();
      Z3o = Z;
      return;
    }

    Elt Z2 = f_.mulf(Z, Z);
    Elt X2 = f_.mulf(X, X);
    Elt X2_3 = f_.addf(f_.addf(X2, X2), X2);
    Elt s = f_.mulf(Y, Z);
    Elt ss = f_.mulf(s, s);
    Elt sss = f_.mulf(s, ss);
    Elt sss_2 = f_.addf(sss, sss);
    Elt w = f_.addf(f_.mulf(a_, Z2), X2_3);
    Elt R = f_.mulf(Y, s);
    Elt sss_4 = f_.addf(sss_2, sss_2);
    Elt B = f_.mulf(X, R);
    Elt sss_8 = f_.addf(sss_4, sss_4);
    Elt B_2 = f_.addf(B, B);
    Elt R2 = f_.mulf(R, R);
    Elt B_4 = f_.addf(B_2, B_2);
    Elt B_8 = f_.addf(B_4, B_4);
    Elt w2 = f_.mulf(w, w);
    Elt h = f_.subf(w2, B_8);
    Elt s_2 = f_.addf(s, s);
    Elt X3 = f_.mulf(h, s_2);
    Elt R2_2 = f_.addf(R2, R2);
    Elt R2_4 = f_.addf(R2_2, R2_2);
    Elt R2_8 = f_.addf(R2_4, R2_4);
    Elt Y3 = f_.subf(f_.mulf(w, f_.subf(B_4, h)), R2_8);
    Elt Z3 = sss_8;

    X3o = X3;
    Y3o = Y3;
    Z3o = Z3;
  }

 private:
  /* From Algorithm 7: Complete, projective point addition for prime order
    j-invariant 0 short Weierstrass curves E/Fq : y^2 = x^3 + b.

    X3 = (X1 Y2 + X2 Y1)(Y1 Y2 - 3b Z1 Z2) - 3b(Y1 Z2 + Y2 Z1)(X1 Z2 + X2 Z1)
    Y3 = (Y1 Y2 + 3b Z1 Z2)(Y1 Y2 - 3b Z1 Z2) + 9b X1 X2 (X1 Z2 + X2 Z1)
    Z3 = (Y1 Z2 + Y2 Z1)(Y1 Y2 + 3b Z1 Z2) + 3 X1 X2(X1 Y2 + X2 Y1)
   */
  void addEZeroA(Elt& X3o, Elt& Y3o, Elt& Z3o, const Elt& X1, const Elt& Y1,
                 const Elt& Z1, const Elt& X2, const Elt& Y2,
                 const Elt& Z2) const {
    Elt t0 = f_.mulf(X2, Y1);
    Elt t1 = f_.mulf(X1, Y2);
    Elt t2 = f_.addf(t1, t0);
    Elt t3 = f_.mulf(Y1, Y2);
    Elt t4 = f_.mulf(Z1, Z2);
    Elt t5 = f_.mulf(Y1, Z2);
    Elt t6 = f_.mulf(Y2, Z1);
    Elt t7 = f_.addf(t5, t6);
    Elt t8 = f_.mulf(X1, Z2);
    Elt t9 = f_.mulf(X2, Z1);
    Elt t10 = f_.addf(t8, t9);
    Elt t11 = f_.mulf(X1, X2);
    Elt t12 = f_.mulf(k3b, t4);
    Elt t13 = f_.addf(t3, t12);
    Elt t14 = f_.subf(t3, t12);

    X3o = f_.subf(f_.mulf(t2, t14), f_.mulf(k3b, f_.mulf(t7, t10)));
    Y3o = f_.addf(f_.mulf(t13, t14), f_.mulf(k9b, f_.mulf(t11, t10)));
    Z3o = f_.addf(f_.mulf(t7, t13), f_.mulf(k3, f_.mulf(t11, t2)));
  }

  /*Algorithm 4: Complete, projective point addition for prime order short
   * Weierstrass curves E/Fq : y^2 = x^33 + ax + b with a = −3.
   */
  void addEMinus3A(Elt& X3o, Elt& Y3o, Elt& Z3o, const Elt& X1, const Elt& Y1,
                   const Elt& Z1, const Elt& X2, const Elt& Y2,
                   const Elt& Z2) const {
    Elt t0 = f_.mulf(X1, X2);
    Elt t1 = f_.mulf(Y1, Y2);
    Elt t2 = f_.mulf(Z1, Z2);
    Elt t3 = f_.addf(X1, Y1);
    Elt t4 = f_.addf(X2, Y2);
    t3 = f_.mulf(t3, t4);
    t4 = f_.addf(t0, t1);
    t3 = f_.subf(t3, t4);
    t4 = f_.addf(Y1, Z1);
    Elt X3 = f_.addf(Y2, Z2);
    t4 = f_.mulf(t4, X3);
    X3 = f_.addf(t1, t2);
    t4 = f_.subf(t4, X3);
    X3 = f_.addf(X1, Z1);
    Elt Y3 = f_.addf(X2, Z2);
    X3 = f_.mulf(X3, Y3);
    Y3 = f_.addf(t0, t2);
    Y3 = f_.subf(X3, Y3);
    Elt Z3 = f_.mulf(b_, t2);
    X3 = f_.subf(Y3, Z3);
    Z3 = f_.addf(X3, X3);
    X3 = f_.addf(X3, Z3);
    Z3 = f_.subf(t1, X3);
    X3 = f_.addf(t1, X3);
    Y3 = f_.mulf(b_, Y3);
    t1 = f_.addf(t2, t2);
    t2 = f_.addf(t1, t2);
    Y3 = f_.subf(Y3, t2);
    Y3 = f_.subf(Y3, t0);
    t1 = f_.addf(Y3, Y3);
    Y3 = f_.addf(t1, Y3);
    t1 = f_.addf(t0, t0);
    t0 = f_.addf(t1, t0);
    t0 = f_.subf(t0, t2);
    t1 = f_.mulf(t4, Y3);
    t2 = f_.mulf(t0, Y3);
    Y3 = f_.mulf(X3, Z3);
    Y3 = f_.addf(Y3, t2);
    X3 = f_.mulf(t3, X3);
    X3 = f_.subf(X3, t1);
    Z3 = f_.mulf(t4, Z3);
    t1 = f_.mulf(t3, t0);
    Z3 = f_.addf(Z3, t1);

    X3o = X3;
    Y3o = Y3;
    Z3o = Z3;
  }

  /* From Algorithm 6: Exception-free point doubling for prime order short
   * Weierstrass curves E/Fq : y^2 = x^3 + ax + b with a = −3.
   */
  void doubleEMinus3A(Elt& X3o, Elt& Y3o, Elt& Z3o, const Elt& X, const Elt& Y,
                      const Elt& Z) const {
    Elt t0 = f_.mulf(X, X);
    Elt t1 = f_.mulf(Y, Y);
    Elt t2 = f_.mulf(Z, Z);
    Elt t3 = f_.mulf(X, Y);
    t3 = f_.addf(t3, t3);
    Elt Z3 = f_.mulf(X, Z);
    Z3 = f_.addf(Z3, Z3);
    Elt Y3 = f_.mulf(b_, t2);
    Y3 = f_.subf(Y3, Z3);
    Elt X3 = f_.addf(Y3, Y3);
    Y3 = f_.addf(X3, Y3);
    X3 = f_.subf(t1, Y3);
    Y3 = f_.addf(t1, Y3);
    Y3 = f_.mulf(X3, Y3);
    X3 = f_.mulf(X3, t3);
    t3 = f_.addf(t2, t2);
    t2 = f_.addf(t2, t3);
    Z3 = f_.mulf(b_, Z3);
    Z3 = f_.subf(Z3, t2);
    Z3 = f_.subf(Z3, t0);
    t3 = f_.addf(Z3, Z3);
    Z3 = f_.addf(Z3, t3);
    t3 = f_.addf(t0, t0);
    t0 = f_.addf(t3, t0);
    t0 = f_.subf(t0, t2);
    t0 = f_.mulf(t0, Z3);
    Y3 = f_.addf(Y3, t0);
    t0 = f_.mulf(Y, Z);
    t0 = f_.addf(t0, t0);
    Z3 = f_.mulf(t0, Z3);
    X3 = f_.subf(X3, Z3);
    Z3 = f_.mulf(t0, t1);
    Z3 = f_.addf(Z3, Z3);
    Z3 = f_.addf(Z3, Z3);

    X3o = X3;
    Y3o = Y3;
    Z3o = Z3;
  }

  /* From  Algorithm 9: Exception-free point doubling for prime order
    j-invariant 0 short Weierstrass curves E/Fq y^2 = x^3 + b

    X3 = 2XY (YY − 9bZZ)
    Y3 = (YY − 9bZZ)(YY + 3bZZ) + 24bYYZZ
    Z3 = 8YYYZ.
  */
  void doubleEZeroA(Elt& X3o, Elt& Y3o, Elt& Z3o, const Elt& X, const Elt& Y,
                    const Elt& Z) const {
    Elt t0 = f_.mulf(X, Y);
    Elt t1 = f_.mulf(Y, Y);
    Elt t2 = f_.mulf(Z, Z);
    Elt t4 = f_.mulf(Y, Z);
    Elt t5 = f_.mulf(k9b, t2);  // 9bZZ
    Elt t6 = f_.subf(t1, t5);   // YY - 9bZZ
    Elt t7 = f_.mulf(k3b, t2);  // 3bZZ
    Elt t8 = f_.addf(t1, t7);   // YY + 3bZZ
    X3o = f_.mulf(k2, f_.mulf(t0, t6));
    Y3o = f_.addf(f_.mulf(t6, t8), f_.mulf(k24b, f_.mulf(t1, t2)));
    Z3o = f_.mulf(k8, f_.mulf(t1, t4));
  }

  //------------------------------------------------------------
  // Multi-exponentiation SUM_i scalarMult(p[i], s[i])

  // We follow the basic strategy outlined in Daniel J. Bernstein,
  // Niels Duif, Tanja Lange, Peter Schwabe, and Bo-Yin Yang,
  // "High-speed high-security signatures",
  // https://eprint.iacr.org/2011/368, where Bernstein et al. credit
  // the method to Bos and Coster via a reference to Peter de Rooij,
  // "Efficient exponentiation using precomputation and vector
  // addition chains", in Eurocrypt ’94.  In my opinion [matteof@]
  // the method of Bernstein et al. is not quite the same as the papers
  // that they reference, but either way we follow Bernstein et al.
  // with a few modifications, and call the method bos_coster() in
  // this file.

  // The basic idea is to keep the list (p[i], s[i]) of pairs
  // (point, scalar) in descending order of scalar, so that s[0]
  // is the maximum.

  // Bernstein's method repeatedly replaces p[0]*s[0]+p[1]*s[1]
  // by p[0]*(s[0]-s[1])+(p[0]+p[1])*s[1], where now the first
  // scalar becomes smaller.  Eventually all the scalars s[i] become
  // 0 for i>=1.

  // For random scalars, one can roughly expect s[0]-s[1] to be
  // about |F|/n, so the method can be expected to set approximately
  // log n scalar bits to zero in each iteration.  However, its worst
  // case is horrific.  E.g., if s[1]=1 and s[0] is O(2**256), the
  // method will require O(2**256) iterations to converge.

  // To avoid this worst-case behavior, we depart from Bernstein and
  // perform either a Bernstein step or a double-and-add step,
  // whichever one decreases s[0] the most.  A double-and-add writes
  // s[0] = 2*a+b and replaces p[0]*s[0] with (2*p[0])*(s[0]/2) *
  // b*p[0], where the second multiplication is trivial because b \in
  // {0,1}.  With this choice, we are guaranteed to eliminate at least
  // one scalar bit per iteration, so the method is no worse than a
  // loop of single scalar multiplications.  Bernstein et al., page
  // 17, are aware of the problem, but they say that doing anything
  // about it is "not worthwhile".  On the other hand, the fix doesn't
  // cost anything either, so may as well do it.  (Bernstein et
  // al. propose a different fix.)

  // For easy access to the largest s[0] and second-largest s[1], we
  // keep the (p[i], s[i]) terms in a heap.  Here, "heap" denotes a
  // variant of the standard heap where the root node H[0] has one
  // child H[1] (as opposed to two children), and every other node i>0
  // has two children H[2*i] and H[2*i+1].  A heap comprises at least
  // two elements H[0] and H[1].  In this way, the two largest scalars
  // are always available directly.

  // The following function is equivalent to assigning (p[i], s[i]) =
  // (tp, ts) followed by restoring heap order.  However, the logic is
  // a bit complicated by our desire to avoid unnecessary copies of
  // large objects (e.g., swap p[i] with a child, followed by another
  // swap of the child with its child.)
  //
  // Warning: tp and ts MUST NOT be references to p[i] and s[i], since
  // the algorithm overwrites the p and s arrays.  This complication
  // ensues because we are trying to avoid unnecessary copies.
  void bury(size_t i, size_t n, ECPoint p[/*n*/], N s[/*n*/], const ECPoint& tp,
            const N& ts) const {
    while (2 * i < n) {
      // at least one child
      size_t cld = 2 * i;
      if (2 * i + 1 < n && s[cld] < s[2 * i + 1]) {
        // right child exists and is larger
        cld = 2 * i + 1;
      }

      if (ts < s[cld]) {
        // I is out of order with CLD.  Bubble CLD up the tree and
        // continue as in BURY(CLD, N, P, S, TP, TS).
        s[i] = s[cld];
        p[i] = p[cld];
        i = cld;
      } else {
        // already in heap order, stop here.
        break;
      }
    }

    p[i] = tp;
    s[i] = ts;
  }

  // bury (p[0], s[0]) to its rightful place in the heap.
  void bury0(size_t n, ECPoint p[/*n*/], N s[/*n*/]) const {
    if (s[0] < s[1]) {
      // equivalent to swap(s[0], s[1]); bury(s[1]);
      // but without the possibly unnecessary assignment of (s,p)[1]
      ECPoint tp = p[0];
      N ts = s[0];
      p[0] = p[1];
      s[0] = s[1];
      bury(1, n, p, s, tp, ts);
    }
  }

  // The main Bernstein/Bos-Coster algorithm.
  ECPoint bos_coster(size_t n, ECPoint p[/*n*/], N s[/*n*/]) const {
    check(n >= 2, "n >= 2");
    ECPoint res = zero();

    // build a heap on [1..n)
    for (size_t i = /*floor*/ (n / 2); i >= 1; --i) {
      // create temporary copies of p[i], s[i], which are passed by
      // const &.
      bury(i, n, p, s, ECPoint(p[i]), N(s[i]));
    }
    // finish the heap on [0..n)
    bury0(n, p, s);

    while (s[0] != /*zero*/ N{}) {
      // ns0 = s[0] - s[1]
      N ns0(s[0]);
      ns0.sub(s[1]);

      // Double-and-add is (locally) better than Bernstein iff s[0]/2
      // < s[0] - s[1], equivalent to s[0] > 2*s[1], equivalent to
      // ns0 = s[0] - s[1] > s[1]:
      if (s[1] < ns0) {
        // res += (s[0] & 1) * p[0]; s[0] /= 2; p[0] *= 2;
        uint64_t lsb = s[0].shiftr(1);
        if (lsb != 0) {
          addE(res, p[0]);
        }
        doubleE(p[0]);
      } else {
        // s[0] -= s[1], p[1] += p[0]
        s[0] = ns0;
        addE(p[1], p[0]);
      }
      bury0(n, p, s);
    }
    return res;
  }

  bool is_zero_a_;
  bool is_minus_3_a_;
};
}  // namespace proofs

#endif  // PRIVACY_PROOFS_ZK_LIB_EC_ELLIPTIC_CURVE_H_
