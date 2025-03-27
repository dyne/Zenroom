/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2025 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

/// <h1>Array of raw bytes: base data type in Zenroom</h1>
//
//  Octets are <a
//  href="https://en.wikipedia.org/wiki/First-class_citizen">first-class
//  citizens</a> in Zenroom. They consist of arrays of bytes (8bit)
//  compatible with all cryptographic functions and methods. They are
//  implemented to avoid any buffer overflow and their maximum size is
//  known at the time of instantiation. It is possible to create OCTET
//  instances using the new() method:
//
//  <code>message = OCTET.new(64) -- creates a 64 bytes long octet</code>
//
//  The code above fills all 64 bytes with zeroes; to initialise with
//  random data is possible to use the @{OCTET.random} function:
//
//  <code>random = OCTET.random(32) -- creates a 32 bytes random octet</code>
//
//  Octets can export their contents to a simple @{string} or more
//  portable encodings as sequences of @{url64}, @{base64}, @{hex} or
//  even @{bin} as sequences of binary 0 and 1. They can also be
//  exported to Lua's @{array} format with one element per byte.
//
//  @usage
//  -- import a string as octet using the shortcut function str()
//  hello = str("Hello, World!")
//  -- print in various encoding formats
//  print(hello:string()) -- print octet as string
//  print(hello:hex())    -- print octet as hexadecimal sequence
//  print(hello:base64()) -- print octet as base64
//  print(hello:url64())  -- print octet as base64 url (preferred)
//  print(hello:bin())    -- print octet as a sequence of 0 and 1
//
//  @module OCTET
//  @author Denis "Jaromil" Roio
//  @license AGPLv3
//  @copyright Dyne.org foundation 2017-2019
//
#include <errno.h>

#include <zen_error.h>
#include <lua_functions.h>

#include <amcl.h>

#include <encoding.h>
#include <zen_error.h>
#include <zen_octet.h>
#include <zen_big.h>
#include <zen_float.h>
#include <zen_time.h>
#include <zen_fuzzer.h>
#include <zen_ecp.h>

#include <math.h> // for log2 in entropy calculation

#include <zenroom.h>

// from segwit_addr.c
extern int segwit_addr_encode(char *output, const char *hrp, int witver, const uint8_t *witprog, size_t witprog_len);
extern int segwit_addr_decode(int* witver, uint8_t* witdata, size_t* witdata_len, const char* hrp, const char* addr);

// from base58.c
extern int b58tobin(void *bin, size_t *binszp, const char *b58, size_t b58sz);
extern int b58enc(char *b58, size_t *b58sz, const void *data, size_t binsz);

// from zenroom types that are convertible to octet
// they don't do any internal memory allocation
// all arguments are allocated and freed by the caller
extern int _ecp_to_octet(octet *o, ecp *e);
extern int _ecp2_to_octet(octet *o, ecp2 *e);

static inline int _max(int x, int y) { if(x > y) return x;	else return y; }
static int _min(int x, int y) { if(x < y) return x;	else return y; }

#include <ctype.h>

extern int _octet_to_big(lua_State *L, big *dst, const octet *src);

// assumes null terminated string
// returns 0 if not base else length of base encoded string
int is_base64(const char *in) {
	if(!in) { return 0; }
	int c;
	// check b64: header
	// if(in[0]!='b' || in[1]!='6' || in[2]!='4' || in[3]!=':') return 0;
	// check all valid characters
	for(c=0; in[c]!='\0'; c++) {
		if (!(isalnum(in[c])
			  || '+' == in[c]
			  || '=' == in[c]
			  || '/' == in[c])) {
			return 0; }
	}
	return c;
}

void push_octet_to_hex_string(lua_State *L, octet *o) {
	char *s = malloc((o->len<<1)+1); // string len = double +1
	buf2hex(s, o->val, o->len);
	lua_pushstring(L,s);
	free(s);
	return;
}

extern const int8_t b58digits_map[];
// extern const char b58digits_ordered[];
int is_base58(lua_State *L, const char *in) {
	if(!in) {
		func(L, "null string in is_base58");
		return 0; }
	int c;
	for(c=0; in[c]!='\0'; c++) {
		if(b58digits_map[(int8_t)in[c]]==-1) {
			func(L, "invalid base58 digit");
			return 0; }
		if(in[c] & 0x80) {
			func(L, "high-bit set on invalid digit");
			return 0; }
	}
	return c;
}

int is_hex(lua_State *L, const char *in) {
	(void)L;
	if(!in) { zerror(L, "Error in %s",__func__); return 0; }
	if ( (in[0] == '0') && (in[1] == 'x') ) {
		in+=2;
	}
	int c;
	for(c=0; in[c]!=0; c++) {
		if (!isxdigit(in[c])) {
			return 0; }
	}
	return c;
}

// return total string length including spaces
int is_bin(lua_State *L, const char *in) {
	(void)L;
	if(!in) { zerror(L, "Error in %s",__func__); return 0; }
	register int c;
	register int len = 0;
	for(c=0; in[c]!='\0'; c++) {
		if (in[c]!='0' && in[c]!='1' && !isspace(in[c])) return 0;
		len++;
	}
	return len;
}

// allocate octet without internally, no lua involved
octet* o_alloc(lua_State *L, int size) {
	if(HEDLEY_UNLIKELY(size<0)) {
		zerror(L, "Cannot create octet, size less than zero");
		return NULL; }
	if(HEDLEY_UNLIKELY(size>MAX_OCTET)) {
		zerror(L, "Cannot create octet, size too big: %u", size);
		return NULL; }
	register int os = sizeof(octet);
	octet *o = malloc(os);
	if(!o) {
		zerror(L, "Cannot create octet, malloc failure: %s",
			   strerror(errno));
		return NULL; }
	Z(L);
	o->val = malloc(size +0x0f);
	if(!o->val) {
		zerror(L, "Cannot create octet value, malloc: %s",
			   strerror(errno));
		return NULL; }
	o->max = size;
	o->len = 0;
	o->val[0] = 0x0;
	o->ref = 1;
	return(o);
}

void o_free(lua_State *L, const octet *o) {
	(void)L;
	if(HEDLEY_UNLIKELY(o==NULL)) return; // accepts NULL args with no errors
	octet *t = (octet*)o; // remove const static check
	t->ref--;
	if(t->ref>0) return;
	if(HEDLEY_LIKELY(t->val!=NULL)) free(t->val);
	free(t);
	return;
}

// REMEMBER: newuserdata already pushes the object in lua's stack
octet* o_new(lua_State *L, const int size) {
	if(HEDLEY_UNLIKELY(size<0)) {
		zerror(L, "Cannot create octet, size less than zero");
		return NULL; }
	if(HEDLEY_UNLIKELY(size>MAX_OCTET)) {
		zerror(L, "Cannot create octet, size too big: %u", size);
		return NULL; }
	octet *o = (octet *)lua_newuserdata(L, sizeof(octet));
	if(HEDLEY_UNLIKELY(o==NULL)) {
		zerror(L, "Cannot create octet, lua_newuserdata failure");
		return NULL; }
	luaL_getmetatable(L, "zenroom.octet");
	lua_setmetatable(L, -2);
	o->val = malloc(size +0x0f);
	if(HEDLEY_UNLIKELY(o->val==NULL)) {
		zerror(L, "Cannot create octet, malloc failure");
		zerror(L, "%s: %s",__func__,strerror(errno));
		return NULL; }
	o->len = 0;
	o->max = size;
	o->ref = 1;
	// func(L, "new octet (%u bytes)",size);
	return(o);
}

// here most internal type conversions happen
const octet* o_arg(lua_State *L, int n) {
	void *ud;
	octet *o = NULL;
	const char *type = luaL_typename(L, n);
	o = (octet*) luaL_testudata(L, n, "zenroom.octet"); // new
	if(o) {
		if(o->len>MAX_OCTET) {
			zerror(L, "argument %u octet too long: %u bytes", n, o->len);
			return NULL;
		} // allocate a new "internal" octet to be freed by caller
		o->ref++; // signal we are reusing the same pointer
		return(o);
	}
	if(strlen(type) >= 6 && ((strncmp("string",type,6)==0)
				 || (strncmp("number",type,6)==0)) ) {
		size_t len; const char *str;
		str = luaL_optlstring(L, n, "", &len);
		if(len>MAX_OCTET) {
			zerror(L, "invalid string size: %lu", len);
			return NULL;
		}
		// fallback to a string
		o = o_alloc(L, len);
		OCT_jstring(o, (char*)str); // null terminates and updates len
		return(o);
	}
	// else
	// zenroom types
	ud = luaL_testudata(L, n, "zenroom.big");
	if(ud) {
		big *b = (big*)ud;
		o = new_octet_from_big(L, b);
		if(!o) {
			zerror(L, "Could not allocate OCTET from BIG");
			return NULL;
		}
		return(o);
	}
	ud = luaL_testudata(L, n, "zenroom.time");
	if(ud) {
		ztime_t *b = (ztime_t*)ud;
		o = new_octet_from_time(L, *b);
		if(!o) {
			zerror(L, "Could not allocate OCTET from TIME");
			return NULL;
		}
		return(o);
	}
	ud = luaL_testudata(L, n, "zenroom.float");
	if(ud) {
		float *f = (float*)ud;
		o = new_octet_from_float(L, f);
		if(!o) {
			zerror(L, "Could not allocate OCTET from FLOAT");
			return NULL;
		}
		return(o);
	}
	ud = luaL_testudata(L, n, "zenroom.ecp");
	if(ud) {
		ecp *e = (ecp*)ud;
		o = o_alloc(L, e->totlen);
		if(!o) {
			zerror(L, "Could not allocate OCTET from ECP");
			return NULL;
		}
		_ecp_to_octet(o, e);
		return(o);
	}
	ud = luaL_testudata(L, n, "zenroom.ecp2");
	if(ud) {
		ecp2 *e = (ecp2*)ud;
		o = o_alloc(L, e->totlen);
		if(!o) {
			zerror(L, "Could not allocate OCTET from ECP2");
			return NULL;
		}
		_ecp2_to_octet(o, e);
		return(o);
	}
	if( lua_isnil(L, n) || lua_isnone(L, n) ) {
		o = o_alloc(L, 1);
		o->val[0] = 0x00;
		o->len = 0;
		return(o);
	}
	zerror(L, "Error in argument #%u", n);
	return NULL;
	// if executing here, something is pushed into Lua's stack
	// but this is an internal function to gather arguments, so
	// should be popped before returning the new octet
}

// allocates a new octet in LUA, duplicating the one in arg
octet *o_dup(lua_State *L, const octet *o) {
	octet *n = o_new(L, o->len);
	if(!n) {
		zerror(L, "Could not create OCTET");
		return NULL;
	}
	OCT_copy(n,(octet*)o);
	return(n);
}

void push_buffer_to_octet(lua_State *L, char *p, size_t len) {
	octet* o = o_new(L, len);
	// newuserdata already pushes the object in lua's stack
	// memcpy(o->val, p, len);
	register uint32_t i;
	for (i=0; i<len; i++) o->val[i] = p[i];
	o->len = len;
}


