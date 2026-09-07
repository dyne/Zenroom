#include "kyber_larkg.h"
#include "skem.h"
#include "indcpa.h"
#include "poly.h"
#include "polyvec.h"
#include "reduce.h"
#include "symmetric.h"
#include "verify.h"
#include <string.h>
#include <stdint.h>

// Imported from zenroom
extern int randombytes(void *buf, size_t n);

// --- Rejection sampling for LARKG ---

// Rejection sampling for LARKG.
//
// Implements lines 7-8 of DeriveSK (Figure 5 of the paper):
//   u <- U[0,1]
//   accept if u < chi_a(K) / (M * chi_a(S))
//
// where chi_a = CBD(eta=3), K = S'' - S is the update vector,
// and S is the actual current secret key. For CBD(eta=3):
//   P(0)=20/64, P(1)=P(-1)=15/64, P(2)=P(-2)=6/64, P(3)=P(-3)=1/64
//
// The common /64 factors cancel. The remaining weights factor over 2, 3,
// and 5, so the complete likelihood ratio can be sampled exactly using a
// fixed-size multiword numerator and denominator. M is 3.
#define LARKG_BIGINT_LIMBS (((KYBER_K * KYBER_N * 5) + 31) / 32 + 1)

static int bigint_compare(const uint32_t *a, const uint32_t *b) {
    for (size_t i = LARKG_BIGINT_LIMBS; i-- > 0;) {
        if (a[i] < b[i]) return -1;
        if (a[i] > b[i]) return 1;
    }
    return 0;
}

static int bigint_multiply_small(uint32_t *value, uint32_t factor) {
    uint64_t carry = 0;
    for (size_t i = 0; i < LARKG_BIGINT_LIMBS; i++) {
        uint64_t product = (uint64_t)value[i] * factor + carry;
        value[i] = (uint32_t)product;
        carry = product >> 32;
    }
    return carry == 0;
}

static int bigint_multiply_power(uint32_t *value, uint32_t base, int exponent) {
    for (int i = 0; i < exponent; i++) {
        if (!bigint_multiply_small(value, base)) return 0;
    }
    return 1;
}

static int larkg_rej_sampling(const polyvec *S_raw,
                              const polyvec *K_raw) {
    // Prime exponents for CBD weights 20, 15, 6, and 1.
    static const int8_t cbd_factors[4][3] = {
        {2, 0, 1}, {0, 1, 1}, {1, 1, 0}, {0, 0, 0}
    };
    int exponents[3] = {0, -1, 0}; // Divide by M=3.

    for (int i = 0; i < KYBER_K; i++) {
        for (int j = 0; j < KYBER_N; j++) {
            int32_t k = K_raw->vec[i].coeffs[j];
            int32_t s = S_raw->vec[i].coeffs[j];
            k = k < 0 ? -k : k;
            s = s < 0 ? -s : s;

            // A zero numerator rejects. A zero denominator makes the
            // likelihood ratio unbounded, so min(ratio, 1) accepts.
            if (k > 3) return 1;
            if (s > 3) return 0;
            for (int p = 0; p < 3; p++) {
                exponents[p] += cbd_factors[k][p] - cbd_factors[s][p];
            }
        }
    }

    static const uint32_t primes[3] = {2, 3, 5};
    uint32_t numerator[LARKG_BIGINT_LIMBS] = {1};
    uint32_t denominator[LARKG_BIGINT_LIMBS] = {1};
    uint32_t sample[LARKG_BIGINT_LIMBS];

    for (int p = 0; p < 3; p++) {
        uint32_t *value = exponents[p] < 0 ? denominator : numerator;
        int exponent = exponents[p] < 0 ? -exponents[p] : exponents[p];
        if (!bigint_multiply_power(value, primes[p], exponent)) return 1;
    }

    if (bigint_compare(numerator, denominator) >= 0) return 0;

    size_t used = LARKG_BIGINT_LIMBS;
    while (used > 1 && denominator[used - 1] == 0) used--;
    uint32_t top = denominator[used - 1];
    unsigned int top_bits = 0;
    while (top != 0) {
        top_bits++;
        top >>= 1;
    }

    do {
        memset(sample, 0, sizeof(sample));
        randombytes(sample, used * sizeof(sample[0]));
        if (top_bits < 32) {
            sample[used - 1] &= ((uint32_t)1 << top_bits) - 1;
        }
    } while (bigint_compare(sample, denominator) >= 0);

    return bigint_compare(sample, numerator) < 0 ? 0 : 1;
}

