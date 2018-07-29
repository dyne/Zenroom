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
#else
#define HERE() (void)__func__
#define HEREs(s) (void)__func__
#define HEREp(s) (void)__func__
#define HEREn(s) (void)__func__
#endif

#endif
