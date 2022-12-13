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

#include <zen_float.h>

// TODO: precision in conf
#define EPS 0.000001

int _string_from_float(char dest[1024], float src) {
	// for small number use decimal notation, while
	// for big one use exponential notation
	char *format = (src > 1000000) ? "%e" : "%f";

	size_t ubufsz = snprintf(dest, 1024, format, src);
	if(ubufsz >= 1024) {
		return -1;
	}
	register int bufsz = (int)ubufsz;

	// Remove tailing zeros (after .)
	int last_zero = -1;
	bool dot = false;
	if(bufsz > 0 && format[1] == 'f') {
		bufsz--;
		while(bufsz >= 0 && !dot) {
			if(last_zero < 0 && dest[bufsz] != '0') {
				last_zero = bufsz + 1;;
			}
			if(dest[bufsz] == '.') {
				dot = true;
				// if last zero is immediately after the
				// dot, remove also the dot
				if(last_zero == bufsz+1) {
					last_zero--;
				}
			}
			bufsz--;
		}
		bufsz++;
		if(dot) {
			dest[last_zero] = '\0';
		}
	}
	return bufsz;

}

octet *new_octet_from_float(lua_State *L, float *f) {
	octet *o;
	char dest[1024];
	int bufsz = _string_from_float(dest, *f);
	if(bufsz < 0) {
		zerror(L, "Output size too big");
		return NULL;
	}
	o = o_alloc(L, bufsz);
	register int i;
	for(i=0; i<bufsz; i++) {
		o->val[i] = dest[i];
	}
	o->len = bufsz;
	return o;
}

float *float_new(lua_State *L) {
	float *number = (float *)lua_newuserdata(L, sizeof(float));
	if(!number) {
		zerror(L, "Error allocating a new float in %s", __func__);
		return NULL;
	}
	*number = 0;
	luaL_getmetatable(L, "zenroom.float");
	lua_setmetatable(L, -2);
	return number;
}

static void float_free(lua_State *L, float *f) {
	Z(L);
	if(f) {
		free(f);
		Z->memcount_floats--;

	}
}

float* float_arg(lua_State *L, int n) {
	Z(L);
	float *result = (float*)malloc(sizeof(float));
	if(result == NULL) {
		return NULL;
	}
	void *ud = luaL_testudata(L, n, "zenroom.float");
	if(ud) {
		*result = *(float*)ud;
		Z->memcount_floats++;
		return result;
	}
	octet *o = o_arg(L, n);
	if(o) {
		char *pEnd = NULL;
		*result = strtof(o->val, &pEnd);
		if(*pEnd) {
			free(result);
			result = NULL;
		}
		o_free(L, o);
	}

	if(result) Z->memcount_floats++;
	return result;
}

/***
    Create a new float number. If an argument is present,
    import it as @{OCTET} and initialise it with its value.

    @param[opt] octet value
    @return a new float number
    @function F.new(octet)
*/
static int newfloat(lua_State *L) {
	BEGIN();
	if(lua_isstring(L, 1)) {
		const char* arg = lua_tostring(L, 1);
		float *flt = float_new(L);
		if(!flt) {
			lerror(L, "Could not create float number");
			return 0;
		}
		char *pEnd;
		*flt = strtof(arg, &pEnd);
		if(*pEnd || isnan(*flt) || isinf(*flt)) {
			lerror(L, "Could not parse float number %s", arg);
			return 0;
		}
		return 1;
	}
	// number argument, import
	if(lua_isnumber(L, 1)) {
		lua_Number number = lua_tonumber(L, 1);
		float *flt = float_new(L);
		if(!flt) {
			lerror(L, "Could not create float number");
			return 0;
		}
		*flt = (float)number;
		return 1;
	}
	// octet argument, import
	char *failed_msg = NULL;
	octet *o = o_arg(L, 1);
	if(!o) {
		failed_msg = "Could not allocate octet";
		goto end;
	}
	char *pEnd = NULL;
	float* f = float_new(L);
	if(!f) {
		failed_msg = "Could not create float number";
		goto end;
	}
	*f = strtof(o->val, &pEnd);
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

static int is_float(lua_State *L) {
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
}

static int float_to_octet(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *o = NULL;
	float *c = float_arg(L,1);
	if(!c) {
		failed_msg = "Could not read float input";
		goto end;
	}
	o = new_octet_from_float(L, c);
	if(o == NULL) {
		failed_msg = "Could not create octet";
		goto end;
	}
	o_dup(L, o);
end:
	float_free(L,c);
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}

	END(1);
}

