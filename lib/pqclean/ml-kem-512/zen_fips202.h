#ifndef ZEN_FIPS202.H
#define ZEN_FIPS202.H

#include <stddef.h>
#include <stdint.h>
#include <fips202.h>

#define shake128_init(state) shake128_inc_init((shake128incctx *)(state))
#define shake128_release(state) shake128_ctx_release(state)

#define shake128_absorb_once(state, in0, inlen) shake128_absorb_once((shake128incctx *)(state), in0, inlen)

#endif