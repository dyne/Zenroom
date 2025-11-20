/*
 * This file is part of zenroom
 *
 * Copyright (C) 2017-2025 Dyne.org foundation
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

/// <h1>TIME</h1>
//This class allows to work with TIME objects. All TIME objects are float number.
//Since all TIME objects are 32 bit signed, there are two limitations for values allowed:
//
//-The MAXIMUM TIME value allowed is the number 2147483647 (<code>t_max = TIME.new(2147483647)</code>)
//
//-The MINIMUM TIME value allowed is the number -2147483647 (<code>t_min = TIME.new(-2147483647)</code>) 
//@module TIME


#include <errno.h>
#include <stdlib.h>
#include <math.h>
#include <float.h>

#include <zen_error.h>
#include <lua_functions.h>

#include <amcl.h>

#include <zen_octet.h>

#include <zen_time.h>

#include <zenroom.h>

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
		zerror(L, "Error allocating a new time in %s", __func__);
		return NULL;
	}
	*number = 0;
	luaL_getmetatable(L, "zenroom.time");
	lua_setmetatable(L, -2);
	return number;
}

static void time_free(lua_State *L, ztime_t *f) {
	(void)L;
	if(f) free(f);
}

ztime_t* time_arg(lua_State *L, int n) {
	Z(L);
	ztime_t *result = (ztime_t*)malloc(sizeof(ztime_t));
	if(result == NULL) {
		zerror(L, "Could not create time, malloc failure: %s", strerror(errno));
		return NULL;
	}
	void *ud = luaL_testudata(L, n, "zenroom.time");
	if(ud) {
		*result = *(ztime_t*)ud;
		goto end;
	}
	if(lua_isstring(L, 1)) {
		const char* arg = lua_tostring(L, 1);
		char *pEnd;
		long l_result = strtol(arg, &pEnd, 10);
		if(*pEnd) {
			free(result);
			lerror(L, "Could not read unix timestamp %s", arg);
			return NULL;
		} else {
			char s_result[1024];
			snprintf(s_result, 1024, "%ld", l_result);
			if (l_result < INT_MIN || l_result > INT_MAX || strcmp(s_result, arg) != 0 ) {
				free(result);
				lerror(L, "Could not read unix timestamp %s out of range", arg);
				return NULL;
			}
		}
		*result = (ztime_t)l_result;
		goto end;
	}
	// number argument, import
	if(lua_isnumber(L, 1)) {
		lua_Number number = lua_tonumber(L, 1);
		*result = (int)number;
		goto end;
	}
	const octet *o = o_arg(L, n);
	if(o) {
		if(o->len != sizeof(ztime_t)) {
			o_free(L, o);
			free(result);
			zerror(L, "Wrong size timestamp %s", __func__);
			return NULL;
		}
		memcpy(result, o->val, sizeof(ztime_t));
		o_free(L, o);
		goto end;
	}
end:
	return result;
}

octet *new_octet_from_time(lua_State *L, ztime_t t) {
	octet *o = o_alloc(L, sizeof(ztime_t));
	if(!o) return NULL;
	// TODO: check endianness
	memcpy(o->val, &t, sizeof(ztime_t));
	o->len = sizeof(ztime_t);
	return o;
}

/// Global TIME Functions
// @type TIME



/***
    Create a new time. If an argument is present,
    *import it as @{OCTET} and initialise it with its value.

    @param[opt] octet value (32 bit)
    @return a new float number
    @function TIME.new
*/
static int newtime(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	ztime_t *c = time_arg(L,1); SAFE_GOTO(c, ALLOCATE_TIME_ERR);
	ztime_t *tm = time_new(L); SAFE_GOTO(tm, CREATE_TIME_ERR);
	*tm = *c;
end:
	time_free(L, c);
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


/***
 It checks if the given input (either a number or a string) falls within a specific range of time values.
 @function TIME.detect_time_value
 @param t a time value
 @return a boolean value: true if the time value is too much big or too much low. false, otherwise
 */
static int detect_time_value(lua_State *L) {
	BEGIN();
	int result = 0;
	if(lua_isnumber(L, 1)) {
		lua_Number n = lua_tonumber(L, 1);
		if (n >= INT_MIN && n <= INT_MAX) {
			result = n >= AUTODETECTED_TIME_MIN && n <= AUTODETECTED_TIME_MAX;
		}
	} else if(lua_isstring(L, 1)) {
		const char* arg = lua_tostring(L, 1);
		char *pEnd;
		long l_result = strtol(arg, &pEnd, 10);
		result = (*pEnd == '\0' && l_result >= AUTODETECTED_TIME_MIN && l_result <= AUTODETECTED_TIME_MAX);
	}
	lua_pushboolean(L, result);
	END(1);
}

/// Object Methods
// @type TIME


static int time_to_octet(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *o = NULL;
	ztime_t *c = time_arg(L,1); SAFE_GOTO(c, ALLOCATE_TIME_ERR);
	o = new_octet_from_time(L, *c); SAFE_GOTO(o, "Could not create octet from time");
	SAFE_GOTO(o_dup(L, o), DUPLICATE_OCT_ERR);
end:
	time_free(L, c);
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}

	END(1);
}

