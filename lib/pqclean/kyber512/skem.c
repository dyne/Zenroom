// Split KEM implementation for Kyber512 (see https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=10190483)
// To be used in LARKG instantiated from Kyber

#include "skem.h"
#include "indcpa.h"
#include "ntt.h"
#include "params.h"
#include "poly.h"
#include "polyvec.h"
#include "symmetric.h"
#include <string.h>
#include <stddef.h>
#include <stdint.h>

// Imported from zenroom
extern int randombytes(void *buf, size_t n);

extern void PQCLEAN_KYBER512_CLEAN_gen_matrix(polyvec *a, const uint8_t seed[KYBER_SYMBYTES], int transposed);

/*************************************************
* Name:        skem_pack_pk
*
* Description: Serialize the public key as concatenation of the
* serialized vector of polynomials pk and the global seed rho.
*
* Arguments:   uint8_t *r: pointer to output serialized public key
* 			   polyvec *pk: pointer to input vector of polynomials (public key)
* 	 		   const uint8_t *seed: pointer to input public seed (rho)
**************************************************/
static void skem_pack_pk(uint8_t r[KYBER_INDCPA_PUBLICKEYBYTES], 
						 polyvec *pk, 
						 const uint8_t seed[KYBER_SYMBYTES]) {
    PQCLEAN_KYBER512_CLEAN_polyvec_tobytes(r, pk);
    for (size_t i = 0; i < KYBER_SYMBYTES; i++) {
        r[i + KYBER_POLYVECBYTES] = seed[i];
    }
}

/*************************************************
* Name:        skem_unpack_pk
*
* Description: De-serialize public key from a byte array. Note that
* the global seed rho is ignored here since it's part of the context.
*
* Arguments:   polyvec *pk: pointer to output vector of polynomials (public key)
* 			   const uint8_t *packedpk: pointer to input serialized public key
**************************************************/
static void skem_unpack_pk(polyvec *pk, 
						   const uint8_t packedpk[KYBER_INDCPA_PUBLICKEYBYTES]) {
    PQCLEAN_KYBER512_CLEAN_polyvec_frombytes(pk, packedpk);
}

/*************************************************
* Name:        skem_pack_sk
*
* Description: Serialize the secret key.
*
* Arguments:   uint8_t *r: pointer to output serialized secret key
* 			   polyvec *sk: pointer to input vector of polynomials (secret key)
**************************************************/
static void skem_pack_sk(uint8_t r[KYBER_INDCPA_SECRETKEYBYTES], 
						 polyvec *sk) {
    PQCLEAN_KYBER512_CLEAN_polyvec_tobytes(r, sk);
}

/*************************************************
* Name:        skem_unpack_sk
*
* Description: De-serialize the secret key; inverse of skem_pack_sk.
*
* Arguments:   polyvec *sk: pointer to output vector of polynomials (secret key)
* 			   const uint8_t *packedsk: pointer to input serialized secret key
**************************************************/
static void skem_unpack_sk(polyvec *sk, 
						   const uint8_t packedsk[KYBER_INDCPA_SECRETKEYBYTES]) {
    PQCLEAN_KYBER512_CLEAN_polyvec_frombytes(sk, packedsk);
}

/*************************************************
* Name:        PQCLEAN_KYBER512_CLEAN_skem_init
*
* Description: Initializes the global Split-KEM context.
*
* Arguments:   skem_context *ctx: pointer to the context to be initialized
* 			   const uint8_t *rho: pointer to the shared 32-byte seed
**************************************************/
void PQCLEAN_KYBER512_CLEAN_skem_init(skem_context *ctx, 
									  const uint8_t rho[KYBER_SYMBYTES]) {
    
	// Store rho in the context
	memcpy(ctx->rho, rho, KYBER_SYMBYTES);

	// Generate matrices A and A^T from rho
    PQCLEAN_KYBER512_CLEAN_gen_matrix(ctx->a, ctx->rho, 0);  // Generate A
    PQCLEAN_KYBER512_CLEAN_gen_matrix(ctx->at, ctx->rho, 1); // Generate A^T
}