int o_destroy(lua_State *L) {
	void *ud = luaL_testudata(L, 1, "zenroom.octet");
	if(!ud) return 0;
	octet *o = (octet*)ud;
	o->ref--;
	if(o->ref > 0) return 0;
	if(o->val) free(o->val);
//	free(o);
	return 0;
}

/// Global OCTET Functions
// @section OCTET
//
// The "global OCTET functions" are all prefixed by <b>OCTET.</b>
// (please note the separator is a "." dot) and always return a new
// octet resulting from the operation.
//
// This is a difference with "object methods" listed in the next
// section which are operating on the octet itself, doing "in place"
// modifications. Plan well what to use to save memory space and
// computations.


/***
Create a new octet with a specified maximum size, or a default if
omitted. All operations exceeding the octet's size will truncate
excessing data. Octets cannot be resized.

@function OCTET.new
@int[opt=64] length maximum length in bytes
@return octet newly instantiated octet
*/
static int newoctet (lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = o_arg(L, 1);
	if(!o) {
		failed_msg = "Could not create OCTET";
		goto end;
	}
	octet *r = o_dup(L, (octet*)o);
	if(!r) {
		failed_msg = "Could not duplicate OCTET";
		goto end;
	}
	(void)r;
end:
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
Create a new octet of size 0.

@function OCTET.empty
@return octet newly instantiated octet
*/
static int new_empty_octet (lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *o = o_alloc(L, 0);
	if(!o) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	if(!o_dup(L, o)){
		failed_msg = "Could not duplicate OCTET";
		goto end;
	}
end:
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
	Generate an octet of specified length containing random bytes.

	@function OCTET.random
	@param len a specified length
	@return random octet of specified length
*/
static int new_random(lua_State *L) {
	BEGIN();
	int tn;
	lua_Number n = lua_tonumberx(L, 1, &tn);
	octet *o = o_new(L,(int)n);
	Z(L);
	OCT_rand(o, Z->random_generator, (int)n);
	END(1);
}

/***
	Check if a Lua string is a valid base64-encoded string.
	*If the string is valid base64, it pushes true, otherwise it pushes false onto the Lua stack.

	@function OCTET.is_base64
	@param s a Lua string
	@return a boolean value
 */
static int lua_is_base64(lua_State *L) {
	BEGIN();
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "string expected");
	int len = is_base64(s);
	if(len<4) {
		lua_pushboolean(L, 0);
		func(L, "string is not a valid base64 sequence");
		END(1); }
	lua_pushboolean(L, 1);
	END(1);
}

/***
	Check if a Lua string is a valid url64-encoded string.
	*If the string is valid url64, it pushes true, otherwise it pushes false onto the Lua stack.

	@function OCTET.is_url64
	@param s a Lua string
	@return a boolean value
 */
static int lua_is_url64(lua_State *L) {
	BEGIN();
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "string expected");
	int len = is_url64(s);
	if(len<3) {
		lua_pushboolean(L, 0);
		func(L, "string is not a valid url64 sequence");
		END(1); }
	lua_pushboolean(L, 1);
	END(1);
}

/***
	Check if a Lua string is a valid base58-encoded string.
	*If the string is valid base58, it pushes true, otherwise it pushes false onto the Lua stack.

	@function OCTET.is_base58
	@param s a Lua string
	@return a boolean value
 */
static int lua_is_base58(lua_State *L) {
	BEGIN();
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "string expected");
	int len = is_base58(L, s);
	if(!len) {
		lua_pushboolean(L, 0);
		func(L, "string is not a valid base58 sequence");
		END(1); }
	lua_pushboolean(L, 1);
	END(1);
}

/***
	Check if a Lua string is a valid hexadecimal-encoded string.
	*If the string is valid hex, it pushes true, otherwise it pushes false onto the Lua stack.

	@function OCTET.is_hex
	@param s a Lua string
	@return a boolean value
 */
static int lua_is_hex(lua_State *L) {
	BEGIN();
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "string expected");
	int len = is_hex(L, s);
	if(!len) {
		lua_pushboolean(L, 0);
		func(L, "string is not a valid hex sequence");
		END(1); }
	lua_pushboolean(L, 1);
	END(1);
}

/***
	Check if a Lua string is a valid bin-encoded string.
	*If the string is valid bin, it pushes true, otherwise it pushes false onto the Lua stack.

	@function OCTET.is_bin
	@param s a Lua string
	@return a boolean value
 */

static int lua_is_bin(lua_State *L) {
	BEGIN();
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "string expected");
	int len = is_bin(L, s);
	if(!len) {
		lua_pushboolean(L, 0);
		func(L, "string is not a valid binary sequence");
		END(1); }
	lua_pushboolean(L, 1);
	END(1);
}

// to emulate 128bit counters, de facto truncate integers to 64bit
typedef struct { uint64_t high, low; } uint128_t;

/***
Convert a Lua integer into a 16-byte octet object,
padding the upper 8 bytes with zeros and handling endianness.

	@function OCTET.from_number
	@param num Lua integer
	@return 16-byte octet object
 */
static int from_number(lua_State *L) {
	BEGIN();
	// number argument, import
	int tn;
	lua_Integer n = lua_tointegerx(L,1,&tn);
	if(!tn) {
		lerror(L, "O.from_number input is not a number");
		return 0; }
	const uint64_t v = n;
	octet *o = o_new(L, 16);
	// conversion from int64 to binary
	// TODO: check endian portability issues
	register uint8_t i = 0;
	register char *d = o->val;
	for(i=0;i<8;i++,d++) *d = 0x0;
	register char *p = (char*) &v;
	d+=7;
	for(i=0;i<8;i++,d--,p++) *d=*p;
	o->len = 16;
	END(1);
}

/*
@function OCTET.from_rawlen(string, length) (unsafe!)
@str string string to copy in octet as-is
@int length string length in bytes
@return octet newly instantiated octet
*/
static int from_rawlen (lua_State *L) {
	BEGIN();
	const char *s;
	size_t len;
	s = lua_tolstring(L, 1, &len);  /* get result */
	luaL_argcheck(L, s != NULL, 1, "string expected");
	int tn;
	lua_Integer n = lua_tointegerx(L,2,&tn);
	if(!tn) {
		lerror(L, "O.new 2nd arg is not a number");
		return 0; }
	octet *o = o_new(L, (int)n);
	register int c;
	for(c=0;c<n;c++) o->val[c] = s[c];
	o->len = (int)n;
	END(1);
}

/***
Decode a base64-encoded string into an octet object,
after checking if the input string is valid base64.

	@function OCTET.from_base64
	@param str base64-encoded string
	@return decoded octet object
 */
static int from_base64(lua_State *L) {
	BEGIN();
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "base64 string expected");
	int len = is_base64(s);
	if(!len) {
		lerror(L, "base64 string contains invalid characters");
		return 0; }
	int nlen = B64decoded_len(len);
	octet *o = o_new(L, nlen); // 4 byte header

	OCT_frombase64(o, (char*)s);
	END(1);
}

/***
Decode a url64-encoded string into an octet object,
after checking if the input string is valid url64.

	@function OCTET.from_url64
	@param str url64-encoded string
	@return decoded octet object
 */
static int from_url64(lua_State *L) {
	BEGIN();
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "url64 string expected");
	int len = is_url64(s);
	if(!len) {
		lerror(L, "url64 string contains invalid characters");
		return 0; }
	int nlen = B64decoded_len(len);
	// func(L,"U64 decode len: %u -> %u",len,nlen);
	octet *o = o_new(L, nlen);
	o->len = U64decode(o->val, (char*)s);
	// func(L,"u64 return len: %u",o->len);
	END(1);
}

/***
Decode a base58-encoded string into an octet object,
after checking if the input string is valid base58.

	@function OCTET.from_base58
	@param str base58-encoded string
	@return decoded octet object
 */
static int from_base58(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "base58 string expected");
	int len = is_base58(L, s);
	if(!len) {
		lerror(L, "base58 string contains invalid characters");
		return 0; }
	size_t binmax = B64decoded_len(len); //((len + 3) >> 2) *3;
	char *tmp = malloc(binmax);
	// size_t binmax = len + len + len;
	size_t binlen = binmax;
	if(!b58tobin((void*)tmp, &binlen, s, len)) {
		failed_msg = "Error in conversion from base58";
		goto end; }
	octet *o = o_new(L, binlen);
	if(!o) {
		failed_msg = "Could not create OCTET";
		goto end;
	}
	if(binlen>binmax) {
		memcpy(o->val,&tmp[binlen-binmax],binmax);
	} else {
		memcpy(o->val,&tmp[binmax-binlen],binlen);
	}
	o->len = binlen;
end:
	free(tmp);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
Convert a string into an octet object,
after checking if the input is a valid string.

	@function OCTET.from_string
	@param str string
	@return convert octet object
 */

static int from_string(lua_State *L) {
	BEGIN();
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "string expected");
	const int len = strlen(s);
	// STRING SIZE CHECK before import to OCTET
	if(len > MAX_OCTET) {
		zerror(L, "%s: invalid string size: %u", __func__, len);
		lerror(L, "operation aborted");
		return 0; }
	octet *o = o_new(L, len);
	register int i = 0;
	for(i=0;s[i] != 0x0;i++) o->val[i]=s[i];
	o->len = i;
	END(1);
}

/***
Decode an hexadecimal-encoded string into an octet object,
after checking if the input string is valid hexadecimal.

	@function OCTET.from_hex
	@param str hexadecimal-encoded string
	@return decoded octet object
 */

static int from_hex(lua_State *L) {
	BEGIN();
	char *s = (char*)lua_tostring(L, 1);
	if(!s) {
		zerror(L, "%s :: invalid argument", __func__); // fatal
		lua_pushboolean(L, 0);
		END(1); }
	int len;
	if ( (s[0] == '0') && (s[1] == 'x') )
		 len = is_hex(L, s+2);
	else len = is_hex(L, s);
	if(!len) {
		zerror(L, "hex sequence invalid"); // fatal
		lua_pushboolean(L, 0);
		END(1); }
	func(L,"hex string sequence length: %u",len);
	if(!len || len>MAX_FILE<<1) { // *2 hex tuples
		zerror(L, "hex sequence too long: %u bytes", len<<1); // fatal
		lua_pushboolean(L, 0);
		END(1); }
	octet *o = o_new(L, len>>1);
	if ( (s[0] == '0') && (s[1] == 'x') ) {
		// ethereum elides the leftmost 0 char when value <= 0F
		if((len&1)==1) { // odd length means elision
			s[1]='0'; // overwrite a single byte in const
			o->len = hex2buf(o->val, s+1);
		} else {
			o->len = hex2buf(o->val, s+2);
		}
	} else {
		o->len = hex2buf(o->val,s);
	}
	if(o->len < 0) {
		zerror(L, "%s :: Invalid octet in hex string", __func__);
		lerror(L, "operation aborted");
		lua_pushnil(L);
	}
	END(1);
}

/***
Convert a binary string (composed of '0' and '1' characters) into an octet object.

	@function OCTET.from_bin
	@param bin binary string
	@return convert octet object
 */
