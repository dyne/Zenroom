/*  Zenroom (DECODE project)
 *
 *  (c) Copyright 2017-2018 Dyne.org foundation
 *  designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This source code is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Public License as published
 * by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 *
 * This source code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * Please refer to the GNU Public License for more details.
 *
 * You should have received a copy of the GNU Public License along with
 * this source code; if not, write to:
 * Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

/// <h1>Base data type for cryptographic opearations</h1>
//
//  Octets are <a
//  href="https://en.wikipedia.org/wiki/First-class_citizen">first-class
//  citizens</a> in Zenroom. They consist of arrays of bytes (8bit)
//  compatible with all cryptographic functions and methods. They are
//  implemented to avoid any buffer overflow and their maximum size is
//  known at the time of instantiation. It is possible to create OCTET
//  instances using the new() method:
//
//  <code>message = octet.new(64) -- creates a 64 bytes long octet</code>
//
//  Octets can export their contents to portable formats as sequences
//  of @{base64} or @{base58} or @{hex} strings just using their
//  appropriate methods. They can also be exported to Lua's @{array}
//  format.
//
//  @module OCTET
//  @author Denis "Jaromil" Roio
//  @license GPLv3
//  @copyright Dyne.org foundation 2017-2018
//

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <jutils.h>
#include <zen_error.h>
#include <lua_functions.h>

#include <amcl.h>

#include <zenroom.h>
#include <zen_memory.h>
#include <zen_octet.h>
#include <zen_big.h>

#include <zen_ecp.h>

// from base58.c
extern int b58tobin(void *bin, size_t *binszp, const char *b58, size_t b58sz);
extern int b58enc(char *b58, size_t *b58sz, const void *data, size_t binsz);

// from zenroom types that are convertible to octet
// they don't do any internal memory allocation
// all arguments are allocated and freed by the caller
extern int _ecp_to_octet(octet *o, ecp *e);
extern int _ecp2_to_octet(octet *o, ecp2 *e);

static int _max(int x, int y) { if(x > y) return x;	else return y; }
// static int _min(int x, int y) { if(x < y) return x;	else return y; }

// takes a base string and calculated the maximum length of the
// decoded string
#include <ctype.h>
static int getlen_base64(int len) {	return( ((3+(4*(len/3))) & ~0x03)+0x0f ); }
static int getlen_base58(int len) {	return( ((3+(5*(len/3))) & ~0x03)+0x0f ); }

// assumes null terminated string
// returns 0 if not base else length of base encoded string
int is_base64(const char *in) {
	if(!in) { return 0; }
	int c;
	for(c=0; in[c]!='\0'; c++) {
		if (!(isalnum(in[c])
		      || '+' == in[c]
		      || '=' == in[c]
		      || '/' == in[c])) {
			return 0; }
	}
	return c;
}
extern const int8_t b58digits_map[];
int is_base58(const char *in) {
	if(!in) {
		HEREs("null string in is_base58");
		return 0; }
	int c;
	for(c=0; in[c]!='\0'; c++) {
		if(b58digits_map[(int8_t)in[c]]==-1) {
			func(NULL,"invalid base58 digit");
			return 0; }
		if(in[c] & 0x80) {
			func(NULL,"high-bit set on invalid digit");
			return 0; }
	}
	return c;
}

int is_hex(const char *in) {
	if(!in) { ERROR(); return 0; }
	int c;
	for(c=0; in[c]!=0; c++) {
		if (!isxdigit(in[c])) {
			return 0; }
	}
	return c;
}

int is_bin(const char *in) {
	if(!in) { ERROR(); return 0; }
	int c;
	for(c=0; in[c]!='\0'; c++) {
		if (in[c]!='0' && in[c]!='1') {
			return 0; }
	}
	return c;
}

// REMEMBER: newuserdata already pushes the object in lua's stack
octet* o_new(lua_State *L, const int size) {
	if(size<=0) return NULL;
	if(size>MAX_FILE) {
		error(L, "Cannot create octet, size too big: %u", size);
		lerror(L, "operation aborted");
		return NULL; }
	octet *o = (octet *)lua_newuserdata(L, sizeof(octet));
	if(!o) {
		lerror(L, "Error allocating new octet in %s",__func__);
		return NULL; }
	luaL_getmetatable(L, "zenroom.octet");
	lua_setmetatable(L, -2);
	o->val = zen_memory_alloc(size +0x0f);
	o->len = 0;
	o->max = size;
	func(L, "new octet (%u bytes)",size);
	return(o);
}

// here most internal type conversions happen
octet* o_arg(lua_State *L,int n) {
	void *ud;
	octet *o = NULL;
	o = (octet*) luaL_testudata(L, n, "zenroom.octet"); // new
	if(!o && strncmp("string",luaL_typename(L,n),6)==0) {
		size_t len; const char *str;
		str = luaL_optlstring(L,n,NULL,&len);
		if(!str || !len) {
			error(L, "invalid NULL string (zero size)");
			lerror(L,"failed implicit conversion from string to octet");
			return 0; }
		if(!len || len>MAX_STRING) {
			error(L, "invalid string size: %u", len);
			lerror(L,"failed implicit conversion from string to octet");
			return 0; }
		// note here implicit conversion is only made from hex
		// TODO: this could be a zenroom configuration setting
		int hlen = is_hex(str);
		if(hlen>0) { // import from a HEX encoded string
			o = o_new(L, hlen); SAFE(o);
			OCT_fromHex(o, (char*)str);
		} else {
			// fallback to a string
			o = o_new(L, len+1); SAFE(o); // new
			OCT_jstring(o, (char*)str);
		}
		lua_pop(L,1);
	} else {
		ud = luaL_testudata(L, n, "zenroom.big");
		if(!o && ud) {
			big *b = (big*)ud;
			o = new_octet_from_big(L,b); SAFE(o);
			lua_pop(L,1);
		}
		ud = luaL_testudata(L, n, "zenroom.ecp");
		if(!o && ud) {
			ecp *e = (ecp*)ud;
			o = o_new(L, e->totlen + 0x0f); SAFE(o); // new
			_ecp_to_octet(o,e);
			lua_pop(L,1);
		}
		ud = luaL_testudata(L, n, "zenroom.ecp2");
		if(!o && ud) {
			ecp2 *e = (ecp2*)ud;
			o = o_new(L, e->totlen + 0x0f); SAFE(o); // new
			_ecp2_to_octet(o,e);
			lua_pop(L,1);
		}
	}
	if(!o) {
		error(L,"Error in argument #%u",n);
		lerror(L, "%s: cannot convert %s to zeroom.octet",__func__,luaL_typename(L,n));
		return NULL; }
	// if executing here, something is pushed into Lua's stack
	// but this is an internal function to gather arguments, so
	// should be popped before returning the new octet
	if(o->len>MAX_FILE) {
		error(L, "argument %u octet too long: %u bytes",n,o->len);
		lerror(L, "operation aborted");
		return NULL; }
	return(o);
}

// allocates a new octet in LUA, duplicating the one in arg
octet *o_dup(lua_State *L, octet *o) {
	SAFE(o);
	octet *n = o_new(L, o->len+1);
	SAFE(n);
	OCT_copy(n,o);
	return(n);
}

int o_destroy(lua_State *L) {
	void *ud = luaL_testudata(L, 1, "zenroom.octet");
	if(ud) {
		octet *o = (octet*)ud;
		if(o->val) zen_memory_free(o->val);
	}
	return 0;
}

/// Global Octet Functions
// @section OCTET
//
// So called "global functions" are all prefixed by <b>octet.</b>,
// operate on one or more octet objects and always return a new octet
// resulting from the operation.
//
// This is a difference with "object methods" listed in the next
// section which are operating on the octet itself, doing "in place"
// modifications. Plan well what to use to save memory space and
// computations.


/***
Create a new octet with a specified maximum size, or a default if
omitted. All operations exceeding the octet's size will truncate
excessing data. Octets cannot be resized.

@function OCTET.new(length)
@int[opt=4096] length maximum length in bytes
@return octet newly instantiated octet
*/
static int newoctet (lua_State *L) {
	const int len = luaL_optinteger(L, 1, MAX_OCTET);
	if(!len) {
		lerror(L, "octet created with zero length");
		return 0; }
	octet *o = o_new(L,len);
	SAFE(o);
	OCT_empty(o);
	return 1;  /* new userdatum is already on the stack */
}

