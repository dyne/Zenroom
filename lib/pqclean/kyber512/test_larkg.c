#include "indcpa.h"
#include "kyber_larkg.h"
#include "params.h"
#include "skem.h"
#include <stdint.h>
#include <stdio.h>
#include <string.h>

extern int randombytes(void *buf, size_t n);

#define MAX_DERIVATION_ATTEMPTS 10000
#define RATCHET_ROUNDS 3

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

int main(void) {
    uint8_t rho[KYBER_SYMBYTES];
    uint8_t current_pk[KYBER_INDCPA_PUBLICKEYBYTES];
    uint8_t current_sk[KYBER_LARKG_SECRETKEYBYTES];
    skem_context ctx;

    randombytes(rho, sizeof(rho));
    PQCLEAN_KYBER512_CLEAN_skem_init(&ctx, rho);
    PQCLEAN_KYBER512_CLEAN_skem_keygen(current_pk, current_sk, &ctx);

    for (int round = 0; round < RATCHET_ROUNDS; round++) {
        uint8_t next_pk[KYBER_INDCPA_PUBLICKEYBYTES];
        uint8_t next_sk[KYBER_LARKG_SECRETKEYBYTES];
        larkg_cred_t credential;
        int result = -1;

        for (int attempt = 0;
             attempt < MAX_DERIVATION_ATTEMPTS && result == -1;
             attempt++) {
            PQCLEAN_KYBER512_CLEAN_larkg_derive_pk(
                next_pk, &credential, current_pk, &ctx);
            result = PQCLEAN_KYBER512_CLEAN_larkg_derive_sk(
                next_sk, current_sk, &credential);
        }

        if (result != 0) {
            fprintf(stderr,
                    "LARKG ratchet round %d did not accept within %d attempts\n",
                    round + 1, MAX_DERIVATION_ATTEMPTS);
            return 1;
        }
        if (!check_keypair(next_pk, next_sk)) {
            fprintf(stderr, "LARKG ratchet round %d keypair mismatch\n", round + 1);
            return 1;
        }

        memcpy(current_pk, next_pk, sizeof(current_pk));
        memcpy(current_sk, next_sk, sizeof(current_sk));
    }

    {
        uint8_t next_pk[KYBER_INDCPA_PUBLICKEYBYTES];
        uint8_t next_sk[KYBER_LARKG_SECRETKEYBYTES];
        larkg_cred_t credential;

        PQCLEAN_KYBER512_CLEAN_larkg_derive_pk(
            next_pk, &credential, current_pk, &ctx);
        credential.mu[0] ^= 1;
        if (PQCLEAN_KYBER512_CLEAN_larkg_derive_sk(
                next_sk, current_sk, &credential) != -2) {
            fputs("LARKG accepted a corrupted authentication tag\n", stderr);
            return 1;
        }
    }

    return 0;
}
