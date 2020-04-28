/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2020 Dyne.org foundation
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

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <jutils.h>
#include <zen_error.h>
#include <lua_functions.h>

#include <amcl.h>

#include <zenroom.h>
#include <encoding.h>
#include <zen_memory.h>
#include <zen_octet.h>
#include <zen_big.h>

#include <zen_ecp.h>

#include <math.h> // for log2 in entropy calculation

extern zenroom_t *Z;

// from base58.c
// extern int b58tobin(void *bin, size_t *binszp, const char *b58, size_t b58sz);
// extern int b58enc(char *b58, size_t *b58sz, const void *data, size_t binsz);

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
// static int getlen_base58(int len) {	return( ((3+(5*(len/3))) & ~0x03)+0x0f ); }

// assumes null terminated string
// returns 0 if not base else length of base encoded string
int is_base64(const char *in) {
	if(!in) { return 0; }
	int c;
	// check b64: header
	// if(in[0]!='b' || in[1]!='6' || in[2]!='4' || in[3]!=':') return 0;
	// check all valid characters
	for(c=4; in[c]!='\0'; c++) {
		if (!(isalnum(in[c])
		      || '+' == in[c]
		      || '=' == in[c]
		      || '/' == in[c])) {
			return 0; }
	}
	if(c%4 != 0) return 0; // always multiple of 4
	return c;
}

void push_octet_to_hex_string(lua_State *L, octet *o) {
	char *s = zen_memory_alloc((o->len<<1)+1); // string len = double +1
	buf2hex(s, o->val, o->len);
	lua_pushstring(L,s);
	zen_memory_free(s);
	return;
}

// extern const int8_t b58digits_map[];
// int is_base58(const char *in) {
// 	if(!in) {
// 		HEREs("null string in is_base58");
// 		return 0; }
// 	int c;
// 	for(c=0; in[c]!='\0'; c++) {
// 		if(b58digits_map[(int8_t)in[c]]==-1) {
// 			func(NULL,"invalid base58 digit");
// 			return 0; }
// 		if(in[c] & 0x80) {
// 			func(NULL,"high-bit set on invalid digit");
// 			return 0; }
// 	}
// 	return c;
// }

int is_hex(const char *in) {
	if(!in) { ERROR(); return 0; }
	int c;
	for(c=0; in[c]!=0; c++) {
		if (!isxdigit(in[c])) {
			return 0; }
	}
	return c;
}

// return total string length including spaces
int is_bin(const char *in) {
	if(!in) { ERROR(); return 0; }
	register int c;
	register int len = 0;
	for(c=0; in[c]!='\0'; c++) {
		if (in[c]!='0' && in[c]!='1' && !isspace(in[c])) return 0;
		len++;
	}
	return len; 
}

