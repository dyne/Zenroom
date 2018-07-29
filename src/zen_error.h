#ifndef __ZEN_ERROR_H__
#define __ZEN_ERROR_H__

#include <stdarg.h>
#include <lua.h>

int lerror(lua_State *L, const char *fmt, ...);

void *zalloc(lua_State *L, size_t size);

#define ERROR() error(0, "Error in %s",__func__)
#define SAFE(x) if(!x) lerror(L, "NULL variable in %s",__func__)

// useful for debugging
#if DEBUG == 1
#define HERE() func(0, "-> %s()",__func__)
#define HEREs(s) func(0, "-> %s(%s)",__func__,s)
#define HEREp(p) func(0, "-> %s(%p)",__func__,p)
#define HEREn(n) func(0, "-> %s(%i)",__func__,n)
#define HEREoct(o) \
	func(0, "-> %s - octet %p (%i/%i)",__func__,o->val,o->len,o->max)
#define HEREecdh(e) \
	func(0, "--> %s - ecdh %p\n\tcurve[%s] type[%s]\n\tkeysize[%i] fieldsize[%i] hash[%i]\n\tpubkey[%p(%i/%i)] publen[%i]\n\tseckey[%p(%i/%i)] seclen[%i]",__func__, e, e->curve, e->type, e->keysize, e->fieldsize, e->hash, e->pubkey, e->pubkey?e->pubkey->len:0x0, e->pubkey?e->pubkey->max:0x0, e->publen, e->seckey, e->seckey?e->seckey->len:0x0, e->seckey?e->seckey->max:0x0, e->seclen)
#else
#define HERE() (void)__func__
#define HEREs(s) (void)__func__
#define HEREp(s) (void)__func__
#define HEREn(s) (void)__func__
#define HEREoct(o) (void)__func__
#define HEREecdh(o) (void)__func__
#endif

#endif