// I'm quite happy about this: its fast and secure. It can just be
// made more elegant.
static int from_bin(lua_State *L) {
	BEGIN();
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "binary string sequence expected");
	const int len = is_bin(L, s);
	if(!len || len > MAX_FILE) {
		zerror(L, "invalid binary sequence size: %u", len);
		lerror(L, "operation aborted");
		return 0; }
	octet *o = o_new(L, len+4);
	register char *S = (char*)s;
	register int p; // position in whole string
	register int i; // increased only when 1 or 0 is found
	register int d; // increased only added to dest
	register int j; // bytemask counter
	volatile uint8_t b = 0x0; // bytemask
	for(p=0, j=0, i=0, d=0; p<len; p++, S++) {
		if(isspace(*S)) continue;
		if(j<7) { // add to bytemask
			if(*S=='1') b = b | 0x1;
			b = b<<1;
			j++;
		} else { // reset bytemask and shift left
			if(*S=='1') b = b | 0x1;
			o->val[d] = b;
			b = 0x0;
			j = 0;
			d++;
		}
		i++;
	}
	o->val[d] = 0x0;
	o->len = d;
	END(1);
}

/***
  In the bitcoin world, addresses are the hash of the public key (binary data).
  However, the user usually knows them in some encoded form (which also include
  some error check mechanism, to improve security against typos). Bech32 is the
  format used with segwit transactions.

	@function OCTET.from_segwit
  	@param s Address encoded as Bech32(m)
  	@treturn[1] Address as binary data
  	@treturn[2] Segwit version (version 0 is Bech32, version >0 is Bechm)
*/
static int from_segwit_address(lua_State *L) {
	BEGIN();
	const char *s = lua_tostring(L, 1);
	if(!s) {
		zerror(L, "%s :: invalid argument", __func__); // fatal
		lua_pushboolean(L, 0);
		END(1); }
	int witver;
	uint8_t witprog[40];
	size_t witprog_len;
	const char* hrp = "bc";
	int ret = segwit_addr_decode(&witver, witprog, &witprog_len, hrp, s);
	if(!ret) {
		hrp = "tb";
		ret = segwit_addr_decode(&witver, witprog, &witprog_len, hrp, s);
	}
	if(!ret) {
		zerror(L, "%s :: not bech32 address", __func__);
		lua_pushboolean(L, 0);
		END(1);
	}
	octet *o = o_new(L, witprog_len);
	register size_t i;
	for(i=0; i<witprog_len; i++) {
		o->val[i] = (char)witprog[i];
	}
	o->len = witprog_len;
	lua_pushinteger(L,witver);
	END(2);
}

/***
  For an introduction see `from_segwit`.
  HRP (human readble part) are the first characters of the address, they can
  be bc (bitcoin network) or tb (testnet network).

	@function OCTET:to_segwit
  	@param o Address in binary format (octet with the result of the hash160)
  	@param witver Segwit version
  	@param s HRP
  	@return Bech32(m) encoded string
*/
static int to_segwit_address(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL, *result = NULL;
	const octet *o = o_arg(L,1);
	if(!o) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	if(!o->len) { lua_pushnil(L); goto end; }
	int tn;
	lua_Integer witver = lua_tointegerx(L, 2, &tn);
	if(!tn) {
		failed_msg = "segwit version is not a number";
		goto end;
	}
	const char *s = lua_tostring(L, 3);
	if(!s) {
		failed_msg = "Invalid 3rd argument";
		goto end;
	}

	if(witver < 0 || witver > 16) {
		zerror(L, "Invalid segwit version: %d", witver);
		failed_msg = "Invalid segwit version";
		goto end;
	}

	if(o->len < 2 || o->len > 40) {
		zerror(L, "Invalid size for segwit address: %d", o->len);
		failed_msg = "Invalid size for segwit address";
		goto end;
	}

	// HRP to lower case
	// the string the user pass could be longer than 2 characters
	// and it could be either lower case of upper case
	// First of all I normalize it:
	// - it can be at most 2 chars
	// - it must be lower case
	char hrp[3];
	register int i = 0;
	while(i < 2 && s[i] != '\0') {
		if(s[i] > 'A' && s[i] < 'Z') {
			hrp[i] = s[i] - 'A' + 'a'; // to lower case
		} else {
			hrp[i] = s[i];
		}
		i++;
	}
	hrp[i] = '\0';
	if(s[i] != '\0' || (strncmp(hrp, "bc", 2) != 0 && strncmp(hrp, "tb", 2) != 0)) {
		zerror(L, "Invalid human readable part: %s", s);
		failed_msg = "Invalid human readable part";
		goto end;
	}
	result = malloc(73+strlen(hrp));

	if (!segwit_addr_encode(result, hrp, witver, (uint8_t*)o->val, o->len)) {
		failed_msg = "Cannot be encoded to segwit format";
		goto end;
	}
	lua_pushstring(L,result);
end:
	free(result);
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
Decode a base45-encoded string into an octet object,
after checking if the input string is valid base45.

	@function OCTET.from_base45
	@param str base45-encoded string
	@return decoded octet object
 */

static int from_base45(lua_State *L) {
	BEGIN();
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "base45 string expected");
	int len = is_base45(s);
	if(len < 0) {
		lerror(L, "base45 string contains invalid characters");
		return 0;
	}
	octet *o = o_new(L, len);
	len = b45decode(o->val, s);
	if(len < 0) {
		lerror(L, "base45 invalid string");
		return 0;
	}
	o->len = len;
	END(1);
}

/***
Decode a mnemonic-encoded string into an octet object,
after checking if the input string is valid mnemonic.

	@function OCTET.from_mnemonic
	@param str mnemonic-encoded string
	@return decoded octet object
 */

static int from_mnemonic(lua_State *L) {
	BEGIN();
	const char *s = lua_tostring(L, 1);
	if(!s) {
		zerror(L, "%s :: invalid argument", __func__); // fatal
		lua_pushboolean(L, 0);
		END(1); }
	// From bip39 it can be at most 32bytes
	octet *o = o_alloc(L, 32);
	if(!mnemonic_check_and_bits(s, &(o->len), o->val)) {
		zerror(L, "%s :: words cannot be encoded with bip39 format", __func__);
		lua_pushboolean(L, 0);
		goto end;
	}
	o_dup(L, o); // push in lua's stack
end:
	o_free(L, o);
	END(1);
}


/***
Decode a uuid-encoded string into an octet object of 16 bytes.

	@function OCTET.from_uuid
	@param str uuid-encoded string
	@return decoded octet object
 */