/***

Bitwise XOR operation on two octets, returns a new octet. This is also
executed when using the '<b>~</b>' operator between two
octets. Results in a newly allocated octet, does not change the
contents of any other octet involved.

    @param dest leftmost octet used in XOR operation
    @param source rightmost octet used in XOR operation
    @function OCTET.xor(dest, source)
    @return a new octet resulting from the operation
*/
static int xor_n(lua_State *L) {
	octet *x = o_arg(L,1);	SAFE(x);
	octet *y = o_arg(L,2);	SAFE(y);
	octet *n = o_new(L,_max(x->len, y->len));
	SAFE(n);
	OCT_copy(n,x);
	OCT_xor(n,y);
	return 1;
}

static int lua_is_base64(lua_State *L) {
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "string expected");
	int len = is_base64(s);
	if(!len) {
		lua_pushboolean(L, 0);
		func(L, "string is not a valid base64 sequence");
		return 1; }
	lua_pushboolean(L, 1);
	return 1;
}
static int lua_is_base58(lua_State *L) {
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "string expected");
	int len = is_base58(s);
	if(!len) {
		lua_pushboolean(L, 0);
		func(L, "string is not a valid base58 sequence");
		return 1; }
	lua_pushboolean(L, 1);
	return 1;
}
static int lua_is_hex(lua_State *L) {
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "string expected");
	int len = is_hex(s);
	if(!len) {
		lua_pushboolean(L, 0);
		func(L, "string is not a valid hex sequence");
		return 1; }
	lua_pushboolean(L, 1);
	return 1;
}
static int lua_is_bin(lua_State *L) {
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "string expected");
	int len = is_bin(s);
	if(!len) {
		lua_pushboolean(L, 0);
		func(L, "string is not a valid binary sequence");
		return 1; }
	lua_pushboolean(L, 1);
	return 1;
}

