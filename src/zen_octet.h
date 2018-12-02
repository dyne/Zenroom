
#ifndef __ZEN_OCTET_H__
#define __ZEN_OCTET_H__

#include <amcl.h>

// REMEMBER: o_new and o_dup push a new object in lua's stack
octet* o_new(lua_State *L, const int size);

octet *o_dup(lua_State *L, octet *o);

octet* o_arg(lua_State *L,int n);

// internal use
// TODO: inverted function signature, see https://github.com/milagro-crypto/milagro-crypto-c/issues/291
#define push_octet_to_hex_string(o)	  \
	{ \
		int odlen = o->len<<1; \
		char *s = zen_memory_alloc(odlen+1); \
		int i; unsigned char ch; \
		for (i=0; i<o->len; i++) { \
		ch=o->val[i]; sprintf(&s[i<<1],"%02x", ch); } \
		s[odlen] = '\0'; \
		lua_pushstring(L,s); \
		zen_memory_free(s); \
	}

#endif