// Recover the current small secret from its serialized NTT representation.
// invntt_tomont leaves coefficients multiplied by R, so remove that factor
// before evaluating their CBD probabilities.
static void larkg_secret_to_raw(polyvec *raw, const polyvec *ntt) {
    *raw = *ntt;
    PQCLEAN_KYBER512_CLEAN_polyvec_invntt_tomont(raw);
    for (int i = 0; i < KYBER_K; i++) {
        for (int j = 0; j < KYBER_N; j++) {
            raw->vec[i].coeffs[j] = PQCLEAN_KYBER512_CLEAN_barrett_reduce(
                PQCLEAN_KYBER512_CLEAN_montgomery_reduce(raw->vec[i].coeffs[j]));
        }
    }
}

// -------------------------------------------------

/*************************************************
* Name:        PQCLEAN_KYBER512_CLEAN_larkg_derive_pk
*
* Description: Derives the next public key and encapsulating key for the sender.
*
* Arguments:   uint8_t *next_pk: pointer to output next public key
* 			   larkg_cred_t *cred_out: pointer to output credentials (encapsulating key and authentication tag)
* 			   const uint8_t *current_pk: pointer to input current public key
* 			   const skem_context *ctx: pointer to the global context
*
* Returns:    0 on success
**************************************************/
int PQCLEAN_KYBER512_CLEAN_larkg_derive_pk(uint8_t next_pk[KYBER_INDCPA_PUBLICKEYBYTES],
										   larkg_cred_t *cred_out,
										   const uint8_t current_pk[KYBER_INDCPA_PUBLICKEYBYTES],
										   const skem_context *ctx) {
	uint8_t S_prime_bytes[KYBER_INDCPA_SECRETKEYBYTES];
	uint8_t k_seed[KYBER_SSBYTES];
	uint8_t rand_buf[KYBER_SYMBYTES];

	polyvec B_poly, K_poly, E_prime_poly, P_poly;
	polyvec matrix_A[KYBER_K];

	PQCLEAN_KYBER512_CLEAN_polyvec_frombytes(&B_poly, current_pk);

	// Ln 1
	PQCLEAN_KYBER512_CLEAN_skem_keygen_enc(cred_out->B_prime, S_prime_bytes, ctx);

	// Ln 2
	PQCLEAN_KYBER512_CLEAN_skem_encaps(cred_out->c, k_seed, S_prime_bytes, current_pk);

	// Ln 3
	for (int i = 0; i < KYBER_K; i++) {
		PQCLEAN_KYBER512_CLEAN_poly_getnoise_eta1(&K_poly.vec[i], k_seed, i);
		PQCLEAN_KYBER512_CLEAN_poly_ntt(&K_poly.vec[i]);
	}

	// Ln 4
	hash_h(cred_out->mu, k_seed, KYBER_SSBYTES);

	// Ln 5
	randombytes(rand_buf, KYBER_SYMBYTES);
	for (int i = 0; i < KYBER_K; i++) {
		PQCLEAN_KYBER512_CLEAN_poly_getnoise_eta1(&E_prime_poly.vec[i], rand_buf, i);
		PQCLEAN_KYBER512_CLEAN_poly_ntt(&E_prime_poly.vec[i]);
	}

	// Ln 6
	const uint8_t *rho = current_pk + KYBER_POLYVECBYTES;
	PQCLEAN_KYBER512_CLEAN_gen_matrix(matrix_A, rho, 0);

	for (int i = 0; i < KYBER_K; i++) {
		PQCLEAN_KYBER512_CLEAN_polyvec_basemul_acc_montgomery(&P_poly.vec[i], &matrix_A[i], &K_poly);
		PQCLEAN_KYBER512_CLEAN_poly_tomont(&P_poly.vec[i]);

		PQCLEAN_KYBER512_CLEAN_poly_add(&P_poly.vec[i], &P_poly.vec[i], &E_prime_poly.vec[i]);
		PQCLEAN_KYBER512_CLEAN_poly_add(&P_poly.vec[i], &P_poly.vec[i], &B_poly.vec[i]);
		PQCLEAN_KYBER512_CLEAN_poly_reduce(&P_poly.vec[i]);
	}

	// Ln 7
	PQCLEAN_KYBER512_CLEAN_polyvec_tobytes(next_pk, &P_poly);
	memcpy(next_pk + KYBER_POLYVECBYTES, rho, KYBER_SYMBYTES);

	return 0;
}