static int from_base64(lua_State *L) {
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "base64 string expected");
	int len = is_base64(s);
	if(!len) {
		lerror(L, "base64 string contains invalid characters");
		return 0; }
	int nlen = len + len + len; // getlen_base64(len);
	octet *o = o_new(L, nlen);
	OCT_frombase64(o,(char*)s);
	return 1;
}

static int from_base58(lua_State *L) {
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "base58 string expected");
	int len = is_base58(s);
	if(!len) {
		lerror(L, "base58 string contains invalid characters");
		return 0; }
	size_t binmax = len + len + len;
	size_t binlen = binmax;
	char *dst = zen_memory_alloc(binmax);
	if(!b58tobin(dst, &binlen, s, len)) {
		zen_memory_free(dst);
		lerror(L,"Error in conversion from base58 for string: %s",s);
		return 0; }
	octet *o = o_new(L, binlen);
	o->len = binlen;
	// b58tobin returns its result at the _end_ of buf!!!
	int l,r;
	for(l=binlen, r=binmax; l>=0; l--, r--) o->val[l] = dst[r];
	zen_memory_free(dst);
	return 1;
}

static int from_string(lua_State *L) {
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "string expected");
	int len = strlen(s);
	if(!len || len>MAX_STRING) {
		error(L, "%s: invalid string size: %u", __func__,len);
		lerror(L, "operation aborted");
		return 0; }
	octet *o = o_new(L, len);
	OCT_jstring(o, (char*)s);
	return 1;
}

