#include <stdint.h>

#include "api.h"
#include <zenroom.h>

static int fail_rng(void *context, void *output, size_t length) {
    (void)context;
    (void)output;
    (void)length;
    return -1;
}

int main(void) {
    uint8_t pk[PQCLEAN_SNTRUP761_CLEAN_CRYPTO_PUBLICKEYBYTES] = {0};
    uint8_t sk[PQCLEAN_SNTRUP761_CLEAN_CRYPTO_SECRETKEYBYTES] = {0};
    uint8_t ct[PQCLEAN_SNTRUP761_CLEAN_CRYPTO_CIPHERTEXTBYTES] = {0};
    uint8_t ss[PQCLEAN_SNTRUP761_CLEAN_CRYPTO_BYTES] = {0};
    uint8_t seed[RANDOM_SEED_LEN] = {0};
    zenroom_t context = {0};

    if (zen_rng_init(&context, seed, sizeof(seed)) != 0)
        return 1;
    if (PQCLEAN_SNTRUP761_CLEAN_crypto_kem_keypair_rng(
            pk, sk, zen_rng_callback_fill, &context) != 0) {
        zen_rng_clear(&context);
        return 2;
    }
    zen_rng_clear(&context);

    if (PQCLEAN_SNTRUP761_CLEAN_crypto_kem_keypair_rng(pk, sk, fail_rng, NULL) == 0)
        return 3;
    if (PQCLEAN_SNTRUP761_CLEAN_crypto_kem_enc_rng(ct, ss, pk, fail_rng, NULL) == 0)
        return 4;
    return 0;
}
