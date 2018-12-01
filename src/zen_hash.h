#ifndef __ZEN_HASH_H__
#define __ZEN_HASH_H__

#include <lua.h>
#include <amcl.h>

#define _SHA256 2
#define _SHA384 3
#define _SHA512 5
#define _SHA3_224 3224
#define _SHA3_256 3256
#define _SHA3_384 3384
#define _SHA3_512 3512

typedef struct {
	char name[16];
	int algo;
	int len;
	hash256 *sha256;
	hash384 *sha384;
	hash512 *sha512;
	// ...
} hash;


hash* hash_new(lua_State *L, const char *hashtype);
hash* hash_arg(lua_State *L, int n);

#endif
