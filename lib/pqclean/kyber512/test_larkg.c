#include "indcpa.h"
#include "kyber_larkg.h"
#include "params.h"
#include "skem.h"
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#ifdef LARKG_TEST_RANDOM_FAILURE
static size_t randombytes_calls;
static size_t randombytes_fail_on_call = 1;

int randombytes(void *buf, size_t n) {
    randombytes_calls++;
    memset(buf, 0xa5, n);
    return randombytes_calls == randombytes_fail_on_call ? -1 : 0;
}
#else
extern int randombytes(void *buf, size_t n);
#endif

static int check_keypair(const uint8_t pk[KYBER_INDCPA_PUBLICKEYBYTES],
                         const uint8_t sk[KYBER_LARKG_SECRETKEYBYTES]) {
    uint8_t ciphertext[KYBER_INDCPA_BYTES];
    uint8_t coins[KYBER_SYMBYTES];
    uint8_t message[KYBER_INDCPA_MSGBYTES];
    uint8_t recovered[KYBER_INDCPA_MSGBYTES];

    randombytes(coins, sizeof(coins));
    randombytes(message, sizeof(message));
    PQCLEAN_KYBER512_CLEAN_indcpa_enc(ciphertext, message, pk, coins);
    PQCLEAN_KYBER512_CLEAN_indcpa_dec(recovered, ciphertext, sk);
    return memcmp(message, recovered, sizeof(message)) == 0;
}

static int check_secret_representation(
    const uint8_t sk[KYBER_LARKG_SECRETKEYBYTES]) {
    polyvec encoded;
    polyvec normal;

    PQCLEAN_KYBER512_CLEAN_polyvec_frombytes(&encoded, sk);
    PQCLEAN_KYBER512_CLEAN_skem_secret_to_normal(&normal, sk);

    for (size_t i = 0; i < KYBER_K; i++) {
        for (size_t j = 0; j < KYBER_N; j++) {
            if (normal.vec[i].coeffs[j] < -KYBER_ETA1 ||
                normal.vec[i].coeffs[j] > KYBER_ETA1) {
                return 0;
            }
        }
    }
    PQCLEAN_KYBER512_CLEAN_polyvec_ntt(&normal);

    for (size_t i = 0; i < KYBER_K; i++) {
        PQCLEAN_KYBER512_CLEAN_poly_reduce(&normal.vec[i]);
        PQCLEAN_KYBER512_CLEAN_poly_reduce(&encoded.vec[i]);
    }
    return memcmp(&encoded, &normal, sizeof(encoded)) == 0;
}

static int check_secret_corruption_rejected(
    const uint8_t sk[KYBER_LARKG_SECRETKEYBYTES]) {
    uint8_t malformed[KYBER_LARKG_SECRETKEYBYTES];
    uint8_t next_sk[KYBER_LARKG_SECRETKEYBYTES];
    larkg_cred_t credential = {0};

    memcpy(malformed, sk, sizeof(malformed));
    malformed[0] = 0xff;
    malformed[1] = (uint8_t)((malformed[1] & 0xf0) | 0x0f);
    if (PQCLEAN_KYBER512_CLEAN_skem_secret_is_canonical(malformed)) {
        return 0;
    }
    return PQCLEAN_KYBER512_CLEAN_larkg_derive_sk(
               next_sk, malformed, &credential) == LARKG_PARAMETER_MISMATCH;
}

int main(void) {
    uint8_t rho[KYBER_SYMBYTES];
    uint8_t current_pk[KYBER_INDCPA_PUBLICKEYBYTES];
    uint8_t current_sk[KYBER_LARKG_SECRETKEYBYTES];
    skem_context ctx;

#ifdef LARKG_TEST_RANDOM_FAILURE
    larkg_cred_t credential;
    uint8_t next_pk[KYBER_INDCPA_PUBLICKEYBYTES];
    memset(current_pk, 0xa5, sizeof(current_pk));
    memset(current_sk, 0xa5, sizeof(current_sk));
    memset(rho, 0, sizeof(rho));
    PQCLEAN_KYBER512_CLEAN_skem_init(&ctx, rho);
    if (PQCLEAN_KYBER512_CLEAN_skem_keygen(current_pk, current_sk, &ctx) == 0 ||
        memcmp(current_pk, (uint8_t[KYBER_INDCPA_PUBLICKEYBYTES]){0}, sizeof(current_pk)) != 0 ||
        memcmp(current_sk, (uint8_t[KYBER_LARKG_SECRETKEYBYTES]){0}, sizeof(current_sk)) != 0) {
        fputs("LARKG RNG failure leaked key-generation output\n", stderr);
        return 1;
    }

    /* derive_pk draws once in keygen_enc, twice in encaps, then once for E'.
     * Fail that fourth draw directly so the final entropy site cannot regress
     * to consuming its buffer and reporting success. */
    randombytes_calls = 0;
    randombytes_fail_on_call = 4;
    memset(&credential, 0xa5, sizeof(credential));
    memset(next_pk, 0xa5, sizeof(next_pk));
    if (PQCLEAN_KYBER512_CLEAN_larkg_derive_pk(next_pk, &credential,
                                                current_pk, &ctx) != LARKG_ENTROPY_FAILURE ||
        randombytes_calls != randombytes_fail_on_call ||
        memcmp(&credential, &(larkg_cred_t){0}, sizeof(credential)) != 0 ||
        memcmp(next_pk, (uint8_t[KYBER_INDCPA_PUBLICKEYBYTES]){0},
               sizeof(next_pk)) != 0) {
        fputs("LARKG RNG failure leaked derivation credential output\n", stderr);
        return 1;
    }
    return 0;
#endif

    randombytes(rho, sizeof(rho));
    PQCLEAN_KYBER512_CLEAN_skem_init(&ctx, rho);
    if (PQCLEAN_KYBER512_CLEAN_skem_keygen(current_pk, current_sk, &ctx) != 0) {
        fputs("LARKG initial key generation exhausted entropy\n", stderr);
        return 1;
    }
    if (!check_secret_representation(current_sk)) {
        fputs("LARKG secret serialization does not round-trip through normal coefficients\n", stderr);
        return 1;
    }
    if (!check_secret_corruption_rejected(current_sk)) {
        fputs("LARKG accepted a non-canonical secret-key encoding\n", stderr);
        return 1;
    }
    if (!check_keypair(current_pk, current_sk)) {
        fputs("LARKG initial keypair does not decrypt\n", stderr);
        return 1;
    }

    {
        uint8_t next_pk[KYBER_INDCPA_PUBLICKEYBYTES];
        uint8_t next_sk[KYBER_LARKG_SECRETKEYBYTES];
        larkg_cred_t credential;

        PQCLEAN_KYBER512_CLEAN_larkg_derive_pk(
            next_pk, &credential, current_pk, &ctx);
        if (PQCLEAN_KYBER512_CLEAN_larkg_derive_sk(
                next_sk, current_sk, &credential) != LARKG_PARAMETER_MISMATCH) {
            fputs("LARKG accepted a derivation despite the depth-zero contract\n", stderr);
            return 1;
        }
        credential.mu[0] ^= 1;
        if (PQCLEAN_KYBER512_CLEAN_larkg_derive_sk(
                next_sk, current_sk, &credential) != LARKG_PARAMETER_MISMATCH) {
            fputs("LARKG leaked authentication processing beyond the depth-zero gate\n", stderr);
            return 1;
        }
    }

    return 0;
}
