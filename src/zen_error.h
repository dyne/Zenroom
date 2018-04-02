#ifndef __ZEN_ERROR_H__
#define __ZEN_ERROR_H__

#include <stdarg.h>
#include <lua.h>

int lerror(lua_State *L, const char *fmt, ...);

void *zalloc(lua_State *L, size_t size);

#define ERROR() error("Error in %s",__func__)
#define SAFE(x) if(!x) lerror(L, "NULL variable in %s",__func__)
#define FREE(p) if(p){func("free(%p)",p); free(p);}
#define HERE() func("-> %s()",__func__)
#endif