#define UUID_STR_LEN 36
static int from_uuid(lua_State *L) {
	BEGIN();
	const char *type = luaL_typename(L, 1);
	char *failed_msg = NULL;
	char *exs = NULL;
	char *tmp = NULL;
	if (strcmp(type, "string") != 0) {
		failed_msg = "the input is not a string";
		goto end;
	}
	const char *s = lua_tostring(L, 1);
	if(!s) {
		failed_msg = "invalid argument";
		goto end;
	}
	int inlen = strlen(s);
	if (strncmp(s, "urn:uuid:", 9) == 0) {
		s+=9;
		inlen-=9;
	}
	if(inlen!=UUID_STR_LEN) {
		failed_msg = "invalid uuid argument length";
		goto end;
	}
	// check the right positions of '-'
	for (int i = 0; i < 4; i++) {
		int positions[] = {8, 13, 18, 23};
		int pos = positions[i];
		if (s[pos] != '-') {
			failed_msg = "invalid '-' positions!";
			goto end;
		}
	}
	//check if the input string is hexadecimal
	exs = strdup(s);
	for(char *p = (char*)exs; *p!=0x0; p++) if(*p=='-') *p = 'aa';
	if(!is_hex(L, exs)) {
		failed_msg = "hex sequence invalid";
		goto end;
	}
	tmp = strdup(s);
	octet *o = o_new(L,UUID_STR_LEN+1);
	// replace all '-' with zero
	for(char *p = (char*)tmp; *p!=0x0; p++) if(*p=='-') *p = 0x0;
	if(hex2buf(o->val,tmp) != 4
		|| hex2buf(o->val+4, tmp+9) != 2
		|| hex2buf(o->val+6, tmp+14) != 2
		|| hex2buf(o->val+8, tmp+19) != 2
		|| hex2buf(o->val+10, tmp+24) != 6) {
		failed_msg = "invalid uuid parsed";
		goto end;
	}
	o->len = 16;
end:
	if(tmp) free(tmp);
	if(exs) free(exs);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
Encode an octet object of 16 bytes in uuid notation.

	@function OCTET.to_uuid
	@param str octet object
	@return encoded octet object
 */

 static int to_uuid(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = o_arg(L, 1);
	if (!o || o->len != 16) {
        failed_msg = "expected 16 bytes octet";
        goto end;
    }
	char tmp[33];
	char dst[UUID_STR_LEN+1];
	buf2hex(tmp, o->val, 16);
	static const int dash_positions[] = {8, 13, 18, 23};
    int src_pos = 0;
	for(int i = 0; i < 36; i++) {
        if((i == 8) || (i == 13) || (i == 18) || (i == 23)) {
            dst[i] = '-';
        } else {
            dst[i] = tmp[src_pos++];
        }
    }
	dst[36] = '\0';
end:
	o_free(L,o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	lua_pushstring(L, dst);
	END(1);
}



/***
	Create an octet filled with zero values up to indicated size or its maximum size.

	@int[opt=octet:max] length fill with zero up to this size, use maximum octet size if omitted
	@function OCTET.zero
	@return octet filled with zeros
*/
static int zero(lua_State *L) {
	BEGIN();
	const int len = luaL_optnumber(L, 1, MAX_OCTET);
	if(len<1) {
		lerror(L, "Cannot create a zero length octet");
		return 0;
	}
	func(L, "Creating a zero filled octet of %u bytes", len);
	octet *n = o_new(L,len);
	register int i;
	for(i=0; i<len; i++) n->val[i]=0x0;
	n->len = len;
	END(1);
}

/// Object Methods
// @type OCTET
//
// This section lists methods that can be called as members of the
// <b>OCTET:</b> objects, using a ":" semicolon notation instead of a
// dot. Example synopsis:
//
// <pre class="example">
// random = OCTET.random(32) -- global OCTET constructor using the dot
// print( random:<span class="global">hex</span>() ) -- method call on the created object using the colon
// </pre>
//
// In the example above we create a new "random" OCTET variable with
// 32 bytes of randomness, then call the ":hex()" method on it to print
// it out as an hexadecimal sequence.
//
// The contents of an octet object are never changed this way: methods
// always return a new octet with the requested changes applied.
//

/***
Encode an octet in base64 notation.

@function OCTET:base64
@return a string representing the octet's contents in base64

*/

static int to_base64 (lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	char *b = NULL;
	const octet *o = o_arg(L, 1);
	if(!o) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	if(!o->len) { lua_pushnil(L); goto end; }
	if(!o->len || !o->val) {
		failed_msg = "base64 cannot encode an empty octet";
		goto end;
	}
	int newlen;
	newlen = ((3+(4*(o->len/3))) & ~0x03)+0x0f;
	b = malloc(newlen);
	OCT_tobase64(b,(octet*)o);
	lua_pushstring(L,b);
end:
	free(b);
	o_free(L,o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
	Encode an octet in url64 notation.

	@function OCTET:url64
	@return a string representing the octet's contents in url64
*/
static int to_url64 (lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	char *b = NULL;
	const octet *o = o_arg(L,1);
	if(!o) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	if(!o->len) { lua_pushnil(L); goto end; }
	if(!o->len || !o->val) {
		failed_msg = "url64 cannot encode an empty octet";
		goto end;
	}
	int newlen;
	newlen = B64encoded_len(o->len);
	b = malloc(newlen);
	// b[0]='u';b[1]='6';b[2]='4';b[3]=':';
	U64encode(b,o->val,o->len);
	lua_pushstring(L,b);
end:
	free(b);
	o_free(L,o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/*
Print an octet in base58 notation.

This encoding uses the same alphabet as Bitcoin addresses. Why base58 instead of standard base64 encoding?

- Don't want 0OIl characters that look the same in some fonts and could be used to create visually identical looking data.
- A string with non-alphanumeric characters is not as easily accepted as input.
- E-mail usually won't line-break if there's no punctuation to break at.
- Double-clicking selects the whole string as one word if it's all alphanumeric.

	@function octet:base58()
	@return a string representing the octet's contents in base58
*/

/***
	Encode an octet in base58 notation.

	@function OCTET:url64
	@return a string representing the octet's contents in base58
*/
static int to_base58(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	char *b = NULL;
	const octet *o = o_arg(L, 1);
	if(!o) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	if(!o->len) { lua_pushnil(L); goto end; }
	if(!o->len || !o->val) {
		failed_msg = "base58 cannot encode an empty octet";
		goto end;
	}
	if(o->len < 3) {
		// there is a bug in luke-jr's implementation of base58 (fixed
		// in bitcoin-core) when encoding strings smaller than 3 bytes
		// the 'j' counter being unsigned and initialised at size-2 in
		// the carry inner loop flips to 18446744073709551615
		failed_msg = "base58 cannot encode octets smaller than 3 bytes";
		goto end;
	}
	size_t maxlen = o->len <<1;
	// TODO: find out why this breaks!
	// debug builds work, optimized build breaks here
	// this workaround will break base58 encoding when using memmanager=lw
	//char *b = malloc(maxlen);
	b = malloc(maxlen);
	size_t b58len = maxlen;
	b58enc(b, &b58len, o->val, o->len);
	// b[b58len] = '\0'; // already present in libbase58
	lua_pushstring(L,b);
end:
	free(b);
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
	Encode an octet in base45 notation.

	@function OCTET:base45
	@return a string representing the octet's contents in base45
*/

static int to_base45 (lua_State *L) {
	BEGIN();
	const octet *o = o_arg(L, 1);
	int newlen = b45encode(NULL, o->val, o->len);
	char *b = malloc(newlen);
	b45encode(b, o->val, o->len);
	lua_pushstring(L, b);
	free(b);
	o_free(L, o);
	END(1);
}

/***
	Encode an octet in mnemonic notation.

	@function OCTET:mnemonic
	@return a string representing the octet's contents in mnemonic
*/

static int to_mnemonic(lua_State *L) {
	BEGIN();
	const octet *o = o_arg(L,1);
	if(!o->len) { lua_pushnil(L); o_free(L,o); return 1; }
	if(o->len > 32) {
		zerror(L, "%s :: octet bigger than 32 bytes cannot be encoded to mnemonic",__func__);
		o_free(L,o);
		lua_pushboolean(L, 0);
		END(0);
	}
	char *result = malloc(24 * 10);
	if(mnemonic_from_data(result, o->val, o->len)) {
		lua_pushstring(L, result);
	} else {
		zerror(L, "%s :: cannot be encoded to mnemonic", __func__);
		lua_pushboolean(L, 0);
	}
	o_free(L,o);
	free(result);
	END(1);
}


/***
	Converts an octet into an array of bytes, compatible with Lua's transformations on <a href="https://www.lua.org/pil/11.1.html">arrays</a>.

	@function OCTET:array
	@return an array as Lua's internal representation
*/

static int to_array(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = o_arg(L,1);
	if(!o) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	if(!o->len) { lua_pushnil(L); goto end; }
	if(!o->len || !o->val) {
		failed_msg = "array cannot encode an empty octet";
		goto end;
	}
	lua_newtable(L);
	// luaL_checkstack(L,1, "in octet:to_array()");
	register int c = o->len;
	register int idx = 0;
	while(c--) {
		lua_pushnumber(L,idx+1);
		lua_pushnumber(L,o->val[idx]);
		lua_settable(L,-3);
		idx++;
	}
end:
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
	Return self (octet), implemented for compatibility with all zenroom types so that anything can be casted to octet.

	@function OCTET:octet
	@return the self octet

*/
static int to_octet(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = o_arg(L, 1);
	if(!o) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	if(!o_dup(L, o)) {
		failed_msg = "Could not duplicate OCTET";
		goto end;
	}
end:
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
	Print an octet as string.

	@function octet:string
	@return a string representing the octet's contents
*/
static int to_string(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = o_arg(L, 1);
	if(!o) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	if(!o->len) { lua_pushnil(L); goto end; }
	char *s = malloc(o->len+2);
	OCT_toStr((octet*)o, s); // TODO: inverted function signature, see
					 // https://github.com/milagro-crypto/milagro-crypto-c/issues/291
	s[o->len] = '\0'; // make sure string is NULL terminated
	lua_pushlstring(L, s, o->len);
	free(s);
end:
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/***
	Encode an octet into a string of hexadecimal numbers representing its contents.

	@function octet:hex
	@return a string of hexadecimal numbers
*/
int to_hex(lua_State *L) {
	BEGIN();
	const octet *o = o_arg(L,1);
	if(!o->len) { lua_pushnil(L); goto end; }
	push_octet_to_hex_string(L, (octet*)o);
end:
	o_free(L,o);
	END(1);
}

/***
	Encode an octet to a string of zeroes and ones (0/1) as binary sequence.

	@function OCTET:bin
	@return a string of bits
*/
static int to_bin(lua_State *L) {
	BEGIN();
	const octet *o = o_arg(L,1);
	if(!o->len) { lua_pushnil(L); goto end; }
	char *s = malloc(o->len*8+2);
	int i;
	char oo;
	char *is = s;
	for(i=0;i<o->len;i++) {
		oo = o->val[i];
		is = &s[i*8];
		is[7] = oo    & 0x1 ? '1':'0';
		is[6] = oo>>1 & 0x1 ? '1':'0';
		is[5] = oo>>2 & 0x1 ? '1':'0';
		is[4] = oo>>3 & 0x1 ? '1':'0';
		is[3] = oo>>4 & 0x1 ? '1':'0';
		is[2] = oo>>5 & 0x1 ? '1':'0';
		is[1] = oo>>6 & 0x1 ? '1':'0';
		is[0] = oo>>7 & 0x1 ? '1':'0';
	}
	s[o->len*8] = 0x0;
	lua_pushstring(L,s);
	free(s);
end:
	o_free(L,o);
	END(1);
}

/***
Fill an octet object with the contents of another octet object.

	@function OCTET:fill
	@param oct the source octet providing the data
	@return the target octet is fully filled, and its len is set to its max capacity.
 */
static int filloctet(lua_State *L) {
	BEGIN();
	int i;
	octet *o = (octet*) luaL_testudata(L, 1, "zenroom.octet");

	octet *fill = (octet*) luaL_testudata(L, 2, "zenroom.octet");

	for(i=0; i<o->max; i++)
		o->val[i] = fill->val[i % fill->len];
	o->len = o->max;
	END(0);
}

/***
Concatenate two octets, returns a new octet. This is also executed
*when using the '<b>..</b>' operator btween two octets. It results in a
*newly allocated octet, does not change the contents of other octets.

	@param dest leftmost octet will be overwritten by result
	@param source rightmost octet used in XOR operation
	@function OCTET.concat
	@return a new octet resulting from the operation
*/
static int concat_n(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *x = NULL, *y = NULL;
	char *sx = NULL, *sy = NULL;
	octet xs, ys;
	void *ud;
	ud = luaL_testudata(L, 1, "string");
	if(ud) {
		x = &xs;
		sx = (char*) lua_tostring(L, 1);
		if(!sx) {
			failed_msg = "octet or string expected in concat";
			goto end;
		}
		xs.len = strlen(sx);
		xs.val = sx;
	} else {
		x = o_arg(L, 1);
		if(!x) {
			failed_msg = "octet or string expected in concat";
			goto end;
		}
	}
	ud = luaL_testudata(L, 2, "string");
	if(ud) {
		y = &ys;
		sy = (char*) lua_tostring(L, 2);
		if(!sy) {
			failed_msg = "octet or string expected in concat";
			goto end;
		}
		ys.len = strlen(sy);
		ys.val = sy;
	} else {
		y = o_arg(L, 2);
		if(!y) {
			failed_msg = "octet or string expected in concat";
			goto end;
		}
	}
	octet *n = o_new(L, x->len+y->len);
	if(!n) {
		failed_msg = "Could not create OCTET";
		goto end;
	}
	OCT_copy(n, (octet*)x);
	OCT_joctet(n, (octet*)y);
end:
	if(y!=&ys) o_free(L, y);
	if(x!=&xs) o_free(L, x);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
	Pad an octet with leading zeroes up to indicated length or its maximum size.

	@int[opt=octet:max] length pad to this size, will use maximum octet size if omitted
	@return new octet padded at length
	@function octet:pad
*/
static int pad(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = o_arg(L, 1);
	if(!o) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	const int len = luaL_optinteger(L, 2, o->max);
	octet *n = o_new(L, len);
	if(!n) {
		failed_msg = "Could not create OCTET";
		goto end;
	}
	OCT_copy(n, (octet*)o);
	OCT_pad(n, len);
end:
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	return 1;
}


/*** Trim all leading and following zero bytes in an octet
 * and return a new one of equal length or smaller.

	 @function OCTET:trim
	 @return trimmed octet
	 @usage
	 --create an octet of bin
	 oct = OCTET.from_bin("00000000111111000")
	 --print 11111100
	 print(oct:trim():bin())
*/
static int trim(lua_State *L) { // o =
	BEGIN();
	char *failed_msg = NULL;
	const octet *src = o_arg(L,1);
	if(!src) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	octet *res;
	const char* front;
	const char* end;
	size_t size = src->len;
	front = src->val;
	end = src->val+size-1;
	while(size && *front == 0) {
		size--;
		front++;
	}
	while(size && *end == 0) {
		size--;
		end--;
	}
	if(size == (size_t)src->len) {
		// no changes
		res = o_dup(L, src);
	} else {
		// new octet
		res = o_new(L, size+4);
		memcpy(res->val,front,size);
		res->len = size;
	}
end:
	o_free(L, src);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***  Split an octet into two parts based on a specified length and return both parts. The first part will have a length in bytes equal to the input parameter. The second part will contain the remaining bytes.

	@function OCTET:chop
	@param len an optional length parameter (defaulting to 0)
	@return Returns the two resulting octets
	@usage
	--create an octet of bin
	oct = OCTET.from_bin("001000001111110001")
	--consider the length parameter equal to 1
	part1, part2 = oct:chop(1)
	--part1 = 00100000, part2 = 11111100
 */
static int chop(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *src = o_arg(L, 1);
	if(!src) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	int len = luaL_optnumber(L, 2, 0);
	if(len > src->len) {
		zerror(L, "cannot chop octet of size %i to higher length %i",src->len, len);
		failed_msg = "Could not chop OCTET";
		goto end;
	} else if(len < 0) {
		// OCT_chop assign len to the len of the new octet without checks
		zerror(L, "cannot chop octet with negative size %d",len);
		failed_msg = "Could not chop OCTET";
		goto end;
	}
	octet *l = o_dup(L, src);
	if(!l) {
		failed_msg = "Could not duplicate OCTET";
		goto end;
	}
	octet *r = o_new(L, src->len - len);
	if(!r) {
		failed_msg = "Could not create OCTET";
		goto end;
	}
	OCT_chop(l, r, len);
end:
	o_free(L, src);
	if(failed_msg) {
		THROW(failed_msg);
		lua_pushnil(L);
	}
	END(2);
}

/***
  Build the byte in reverse order with respect to the one which is given.

  @function OCTET:reverse
  @return reverse order octet
*/
static int reverse(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *src = o_arg(L, 1);
	if(!src) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	octet *dest = o_new(L, src->len);
	if(!dest) {
		failed_msg = "Could not create OCTET";
		goto end;
	}
	register int i=0, j=src->len-1;
	while(i < src->len) {
		dest->val[j] = src->val[i];
		i++;
		j--;
	}
	dest->len = src->len;
end:
	o_free(L, src);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/***
 	Extracts a piece of the octet from the start position to the end position inclusive, expressed in numbers.

	@int start position, begins from 1 not 0 like in lua
	@int end position, may be same as start for a single byte
	@return new octet sub-section from start to end inclusive
	@function octet:sub
*/
static int sub(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	register int i, c;
	const octet *src = NULL;
	octet *dst = NULL;
	int start, end;
	src = o_arg(L, 1);
	if(!src) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	start = luaL_optnumber(L, 2, 0);
	if(start<1) {
		zerror(L, "invalid octet:sub() position starts from 1 not %i", start);
		failed_msg = "Could not extract sub OCTET";
		goto end;
	}
	end = luaL_optnumber(L, 3, 0);
	if(end < start) {
		zerror(L, "invalid octet:sub() to end position %i smaller than start position %i", end, start);
		failed_msg = "Could not extract sub OCTET";
		goto end;
	}
	if(end > src->len) {
		zerror(L, "invalid octet:sub() to end position %i on small octet of len %i", end, src->len);
		failed_msg = "Could not extract sub OCTET";
		goto end;
	}
	dst = o_new(L, end - start + 1);
	if(!dst) {
		failed_msg = "Could not create OCTET";
		goto end;
	}
	for(i=start-1, c=0; i<=end; i++, c++)
		dst->val[c] = src->val[i];
	dst->len = end - start + 1;
end:
	o_free(L, src);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
	Compare two octets to see if contents are equal.

	@function octet:eq
	@return true if equal, false otherwise
*/

static int eq(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *x = o_arg(L,1);
	const octet *y = o_arg(L,2);
	if(!x || !y) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	if (x->len!=y->len) {
		lua_pushboolean(L, 0);
		goto end; }
	register int i;
	short res = 1;
	for (i=0; i<x->len; i++) { // xor
		if (x->val[i] ^ y->val[i]) res = 0;
	}
	lua_pushboolean(L, res);
end:
	o_free(L, x);
	o_free(L, y);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
	Retrieve and return the length of an octet.

	@function OCTET:__len
	@return length of the octet
 */
static int octet_size(lua_State *L) {
	BEGIN();
	octet *o = (octet*) luaL_testudata(L, 1, "zenroom.octet");
	lua_pushinteger(L, o->len);
	END(1);
}

/***
	Retrieve and return the maximum capacity of an octet.

	@function OCTET:max
	@return maximum capacity of an octet
 */
static int max(lua_State *L) {
	BEGIN();
	const octet *o = o_arg(L, 1);
	lua_pushinteger(L, o->max);
	o_free(L, o);
	END(1);
}

/***
	Given a string and a characater, this function removes from the string
	*all the occurences of the character in the string
	@param char the character to remove
	@function OCTET:rmchar

	@return the initial string without the input character

	@usage
	-- oct is the octet with the string to modify
	-- to_remove is the character to remove from oct
	oct = OCTET.from_string("Hello, world!")
	to_remove = OCTET.from_string("l")
	print(oct:rmchar(to_remove))
	--print: Heo, word!
*/
static int remove_char(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = o_arg(L, 1);
	const octet *c = o_arg(L, 2);
	if(!o || !c) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	octet *res = o_new(L, o->len);
	if(!res) {
		failed_msg = "Could not create OCTET";
		goto end;
	}
	register int i;
	register int len = 0;
	register char tc = c->val[0];
	for(i=0; i < o->len; i++) {
		if( o->val[i] == tc) continue;
		res->val[len] = o->val[i];
		len++;
	}
	res->len = len;
end:
	o_free(L, o);
	o_free(L, c);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

// optimized for newlines of all kinds

/***
	Process an octet structure and create a new octet by filtering out certain ASCII characters and handling escape sequences.
	*If an escape character \ is encountered, it sets an escape flag.
	*If the next character is one of 'a', 'b', 't', 'n', 'v', 'f', or 'r', both the escape character \ and the escaped character are skipped.
	*All other valid characters are copied to the new octet.

	@function OCTET:compact_ascii
	@return New octet which contains the filtered and processed data
	@usage
	--create a string octet
	oct=OCTET.from_string("st\ring fo\r ex\ample")
	print(oct:compact_ascii())
	--print: stingfoexmple

 */

static int compact_ascii(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = o_arg(L, 1);
	if(!o) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	octet *res = o_new(L, o->len);
	if(!res) {
		failed_msg = "Could not create OCTET";
		goto end;
	}
	register int i;
	register int len = 0;
	register short escape = 0;
	for(i=0; i < o->len; i++) {
		if( o->val[i] < 0x21 ) continue; // all ASCII below space
		if(escape) {
			escape--;
			if( o->val[i] == 'a'
				|| o->val[i] == 'b'
				|| o->val[i] == 't'
				|| o->val[i] == 'n'
				|| o->val[i] == 'v'
				|| o->val[i] == 'f'
				|| o->val[i] == 'r' )
				continue;
		}
		if( o->val[i] == 0x5C) { escape++; continue; } // \ = 0x5c ASCII
		res->val[len] = o->val[i];
		len++;
	}
	res->len = len;
end:
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
	Calculate the frequency of each byte value in an octet and returns the results as a Lua table. It is useful for analyzing the distribution of
	*byte values in a byte array, which can be used for entropy calculations or other statistical analyses.

	@function OCTET:bytefreq
	@return Lua table containing bytes distribution
	@usage
	--create an octet of bin
	oct=OCTET.from_bin("101010001010100010101000101010000001011000011111")
	--save the frequency of the bytes in a table (tab)
	tab=oct:bytefreq()
	--print the table
	for byte, freq in pairs(tab) do
    	print(string.format("Byte %d: Frequency %d", byte, freq))
	end
	--print .. Byte 23: Frequency 1 ..
		.. Byte 32: Frequency 1 ..
		.. Byte 169: Frequency 4 ..
	--all the others frequency values are 0
 */
static int entropy_bytefreq(lua_State *L) {
	BEGIN();
	const octet *o = o_arg(L, 1);
	register int i; // register
	// byte frequency table
	char *bfreq = malloc(0xff);
	memset(bfreq, 0x0, 0xff);
	// calculate freqency of byte values
	register char *p = o->val;
	for(i=0; i<o->len; i++, p++) bfreq[(uint8_t)*p]++;
	lua_newtable(L);
	register int c;
	p = bfreq;
	for(c=0;c<0xff;c++,p++) {
		lua_pushnumber(L,c+1);
		lua_pushnumber(L,*p);
		lua_settable(L,-3);
	}
	free(bfreq);
	o_free(L, o);
	END(1);
}

/***
	Calculate the entropy of an octet structure.
	*Entropy is a measure of randomness or uncertainty in the data, often used in information theory.
	Allocate a frequency table to store the count of each byte value.
	Allocate a probability table to store the probability of each byte value.
	Increment the count for each byte value in the frequency table.
	Calculate the probability of each byte value.
	Compute the entropy.
	Compute the maximum possible entropy for the given number of unique bytes.

	@function OCTET:entropy
	@return the entropy ratio (relative to the maximum entropy)
	@return the maximum possible entropy
	@return he computed entropy in bits
	@usage
	--create an octet of bin
	oct=OCTET.from_bin("101010001010100010101000101010000001011000011111")
	--save the three outpus
	ratio, max_entropy, bits = oct:entropy()
	print(ratio)
	print(max_entropy)
	print(bits)
	--the three outputs are: 0.7896901, 1.584962, 1.251629

 */
static int entropy(lua_State *L) {
	BEGIN();
	const octet *o = o_arg(L,1);
	register int i; // register
	// byte frequency table
	char *bfreq = malloc(0xff+0x0f);
	memset(bfreq, 0x0, 0xff+0x0f);
	// probability of recurring for each byte
	float *bprob = (float*)malloc(sizeof(float)*(0xff+0x0f));
	memset(bprob, 0x0, sizeof(float)*(0xff+0x0f));
	// calculate freqency of byte values
	register char *p = o->val;
	for(i=0; i<o->len; i++, p++) bfreq[(uint8_t)*p]++;
	// calculate proability of byte values
	float freq = 0.0;
	float entropy = 0.0;
	register uint8_t num = 0; // register
	float *f;
	for(i=0; i < 0xff; i++, p++) {
		if(bfreq[i] == 0x0) continue;
		num++;
		freq = (float)bfreq[i];
		f = &bprob[i];
		*f = freq / (float)o->len;
		entropy += *f * log2(*f);
	}
	// free work buffers
	free(bfreq);
	free(bprob);
	o_free(L, o);
	// return entropy ratio, max and bits
	float bits = -1.0 * entropy;
	float entmax = log2(num);
	lua_pushnumber(L, (lua_Number) (bits / entmax)); // ratio
	lua_pushnumber(L, (lua_Number) entmax ); // max
	lua_pushnumber(L, (lua_Number) bits);
	END(3);
}

static int popcount64b(uint64_t x) {
	//types and constants
	const uint64_t m1  = 0x5555555555555555; //binary: 0101...
	const uint64_t m2  = 0x3333333333333333; //binary: 00110011..
	const uint64_t m4  = 0x0f0f0f0f0f0f0f0f; //binary:  4 zeros,  4 ones ...
	// const uint64_t m8  = 0x00ff00ff00ff00ff; //binary:  8 zeros,  8 ones ...
	// const uint64_t m16 = 0x0000ffff0000ffff; //binary: 16 zeros, 16 ones ...
	// const uint64_t m32 = 0x00000000ffffffff; //binary: 32 zeros, 32 ones
	// const uint64_t hff = 0xffffffffffffffff; //binary: all ones
	// const uint64_t h01 = 0x0101010101010101; //the sum of 256 to the power of 0,1,2,3...
	x -= (x >> 1) & m1;             //put count of each 2 bits into those 2 bits
	x = (x & m2) + ((x >> 2) & m2); //put count of each 4 bits into those 4 bits
	x = (x + (x >> 4)) & m4;        //put count of each 8 bits into those 8 bits
	x += x >>  8;  //put count of each 16 bits into their lowest 8 bits
	x += x >> 16;  //put count of each 32 bits into their lowest 8 bits
	x += x >> 32;  //put count of each 64 bits into their lowest 8 bits
	return x & 0x7f;
}
#define min(a, b)   ((a) < (b) ? (a) : (b))
// compare bit by bit two arrays and returns the hamming distance

/***
	Calculate the Hamming distance between two octet structures.
	*The Hamming distance is the number of positions at which the corresponding bits differ between the two octets.
	*This function calculates the Hamming distance between two octets by treating them as arrays of 64-bit integers.
	*It only works with octets whose lengths are multiples of 8 bytes. It does not handle smaller octets or padding.
	*Ideal for applications involving large octets where performance is critical.


	@function OCTET:popcount_hamming
	@param oct an octet to compare with another one
	@return the Hamming distance between the two octets
	@usage
	--create two octets of bin (number of bits multiple of 64)
	oct=OCTET.from_bin("1010001010100010101000101010001010100010101000101010001010100010")
	oct2=OCTET.from_bin("1001000010010000100100001001000010010000100100001001000010010000")
	--print the Hamming distance between the two octets
	print(oct:popcount_hamming(oct2))
	--print: 24

 */
static int popcount_hamming_distance(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	int distance, c, nlen;
	const octet *left = o_arg(L, 1);
	const octet *right = o_arg(L, 2);
	if(!left || !right) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	nlen = min(left->len, right->len)>>3; // 64bit chunks of minimum length
	// TODO: support sizes below 8byte length by padding
	distance = 0;
	uint64_t *l, *r;
	l=(uint64_t*)left->val;
	r=(uint64_t*)right->val;
	for(c=0; c<nlen; c++)
		distance += popcount64b(  l[c] ^ r[c] );
	lua_pushinteger(L, distance);
end:
	o_free(L, left);
	o_free(L, right);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
	Calculate the Hamming distance between two octets by comparing them byte by byte and counting the number of differing bits.
 	* It is useful for comparing binary data and measuring their similarity.
	* This function requires the two octets to have the same length. If they differ, it throws an error.
	* Suitable for small to medium-sized octets where simplicity is more important than performance.

	@function OCTET:hamming
	@param oct an octet to compare with another one
	@return the Hamming distance between the two octets
	@usage
	--create two octets of bin of the same length
	oct=OCTET.from_bin("101000101010001010100010101000101010001010100010")
	oct2=OCTET.from_bin("100100001001000010010000100100001001000010010000")
	--print the Hamming distance between the two octets
	print(oct:hamming(oct2))
	--print: 18

 */
static int bitshift_hamming_distance(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	register uint32_t distance;
	register uint8_t x;
	register int c;
	const octet *left = o_arg(L, 1);
	const octet *right = o_arg(L, 2);
	if(!left || !right) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	// same length of octets needed
	if(left->len != right->len) {
		zerror(L, "Cannot measure hamming distance of octets of different lengths");
		failed_msg = "execution aborted";
		goto end;
	}
	distance = 0;
	for(c=0; c<left->len; c++) {
		x = left->val[c] ^ right->val[c];
		while(x > 0) {
			distance += x & 1;
			x >>= 1;
		}
	}
	lua_pushinteger(L,distance);
end:
	o_free(L, left);
	o_free(L, right);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
	Count the occurrences of a specific character in an octet and return the count as an integer to Lua.
	*It is useful for simple character-based analysis of binary data.

	@function OCTET:charcount
	@param char the charcater to count
	@return the number of occurrences of a specific character
	@usage
	--create a string octet
	oct=OCTET.from_string("Hello world!")
	--print the number of occurrences of "l"
	print(oct:charcount("l"))
	--print: 3

 */
static int charcount(lua_State *L) {
	BEGIN();
	register char needle;
	register const char *p;
	register int count = 0;
	register int c;
	const char *s = lua_tostring(L, 2);
	luaL_argcheck(L, s != NULL, 1, "string expected");
	const octet *o = o_arg(L,1);
	needle = *s; // single char
	const char *hay = (const char*)o->val;
	for(p=hay, c=0; c < o->len; p++, c++) if(needle==*p) count++;
	lua_pushinteger(L, count);
	o_free(L, o);
	END(1);
}

/***
	Compute the CRC-8 checksum of an octet and return the result as a new octet of length 1.
	*It is useful for error detection in data transmission or storage.
	*CRC-8 is a cyclic redundancy check algorithm that produces an 8-bit checksum.

	@function OCTET:crc
	@return the new octet containing the CRC-8 checksum
	@usage
	--create an octet of bin
	oct=OCTET.from_bin("01110100000111010100101000100111010")
	print(oct:crc():bin())
	--print: 10011110
 */
static int crc8(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	register uint8_t crc = 0xff;
	register size_t j;
	register int i;
	const octet *o = o_arg(L, 1);
	if(!o) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	char *data = o->val;
	for (i = 0; i < o->len; i++) {
		crc ^= data[i];
		for (j = 0; j < 8; j++) {
			if ((crc & 0x80) != 0)
				crc = (uint8_t)((crc << 1) ^ 0x31);
			else
				crc <<= 1;
		}
	}
	octet *res = o_new(L, 1);
	if(!o) {
		failed_msg = "Could not create OCTET";
		goto end;
	}
	res->val[0] = crc; res->len = 1;
end:
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	return 1;
}

/***
	Create a new octet with the prefix removed.
	*If the prefix doesn't match, it returns nil.

	@function octet:elide_at_start
	@param prefix to remove
	@return initial octet without the prefix or nil
*/
static int elide_at_start(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = o_arg(L,1);
	const octet *prefix = NULL;
	if(!o) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	prefix = o_arg(L,2);
	if(!prefix) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	int i = 0;
	while (i < o->len && i < prefix->len && o->val[i] == prefix->val[i]) {
        	i++;
    	}

	if (i != prefix->len) {
		lua_pushnil(L);
	} else {
		octet* res = o_new(L, o->len - prefix->len);
		if (i < o->len) {
			memmove(res->val, o->val + i, o->len - i);
			res->len = o->len - prefix->len;
		}
	}

end:
	o_free(L, o);
	o_free(L, prefix);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/***
	Creates a new octet of given size repeating the octet as input.

	@function octet:fillrepeat
	@param size
	@return octet of given size
	@usage
	--create an octet of hex
	oct=OCTET.from_hex("0xa1")
	print(oct:fillrepeat(5):hex())
	print: a1a1a1a1a1
*/
static int fillrepeat(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = o_arg(L,1);
	if(!o) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	int tn;
	lua_Integer size = lua_tointegerx(L,2,&tn);
	if(!tn || size < 0) {
		failed_msg = "size is not a positive number";
		goto end;
	}
	octet* res = o_new(L, size);
	res->len = size;
	int i;
	for(i=0; i<res->len; i++) {
		res->val[i] = o->val[i % o->len];
	}

end:
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
	Compare two octet structures and determine if the first octet
	*is lexicographically less than the second octet.

	@function OCTET:__lt
	@param oct an octet to compare
	@return a boolean value
	@usage
	--create two octets of bin to compare
	oct=OCTET.from_bin("01001010")
	oct2=OCTET.from_bin("10111011")
	--compare them
	if (oct:__lt(oct2)) then
    	print("oct less than oct2")
	else
    	print("oct2 less than oct")
	end
	--print: oct less than oct2

 */
static int lesser_than(lua_State *L) {
	BEGIN();
	const octet *l = o_arg(L,1);
	const octet *r = o_arg(L,2);
	size_t minlen = (l->len < r->len) ? l->len : r->len;
	if( memcmp(l->val,r->val,minlen) < 0 ) lua_pushboolean(L, 1);
	else lua_pushboolean(L, 0);
	o_free(L,l);
	o_free(L,r);
	END(1);
}

void OCT_shl_bits(octet *x, int n) {
	if (n >= 8 * x->len) { // If shifting more bits than the entire octet length, clear it.
		x->len = 0;
		return;
	}

	int byte_shift = n / 8;
	int bit_shift = n % 8;
	int carry_bits = 8 - bit_shift;

	if (byte_shift > 0) {
		for (int i = 0; i < x->len- byte_shift; i++)  x->val[i] = x->val[i + byte_shift];
		for (int i = x->len - byte_shift; i < x->len; i++)  x->val[i] = 0;
	}
	if (bit_shift > 0) {
		unsigned char carry = 0;
		for (int i = x->len-1; i >= 0; i--) {
			unsigned char current = x->val[i];
			x->val[i] = (current << bit_shift) | carry;
			carry = (current >> carry_bits) & ((1 << bit_shift) - 1);
		}
	}
}

/***
	Shift octet to the left by n bits. Leftmost bits disappear.
	*This is also executed when using the 'o << n' with o an octet and n an integer.

	@function OCTET:__shl
	@param positions number of positions to bit shift to the left
	@return the shifted octet
	@usage
	--create an octet of bin
	oct=OCTET.from_bin("01001010")
	--shift of three positions
	print(oct:__shl(3):bin())
	print: 01010000
*/
static int shift_left(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = o_arg(L,1);
	int isnum;
	lua_Integer n = lua_tointegerx(L,2,&isnum);
	if(!isnum) {
		failed_msg = "shift input is not a number";
		goto end;
	}
	octet *out = o_new(L,o->len);

	if(!out) {
		failed_msg = "Could not create OCTET";
		goto end;
	}
	OCT_copy(out, o);

	OCT_shl_bits(out, n);
	end:
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);


}

void OCT_shr_bits(octet *x, int n) {
	if (n >= 8 * x->len) {
		x->len = 0;
		return;
	}
	int byte_shift = n / 8;
	int bit_shift = n % 8;
	int carry_bits = 8- bit_shift;
	if (byte_shift > 0) {
		for (int i = x->len - 1; i >= byte_shift; i--) x->val[i] = x->val[i - byte_shift];
		for (int i = 0; i < byte_shift; i++) x->val[i] = 0;
	}

	if (bit_shift > 0) {
		unsigned char carry = 0;
		for (int i = 0; i < x->len; i++) {
			unsigned char current = x->val[i];
			x->val[i] = (current >> bit_shift) | carry;
			carry = (current  & ((1 << (bit_shift)) - 1)) << carry_bits;
		}
	}
}

/***
	Shift octet to the right by n bits. Rightmost bits disappear.
 	*This is also executed when using the 'o >> n' with o an octet and n an integer.

	@function OCTET:__shr
	@param positions number of positions to bit shift to the right
	@return the shiftet octet
	@usage
	--create an octet of bin
	oct=OCTET.from_bin("01001010")
	--shift of three positions
	print(oct:__shr(3):bin())
	print: 00001001
*/
static int shift_right(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = o_arg(L,1);
	int isnum;
	lua_Integer n = lua_tointegerx(L,2,&isnum);
	if(!isnum) {
		failed_msg = "shift input is not a number";
		goto end;
	}
	octet *out = o_new(L,o->len);

	if(!out) {
		failed_msg = "Could not create OCTET";
		goto end;
	}
	OCT_copy(out, o);

	OCT_shr_bits(out, n);
	end:
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);


}

/***
	Shift octet to the left by n bits.
	*Leftmost bits do not disappear but appear on the right.

	@function OCTET:shl_circular
	@param positions number of positions to bit shift to the left
	@return the circular shiftet octet
	@usage
	--create an octet of bin
	oct=OCTET.from_bin("01001010")
	--circular shift of three positions
	print(oct:shl_circular(3):bin())
	--print: 01010010
 */
// Circular shift octet to the left by n bits.
static int shift_left_circular(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = o_arg(L,1);
	int isnum;
	lua_Integer n = lua_tointegerx(L,2,&isnum);
	if(!isnum) {
		failed_msg = "shift input is not a number";
		goto end;
	}
	octet *out = o_new(L,o->len);

	if(!out) {
		failed_msg = "Could not create OCTET";
		goto end;
	}
	OCT_copy(out, o);

	OCT_circular_shl_bits(out, n);
	end:
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

void OCT_circular_shr_bits(octet *x, int n) {
	if (n >= 8 * x->len) {
		n = n % (8 * x->len);
	}

	int byte_shift = n / 8;
	int bit_shift = n % 8;
	int carry_bits = 8 - bit_shift;

	if (byte_shift > 0) {
		unsigned char temp[x->len];
		for (int i = 0; i < x->len; i++) {
			temp[i] = x->val[i];
		}

		for (int i = 0; i < x->len; i++) {
			x->val[i] = temp[(x->len + i - byte_shift) % x->len];
		}
	}

	if (bit_shift > 0) {
		unsigned char carry = 0;
		unsigned char last_byte_carry = (x->val[x->len - 1] & ((1 << (bit_shift)) - 1)) << carry_bits;

		for (int i = 0; i < x->len; i++) {
			unsigned char current = x->val[i];
			x->val[i] = (current >> bit_shift) | carry;
			carry = (current & ((1 << (bit_shift)) - 1)) << carry_bits;
		}
		x->val[0] |= last_byte_carry;
	}
}

/***
	Shift octet to the right by n bits.
	*Rightmost bits do not disappear but appear on the left.

	@function OCTET:rhl_circular
	@param positions number of positions to bit shift to the right
	@return the circular shiftet octet
	@usage
	--create an octet of bin
	oct=OCTET.from_bin("01001010")
	--circular shift of three positions
	print(oct:shr_circular(3):bin())
	--print: 01001001
*/
// Circular shift octet to the right by n bits
static int shift_right_circular(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *o = o_arg(L,1);
	int isnum;
	lua_Integer n = lua_tointegerx(L,2,&isnum);
	if(!isnum) {
		failed_msg = "shift input is not a number";
		goto end;
	}
	octet *out = o_new(L,o->len);

	if(!out) {
		failed_msg = "Could not create OCTET";
		goto end;
	}
	OCT_copy(out, o);

	OCT_circular_shr_bits(out, n);
	end:
	o_free(L, o);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);


}

void OCT_and(octet *y, octet *x)
{
	int i;
	for (i = 0; i < x->len && i < y->len; i++) {
		y->val[i] &= x->val[i];
	}
}

/***
	Bitwise AND operation on two octets padded to reach the same length, returns a new octet.
	*Results in a newly allocated octet, does not change the contents of any other octet involved.
	*If the two octets have different lengths,
	*the shorter one is padded with zeros to match the length of the longer one before performing the operation.

	@function OCTET:and_grow
	@param oct an octet for the bitwise AND operation
	@return the result of the bitwise AND operation between the two octets
	@usage
	--create two octets of bin
	oct=OCTET.from_bin("0100101001001011")
	oct2=OCTET.from_bin("10111011")
	print(oct:and_grow(oct2):bin())
	--print: 0000000000001011

*/
static int and_grow(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *x = o_arg(L, 1);
	octet *y = o_arg(L, 2);
	if(!x || !y) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	int max = _max(x->len, y->len);
	octet *n = o_new(L,max);
	if(!n) {
		failed_msg = "Could not create OCTET";
		goto end;
	}

	// pad first arg with zeroes
	if(x->len < max) {
		x->val = realloc(x->val, max);
		x->max = max;
		OCT_pad(x, max);
	}
	if(y->len < max) {
		y->val = realloc(y->val, max);
		y->max = max;
		OCT_pad(y, max);
	}

	OCT_copy(n, x);
	OCT_and(n, y);
end:
	o_free(L, x);
	o_free(L, y);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
	Bitwise AND operation on two octets truncating at the shortest one length, returns a new octet.
	*This is also executed when using the '<b>&</b>' operator between two
	*octets. Results in a newly allocated octet, does not change the
	*contents of any other octet involved.

	@function OCTET:__band
	@param oct an octet for the bitwise AND operation
	@return the result of the bitwise AND operation between the two octets
	@usage
	--create two octets of bin
	oct=OCTET.from_bin("0100101001001011")
	oct2=OCTET.from_bin("10111011")
	print(oct:__band(oct2):bin())
	--print: 00001010
*/
static int and_shrink(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *x = o_arg(L, 1);
	octet *y = o_arg(L, 2);
	if(!x || !y) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	int min = _min(x->len, y->len);
	octet *n = o_new(L,min);
	if(!n) {
		failed_msg = "Could not create OCTET";
		goto end;
	}
	OCT_copy(n, x);
	OCT_and(n, y);
end:
	o_free(L, x);
	o_free(L, y);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

void OCT_or(octet *y, octet *x)
{
	int i;
	for (i = 0; i < x->len && i < y->len; i++) {
		y->val[i] |= x->val[i];
	}
}

/***
	Bitwise OR operation on two octets padded to reach the same length, returns a new octet.
	*Results in a newly allocated octet, does not change the contents of any other octet involved.
	*If the two octets have different lengths,
	*the shorter one is padded with zeros to match the length of the longer one before performing the operation.

	@function OCTET:or_grow
	@param oct an octet for the bitwise OR operation
	@return the result of the bitwise OR operation between the two octets
	@usage
	--create two octets of bin
	oct=OCTET.from_bin("0100101001001011")
	oct2=OCTET.from_bin("10111011")
	print(oct:or_grow(oct2):bin())
	--print: 0100101011111011

*/
static int or_grow(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *x = o_arg(L, 1);
	octet *y = o_arg(L, 2);
	if(!x || !y) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	int max = _max(x->len, y->len);
	octet *n = o_new(L,max);
	if(!n) {
		failed_msg = "Could not create OCTET";
		goto end;
	}

	// pad first arg with zeroes
	if(x->len < max) {
		x->val = realloc(x->val, max);
		x->max = max;
		OCT_pad(x, max);
	}
	if(y->len < max) {
		y->val = realloc(y->val, max);
		y->max = max;
		OCT_pad(y, max);
	}

	OCT_copy(n, x);
	OCT_or(n, y);
end:
	o_free(L, x);
	o_free(L, y);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
	Bitwise OR operation on two octets truncating at the shortest one length, returns a new octet.
	*This is also executed when using the '<b>|</b>' operator between two
	*octets. Results in a newly allocated octet, does not change the
	*contents of any other octet involved.

	@function OCTET:__bor
	@param oct an octet for the bitwise OR operation
	@return the result of the bitwise OR operation between the two octets
	@usage
	--create two octets of bin
	oct=OCTET.from_bin("0100101001001011")
	oct2=OCTET.from_bin("10111011")
	print(oct:__bor(oct2):bin())
	--print: 11111011
*/
static int or_shrink(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *x = o_arg(L, 1);
	octet *y = o_arg(L, 2);
	if(!x || !y) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	int min = _min(x->len, y->len);
	octet *n = o_new(L,min);
	if(!n) {
		failed_msg = "Could not create OCTET";
		goto end;
	}
	OCT_copy(n, x);
	OCT_or(n, y);
end:
	o_free(L, x);
	o_free(L, y);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***

Bitwise XOR operation on two octets padded to reach the same length, returns a new octet.
*Results in a newly allocated octet, does not change the contents of any other octet involved.

	@param dest leftmost octet used in XOR operation
	@param source rightmost octet used in XOR operation
	@function OCTET:xor_grow
	@return a new octet resulting from the operation
	@usage
	--create two octets of bin
	oct=OCTET.from_bin("0100101001001011")
	oct2=OCTET.from_bin("10111011")
	print(oct:xor_grow(oct2):bin())
	--print: 0100101001001011
*/
static int xor_grow(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *x = o_arg(L, 1);
	const octet *y = o_arg(L, 2);
	if(!x || !y) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	int max = _max(x->len, y->len);
	octet *n = o_new(L,max);
	if(!n) {
		failed_msg = "Could not create OCTET";
		goto end;
	}
	octet *tx = o_alloc(L,max);
	memcpy(tx->val,x->val,x->len);
	tx->len = x->len;
	OCT_pad(tx, max);

	octet *ty = o_alloc(L,max);
	memcpy(ty->val,y->val,y->len);
	ty->len = y->len;
	OCT_pad(ty, max);

	o_free(L, x);
	o_free(L, y);

	OCT_copy(n, tx);
	OCT_xor(n, ty);
end:
	o_free(L, tx);
	o_free(L, ty);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***

Bitwise XOR operation on two octets truncating at the shortest one length, returns a new octet.
*This is also executed when using the '<b>~</b>' operator between two
*octets. Results in a newly allocated octet, does not change the
*contents of any other octet involved.

	@param dest leftmost octet used in XOR operation
	@param source rightmost octet used in XOR operation
	@function OCTET:__bxor
	@return a new octet resulting from the operation
	@usage
	--create two octets of bin
	oct=OCTET.from_bin("0100101001001011")
	oct2=OCTET.from_bin("10111011")
	print(oct:__bxor(oct2):bin())
	--print: 11110001

*/
static int xor_shrink(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *x = o_arg(L, 1);
	const octet *y = o_arg(L, 2);
	if(HEDLEY_UNLIKELY(!x || !y)) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	int min = _min(x->len, y->len);
	octet *n = o_new(L,min);
	if(HEDLEY_UNLIKELY(!n)) {
		failed_msg = "Could not create OCTET";
		goto end;
	}
	OCT_copy(n, (octet*)x);
	OCT_xor(n, (octet*)y);
end:
	o_free(L, x);
	o_free(L, y);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

/***
	Bitwise NOT operation on an octet returns a new octet.
	*This is also executed when using the '~</b>' operator.
	*Results in a newly allocated octet.

	@function OCTET:__bnot
	@return the new octet containing the result of the bitwise NOT operation
	@usage
	--create an octet of bin
	oct=OCTET.from_bin("0100101001001011")
	print(oct:__bnot():bin())
	--print: 1011010110110100
*/
static int bit_not(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	octet *x = o_arg(L, 1);
	if(!x) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	octet *n = o_new(L,x->len);
	OCT_copy(n, x);
	int i;
	for (i = 0; i < x->len; i++) {
		n->val[i] = ~(x->val[i]);
	}
end:
	o_free(L, x);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

// windows has no memmem, we provide our own
#if defined(_WIN32)
HEDLEY_NON_NULL(1,3)
static void *memmem(const void *src,int srclen,const void *dst,int dstlen) {
	unsigned char *csrc = (unsigned char *)src;
	unsigned char *cdst = (unsigned char *)dst;
	unsigned char *tptr,*cptr;
	int searchlen;
	int ndx = 0;
    while (ndx<=srclen) {
        cptr = &csrc[ndx];
        if ((searchlen = srclen-ndx-dstlen+1) <= 0) {
            return NULL;
        }
        if ((tptr = memchr(cptr,*cdst,searchlen)) == NULL) {
            return NULL;
        }
        if (memcmp(tptr,cdst,dstlen) == 0) {
            return tptr;
        }
        ndx += tptr-cptr+1;
    }
    return NULL;
}
#endif

/***
Finds a needle sequence of bytes in a haystack octet and returns the
*position where it has been found (counting from 0) or nil when not
*found.

	@function OCTET:find
	@param haystack the octet in which to find the needle
	@param needle the octet needle to search for
	@int pos (optional) the position to start searching in haystack
	@return a number indicating the position found in haystack or nil
	@usage
	--create an octet in hex
	oct=OCTET.from_hex("0xa1b2c3d4")
	--create the needle
	needle=OCTET.from_hex("0xc3")
	print(oct:find(needle))
	--print: 2.0
*/
static int memfind(lua_State *L) {
	BEGIN();
	const octet *haystack = o_arg(L,1);
	const octet *needle = o_arg(L,2);
	if(needle->len>=haystack->len) {
		lua_pushnil(L);
		zerror(L,"Octet:substr called on a needle bigger than haystack");
		goto end;
	}
	const int pos = luaL_optnumber(L, 3, 0);
	char *start = haystack->val;
	if(pos>0) {
		if(pos>=haystack->len) {
			lua_pushnil(L);
			zerror(L,"Octet:find position (3rd arg) out of haystack");
			goto end;
		}
		if(haystack->len-pos<needle->len) {
			lua_pushnil(L);
			zerror(L,"Octet:find position (3rd arg) squeezes out needle");
			goto end;
		}
		start += pos;
	}
	char *res = (char*)
		memmem(start, haystack->len-pos,
			   needle->val,   needle->len);
	if(!res) { // not found
		lua_pushnil(L);
	} else {
		lua_pushnumber(L, (uint32_t)(res - haystack->val));
	}
 end:
	o_free(L,needle);
	o_free(L,haystack);
	END(1);
}

/***
	Copies out a needle octet from an haystack octet starting at
	*position and long as indicated.

	@function OCTET:copy
	@param haystack octet from which we copy bytes out into needle
	@int start position, begins from 0
	@int length of byte sequence to copy
	@return new octet copied out
	@usage
	--create an octet in hex
	oct=OCTET.from_hex("0xa1b2c3d4")
	--define the start position equal to 1
	--define the length of byte sequence to copy equal to 2
	print(oct:copy(1,2):hex())
	--print: b2c3
*/
static int memcopy(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	const octet *src = NULL;
	octet *dst = NULL;
	int start, length;
	src = o_arg(L, 1);
	if(!src) {
		failed_msg = "Could not allocate OCTET";
		goto end;
	}
	start = luaL_optnumber(L, 2, 0);
	if(start < 0 || start > src->len) {
		zerror(L, "Octet:copy starting position out of bounds: %i", start);
		failed_msg = "Cannot copy octet";
		goto end;
	}
	length = luaL_optnumber(L, 3, 0);
	if(start+length > src->len) {
		zerror(L, "invalid octet:copy() length too big: %i", length);
		failed_msg = "Cannot copy octet";
		goto end;
	}
	dst = o_new(L, length+1);
	if(!dst) {
		failed_msg = "Cannot allocate octet memory";
		goto end;
	}
	memcpy(dst->val, src->val+start, length);
	dst->len = length;
end:
	o_free(L, src);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}


/***
	Paste a needle octet into an haystack octet starting at position
	*and overwriting all its byte values in place.

	@function OCTET:paste
	@param haystack octet destination in which to copy needle
	@param needle octet source of needle bytes
	@int starting position to paste the needle
	@return the modified octet

	--create an octet of hex
	oct=OCTET.from_hex("0xa1b2c3d4")
	--create the needle
	needle=OCTET.from_hex("0xc3")
	--paste the needle in the position 1
	print(oct:paste(needle,1):hex())
	--print: a1c3c3d4
*/
static int mempaste(lua_State *L) {
	BEGIN();
	char *failed_msg = NULL;
	int start;
	const octet *hay = o_arg(L, 1);
	if(!hay) {
		failed_msg = "Cannot allocate octet memory";
		goto end;
	}
	const octet *src = o_arg(L,2);
	if(!src) {
		failed_msg = "Cannot allocate octet memory";
		goto end;
	}
	if(src->len > hay->len) {
		zerror(L, "Octet:paste needle size (%i) exceeds haystack (%i)",
			   src->len, hay->len);
		failed_msg = "Cannot paste octet";
		goto end;
	}
	start = luaL_optnumber(L, 3, 0);
	if(start < 1 || start >= hay->len || start+src->len > hay->len) {
		zerror(L, "Octet:paste starting position out of bounds: %i", start);
		failed_msg = "Cannot paste octet";
		goto end;
	}
	octet *res = o_dup(L,hay);
	memcpy(res->val+start, src->val, src->len);
end:
	o_free(L, src);
	o_free(L, hay);
	if(failed_msg) {
		THROW(failed_msg);
	}
	END(1);
}

int luaopen_octet(lua_State *L) {
	(void)L;
	const struct luaL_Reg octet_class[] = {
		{"new",   newoctet},
		{"empty",   new_empty_octet}, // OCTET.empty()
		{"zero",  zero},
		{"crc",  crc8},
		{"concat",concat_n},
		{"xor",   xor_shrink},
		{"xor_shrink", xor_shrink},
		{"xor_grow", xor_grow},
		{"trim", trim},
		{"chop",  chop},
		{"sub",   sub},
		{"is_base64", lua_is_base64},
		{"is_url64", lua_is_url64},
		{"is_base58", lua_is_base58},
		{"is_hex", lua_is_hex},
		{"is_bin", lua_is_bin},
		{"from_number",from_number},
		{"from_base64",from_base64},
		{"from_base45",from_base45},
		{"from_url64",from_url64},
		{"from_base58",from_base58},
		{"from_string",from_string},
		{"from_str",   from_string},
		{"from_rawlen",  from_rawlen},
		{"from_hex",   from_hex},
		{"from_bin",   from_bin},
		{"from_mnemonic",   from_mnemonic},
		{"from_uuid", from_uuid},
		{"base64",from_base64},
		{"url64",from_url64},
		{"base58",from_base58},
		{"string",from_string},
		{"str",   from_string},
		{"hex",   from_hex},
		{"bin",   from_bin},
		{"to_hex"   , to_hex},
		{"to_base64", to_base64},
		{"to_url64",  to_url64},
		{"to_base58", to_base58},
		{"to_string", to_string},
		{"to_str",    to_string},
		{"to_array",  to_array},
		{"to_octet",  to_octet},
		{"to_bin",    to_bin},
		{"to_uuid",   to_uuid},
		// {"zcash_topoint", zcash_topoint},
		{"to_mnemonic", to_mnemonic},
		{"random",  new_random},
		{"entropy", entropy},
		{"bytefreq", entropy_bytefreq},
		{"rmchar", remove_char},
		{"compact_ascii", compact_ascii},
		{"charcount", charcount},
		{"hamming", bitshift_hamming_distance},
		{"popcount_hamming", popcount_hamming_distance},
		{"to_segwit", to_segwit_address},
		{"from_segwit", from_segwit_address},
		{"fuzz_byte", fuzz_byte_random},
		{"fuzz_byte_xor", fuzz_byte_xor},
		{"fuzz_bit", fuzz_bit_random},
		{"fuzz_byte_circular_shift", fuzz_byte_circular_shift_random},
		{"fuzz_bit_circular_shift", fuzz_bit_circular_shift_random},
		{"shl", shift_left},
		{"shl_circular", shift_left_circular},
		{"shr_circular", shift_right_circular},
		{"shr", shift_right},
		{"and",   and_shrink},
		{"and_grow", and_grow},
		{"or",   or_shrink},
		{"or_grow", or_grow},
		{"not", bit_not},
		{"find", memfind},
		{"copy", memcopy},
		{"paste", mempaste},

		{NULL,NULL}
	};
	const struct luaL_Reg octet_methods[] = {
		{"crc",  crc8},
		{"xor",   xor_shrink},
		{"xor_shrink", xor_shrink},
		{"xor_grow", xor_grow},
		{"trim", trim},
		{"chop",  chop},
		{"sub",   sub},
		{"reverse",  reverse},
		{"fill"  , filloctet},
		{"hex"   , to_hex},
		{"base64", to_base64},
		{"url64",  to_url64},
		{"base58", to_base58},
		{"base45", to_base45},
		{"string", to_string},
		{"octet",  to_octet},
		{"str",    to_string},
		{"array",  to_array},
		{"bin",    to_bin},
		{"uuid",    to_uuid},
		{"mnemonic", to_mnemonic},
		{"to_hex"   , to_hex},
		{"to_base64", to_base64},
		{"to_url64",  to_url64},
		{"to_base58", to_base58},
		{"to_base45", to_base45},
		{"to_string", to_string},
		{"to_octet",  to_octet},
		{"to_str",    to_string},
		{"to_array",  to_array},
		{"to_bin",    to_bin},
		{"to_uuid",   to_uuid},
		{"to_mnemonic", to_mnemonic},
		{"eq", eq},
		{"pad", pad},
		{"max", max},
		{"entropy", entropy},
		{"bytefreq", entropy_bytefreq},
		{"hamming", bitshift_hamming_distance},
		{"popcount_hamming", popcount_hamming_distance},
		{"segwit", to_segwit_address},
		{"charcount", charcount},
		{"rmchar", remove_char},
		{"compact_ascii", compact_ascii},
		{"elide_at_start", elide_at_start},
		{"fillrepeat", fillrepeat},
		{"fuzz_byte", fuzz_byte_random},
		{"fuzz_byte_xor", fuzz_byte_xor},
		{"fuzz_bit", fuzz_bit_random},
		{"fuzz_byte_circular_shift", fuzz_byte_circular_shift_random},
		{"fuzz_bit_circular_shift", fuzz_bit_circular_shift_random},
		{"shl", shift_left},
		{"shr", shift_right},
		{"shl_circular", shift_left_circular},
		{"shr_circular", shift_right_circular},
		{"and",   and_shrink},
		{"and_grow", and_grow},
		{"or",   or_shrink},
		{"or_grow", or_grow},
		{"not", bit_not},
		{"find", memfind},
		{"copy", memcopy},
		{"paste", mempaste},
		// {"zcash_topoint", zcash_topoint},
		// idiomatic operators
		{"__len",octet_size},
		{"__concat",concat_n},
		{"__bxor",xor_shrink},
		{"__eq",eq},
		{"__gc", o_destroy},
		{"__tostring",to_base64},
		{"__lt",lesser_than},
		{"__shl", shift_left},
		{"__shr", shift_right},
		{"__band", and_shrink},
		{"__bor", or_shrink},
		{"__bnot", bit_not},
		{NULL,NULL}
	};
	zen_add_class(L, "octet", octet_class, octet_methods);
	return 1;
}