static int from_hex(lua_State *L) {
	const int32_t hextable[] = {
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
		-1,-1, 0,1,2,3,4,5,6,7,8,9,-1,-1,-1,-1,-1,-1,-1,10,11,12,13,14,15,-1,
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
		-1,-1,10,11,12,13,14,15,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
		-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
	};
	// const long hextable[] = {
	// 	[0 ... 255] = -1,
	// 	['0'] = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
	// 	['A'] = 10, 11, 12, 13, 14, 15,
	// 	['a'] = 10, 11, 12, 13, 14, 15
	// };
	const char *s = lua_tostring(L, 1);
	if(!s) {
		error(L, "%s :: invalid argument",__func__);
		lua_pushboolean(L,0);
		return 1; }
	// luaL_argcheck(L, s != NULL, 1, "hex string sequence expected");
	int len = is_hex(s);
	func(L,"hex string sequence length: %u",len);
	if(!len || len>MAX_STRING*2) {
		error(L, "invalid hex sequence size: %u", len);
		lua_pushboolean(L,0);
		return 1; }
	octet *o = o_new(L, len); // can be halved
	int i, j;
	for(i=0, j=0; s[j]!=0; i++, j+=2)
		o->val[i] = (hextable[(short)s[j]]<<4) + hextable[(short)s[j+1]];
	o->len=i;
	return 1;
}

static int from_bin(lua_State *L) {
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "binary string sequence expected");
	int len = is_bin(s);
	int bytes = len/8; // TODO: check that len is mult of 8 (no carry)
	if(!len || bytes>MAX_STRING) {
		error(L, "invalid binary sequence size: %u", bytes);
		lerror(L, "operation aborted");
		return 0; }
	octet *o = o_new(L, bytes+1);
	int i,j;
	uint8_t b;
	for(i=0; i<len; i+=8) {
		b = 0x0;
		for(j=0;j<8;++j) {
			if(s[i+j]=='1') b = b | 0x1;
			b <<= 1;
		}
		o->val[i/8] = b>>1;
	}
	o->val[bytes] = 0x0;
	o->len = bytes;
	return 1;
}

/***
Concatenate two octets, returns a new octet. This is also executed
when using the '<b>..</b>' operator btween two octets. It results in a
newly allocated octet, does not change the contents of other octets.

    @param dest leftmost octet will be overwritten by result
    @param source rightmost octet used in XOR operation
    @function OCTET.concat(dest, source)
    @return a new octet resulting from the operation
*/
static int concat_n(lua_State *L) {
	octet *x, *y;
	char *sx = NULL;
	char *sy = NULL;
	octet xs, ys;
	void *ud;
	ud = luaL_checkudata(L, 1, "zenroom.octet");
	if(ud) {
		x = o_arg(L,1);	SAFE(x);
	} else {
		x = &xs;
		sx = (char*) lua_tostring(L, 1);
		luaL_argcheck(L, sx != NULL, 1, "octet or string expected in concat");
		xs.len = strlen(sx);
		xs.val = sx;
	}
	ud = luaL_checkudata(L, 2, "zenroom.octet");
	if(ud) {
		y = o_arg(L,2);	SAFE(y);
	} else {
		y = &ys;
		sy = (char*) lua_tostring(L, 2);
		luaL_argcheck(L, sy != NULL, 2, "octet or string expected in concat");
		ys.len = strlen(sy);
		ys.val = sy;
	}
	octet *n = o_new(L,x->len+y->len); SAFE(n);
	OCT_copy(n,x);
	OCT_joctet(n,y);
	return 1;
}


/// Object Methods
// @type octet
//
// This section lists methods that can be called as members of the
// 'octet' objects, using a semicolon notation instead of a
// dot. Example synopsis:
//
// <pre class="example">
// octet:<span class="global">method</span>(<span class="string">args</span>)
// </pre>
//
// Octet contents are never changed: the methods always return a new
// octet with the requested changes applied.
//

/***
Print an octet in base64 notation.

@function octet:base64()
@return a string representing the octet's contents in base64

@see octet:hex
@usage

-- This method as well :string() and :hex() can be used both to set
-- from and print out in particular formats.

-- create an octet from a string:
msg = OCTET.string("my message to be encoded in base64")
-- print the message in base64 notation:
print(msg:base64())


*/
static int to_base64 (lua_State *L) {
	octet *o = o_arg(L,1);	SAFE(o);
	if(!o->len || !o->val) {
		lerror(L, "base64 cannot encode an empty string");
		return 0; }
	int newlen;
	newlen = getlen_base64(o->len);
	char *b = zen_memory_alloc(newlen);
	OCT_tobase64(b,o);
//	b[newlen] = '\0';
	lua_pushstring(L,b);
	zen_memory_free(b);
	return 1;
}


