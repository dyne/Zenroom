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

static void larkg_auth_tag(uint8_t tag[KYBER_SYMBYTES],
                           const uint8_t key[KYBER_SSBYTES]) {
    static const uint8_t domain[] = "Zenroom/LARKG/v1/auth";
    sha3_256incctx state;

    sha3_256_inc_init(&state);
    sha3_256_inc_absorb(&state, domain, sizeof(domain) - 1);
    sha3_256_inc_absorb(&state, key, KYBER_SSBYTES);
    sha3_256_inc_finalize(tag, &state);
}

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
#define LARKG_MAX_EXPONENT (2 * KYBER_K * KYBER_N + 1)
#define LARKG_SAMPLER_ATTEMPTS 128

static uint32_t bigint_less_than(const uint32_t *a, const uint32_t *b) {
    uint64_t borrow = 0;
    uint32_t different = 0;
    for (size_t i = 0; i < LARKG_BIGINT_LIMBS; i++) {
        uint64_t subtrahend = (uint64_t)a[i] + borrow;
        borrow = (uint64_t)b[i] < subtrahend;
        different |= a[i] ^ b[i];
    }
    return (uint32_t)(1U ^ (uint32_t)borrow) &
           (uint32_t)((different | (uint32_t)(0U - different)) >> 31);
}

static uint32_t larkg_abs_clamped(int16_t coefficient, uint32_t *invalid) {
    int32_t value = coefficient;
    int32_t sign = value >> 31;
    uint32_t magnitude = (uint32_t)((value ^ sign) - sign);
    uint32_t out_of_support = magnitude > 3;
    uint32_t mask = 0U - out_of_support;
    *invalid |= out_of_support;
    return (magnitude & ~mask) | (3U & mask);
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
    int ok = 1;
    for (int i = 0; i < LARKG_MAX_EXPONENT; i++) {
        uint32_t use_base = (uint32_t)(i < exponent);
        uint32_t factor = 1U + use_base * (base - 1U);
        ok &= bigint_multiply_small(value, factor);
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

    uint32_t invalid = 0;
    for (int i = 0; i < KYBER_K; i++) {
        for (int j = 0; j < KYBER_N; j++) {
            uint32_t k = larkg_abs_clamped(K_raw->vec[i].coeffs[j], &invalid);
            uint32_t s = larkg_abs_clamped(S_raw->vec[i].coeffs[j], &invalid);
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

    size_t used = LARKG_BIGINT_LIMBS;
    while (used > 1 && denominator[used - 1] == 0) used--;
    uint32_t top = denominator[used - 1];
    unsigned int top_bits = 0;
    while (top != 0) {
        top_bits++;
        top >>= 1;
    }

    uint32_t selected[LARKG_BIGINT_LIMBS] = {0};
    uint32_t found = 0;
    for (size_t attempt = 0; attempt < LARKG_SAMPLER_ATTEMPTS; attempt++) {
        memset(sample, 0, sizeof(sample));
        randombytes(sample, used * sizeof(sample[0]));
        if (top_bits < 32) {
            sample[used - 1] &= ((uint32_t)1 << top_bits) - 1;
        }
        uint32_t valid = bigint_less_than(sample, denominator);
        uint32_t take = valid & (found ^ 1U);
        uint32_t mask = 0U - take;
        for (size_t i = 0; i < LARKG_BIGINT_LIMBS; i++) {
            selected[i] = (selected[i] & ~mask) | (sample[i] & mask);
        }
        found |= valid;
    }

    return (invalid != 0 || found == 0 ||
            bigint_less_than(selected, numerator) == 0) ? 1 : 0;
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
	if (PQCLEAN_KYBER512_CLEAN_skem_keygen_enc(cred_out->B_prime, S_prime_bytes, ctx) != 0) return LARKG_ENTROPY_FAILURE;

	// Ln 2
	if (PQCLEAN_KYBER512_CLEAN_skem_encaps(cred_out->c, k_seed, S_prime_bytes, current_pk) != 0) return LARKG_ENTROPY_FAILURE;

	// Ln 3
	for (int i = 0; i < KYBER_K; i++) {
		PQCLEAN_KYBER512_CLEAN_poly_getnoise_eta1(&K_poly.vec[i], k_seed, i);
		PQCLEAN_KYBER512_CLEAN_poly_ntt(&K_poly.vec[i]);
	}

	// Ln 4
    larkg_auth_tag(cred_out->mu, k_seed);

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
    uint8_t depth;
    polyvec S_poly, K_poly, K_raw, S_prime_prime;

    if (!PQCLEAN_KYBER512_CLEAN_skem_secret_depth(current_sk, &depth)) {
        return LARKG_PARAMETER_MISMATCH;
    }
#if LARKG_MAX_SUPPORTED_DEPTH == 0
    (void)depth;
    return LARKG_PARAMETER_MISMATCH;
#else
    if (depth >= LARKG_MAX_SUPPORTED_DEPTH) {
        return LARKG_PARAMETER_MISMATCH;
    }
#endif

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
    larkg_auth_tag(mu_star, k_seed);

    // Ln 5
    if (PQCLEAN_KYBER512_CLEAN_verify(mu_star, cred_in->mu, sizeof(mu_star)) != 0) {
        return LARKG_AUTHENTICATION_FAILED;
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
    PQCLEAN_KYBER512_CLEAN_skem_secret_to_normal(&S_raw, current_sk);
    if (larkg_rej_sampling(&S_raw, &K_raw) != 0) {
        return LARKG_REJECTED;
    }

    // Ln 9
    PQCLEAN_KYBER512_CLEAN_polyvec_tobytes(next_sk, &S_prime_prime);
    PQCLEAN_KYBER512_CLEAN_skem_secret_set_depth(next_sk, (uint8_t)(depth + 1));

    return 0;
}
