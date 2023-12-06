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
 */

#include <stdlib.h>
#include <math.h>
#include <float.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <zen_error.h>
#include <lua_functions.h>

#include <amcl.h>

#include <zenroom.h>
#include <zen_octet.h>
#include <zen_memory.h>

#include <zen_time.h>

int _string_from_time(char dest[1024], ztime_t src) {
	char *format = "%d";

	size_t ubufsz = snprintf(dest, 1024, format, src);
	if(ubufsz >= 1024) {
		return -1;
	}
	register int bufsz = (int)ubufsz;

	return bufsz;
}


ztime_t *time_new(lua_State *L) {
	ztime_t *number = (ztime_t *)lua_newuserdata(L, sizeof(ztime_t));
	if(!number) {
		zerror(L, "Error allocating a new int in %s", __func__);
		return NULL;
	}
	*number = 0;
	luaL_getmetatable(L, "zenroom.time");
	lua_setmetatable(L, -2);
	return number;
}

static void time_free(lua_State *L, ztime_t *f) {
	Z(L);
	if(f) {
		free(f);
		Z->memcount_times--;

	}
}

ztime_t* time_arg(lua_State *L, int n) {
	Z(L);
	ztime_t *result = (ztime_t*)malloc(sizeof(ztime_t));
	if(result == NULL) {
		return NULL;
	}
	void *ud = luaL_testudata(L, n, "zenroom.time");
	if(ud) {
		*result = *(ztime_t*)ud;
		Z->memcount_times++;
		return result;
	}
	octet *o = o_arg(L, n);
	if(o) {
		char *pEnd = NULL;
		*result = strtol(o->val, &pEnd, 10);
		if(*pEnd) {
			free(result);
			result = NULL;
		}
		o_free(L, o);
	}

	if(result) Z->memcount_times++;
	return result;
}

octet *new_octet_from_time(lua_State *L, ztime_t t) {
	octet *o;
	o = o_alloc(L, sizeof(ztime_t));
	// TODO: check endianness
	memcpy(o->val, &t, sizeof(ztime_t));
	o->len = sizeof(ztime_t);
	return o;
}
/***
    Create a new float number. If an argument is present,
    import it as @{OCTET} and initialise it with its value.

    @param[opt] octet value
    @return a new float number
    @function T.new(octet)
*/
static int newtime(lua_State *L) {
	BEGIN();
	if(lua_isstring(L, 1)) {
		const char* arg = lua_tostring(L, 1);
		ztime_t *tm = time_new(L);
		if(!tm) {
			zerror(L, "Could not create time object");
			return 0;
		}
		char *pEnd;
		*tm = strtol(arg, &pEnd, 10);
		if(*pEnd) {
			zerror(L, "Could not parse unix timestamp %s", arg);
			return 0;
		}
		return 1;
	}
	// number argument, import
	if(lua_isnumber(L, 1)) {
		lua_Number number = lua_tonumber(L, 1);
		ztime_t *tm = time_new(L);
		if(!tm) {
			lerror(L, "Could not create time object");
			return 0;
		}
		*tm = (int)number;
		END(1);
	}
	// octet argument, import
	char *failed_msg = NULL;
	octet *o = o_arg(L, 1);
	if(!o) {
		failed_msg = "Could not allocate octet";
		goto end;
	}
	char *pEnd = NULL;
	ztime_t* tm = time_new(L);
	if(!tm) {
		failed_msg = "Could not create float number";
		goto end;
	}
	*tm = strtol(o->val, &pEnd, 10);
	if(*pEnd) {
		failed_msg = "Could not parse float number";
		goto end;
	}
end:
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/*static int is_time(lua_State *L) {
	BEGIN();
	int result = 0;
	if(lua_isnumber(L, 1)) {
		result = 1;
	} else if(lua_isstring(L, 1)) {
		const char* arg = lua_tostring(L, 1);
		float *flt = float_new(L);
		if(!flt) {
			THROW("Could not create float number");
		}
		char *pEnd;
		*flt = strtof(arg, &pEnd);
		result = (*pEnd == '\0');
	}
	lua_pushboolean(L, result);
	END(1);
}*/

static int time_to_octet(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *o = NULL;
	ztime_t *c = time_arg(L,1);
	if(!c) {
		failed_msg = "Could not read float input";
		goto end;
	}
	o = new_octet_from_time(L, *c);
	if(o == NULL) {
		failed_msg = "Could not create octet";
		goto end;
	}
	o_dup(L, o);
end:
	time_free(L,c);
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}

	END(1);
}

static int time_eq(lua_State *L) {
	BEGIN();
	ztime_t *a,*b;
	a = time_arg(L,1);
	b = time_arg(L,2);
	if(a && b) {
		lua_pushboolean(L, *a == *b);
	}
	time_free(L,a);
	time_free(L,b);
	if(!a || !b) {
		THROW("Could not allocate float number");
	}
	END(1);
}

static int time_lt(lua_State *L) {
	BEGIN();
	ztime_t *a = time_arg(L,1);
	ztime_t *b = time_arg(L,2);
	if(a && b) {
		lua_pushboolean(L, *a < *b);
	}
	time_free(L,a);
	time_free(L,b);
	if(!a || !b) {
		THROW("Could not allocate time number");
	}
	END(1);
}

// TODO: could be wrong due to equality
static int time_lte(lua_State *L) {
	BEGIN();
	ztime_t *a = time_arg(L,1);
	ztime_t *b = time_arg(L,2);
	if(a && b) {
		lua_pushboolean(L, *a <= *b);
	}
	time_free(L,a);
	time_free(L,b);
	if(!a || !b) {
		THROW("Could not allocate time number");
	}
	END(1);
}


static int time_to_string(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	ztime_t* c = time_arg(L,1);
	if(c == NULL) {
		failed_msg = "Could not read float";
		goto end;
	}
	char dest[1024];
	int bufsz = _string_from_time(dest, *c);
	if(bufsz < 0) {
		failed_msg = "Output size too big";
		goto end;
	}
	lua_pushstring(L, dest);
end:
	time_free(L,c);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

int luaopen_time(lua_State *L) {
	(void)L;
	const struct luaL_Reg time_class[] = {
		{"new", newtime},
		{"to_octet", time_to_octet},
		//{"is_time", is_time},
		{NULL, NULL}
	};
	const struct luaL_Reg time_methods[] = {
		{"octet", time_to_octet},
		{"__tostring", time_to_string},
		{"__eq", time_eq},
		{"__lt", time_lt},
		{"__lte", time_lte},
		{NULL, NULL}
	};
	zen_add_class(L, "time", time_class, time_methods);
	return 1;
}
