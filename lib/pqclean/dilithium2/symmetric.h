#ifndef PQCLEAN_DILITHIUM2_CLEAN_SYMMETRIC_H
#define PQCLEAN_DILITHIUM2_CLEAN_SYMMETRIC_H
#include "fips202.h"
#include "params.h"
#include <stdint.h>
#include <amcl.h>


typedef sha3 stream128_state;
typedef shake256incctx stream256_state;

void PQCLEAN_DILITHIUM2_CLEAN_dilithium_shake128_stream_init(sha3 *state,
        const uint8_t seed[SEEDBYTES],
        uint16_t nonce);

void PQCLEAN_DILITHIUM2_CLEAN_dilithium_shake256_stream_init(shake256incctx *state,
        const uint8_t seed[CRHBYTES],
        uint16_t nonce);

#define STREAM128_BLOCKBYTES SHAKE128_RATE
#define STREAM256_BLOCKBYTES SHAKE256_RATE

#define stream128_init(STATE, SEED, NONCE) \
  PQCLEAN_DILITHIUM2_CLEAN_dilithium_shake128_stream_init(STATE, SEED, NONCE)
void stream128_squeezeblocks(uint8_t *output, size_t outlen, sha3 *state);
void stream128_release(sha3* state);

#define stream256_init(STATE, SEED, NONCE)				\
    PQCLEAN_DILITHIUM2_CLEAN_dilithium_shake256_stream_init(STATE, SEED, NONCE)
#define stream256_squeezeblocks(OUT, OUTBLOCKS, STATE) \
    shake256_inc_squeeze(OUT, (OUTBLOCKS)*(SHAKE256_RATE), STATE)
#define stream256_release(STATE) shake256_inc_ctx_release(STATE)


#endif
