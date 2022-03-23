/*
 * This file is part of zenroom
 * 
 * Copyright (C) 2017-2021 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License v3.0
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 * 
 * Along with this program you should have received a copy of the
 * GNU Affero General Public License v3.0
 * If not, see http://www.gnu.org/licenses/agpl.txt
 * 
 * Last modified by Alberto Lerda
 * on 16/03/2022
 */

#include <math.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <zen_error.h>
#include <lua_functions.h>

#include <amcl.h>

#include <zenroom.h>
#include <zen_octet.h>
#include <zen_memory.h>

octet *new_octet_from_float(lua_State *L, float *f) {
        octet *o;
        char *byts = (char*)f;
        register unsigned int i;
        o = o_new(L, sizeof(f));
        for(i=0; i<sizeof(f); i++) {
                o->val[i] = byts[i];
        }
        o->len = sizeof(f);
        return o;
}

static float *float_new(lua_State *L) {
        float *number = (float *)lua_newuserdata(L, sizeof(float));
        if(!number) {
                lerror(L, "Error allocating a new big in %s", __func__);
                return NULL;
        }
        *number = 0;
	luaL_getmetatable(L, "zenroom.float");
	lua_setmetatable(L, -2);
        return number;
}

float *new_float_from_octet(lua_State *L, octet* o) {
        float *f = float_new(L);
        char *byts = (char*)f;
        register unsigned int i;
        if(o->len != sizeof(f)) {
                lerror(L, "Wrong octet size for a float number %d", o->len);
                return NULL;
        }
        for(i=0; i<sizeof(f); i++) {
                 byts[i] = o->val[i];
        }
        return f;
}


/***
    Create a new float number. If an argument is present, import it as @{OCTET} and initialise it with its value.

    @param[opt] octet value
    @return a new float number
    @function F.new(octet)
*/
static int newfloat(lua_State *L) {
	HERE();
	// number argument, import
        if(lua_isnumber(L, 1)) {
                lua_Number number = lua_tonumber(L, 1);
                float *flt = float_new(L);
                *flt = (float)number;
                return 1;
        }
        if(lua_isstring(L, 1)) {
                const char* arg = lua_tostring(L, 1);
                float *flt = float_new(L);
                char *pEnd;
                *flt = strtof(arg, &pEnd);
                if(*pEnd) {
                        lerror(L, "Could not parse float number %s", arg);
                        return 0;
                }
                return 1;
        }
	// octet argument, import
	octet *o = o_arg(L, 1); SAFE(o);
	new_float_from_octet(L, o);
	return 1;
}
static int is_float(lua_State *L) {
        int result = 0;
        if(lua_isnumber(L, 1)) {
                result = 1;
        } else if(lua_isstring(L, 1)) {
                const char* arg = lua_tostring(L, 1);
                float *flt = float_new(L);
                char *pEnd;
                *flt = strtof(arg, &pEnd);
                result = (*pEnd == '\0');
        }
        lua_pushboolean(L, result);
        return 1;
}
float* float_arg(lua_State *L,int n) {
	void *ud = luaL_testudata(L, n, "zenroom.float");
	luaL_argcheck(L, ud != NULL, n, "float class expected");
	if(ud) {
		float *b = (float*)ud;
		return(b);
	}

	octet *o = o_arg(L,n);
	if(o) {
		return new_float_from_octet(L, o);
	}
	lerror(L, "invalib float number in argument");
	return NULL;
}

static int float_to_octet(lua_State *L) {
	float *c = float_arg(L,1); SAFE(c);
	new_octet_from_float(L,c);
	return 1;
}

static int float_eq(lua_State *L) {
	float *a = float_arg(L,1); SAFE(a);
	float *b = float_arg(L,2); SAFE(b);
        lua_pushboolean(L, *a == *b);
	return 1;
}

static int float_add(lua_State *L) {
	float *a = float_arg(L,1); SAFE(a);
	float *b = float_arg(L,2); SAFE(b);
        float *c = float_new(L); SAFE(c);
        *c = *a + *b;
	return 1;
}

static int float_opposite(lua_State *L) {
	float *a = float_arg(L,1); SAFE(a);
        float *b = float_new(L); SAFE(b);
        *b = -(*a);
	return 1;
}

static int float_sub(lua_State *L) {
	float *a = float_arg(L,1); SAFE(a);
	float *b = float_arg(L,2); SAFE(b);
        float *c = float_new(L); SAFE(c);
        *c = *a - *b;
	return 1;
}

static int float_mul(lua_State *L) {
	float *a = float_arg(L,1); SAFE(a);
	float *b = float_arg(L,2); SAFE(b);
        float *c = float_new(L); SAFE(c);
        *c = *a * *b;
	return 1;
}

static int float_div(lua_State *L) {
	float *a = float_arg(L,1); SAFE(a);
	float *b = float_arg(L,2); SAFE(b);
        float *c = float_new(L); SAFE(c);
        *c = *a / *b;
	return 1;
}

static int string_from_float(lua_State *L) {
	float *c = float_arg(L,1); SAFE(c);
        char dest[1024];
        size_t bufsz = snprintf(dest, 1024, "%f", *c);
        if(bufsz >= 1024) {
	        lerror(L, "Output size too big");
                return 0;
        }
        lua_pushstring(L, dest);
	return 1;
}

int luaopen_float(lua_State *L) {
	(void)L;
	const struct luaL_Reg float_class[] = {
		{"new",newfloat},
		{"to_octet",float_to_octet},
		{"eq",float_eq},
		{"add",float_add},
		{"sub",float_sub},
		{"mul",float_mul},
		{"div",float_div},
		{"opposite",float_opposite},
		{"is_float",is_float},
		{NULL,NULL}
	};
	const struct luaL_Reg float_methods[] = {
		{"octet",float_to_octet},
		{"__tostring",string_from_float},
		{"__eq",float_eq},
		{"__add",float_add},
		{"__sub",float_sub},
		{"__mul",float_mul},
		{"__div",float_div},
		{NULL,NULL}
	};
	zen_add_class("float", float_class, float_methods);
	return 1;
}
