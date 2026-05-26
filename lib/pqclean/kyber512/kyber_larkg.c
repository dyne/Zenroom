#include "kyber_larkg.h"
#include "skem.h"
#include "indcpa.h"
#include "poly.h"
#include "polyvec.h"
#include "symmetric.h"
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h> // REMOVE AFTER TESTING
#include <math.h>   // REMOVE AFTER TESTING

// Imported from zenroom
extern int randombytes(void *buf, size_t n);

// --- Rejection sampling for LARKG ---

// Portable count of trailing zero bits, used to sample G ~ Geom(1/2).
static int count_trailing_zeros(uint64_t x) {
    if (x == 0) return 64;
    int n = 0;
    while ((x & 1) == 0) { n++; x >>= 1; }
    return n;
}

// Rejection sampling for LARKG (Lyubashevsky-style).
//
// Implements lines 7-8 of DeriveSK (Figure 5 of the paper):
//   u <- U[0,1]
//   accept if u < chi_a(K) / (M * chi_a(S))
//
// where chi_a = CBD(eta=3), K = S'' - S is the update vector,
// and S is the current secret key. Both K and S have coefficients
// in [-3, 3] (K from getnoise_eta1 before NTT, S from the appended seed).
//
// In log domain the condition becomes:
//   log_chi_K - log_chi_S > ln(M) - exp_sample
//
// where:
//   log_chi_K = sum_i log P(k_i)   (absolute log-prob under CBD(eta=3))
//   log_chi_S = sum_i log P(s_i)
//   log_ratio = log_chi_K - log_chi_S has mean 0 (K and S i.i.d.)
//     and stddev = sqrt(2 * N * Var[log P(single coeff)])
//   exp_sample ~ Exp(1) * stddev, sampled via geometric bit counting
//
// log_cbd[|k|] = log P(k) * 2^16, for CBD(eta=3):
//   P(0)=20/64, P(1)=P(-1)=15/64, P(2)=P(-2)=6/64, P(3)=P(-3)=1/64
//
// Constants
//   MEAN     = 0         (exact by symmetry)
//   PER_ZERO = ln(2) * stddev
//   LN_M     = ln(3) * stddev   (M=3, acceptance rate ~1/3)
//
// Returns 0 (accept) or 1 (reject).
static int larkg_rej_sampling(const polyvec *S_raw,
                               const polyvec *K_raw) {
    // log P(|k|) * 2^16 for CBD(eta=3), absolute log-probabilities
    static const int64_t log_cbd[4] = {
        -76228,		// |k|=0: log(20/64) * 65536
        -95082,		// |k|=1: log(15/64) * 65536
        -155132,	// |k|=2: log(6/64)  * 65536
        -272557		// |k|=3: log(1/64)  * 65536
    };

    static const int64_t PER_ZERO = 901636;
    static const int64_t LN_M = 1429059;

    int64_t log_chi_K = 0;
    int64_t log_chi_S = 0;

    for (int i = 0; i < KYBER_K; i++) {
        for (int j = 0; j < KYBER_N; j++) {
            int32_t k = abs((int32_t)K_raw->vec[i].coeffs[j]);
            int32_t s = abs((int32_t)S_raw->vec[i].coeffs[j]);
            if (k > 3 || s > 3) return 1;
            log_chi_K += log_cbd[k];
            log_chi_S += log_cbd[s];
        }
    }

    // Sample exp_sample ~ Exp(1) * stddev via geometric bit counting.
    // Each trailing zero bit of a random uint64_t contributes PER_ZERO.
    int64_t exp_sample = 0;
    uint64_t bits;
    randombytes(&bits, sizeof(bits));
    do {
        int z = count_trailing_zeros(bits);
        exp_sample += (int64_t)z * PER_ZERO;
        if (bits != 0) break;
        randombytes(&bits, sizeof(bits));
    } while (1);

    // Accept if log_chi_K - log_chi_S > LN_M - exp_sample.
    // MEAN = 0 by symmetry, so no centring needed.
    return ((log_chi_K - log_chi_S) > LN_M - exp_sample) ? 0 : 1;
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
    if (memcmp(mu_star, cred_in->mu, 32) != 0) {
        return -2;
    }

    // Ln 6
    for (int i = 0; i < KYBER_K; i++) {
        PQCLEAN_KYBER512_CLEAN_poly_add(&S_prime_prime.vec[i],
                                        &S_poly.vec[i],
                                        &K_poly.vec[i]);
        PQCLEAN_KYBER512_CLEAN_poly_reduce(&S_prime_prime.vec[i]);
    }

    // Ln 7-8: rejection sampling
	// Recover S in normal domain from appended seed in the secret key, and use it for rejection sampling
	const uint8_t *s_seed = current_sk + KYBER_POLYVECBYTES;
	polyvec S_raw;
	for (int i = 0; i < KYBER_K; i++) {
		PQCLEAN_KYBER512_CLEAN_poly_getnoise_eta1(&S_raw.vec[i], s_seed, (uint8_t)i);
	}
    if (larkg_rej_sampling(&S_raw, &K_raw) != 0) {
        return -1;
    }

    // Ln 9
    PQCLEAN_KYBER512_CLEAN_polyvec_tobytes(next_sk, &S_prime_prime);
	memcpy(next_sk + KYBER_POLYVECBYTES, k_seed, KYBER_SYMBYTES); // Append seed to the secret key for the next round of rejection sampling

    return 0;
}
