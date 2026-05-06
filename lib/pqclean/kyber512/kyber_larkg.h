#ifndef KYBER_LARKG_H
#define KYBER_LARKG_H

#include "params.h"
#include "skem.h"
#include <stdint.h>

typedef struct {
	uint8_t B_prime[KYBER_POLYVECBYTES];	// Encapsulating key
	uint8_t c[KYBER_POLYCOMPRESSEDBYTES];	// SKEM ciphertext
	uint8_t mu[32];							// Authentication tag (hash of shared secret)
} larkg_cred_t;

int PQCLEAN_KYBER512_CLEAN_larkg_derive_pk(uint8_t next_pk[KYBER_INDCPA_PUBLICKEYBYTES],
					larkg_cred_t *cred_out,
					const uint8_t current_pk[KYBER_INDCPA_PUBLICKEYBYTES],
					const skem_context *ctx);

int PQCLEAN_KYBER512_CLEAN_larkg_derive_sk(uint8_t next_sk[KYBER_INDCPA_SECRETKEYBYTES],
					const uint8_t current_sk[KYBER_INDCPA_SECRETKEYBYTES],
					const larkg_cred_t *cred_in);

#endif
