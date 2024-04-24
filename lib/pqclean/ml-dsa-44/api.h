#ifndef API_H
#define API_H

#include <stddef.h>
#include <stdint.h>

#define pqcrystals_ml_dsa_44_ipd_PUBLICKEYBYTES 1312
#define pqcrystals_ml_dsa_44_ipd_SECRETKEYBYTES 2560
#define pqcrystals_ml_dsa_44_ipd_BYTES 2420

#define pqcrystals_ml_dsa_44_ipd_ref_PUBLICKEYBYTES pqcrystals_ml_dsa_44_ipd_PUBLICKEYBYTES
#define pqcrystals_ml_dsa_44_ipd_ref_SECRETKEYBYTES pqcrystals_ml_dsa_44_ipd_SECRETKEYBYTES
#define pqcrystals_ml_dsa_44_ipd_ref_BYTES pqcrystals_ml_dsa_44_ipd_BYTES

int pqcrystals_ml_dsa_44_ipd_ref_keypair(uint8_t *pk, uint8_t *sk);

int pqcrystals_ml_dsa_44_ipd_ref_signature(uint8_t *sig, size_t *siglen,
                                        const uint8_t *m, size_t mlen,
                                        const uint8_t *sk);

int pqcrystals_ml_dsa_44_ipd_ref(uint8_t *sm, size_t *smlen,
                              const uint8_t *m, size_t mlen,
                              const uint8_t *sk);

int pqcrystals_ml_dsa_44_ipd_ref_verify(const uint8_t *sig, size_t siglen,
                                     const uint8_t *m, size_t mlen,
                                     const uint8_t *pk);

int pqcrystals_ml_dsa_44_ipd_ref_open(uint8_t *m, size_t *mlen,
                                   const uint8_t *sm, size_t smlen,
                                   const uint8_t *pk);


#define pqcrystals_ml_dsa_65_ipd_PUBLICKEYBYTES 1952
#define pqcrystals_ml_dsa_65_ipd_SECRETKEYBYTES 4032
#define pqcrystals_ml_dsa_65_ipd_BYTES 3309

#define pqcrystals_ml_dsa_65_ipd_ref_PUBLICKEYBYTES pqcrystals_ml_dsa_65_ipd_PUBLICKEYBYTES
#define pqcrystals_ml_dsa_65_ipd_ref_SECRETKEYBYTES pqcrystals_ml_dsa_65_ipd_SECRETKEYBYTES
#define pqcrystals_ml_dsa_65_ipd_ref_BYTES pqcrystals_ml_dsa_65_ipd_BYTES

int pqcrystals_ml_dsa_65_ipd_ref_keypair(uint8_t *pk, uint8_t *sk);

int pqcrystals_ml_dsa_65_ipd_ref_signature(uint8_t *sig, size_t *siglen,
                                        const uint8_t *m, size_t mlen,
                                        const uint8_t *sk);

int pqcrystals_ml_dsa_65_ipd_ref(uint8_t *sm, size_t *smlen,
                              const uint8_t *m, size_t mlen,
                              const uint8_t *sk);

int pqcrystals_ml_dsa_65_ipd_ref_verify(const uint8_t *sig, size_t siglen,
                                     const uint8_t *m, size_t mlen,
                                     const uint8_t *pk);

int pqcrystals_ml_dsa_65_ipd_ref_open(uint8_t *m, size_t *mlen,
                                   const uint8_t *sm, size_t smlen,
                                   const uint8_t *pk);


#define pqcrystals_ml_dsa_87_ipd_PUBLICKEYBYTES 2592
#define pqcrystals_ml_dsa_87_ipd_SECRETKEYBYTES 4896
#define pqcrystals_ml_dsa_87_ipd_BYTES 4627

#define pqcrystals_ml_dsa_87_ipd_ref_PUBLICKEYBYTES pqcrystals_ml_dsa_87_ipd_PUBLICKEYBYTES
#define pqcrystals_ml_dsa_87_ipd_ref_SECRETKEYBYTES pqcrystals_ml_dsa_87_ipd_SECRETKEYBYTES
#define pqcrystals_ml_dsa_87_ipd_ref_BYTES pqcrystals_ml_dsa_87_ipd_BYTES

int pqcrystals_ml_dsa_87_ipd_ref_keypair(uint8_t *pk, uint8_t *sk);

int pqcrystals_ml_dsa_87_ipd_ref_signature(uint8_t *sig, size_t *siglen,
                                        const uint8_t *m, size_t mlen,
                                        const uint8_t *sk);

int pqcrystals_ml_dsa_87_ipd_ref(uint8_t *sm, size_t *smlen,
                              const uint8_t *m, size_t mlen,
                              const uint8_t *sk);

int pqcrystals_ml_dsa_87_ipd_ref_verify(const uint8_t *sig, size_t siglen,
                                     const uint8_t *m, size_t mlen,
                                     const uint8_t *pk);

int pqcrystals_ml_dsa_87_ipd_ref_open(uint8_t *m, size_t *mlen,
                                   const uint8_t *sm, size_t smlen,
                                   const uint8_t *pk);


#endif