/*************************************************
* Name:        PQCLEAN_KYBER512_CLEAN_skem_keygen_dec
*
* Description: Generates public and private key for the receiver.
*
* Arguments:   uint8_t *pk: pointer to output public key
* 			   uint8_t *sk: pointer to output private key
* 			   const skem_context *ctx: pointer to the global context
**************************************************/
void PQCLEAN_KYBER512_CLEAN_skem_keygen(uint8_t pk[KYBER_INDCPA_PUBLICKEYBYTES], 
											uint8_t sk[KYBER_INDCPA_SECRETKEYBYTES], 
											const skem_context *ctx) {
	uint8_t buf[2 * KYBER_SYMBYTES];
	uint8_t nonce = 0;
	polyvec e, skpv, pkpv;

	randombytes(buf, KYBER_SYMBYTES);
	hash_g(buf, buf, KYBER_SYMBYTES);
	
	// Generate the error vector s ∈ R^k
	for (int i = 0; i < KYBER_K; i++) {
		PQCLEAN_KYBER512_CLEAN_poly_getnoise_eta1(&skpv.vec[i], buf, nonce++);
	}

	// Generate the error vector e ∈ R^k
	for (int i = 0; i < KYBER_K; i++) {
		PQCLEAN_KYBER512_CLEAN_poly_getnoise_eta1(&e.vec[i], buf, nonce++);
	}

	PQCLEAN_KYBER512_CLEAN_polyvec_ntt(&skpv); // No need to reduce coefficients of skpv since they are already small
	PQCLEAN_KYBER512_CLEAN_polyvec_ntt(&e);

	// Compute the public key pk = A * s + e and reduce coefficients
	for (int i = 0; i < KYBER_K; i++) {
		PQCLEAN_KYBER512_CLEAN_polyvec_basemul_acc_montgomery(&pkpv.vec[i], &ctx->a[i], &skpv);
		PQCLEAN_KYBER512_CLEAN_poly_tomont(&pkpv.vec[i]);
	}
	PQCLEAN_KYBER512_CLEAN_polyvec_add(&pkpv, &pkpv, &e);
	PQCLEAN_KYBER512_CLEAN_polyvec_reduce(&pkpv);

	// Encode pk and sk to byte arrays
	skem_pack_sk(sk, &skpv);
	skem_pack_pk(pk, &pkpv, ctx->rho);
}

/*************************************************
* Name:        PQCLEAN_KYBER512_CLEAN_skem_keygen_enc
*
* Description: Generates the encapsulation key pair (pkp, skp) for the sender.
*
* Arguments:   uint8_t *pkp: pointer to output public key for encapsulation
* 			   uint8_t *skp: pointer to output secret key for encapsulation
* 			   const skem_context *ctx: pointer to the global context
**************************************************/
void PQCLEAN_KYBER512_CLEAN_skem_keygen_enc(uint8_t pkp[KYBER_POLYVECBYTES], 
											uint8_t skp[KYBER_INDCPA_SECRETKEYBYTES], 
											const skem_context *ctx) {
	uint8_t coins[KYBER_SYMBYTES];
	uint8_t nonce = 0;
	polyvec r, e1, u;

	randombytes(coins, KYBER_SYMBYTES);
	
	// Generate the error vector r ∈ R^k
	for (int i = 0; i < KYBER_K; i++) {
		PQCLEAN_KYBER512_CLEAN_poly_getnoise_eta1(&r.vec[i], coins, nonce++);
	}
	// Generate the error vector e1 ∈ R^k
	for (int i = 0; i < KYBER_K; i++) {
		PQCLEAN_KYBER512_CLEAN_poly_getnoise_eta2(&e1.vec[i], coins, nonce++);
	}

	PQCLEAN_KYBER512_CLEAN_polyvec_ntt(&r);

	// Compute u = A^t * skp + e1 and reduce coefficients
	for (int i = 0; i < KYBER_K; i++) {
		PQCLEAN_KYBER512_CLEAN_polyvec_basemul_acc_montgomery(&u.vec[i], &ctx->at[i], &r);
	}
	PQCLEAN_KYBER512_CLEAN_polyvec_invntt_tomont(&u);
	PQCLEAN_KYBER512_CLEAN_polyvec_add(&u, &u, &e1);
	PQCLEAN_KYBER512_CLEAN_polyvec_reduce(&u);

	// Encode pkp and skp to byte arrays
	PQCLEAN_KYBER512_CLEAN_polyvec_tobytes(pkp, &u);
	skem_pack_sk(skp, &r);
}

