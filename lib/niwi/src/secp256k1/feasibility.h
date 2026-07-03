/* FFT root feasibility guard for secp256k1.
 *
 * Longfellow/zkcc requires a primitive root of unity ω in an
 * extension field such that ω^N = 1 for N = 2^k with k ≥ 20
 * (to support domain sizes ≥ 2^20 ≈ 1M). The maximum k is
 * v2(|F*|) where F is the extension field.
 *
 * For secp256k1:
 *   p     = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
 *   v2(p-1)   = 1     (p-1 has one factor of 2)
 *   v2(p+1)   = 4     (p+1 = 0x...FC30 = 2^4 × odd)
 *   v2(p^2-1) = 5     (= 1 + 4)
 *
 * Maximum FFT size in Fp2: 2^5 = 32.  This is not practical.
 *
 * Higher extensions are not better:
 *   d=4:   v2(p^4-1)  = v2(p-1) + v2(p+1) + v2(p^2+1) = 1+4+1 = 6  → 2^6 = 64
 *   d=8:   v2(p^8-1)  = v2(p-1) + v2(p+1) + v2(p^2+1) + v2(p^4+1)
 *                       = 1+4+1+1 = 7  → 2^7 = 128
 *   ...
 *   Need d = 2^15 = 32768 to reach k=20.
 *
 * CONCLUSION: native secp256k1 Longfellow prove/verify is INFEAISIBLE
 * due to insufficient FFT root capacity. The RPBSch circuit and
 * evaluator remain valuable as correctness oracles. Production
 * proving requires either a different proof system over
 * secp256k1-friendly fields, or non-native emulation over P-256.
 */

#ifndef NIWI_SECP256K1_FEASIBILITY_H
#define NIWI_SECP256K1_FEASIBILITY_H

#include <cstddef>
#include <cstdint>

namespace niwi {

/* Check whether the secp256k1 field can support a given FFT domain size.
 * domain_bits = log2(domain_size), typically >= 20 for practical circuits.
 * Returns true if feasible, false otherwise. */
static inline bool secp256k1_fft_feasible(size_t domain_bits) {
    /* v2(p^2 - 1) = 5 for secp256k1 */
    constexpr size_t kMaxBits = 5;
    if (domain_bits > kMaxBits) return false;
    return true;
}

/* Return the maximum FFT domain size (as log2) supported by secp256k1. */
static inline size_t secp256k1_fft_max_bits() {
    return 5;
}

/* Return a human-readable explanation of infeasibility. */
static inline const char *secp256k1_fft_explain() {
    return "native secp256k1 proof backend unsupported: "
           "v2(p^2-1)=5, need >= log2(domain_size) >= 20. "
           "Maximum FFT domain in Fp2 is 2^5 = 32. "
           "Consider non-native over P-256 or a different proof system.";
}

}  // namespace niwi

#endif  // NIWI_SECP256K1_FEASIBILITY_H