// REMEMBER: newuserdata already pushes the object in lua's stack
octet* o_new(lua_State *L, const int size) {
	if(size<=0) {
		error(L, "Cannot create octet, size zero or less");
		lerror(L, "execution aborted");
		return NULL; }
	if(size>MAX_OCTET) {
		error(L, "Cannot create octet, size too big: %u", size);
		lerror(L, "execution aborted");
		return NULL; }
	octet *o = (octet *)lua_newuserdata(L, sizeof(octet));
	if(!o) {
		lerror(L, "Error allocating new userdata for octet");
		return NULL; }
	luaL_getmetatable(L, "zenroom.octet");
	lua_setmetatable(L, -2);
	o->val = zen_memory_alloc(size +0x0f);
	if(!o->val) {
		lerror(L, "Error allocating new octet of %u bytes",size);
		return NULL; }
	o->len = 0;
	o->max = size;
	// func(L, "new octet (%u bytes)",size);
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
		// note here implicit conversion is only made from u64 and hex
		// TODO: convert from more string encodings cascading is_* funcs
		int hlen;
		if((hlen = is_url64(str))>0) { // import from U64 encoded string
			int declen = B64decoded_len(hlen);
			func(L,"octet argument is_url64 len %u -> %u",hlen, declen);
			o = o_new(L, declen); SAFE(o);
			o->len = U64decode(o->val, str);
		} else if((hlen = is_hex(str))>0) { // import from a HEX encoded string
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
	if(o->len>MAX_OCTET) {
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

void push_buffer_to_octet(lua_State *L, char *p, size_t len) {
	octet* o = o_new(L, len); SAFE(o);
	// newuserdata already pushes the object in lua's stack
	// memcpy(o->val, p, len);
	register uint32_t i;
	for (i=0; i<len; i++) o->val[i] = p[i];
	o->len = len;
}


extern int zconf_memwipe; // zenroom_config
extern char runtime_random256[256]; // zen_random
int o_destroy(lua_State *L) {
	void *ud = luaL_testudata(L, 1, "zenroom.octet");
	if(ud) {
		octet *o = (octet*)ud;
		if(zconf_memwipe) { // zenroom memory wipe configuration
			register int i;
			for(i=0;i<o->len;i++) o->val[i] = runtime_random256[i+11%256];
		}
		if(o->val) zen_memory_free(o->val);
	}
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

@function OCTET.new(length)
@int[opt=64] length maximum length in bytes
@return octet newly instantiated octet
*/
static int newoctet (lua_State *L) {
	octet *o;
	size_t len = luaL_optnumber(L, 1, 0);
	o = o_new(L,len); SAFE(o);
	OCT_empty(o);
	return 1;  /* new userdatum is already on the stack */
}

static int filloctet(lua_State *L) {
	int i;
	octet *o = o_arg(L,1); SAFE(o);
	octet *fill = o_arg(L,2); SAFE(fill);
	for(i=0; i<o->max; i++)
		o->val[i] = fill->val[i % fill->len];
	o->len = o->max;
	return 0;
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
	if(len<4) {
		lua_pushboolean(L, 0);
		func(L, "string is not a valid base64 sequence");
		return 1; }
	lua_pushboolean(L, 1);
	return 1;
}

static int lua_is_url64(lua_State *L) {
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "string expected");
	int len = is_url64(s);
	if(len<3) {
		lua_pushboolean(L, 0);
		func(L, "string is not a valid url64 sequence");
		return 1; }
	lua_pushboolean(L, 1);
	return 1;
}

// static int lua_is_base58(lua_State *L) {
// 	const char *s = lua_tostring(L, 1);
// 	luaL_argcheck(L, s != NULL, 1, "string expected");
// 	int len = is_base58(s);
// 	if(!len) {
// 		lua_pushboolean(L, 0);
// 		func(L, "string is not a valid base58 sequence");
// 		return 1; }
// 	lua_pushboolean(L, 1);
// 	return 1;
// }
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

// to emulate 128bit counters, de facto truncate integers to 64bit
typedef struct { uint64_t high, low; } uint128_t;
static int from_number(lua_State *L) {
	// number argument, import
	int tn;
	lua_Number n = lua_tointegerx(L,1,&tn);
	if(!tn) {
		lerror(L, "O.from_number input is not a number");
		return 0; }
	const uint64_t v = floorf(n);
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
	octet *o = o_new(L, nlen); // 4 byte header
	OCT_frombase64(o,(char*)s);
	return 1;
}

static int from_url64(lua_State *L) {
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "url64 string expected");
	int len = is_url64(s);
	if(!len) {
		lerror(L, "url64 string contains invalid characters");
		return 0; }
	int nlen = B64decoded_len(len);
	// func(L,"U64 decode len: %u -> %u",len,nlen);
	octet *o = o_new(L, nlen);
	o->len = U64decode(o->val,(char*)s);
	// func(L,"u64 return len: %u",o->len);
	return 1;
}

// static int from_base58(lua_State *L) {
// 	const char *s = lua_tostring(L, 1);
// 	luaL_argcheck(L, s != NULL, 1, "base58 string expected");
// 	int len = is_base58(s);
// 	if(!len) {
// 		lerror(L, "base58 string contains invalid characters");
// 		return 0; }
// 	size_t binmax = len + len + len;
// 	size_t binlen = binmax;
// 	char *dst = zen_memory_alloc(binmax);
// 	if(!b58tobin(dst, &binlen, s, len)) {
// 		zen_memory_free(dst);
// 		lerror(L,"Error in conversion from base58 for string: %s",s);
// 		return 0; }
// 	octet *o = o_new(L, binlen);
// 	o->len = binlen;
// 	// b58tobin returns its result at the _end_ of buf!!!
// 	int l,r;
// 	for(l=binlen, r=binmax; l>=0; l--, r--) o->val[l] = dst[r];
// 	zen_memory_free(dst);
// 	return 1;
// }

static int from_string(lua_State *L) {
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "string expected");
	const int len = strlen(s);
	// STRING SIZE CHECK before import to OCTET
	if(!len || len>MAX_STRING) {
		error(L, "%s: invalid string size: %u", __func__,len);
		lerror(L, "operation aborted");
		return 0; }
	octet *o = o_new(L, len);
	register int i = 0;
	for(i=0;s[i];i++) o->val[i]=s[i];
	o->len = i;
	return 1;
}

static int from_hex(lua_State *L) {
	const char *s = lua_tostring(L, 1);
	if(!s) {
		error(L, "%s :: invalid argument",__func__);
		lua_pushboolean(L,0);
		return 1; }
	int len = is_hex(s);
	func(L,"hex string sequence length: %u",len);
	if(!len || len>MAX_FILE<<1) { // *2 hex tuples
		error(L, "hex sequence too long: %u bytes", len<<1);
		lua_pushboolean(L,0);
		return 1; }
	octet *o = o_new(L, len>>1);
	o->len = hex2buf(o->val,s);
	return 1;
}

// I'm quite happy about this: its fast and secure. It can just be
// made more elegant.
static int from_bin(lua_State *L) {
	const char *s = lua_tostring(L, 1);
	luaL_argcheck(L, s != NULL, 1, "binary string sequence expected");
	const int len = is_bin(s);
	if(!len || len>MAX_FILE) {
		error(L, "invalid binary sequence size: %u", len);
		lerror(L, "operation aborted");
		return 0; }
	octet *o = o_new(L, len+4); // destination
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
			o->val[d] = b;
			b = 0x0;
			j = 0;
			d++;
			if(*S=='1') b = b | 0x1;
			b = b<<1;
		}
		i++;
	}
	o->val[d] = 0x0;
	o->len = d;
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
	lua_pushstring(L,b);
	zen_memory_free(b);
	return 1;
}