/*************************************************
* Name:        PQCLEAN_KYBER512_CLEAN_skem_encaps
*
* Description: Generates cipher text and shared secret for given public key.
*
* Arguments:   uint8_t *c_out: pointer to output cipher text
* 			   uint8_t *K: pointer to output shared secret
* 			   const uint8_t *skp: pointer to input secret key for encapsulation
* 			   const uint8_t *pk: pointer to input public key for encapsulation
**************************************************/
void PQCLEAN_KYBER512_CLEAN_skem_encaps(uint8_t c_out[KYBER_POLYCOMPRESSEDBYTES], 
										uint8_t K[KYBER_SSBYTES], 
										const uint8_t skp[KYBER_INDCPA_SECRETKEYBYTES], 
										const uint8_t pk[KYBER_INDCPA_PUBLICKEYBYTES]) {
	uint8_t coins[KYBER_SYMBYTES];
	uint8_t buf[KYBER_SYMBYTES];
	uint8_t nonce = 0;
	polyvec sp, pkpv;
	poly v, e2, m_poly;

	randombytes(buf, KYBER_SSBYTES);
	hash_h(K, buf, KYBER_SSBYTES);
	
	// Encode message as polynomial
	PQCLEAN_KYBER512_CLEAN_poly_frommsg(&m_poly, K);
	skem_unpack_pk(&pkpv, pk);
	skem_unpack_sk(&sp, skp);

	randombytes(coins, KYBER_SYMBYTES);

	// Generate the error polynomial e2 ∈ R
	PQCLEAN_KYBER512_CLEAN_poly_getnoise_eta2(&e2, coins, nonce++);
	
	// Compute v = pk * sp + e2 + m_poly and reduce coefficients
	PQCLEAN_KYBER512_CLEAN_polyvec_basemul_acc_montgomery(&v, &pkpv, &sp);
	PQCLEAN_KYBER512_CLEAN_poly_invntt_tomont(&v);
	PQCLEAN_KYBER512_CLEAN_poly_add(&v, &v, &e2);
	PQCLEAN_KYBER512_CLEAN_poly_add(&v, &v, &m_poly);
	PQCLEAN_KYBER512_CLEAN_poly_reduce(&v);

	// Ciphertext to bytes
	PQCLEAN_KYBER512_CLEAN_poly_compress(c_out, &v);
}

/*************************************************
* Name:        PQCLEAN_KYBER512_CLEAN_skem_decaps
*
* Description: Generates shared secret for given cipher text and private key.
*
* Arguments:   uint8_t *m: pointer to output shared secret
* 			   const uint8_t *sk: pointer to input private key
* 			   const uint8_t *c_in: pointer to input cipher text
* 			   const uint8_t *pkp: pointer to input public key for encapsulation
**************************************************/
void PQCLEAN_KYBER512_CLEAN_skem_decaps(uint8_t m[KYBER_INDCPA_MSGBYTES], 
										const uint8_t sk[KYBER_INDCPA_SECRETKEYBYTES], 
										const uint8_t c_in[KYBER_POLYCOMPRESSEDBYTES], 
										const uint8_t pkp[KYBER_POLYVECBYTES]) {
	polyvec u, skpv;
	poly v, mp;

	PQCLEAN_KYBER512_CLEAN_polyvec_frombytes(&u, pkp);
	PQCLEAN_KYBER512_CLEAN_poly_decompress(&v, c_in);
	skem_unpack_sk(&skpv, sk);

	PQCLEAN_KYBER512_CLEAN_polyvec_ntt(&u);

	// Recover message polynomial mp = v - u * skpv and reduce coefficients
	PQCLEAN_KYBER512_CLEAN_polyvec_basemul_acc_montgomery(&mp, &skpv, &u);
	PQCLEAN_KYBER512_CLEAN_poly_invntt_tomont(&mp);
	PQCLEAN_KYBER512_CLEAN_poly_sub(&mp, &v, &mp);
	PQCLEAN_KYBER512_CLEAN_poly_reduce(&mp);

	// Message to bytes
	PQCLEAN_KYBER512_CLEAN_poly_tomsg(m, &mp);
}