/***
Print an octet in base58 notation.

This encoding uses the same alphabet as Bitcoin addresses. Why base58 instead of standard base64 encoding?

- Don't want 0OIl characters that look the same in some fonts and could be used to create visually identical looking data.
- A string with non-alphanumeric characters is not as easily accepted as input.
- E-mail usually won't line-break if there's no punctuation to break at.
- Double-clicking selects the whole string as one word if it's all alphanumeric.

    @function octet:base58()
    @return a string representing the octet's contents in base58
*/
static int to_base58(lua_State *L) {
	octet *o = o_arg(L,1);	SAFE(o);
	if(!o->len || !o->val) {
		lerror(L, "base64 cannot encode an empty octet");
		return 0; }
	if(o->len < 3) {
		// there is a bug in luke-jr's implementation of base58 (fixed
		// in bitcoin-core) when encoding strings smaller than 3 bytes
		// the 'j' counter being unsigned and initialised at size-2 in
		// the carry inner loop flips to 18446744073709551615
		lerror(L,"base58 cannot encode octets smaller than 3 bytes");
		return 0; }
	int newlen = getlen_base58(o->len);
	char *b = zen_memory_alloc(newlen);
	size_t b58len = newlen;
	b58enc(b, &b58len, o->val, o->len);
	// b[b58len] = '\0'; // already present, but for safety
	lua_pushlstring(L,b,b58len-1);
	zen_memory_free(b);
	return 1;
}

/***
    Converts an octet into an array of bytes, compatible with Lua's transformations on <a href="https://www.lua.org/pil/11.1.html">arrays</a>.

    @function octet:array()
    @return an array as Lua's internal representation
*/

static int to_array(lua_State *L) {
	octet *o = o_arg(L,1);	SAFE(o);
	if(!o->len || !o->val) {
		lerror(L, "array cannot encode an empty octet");
		return 0; }
	lua_newtable(L);
	// luaL_checkstack(L,1, "in octet:to_array()");
	int c = o->len;
	int idx = 0;
	while(c--) {
		lua_pushnumber(L,idx+1);
		lua_pushinteger(L,o->val[idx]);
		lua_settable(L,-3);
		idx++;
	}
	return 1;
}

/***
    Print an octet as string.

    @function octet:string()
    @return a string representing the octet's contents
*/
static int to_string(lua_State *L) {
	octet *o = o_arg(L,1);	SAFE(o);
	char *s = zen_memory_alloc(o->len+2);
	OCT_toStr(o,s); // TODO: inverted function signature, see
					// https://github.com/milagro-crypto/milagro-crypto-c/issues/291
	s[o->len] = '\0'; // make sure string is NULL terminated
	lua_pushstring(L,s);
	zen_memory_free(s);
	return 1;
}


/***
Converts an octet into a string of hexadecimal numbers representing its contents.

This is the default format when `print()` is used on an octet.

    @function octet:hex()
    @return a string of hexadecimal numbers
*/
int to_hex(lua_State *L) {
	octet *o = o_arg(L,1);	SAFE(o);
	push_octet_to_hex_string(o);
	return 1;
}

static int to_bin(lua_State *L) {
	octet *o = o_arg(L,1);	SAFE(o);
	char *s = zen_memory_alloc(o->len*8+2);
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
	zen_memory_free(s);
	return(1);
}

/***
    Pad an octet with leading zeroes up to indicated length or its
    maximum size.

    @int[opt=octet:max] length pad to this size, will use maximum octet size if omitted
    @return new octet padded at length
    @function octet:pad(length)
*/
static int pad(lua_State *L) {
	octet *o = o_arg(L,1);	SAFE(o);
	const int len = luaL_optinteger(L, 2, o->max);
	octet *n = o_new(L,len); SAFE(n);
	OCT_copy(n,o);
	OCT_pad(n,len);
	return 1;
}