static int to_url64 (lua_State *L) {
	octet *o = o_arg(L,1);	SAFE(o);
	if(!o->len || !o->val) {
		lerror(L, "url64 cannot encode an empty string");
		return 0; }
	int newlen;
	newlen = B64encoded_len(o->len);
	char *b = zen_memory_alloc(newlen);
	// b[0]='u';b[1]='6';b[2]='4';b[3]=':';
	U64encode(b,o->val,o->len);
	lua_pushstring(L,b);
	zen_memory_free(b);
	return 1;
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
// static int to_base58(lua_State *L) {
// 	octet *o = o_arg(L,1);	SAFE(o);
// 	if(!o->len || !o->val) {
// 		lerror(L, "base64 cannot encode an empty octet");
// 		return 0; }
// 	if(o->len < 3) {
// 		// there is a bug in luke-jr's implementation of base58 (fixed
// 		// in bitcoin-core) when encoding strings smaller than 3 bytes
// 		// the 'j' counter being unsigned and initialised at size-2 in
// 		// the carry inner loop flips to 18446744073709551615
// 		lerror(L,"base58 cannot encode octets smaller than 3 bytes");
// 		return 0; }
// 	int newlen = getlen_base58(o->len);
// 	char *b = zen_memory_alloc(newlen);
// 	size_t b58len = newlen;
// 	b58enc(b, &b58len, o->val, o->len);
// 	// b[b58len] = '\0'; // already present, but for safety
// 	lua_pushlstring(L,b,b58len-1);
// 	zen_memory_free(b);
// 	return 1;
// }

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
	register int c = o->len;
	register int idx = 0;
	while(c--) {
		lua_pushnumber(L,idx+1);
		lua_pushnumber(L,o->val[idx]);
		lua_settable(L,-3);
		idx++;
	}
	return 1;
}

