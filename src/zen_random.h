#ifndef __ZEN_RANDOM_H__
#define __ZEN_RANDOM_H__

#include <amcl.h>

// easier name (csprng comes from amcl.h in milagro)
#define RNG csprng

RNG* rng_new(lua_State *L);
RNG* rng_arg(lua_State *L, int n);
int  rng_oct(lua_State *L);
int  rng_big(lua_State *L);

#endif