/***
    Fill an octet with zero values up to indicated size or its maximum size.

    @int[opt=octet:max] length fill with zero up to this size, use maxumum octet size if omitted
    @function octet:zero(length)
*/
static int zero(lua_State *L) {
	octet *o = o_arg(L,1);	SAFE(o);
	const int len = luaL_optinteger(L, 2, o->max);
	octet *n = o_new(L,len); SAFE(n);
	OCT_copy(n,o);
	int i;
	for(i=0; i<len; i++) n->val[i]=0x0;
	n->len = len;
	return 1;
}

/***
    Compare two octets to see if contents are equal.

    @function octet:eq(first, second)
    @return true if equal, false otherwise
*/

static int eq(lua_State *L) {
	octet *x = o_arg(L,1);	SAFE(x);
	octet *y = o_arg(L,2);	SAFE(y);
	if (x->len!=y->len) {
		lua_pushboolean(L, 0);
		return 1; }
	int i;
	for (i=0; i<x->len; i++) {
		if (x->val[i]!=y->val[i]) {
			lua_pushboolean(L, 0);
			return 1; }
	}
	lua_pushboolean(L, 1);
	return 1;
}

static int size(lua_State *L) {
	octet *o = o_arg(L,1); SAFE(o);
	lua_pushinteger(L,o->len);
	return 1;
}

static int max(lua_State *L) {
	octet *o = o_arg(L,1); SAFE(o);
	lua_pushinteger(L,o->max);
	return 1;
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
static int hamming_distance(lua_State *L) {
	int distance, c, nlen;
	octet *left = o_arg(L,1); SAFE(left);
	octet *right = o_arg(L,2); SAFE(right);
	nlen = min(left->len,right->len)>>3; // 64bit chunks of minimum length
	// TODO: support sizes below 8byte length by padding
	distance = 0;
	uint64_t *l, *r;
	l=(uint64_t*)left->val;
	r=(uint64_t*)right->val;
	for(c=0;c<nlen;c++)
		distance += popcount64b(  l[c] ^ r[c] );
	lua_pushinteger(L,distance);
	return 1;
}


int luaopen_octet(lua_State *L) {
	const struct luaL_Reg octet_class[] = {
		{"new",   newoctet},
		{"concat",concat_n},
		{"xor",   xor_n},
		{"is_base64", lua_is_base64},
		{"is_base58", lua_is_base58},
		{"is_hex", lua_is_hex},
		{"is_bin", lua_is_bin},

		{"from_base64",from_base64},
		{"from_base58",from_base58},
		{"from_string",from_string},
		{"from_str",   from_string},
		{"from_hex",   from_hex},
		{"from_bin",   from_bin},
		{"base64",from_base64},
		{"base58",from_base58},
		{"string",from_string},
		{"str",   from_string},
		{"hex",   from_hex},
		{"bin",   from_bin},
		{"to_hex"   , to_hex},
		{"to_base64", to_base64},
		{"to_base58", to_base58},
		{"to_string", to_string},
		{"to_str",    to_string},
		{"to_array",  to_array},
		{"to_bin",    to_bin},

		{"hamming", hamming_distance},
		{NULL,NULL}
	};
	const struct luaL_Reg octet_methods[] = {
		{"hex"   , to_hex},
		{"base64", to_base64},
		{"base58", to_base58},
		{"string", to_string},
		{"str",    to_string},
		{"array",  to_array},
		{"bin",    to_bin},
		{"eq", eq},
		{"pad", pad},
		{"zero", zero},
		{"max", max},
		{"hamming", hamming_distance},
		// idiomatic operators
		{"__len",size},
		{"__concat",concat_n},
		{"__bxor",xor_n},
		{"__eq",eq},
		{"__gc", o_destroy},
		{"__tostring",to_hex},
		{NULL,NULL}
	};
	zen_add_class(L, "octet", octet_class, octet_methods);
	return 1;
}