static int float_eq(lua_State *L) {
	BEGIN();
	float *a,*b;
	a = float_arg(L,1);
	b = float_arg(L,2);
	if(a && b) {
		lua_pushboolean(L, fabs(*a - *b) < EPS);
	}
	// ref. https://stackoverflow.com/a/4915891
	// TODO: try these tests https://floating-point-gui.de/errors/NearlyEqualsTest.java
	/*const float absA = fabs(*a);
	const float absB = fabs(*b);
	const float diff = fabs(*a-*b);

	char res = 0;
	if (*a == *b) { // shortcut, handles infinities
		res = 1;
	} else if(*a == 0 || *b == 0 || diff < FLT_MIN) {
		// a or b is zero or both are extremely close to it
		// relative error is less meaningful here
		res = (diff < (EPS * FLT_MIN));
	} else {  // use relative error
		res = (diff / (absA + absB) < EPS);
	}*/
	float_free(L,a);
	float_free(L,b);
	if(!a || !b) {
		THROW("Could not allocate float number");
	}
	END(1);
}

static int float_lt(lua_State *L) {
	BEGIN();
	float *a = float_arg(L,1);
	float *b = float_arg(L,2);
	if(a && b) {
		lua_pushboolean(L, *a < *b);
	}
	float_free(L,a);
	float_free(L,b);
	if(!a || !b) {
		THROW("Could not allocate float number");
	}
	END(1);
}

// TODO: could be wrong due to equality
static int float_lte(lua_State *L) {
	BEGIN();
	float *a = float_arg(L,1);
	float *b = float_arg(L,2);
	if(a && b) {
		lua_pushboolean(L, *a <= *b);
	}
	float_free(L,a);
	float_free(L,b);
	if(!a || !b) {
		THROW("Could not allocate float number");
	}
	END(1);
}

static int float_add(lua_State *L) {
	BEGIN();
	float *a = float_arg(L,1);
	float *b = float_arg(L,2);
	float *c = float_new(L);
	if(a && b && c) {
		*c = *a + *b;
	}
	float_free(L,a);
	float_free(L,b);
	if(!a || !b || !c) {
		THROW("Could not allocate float number");
	}
	END(1);
}

static int float_opposite(lua_State *L) {
	BEGIN();
	float *a = float_arg(L,1);
	float *b = float_new(L);
	if(a && b) {
		*b = -(*a);
	}
	float_free(L,a);
	if(!a || !b) {
		THROW("Could not allocate float number");
	}
	END(1);
}

static int float_sub(lua_State *L) {
	BEGIN();
	float *a = float_arg(L,1);
	float *b = float_arg(L,2);
	float *c = float_new(L);
	if(a && b && c) {
		*c = *a - *b;
	}
	float_free(L,a);
	float_free(L,b);
	if(!a || !b || !c) {
		THROW("Could not allocate float number");
	}
	END(1);
}

static int float_mul(lua_State *L) {
	BEGIN();
	float *a = float_arg(L,1);
	float *b = float_arg(L,2);
	float *c = float_new(L);
	if(a && b && c) {
		*c = *a * *b;
	}
	float_free(L,a);
	float_free(L,b);
	if(!a || !b || !c) {
		THROW("Could not allocate float number");
	}
	END(1);
}

static int float_div(lua_State *L) {
	BEGIN();
	float *a = float_arg(L,1);
	float *b = float_arg(L,2);
	float *c = float_new(L);
	if(a && b && c) {
		// TODO: what happen if I divide by 0?
		*c = *a / *b;
	}
	float_free(L,a);
	float_free(L,b);
	if(!a || !b || !c) {
		THROW("Could not allocate float number");
	}
	END(1);
}

static int float_mod(lua_State *L) {
	BEGIN();
	float *a = float_arg(L,1);
	float *b = float_arg(L,2);
	float *c = float_new(L);
	if(a && b && c) {
		// TODO: what happen if I divide by 0?
		*c = fmod(*a, *b);
	}
	float_free(L,a);
	float_free(L,b);
	if(!a || !b || !c) {
		THROW("Could not allocate float number");
	}
	END(1);
}

static int float_to_string(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	float* c = float_arg(L,1);
	if(c == NULL) {
		failed_msg = "Could not read float";
		goto end;
	}
	char dest[1024];
	int bufsz = _string_from_float(dest, *c);
	if(bufsz < 0) {
		failed_msg = "Output size too big";
		goto end;
	}
	lua_pushstring(L, dest);
end:
	float_free(L,c);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

int luaopen_float(lua_State *L) {
	(void)L;
	const struct luaL_Reg float_class[] = {
		{"new", newfloat},
		{"to_octet", float_to_octet},
		{"eq", float_eq},
		{"add", float_add},
		{"sub", float_sub},
		{"mul", float_mul},
		{"div", float_div},
		{"opposite", float_opposite},
		{"is_float", is_float},
		{NULL, NULL}
	};
	const struct luaL_Reg float_methods[] = {
		{"octet", float_to_octet},
		{"__tostring", float_to_string},
		{"__eq", float_eq},
		{"__lt", float_lt},
		{"__lte", float_lte},
		{"__add", float_add},
		{"__sub", float_sub},
		{"__mul", float_mul},
		{"__div", float_div},
		{"__mod", float_mod},
		{NULL, NULL}
	};
	zen_add_class(L, "float", float_class, float_methods);
	return 1;
}
