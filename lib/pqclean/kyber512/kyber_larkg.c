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

// Imported from zenroom
extern int randombytes(void *buf, size_t n);

// --- Helpers for rejection sampling in LARKG ---

// Parameters for LARKG
#define LARKG_ETA KYBER_ETA1
#define KYBER_MONT_R_INV 169 // Montgomery constant R^-1 mod q, where R = 2^16 and q = 3329. Used for converting to/from Montgomery form.

// Function to convert from Montgomery form to standard representation and center around 0
static inline int16_t demont_center(int16_t coeff) {
	int32_t v = ((int32_t)coeff % KYBER_Q + KYBER_Q) % KYBER_Q; // Ensure coeff is in [0, q-1]
	v = (v * KYBER_MONT_R_INV) % KYBER_Q; // Convert from Montgomery form to standard representation
	if (v >= KYBER_Q - 2 * KYBER_ETA1) {
		v -= KYBER_Q; // Center around 0
	}
	return (int16_t)v;
}

// Function to compute gcd, to reduce numerator and denominator in the rejection sampling step
static uint64_t gcd64(uint64_t a, uint64_t b) {
	while (b != 0) {
		uint64_t t = b;
		b = a % b;
		a = t;
	}
	return a;
}

// Function to generate a 64-bit number
static uint64_t random64(void) {
    uint8_t buf[8];
    
    randombytes(buf, 8);
    
    return ((uint64_t)buf[0] << 56) | 
           ((uint64_t)buf[1] << 48) | 
           ((uint64_t)buf[2] << 40) | 
           ((uint64_t)buf[3] << 32) | 
           ((uint64_t)buf[4] << 24) | 
           ((uint64_t)buf[5] << 16) | 
           ((uint64_t)buf[6] << 8)  | 
           ((uint64_t)buf[7]);
}

// LARKG rejection sampling in integer-only arithmetic
// Returns 0 on success, 1 on rejection
static int larkg_rej_sampling(const polyvec *S_flat,
                               const polyvec *S_pp_flat) {
    static const int64_t LOG2_RSP[4] = {283261, 321617, 234953, 65536};
    static const int64_t LOG2_M_Q16  = 1182310LL;

    int64_t log2_num = LOG2_M_Q16;

    for (int i = 0; i < KYBER_K; i++) {
        for (int j = 0; j < KYBER_N; j++) {
            int16_t s_ij    = demont_center(S_flat->vec[i].coeffs[j]);
            int16_t s_pp_ij = demont_center(S_pp_flat->vec[i].coeffs[j]);

            if (abs(s_ij) > LARKG_ETA || abs(s_pp_ij - s_ij) > 2 * LARKG_ETA)
                return 1;
            if (abs(s_ij) > 3 || abs(s_pp_ij - s_ij) > 3)
                return 1;

            log2_num += LOG2_RSP[abs(s_pp_ij - s_ij)] - LOG2_RSP[abs(s_ij)];
        }
    }

    static int debug_count = 0;
    debug_count++;
    if (debug_count <= 10) {
        printf("  [SAMPLE %d] log2_num=%.4f neg=%lld int_part=%lld\n",
               debug_count,
               (double)log2_num / 65536.0,
               (long long)(-log2_num),
               (long long)((-log2_num) >> 16));
    }

    // Reject if reject_prob >= 1
    if (log2_num >= 0)
        return 1;

    // threshold = 2^(64 + log2_num/65536), with log2_num < 0
    int64_t neg      = -log2_num;
    int64_t int_part = neg >> 16;
    int64_t frac_part = neg & 0xFFFF;

    if (int_part >= 64)
        return 1;

    // base = 2^(64 - int_part) as uint64_t
    uint64_t base = (int_part == 0) ? UINT64_MAX : (UINT64_MAX >> int_part);

    // Correct for fractional part using ln2 approximation:
    // 2^(-frac/65536) ≈ 1 - frac/65536 * ln2
    // ln2 * 65536 = 45426 */
    uint64_t threshold = base - ((__uint128_t)base * frac_part * 45426ULL >> 32);

    uint64_t u64 = random64();
    return (u64 < threshold) ? 1 : 0;
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
int PQCLEAN_KYBER512_CLEAN_larkg_derive_sk(uint8_t next_sk[KYBER_INDCPA_SECRETKEYBYTES],
										   const uint8_t current_sk[KYBER_INDCPA_SECRETKEYBYTES],
										   const larkg_cred_t *cred_in) {
	uint8_t k_seed[KYBER_SSBYTES];
	uint8_t mu_star[32];
	polyvec S_poly, K_poly, S_prime_prime;

	// Ln 1
	PQCLEAN_KYBER512_CLEAN_polyvec_frombytes(&S_poly, current_sk);

	// Ln 2
	PQCLEAN_KYBER512_CLEAN_skem_decaps(k_seed, current_sk, cred_in->c, cred_in->B_prime);

	// Ln 3
	for (int i = 0; i < KYBER_K; i++) {
		PQCLEAN_KYBER512_CLEAN_poly_getnoise_eta1(&K_poly.vec[i], k_seed, (uint8_t)i);
		PQCLEAN_KYBER512_CLEAN_poly_ntt(&K_poly.vec[i]);
	}

	// Ln 4
	hash_h(mu_star, k_seed, KYBER_SSBYTES);

	// Ln 5
	if (memcmp(mu_star, cred_in->mu, 32) != 0) {
		return -2;	// Authentication failed (mu_star != mu)
	}

	// Ln 6
	for (int i = 0; i < KYBER_K; i++) {
		PQCLEAN_KYBER512_CLEAN_poly_add(&S_prime_prime.vec[i], &S_poly.vec[i], &K_poly.vec[i]);
		PQCLEAN_KYBER512_CLEAN_poly_reduce(&S_prime_prime.vec[i]);
	}

	// Ln 7 and 8 (rejection sampling)
	polyvec S_flat = S_poly;
	polyvec S_pp_flat = S_prime_prime;
	PQCLEAN_KYBER512_CLEAN_polyvec_invntt_tomont(&S_flat);
	PQCLEAN_KYBER512_CLEAN_polyvec_invntt_tomont(&S_pp_flat);

	int rej = larkg_rej_sampling(&S_flat, &S_pp_flat);
	if (rej != 0) return -1;	// Rejection

	// Ln 9
	PQCLEAN_KYBER512_CLEAN_polyvec_tobytes(next_sk, &S_prime_prime);

	return 0;
}
