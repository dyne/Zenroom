// Split KEM implementation for Kyber512 (see https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=10190483)
// To be used in LARKG instantiated from Kyber

#ifndef PQCLEAN_KYBER512_CLEAN_SKEM_H
#define PQCLEAN_KYBER512_CLEAN_SKEM_H

#include "params.h"
#include "polyvec.h"
#include <stdint.h>

/*************************************************
* Name:        skem_context
*
* Description: Global context for the Split-KEM scheme. 
* Contains the globally shared seed rho and the pre-computed
* matrices A and A^T.
**************************************************/
typedef struct {
    uint8_t rho[KYBER_SYMBYTES];
    polyvec a[KYBER_K];
    polyvec at[KYBER_K];
} skem_context;

// SK size for the receiver (includes seed for rejection sampling)
#define KYBER_LARKG_SECRETKEYBYTES (KYBER_POLYVECBYTES + KYBER_SYMBYTES)

void PQCLEAN_KYBER512_CLEAN_skem_init(skem_context *ctx, const uint8_t rho[KYBER_SYMBYTES]);

void PQCLEAN_KYBER512_CLEAN_skem_keygen(uint8_t pk[KYBER_INDCPA_PUBLICKEYBYTES],
                                            uint8_t sk[KYBER_LARKG_SECRETKEYBYTES],
                                            const skem_context *ctx);

void PQCLEAN_KYBER512_CLEAN_skem_keygen_enc(uint8_t pkp[KYBER_POLYVECBYTES],
                                            uint8_t skp[KYBER_INDCPA_SECRETKEYBYTES],
                                            const skem_context *ctx);

void PQCLEAN_KYBER512_CLEAN_skem_encaps(uint8_t c_out[KYBER_POLYCOMPRESSEDBYTES],
                                        uint8_t K[KYBER_SSBYTES],
                                        const uint8_t skp[KYBER_INDCPA_SECRETKEYBYTES],
                                        const uint8_t pk[KYBER_INDCPA_PUBLICKEYBYTES]);

void PQCLEAN_KYBER512_CLEAN_skem_decaps(uint8_t m[KYBER_INDCPA_MSGBYTES],
                                        const uint8_t sk[KYBER_LARKG_SECRETKEYBYTES],
                                        const uint8_t c_in[KYBER_POLYCOMPRESSEDBYTES],
                                        const uint8_t pkp[KYBER_POLYVECBYTES]);

#endif
