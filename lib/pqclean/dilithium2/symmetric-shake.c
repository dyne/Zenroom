#include "fips202.h"
#include "params.h"
#include "symmetric.h"
#include <stdint.h>

void PQCLEAN_DILITHIUM2_CLEAN_dilithium_shake128_stream_init(sha3 *state, const uint8_t seed[SEEDBYTES], uint16_t nonce) {
    uint8_t t[2];
    t[0] = (uint8_t) nonce;
    t[1] = (uint8_t) (nonce >> 8);

    SHA3_init(state, 16);
    for(int i=0; i<SEEDBYTES; i++) SHA3_process(state, seed[i]);
    for(int i=0; i<2; i++) SHA3_process(state, t[i]);
}

void stream128_squeezeblocks(uint8_t *output, size_t outlen, sha3 *state) {
    SHA3_shake(state, (char*)output, (int)outlen * SHAKE128_RATE);
}

void stream128_release(sha3* state) {
    (void)state;
    return;
}

void PQCLEAN_DILITHIUM2_CLEAN_dilithium_shake256_stream_init(shake256incctx *state, const uint8_t seed[CRHBYTES], uint16_t nonce) {
    uint8_t t[2];
    t[0] = (uint8_t) nonce;
    t[1] = (uint8_t) (nonce >> 8);

    shake256_inc_init(state);
    shake256_inc_absorb(state, seed, CRHBYTES);
    shake256_inc_absorb(state, t, 2);
    shake256_inc_finalize(state);
}