/***
    Print an octet as string.

    @function octet:str()
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
	push_octet_to_hex_string(L, o);
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
    Pad an octet with leading zeroes up to indicated length or its maximum size.

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

static int chop(lua_State *L) {
	octet *src = o_arg(L, 1); SAFE(src);
	int len = luaL_optnumber(L, 2, 0);
	if(len >= src->len) {
		lerror(L, "cannot chop octet of size %i to higher length %i",src->len, len);
		return 0; }
	octet *l = o_dup(L, src); SAFE(l);
	octet *r = o_new(L, src->len - len); SAFE(r);
	OCT_chop(l, r, len);
	return 2;
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
	for (i=0; i<x->len; i++) { // xor
		if (x->val[i] ^ y->val[i]) {
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

static int new_random(lua_State *L) {
	int tn;
	lua_Number n = lua_tonumberx(L, 1, &tn); SAFE(n);
	octet *o = o_new(L,(int)n); SAFE(o);
	OCT_rand(o,Z->random_generator,(int)n);
	return 1;
}

static int entropy_bytefreq(lua_State *L) {
	octet *o = o_arg(L,1); SAFE(o);
	register int i; // register
	// byte frequency table
	char *bfreq = zen_memory_alloc(0xff);
	memset(bfreq,0x0,0xff);
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
	zen_memory_free(bfreq);
	return 1;
}

static int entropy(lua_State *L) {
	octet *o = o_arg(L,1); SAFE(o);
	register int i; // register
	// byte frequency table
	char *bfreq = zen_memory_alloc(0xff);
	memset(bfreq,0x0,0xff);
	// probability of recurring for each byte
	float *bprob = (float*)zen_memory_alloc(sizeof(float)*0xff);
	memset(bprob,0x0,sizeof(float)*0xff);
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
	zen_memory_free(bfreq);
	zen_memory_free(bprob);
	// return entropy ratio, max and bits
	float bits = -1.0 * entropy;
	float entmax = log2(num);
	lua_pushnumber(L, (lua_Number) (bits / entmax)); // ratio
	lua_pushnumber(L, (lua_Number) entmax ); // max
	lua_pushnumber(L, (lua_Number) bits);
	return(3);
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
static int popcount_hamming_distance(lua_State *L) {
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

static int bitshift_hamming_distance(lua_State *L) {
	register uint32_t distance;
	register uint8_t x;
	register int c;
	octet *left = o_arg(L,1); SAFE(left);
	octet *right = o_arg(L,2); SAFE(right);
	// same length of octets needed
	if(left->len != right->len) {
		error(L, "Cannot measure hamming distance of octets of different lengths");
		lerror(L, "execution aborted");
	}
	distance = 0;
	for(c=0;c<left->len;c++) {
		x = left->val[c] ^ right->val[c];
		while(x > 0) {
			distance += x & 1;
			x >>= 1;
		}
	}
	lua_pushinteger(L,distance);
	return 1;
}


int luaopen_octet(lua_State *L) {
	const struct luaL_Reg octet_class[] = {
		{"new",   newoctet},
		{"concat",concat_n},
		{"xor",   xor_n},
		{"chop",  chop},
		{"is_base64", lua_is_base64},
		{"is_url64", lua_is_url64},
//		{"is_base58", lua_is_base58},
		{"is_hex", lua_is_hex},
		{"is_bin", lua_is_bin},
		{"from_number",from_number},
		{"from_base64",from_base64},
		{"from_url64",from_url64},
//		{"from_base58",from_base58},
		{"from_string",from_string},
		{"from_str",   from_string},
		{"from_hex",   from_hex},
		{"from_bin",   from_bin},
		{"base64",from_base64},
		{"url64",from_url64},
//		{"base58",from_base58},
		{"string",from_string},
		{"str",   from_string},
		{"hex",   from_hex},
		{"bin",   from_bin},
		{"to_hex"   , to_hex},
		{"to_base64", to_base64},
		{"to_url64",  to_url64},
//		{"to_base58", to_base58},
		{"to_string", to_string},
		{"to_str",    to_string},
		{"to_array",  to_array},
		{"to_bin",    to_bin},
		{"random",  new_random},
		{"entropy", entropy},
		{"bytefreq", entropy_bytefreq},
		{"hamming", bitshift_hamming_distance},
		{"popcount_hamming", popcount_hamming_distance},
		{NULL,NULL}
	};
	const struct luaL_Reg octet_methods[] = {
		{"fill"  , filloctet},
		{"hex"   , to_hex},
		{"base64", to_base64},
		{"url64",  to_url64},
//		{"base58", to_base58},
		{"string", to_string},
		{"str",    to_string},
		{"array",  to_array},
		{"bin",    to_bin},
		{"eq", eq},
		{"pad", pad},
		{"zero", zero},
		{"max", max},
		{"entropy", entropy},
		{"bytefreq", entropy_bytefreq},
		{"hamming", bitshift_hamming_distance},
		{"popcount_hamming", popcount_hamming_distance},

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
