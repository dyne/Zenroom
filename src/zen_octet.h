
#ifndef __OCTET_H__
#define __OCTET_H__

#include <amcl.h>

// REMEMBER: o_new already pushes the object in lua's stack
octet* o_new(lua_State *L, const int size);

octet *o_dup(lua_State *L, octet *o);

octet* o_arg(lua_State *L,int n);

int o_destroy(lua_State *L);

#endif