/***
 Allow to do the sum between two time object.
 @function time:__add
 @return return the sum if it allowed. It might be return the error message "Result of addition out of range" if the result of the sum is too much big
 @param t2 the time to sum		
 @usage
 oct1 = OCTET.random(4)
 oct2 = OCTET.random(4)
 t1 = time.new(oct1)		
 t2 = time.new(oct2)		
 sum = t1:__add(t2)	

 */

 static int time_add(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	ztime_t *a = time_arg(L, 1);
	ztime_t *b = time_arg(L, 2);
	SAFE_GOTO(a && b, ALLOCATE_TIME_ERR);
	ztime_t *c = time_new(L); SAFE_GOTO(c, CREATE_TIME_ERR);
	// manage possible overflow
	SAFE_GOTO(*a <= 0 || *b <= 0 || *a <= INT_MAX - *b, "Result of addition out of range");
	SAFE_GOTO(*a >= 0 || *b >= 0 || *a >= INT_MIN - *b, "Result of addition out of range");
	*c = *a + *b;
end:
	time_free(L, a);
	time_free(L, b);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/*** Allow to subtract two time object.
 @function time:__sub
 @return return the subtraction if it allowed. It might be return the error message "Result of subtraction out of range" if the result of the subtraction is too much big
 @param t2 the time to subtract	
 @usage
 The same of the method __add()	
 */

static int time_sub(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	ztime_t *a = time_arg(L, 1);
	ztime_t *b = time_arg(L, 2);
	SAFE_GOTO(a && b, ALLOCATE_TIME_ERR);
	ztime_t *c = time_new(L); SAFE_GOTO(c, CREATE_TIME_ERR);
	// manage possible overflow
	SAFE_GOTO(*a <= 0 || *b >= 0 || *a <= INT_MAX + *b, "Result of subtraction out of range");
	SAFE_GOTO(*a >= 0 || *b <= 0 || *a >= INT_MIN + *b, "Result of subtraction out of range");
	*c = *a - *b;
end:
	time_free(L, a);
	time_free(L, b);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/*** Calculate the opposite of a time object.
 @function time:__unm
 @return the opposite a time object
 @usage
 oct1 = OCTET.random(4)
 t1 = time.new(oct1)			
 opp = t1:__unm() 	
 */

static int time_opposite(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	ztime_t *a = time_arg(L,1); SAFE_GOTO(a, ALLOCATE_TIME_ERR);
	ztime_t *b = time_new(L); SAFE_GOTO(b, CREATE_TIME_ERR);
	*b = -(*a);
end:
	time_free(L,a);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
 Given two time objects, it checks if they are equal.
 @function time:__eq
 @param t2
 @return a boolean value "true" if they are equal, "false" otherwise
 @usage
 oct1 = OCTET.random(4)
 t1 = time.new(oct1)
 bool = t1:__eq(t1)
 if bool then print("true")		--Output: true
 else print("false")
 end

 */
static int time_eq(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	ztime_t *a,*b;
	a = time_arg(L,1);
	b = time_arg(L,2);
	SAFE_GOTO(a && b, ALLOCATE_TIME_ERR);
	lua_pushboolean(L, *a == *b);
end:
	time_free(L,a);
	time_free(L,b);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
 Given two time object it checks if the first one is less (<) then the second one  
 @function time:__lt
 @return a boolean value "true" if the first argument is less than the second one, "false" otherwise
 @usage
 The same of :__eq()
 */

static int time_lt(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	ztime_t *a = time_arg(L,1);
	ztime_t *b = time_arg(L,2);
	SAFE_GOTO(a && b, ALLOCATE_TIME_ERR);
	lua_pushboolean(L, *a < *b);
end:
	time_free(L, a);
	time_free(L, b);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

// TODO: could be wrong due to equality

/***
 Given two time object it checks if the first one is less (<=) then the second one  
 @function time:__lte
 @return a boolean value "true" if the first argument is less or equal than the second one, "false" otherwise
 @usage
 The same of :__eq()
 */
static int time_lte(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	ztime_t *a = time_arg(L,1);
	ztime_t *b = time_arg(L,2);
	SAFE_GOTO(a && b, ALLOCATE_TIME_ERR);
	lua_pushboolean(L, *a <= *b);
end:
	time_free(L, a);
	time_free(L, b);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
 This method converts a time object to a string
 @function time:__tostring
 @return the string representation of a time object
 @usage
 oct1 = OCTET.random(4)
 t1 = time.new(oct1)
 t1:__tostring()	

*/

static int time_to_string(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	ztime_t* c = time_arg(L, 1); SAFE_GOTO(c, ALLOCATE_TIME_ERR);
	char dest[1024];
	int bufsz = _string_from_time(dest, *c); SAFE_GOTO(bufsz >= 0, "Could not convert time to string");
	lua_pushstring(L, dest);
end:
	time_free(L, c);
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
		{"detect_time_value", detect_time_value},
		{"add", time_add},
		{"sub", time_sub},
		{"opposite", time_opposite},
		{NULL, NULL}
	};
	const struct luaL_Reg time_methods[] = {
		{"octet", time_to_octet},
		{"__tostring", time_to_string},
		{"__eq", time_eq},
		{"__lt", time_lt},
		{"__lte", time_lte},
		{"__add", time_add},
		{"__sub", time_sub},
		{"__unm", time_opposite},
		{NULL, NULL}
	};
	zen_add_class(L, "time", time_class, time_methods);
	return 1;
}