/*************************************************
* Name:        PQCLEAN_KYBER512_CLEAN_larkg_derive_sk
*
* Description: Derives the next secret key for the receiver.
*
* Arguments:   uint8_t *next_sk: pointer to output next secret key
* 			   const uint8_t *current_sk: pointer to input current secret key
* 			   const larkg_cred_t *cred_in: pointer to input credentials (encapsulating key and authentication tag)
*
* Returns:    0 on success, -1 on rejection, -2 on failed authentication
**************************************************/
int PQCLEAN_KYBER512_CLEAN_larkg_derive_sk(uint8_t next_sk[KYBER_LARKG_SECRETKEYBYTES],
                                           const uint8_t current_sk[KYBER_LARKG_SECRETKEYBYTES],
                                           const larkg_cred_t *cred_in) {
    uint8_t k_seed[KYBER_SSBYTES];
    uint8_t mu_star[32];
    polyvec S_poly, K_poly, K_raw, S_prime_prime;

    // Ln 1
    PQCLEAN_KYBER512_CLEAN_polyvec_frombytes(&S_poly, current_sk);

    // Ln 2
    PQCLEAN_KYBER512_CLEAN_skem_decaps(k_seed, current_sk, cred_in->c, cred_in->B_prime);

    // Ln 3
    for (int i = 0; i < KYBER_K; i++) {
        PQCLEAN_KYBER512_CLEAN_poly_getnoise_eta1(&K_raw.vec[i], k_seed, (uint8_t)i);
        K_poly.vec[i] = K_raw.vec[i];
        PQCLEAN_KYBER512_CLEAN_poly_ntt(&K_poly.vec[i]);
    }

    // Ln 4
    hash_h(mu_star, k_seed, KYBER_SSBYTES);

    // Ln 5
    if (PQCLEAN_KYBER512_CLEAN_verify(mu_star, cred_in->mu, sizeof(mu_star)) != 0) {
        return -2;
    }

    // Ln 6
    for (int i = 0; i < KYBER_K; i++) {
        PQCLEAN_KYBER512_CLEAN_poly_add(&S_prime_prime.vec[i],
                                        &S_poly.vec[i],
                                        &K_poly.vec[i]);
        PQCLEAN_KYBER512_CLEAN_poly_reduce(&S_prime_prime.vec[i]);
    }

    // Ln 7-8: rejection sampling. Recover the actual current secret rather
    // than expanding the suffix seed, which only describes the last update.
    polyvec S_raw;
    larkg_secret_to_raw(&S_raw, &S_poly);
    if (larkg_rej_sampling(&S_raw, &K_raw) != 0) {
        return -1;
    }

    // Ln 9
    PQCLEAN_KYBER512_CLEAN_polyvec_tobytes(next_sk, &S_prime_prime);
	memcpy(next_sk + KYBER_POLYVECBYTES, k_seed, KYBER_SYMBYTES); // Append seed to the secret key for the next round of rejection sampling

    return 0;
}
