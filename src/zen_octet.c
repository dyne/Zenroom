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

/// <h1>Base data type for cryptography</h1>
//
//  Octets are <a
//  href="https://en.wikipedia.org/wiki/First-class_citizen">first-class
//  citizens</a> in Zenroom. They consist of arrays of bytes (8bit)
//  compatible with all cryptographic functions and methods. They are
//  implemented to avoid any buffer overflow and their maximum size is
//  known at the time of instantiation. The are provided by the
//  'octet' extension which has to be required explicitly:
//
//  <code>octet = require'octet'</code>
//
//  After requiring the extension it is possible to create keyring
//  instances using the new() method:
//
//  <code>message = octet.new()</code>
//
//  Octets can import and export their contents to portable formats as
//  sequences of :base64() or :hex() numbers just using their
//  appropriate methods. Without an argument, these methods export
//  contents in the selected format, when there is an argument that is
//  considered to be of the selected format and its contents are
//  converted to bytes and imported.
//
//  @module octet
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
#include <randombytes.h>

#include <amcl.h>

#include <zenroom.h>
#include <zen_memory.h>

static int _max(int x, int y) { if(x > y) return x;	else return y; }
static int _min(int x, int y) { if(x < y) return x;	else return y; }

// REMEMBER: newuserdata already pushes the object in lua's stack
octet* o_new(lua_State *L, const int size) {
	if(size<=0) return NULL;
	if(size>MAX_FILE) {
		lerror(L, "Cannot create octet, size too big: %u", size);
		return NULL; }
	octet *o = (octet *)lua_newuserdata(L, sizeof(octet));
	if(!o) {
		lerror(L, "Error allocating new octet in %s",__func__);
		return NULL; }
	// TODO: check that maximum is not exceeded
	luaL_getmetatable(L, "zenroom.octet");
	lua_setmetatable(L, -2);
	o->val = malloc(size);
	o->len = 0;
	o->max = size;
	func("new octet (%u bytes)",size);
	return(o);
}

octet* o_arg(lua_State *L,int n) {
	void *ud = luaL_checkudata(L, n, "zenroom.octet");
	luaL_argcheck(L, ud != NULL, n, "octet class expected");
	octet *o = (octet*)ud;
	if(o->len>MAX_FILE) {
		lerror(L, "%s: octet too long (%u bytes)",__func__,o->len);
		return NULL; }
	return(o);
}

// allocates a new octet in LUA, duplicating the one in arg
octet *o_dup(lua_State *L, octet *o) {
	SAFE(o);
	octet *n = o_new(L, o->len+1);
	OCT_copy(n,o);
	return(n);
}
	
int o_destroy(lua_State *L) {
	HERE();
	octet *o = o_arg(L,1);
	SAFE(o);
	free(o->val);
	return 0;
}

/// Global Octet Functions
// @section octet
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

@function octet.new(length)
@int[opt=4096] length maximum length in bytes
@return octet newly instantiated octet
@usage
var2k = octet.new(2048) -- create an octet of 2KB
-- create another octet at default size
var4k = octet.new()

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
    Bitwise XOR operation on two octets, returns a new octet. This is
    also executed when using the '<b>~</b>' operator between two
    octets. Results in a newly allocated octet, does not change the
    contents of any other octet involved.

    @param dest leftmost octet used in XOR operation
    @param source rightmost octet used in XOR operation
    @function octet.xor(dest, source)
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


/***
    Concatenate two octets, returns a new octet. This is also executed
    when using the '<b>..</b>' operator btween two octets. It results
    in a newly allocated octet, does not change the contents of other
    octets.

    @param dest leftmost octet will be overwritten by result
    @param source rightmost octet used in XOR operation
    @function octet.concat(dest, source)
    @return a new octet resulting from the operation
*/
static int concat_n(lua_State *L) {
	octet *x = o_arg(L,1);	SAFE(x);
	octet *y = o_arg(L,2);	SAFE(y);
	octet *n = o_new(L,x->len+y->len);
	SAFE(n);

	OCT_copy(n,x);
	OCT_joctet(n,y);
	return 1;
	// TODO: support strings
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
// Octet contents are changed by the method "in-place" on "this"
// object, instead of returning a new octet. This is the main
// difference from using global functions in the octet namespace.
// @see globals

// above we could use @type octet but rendering is ugly

/***
Empty an octet filling it with zeroes. It is already executed on every
new octet.

@function octet:empty
@usage
octet:empty()
*/
static int empty (lua_State *L) {
	octet *o = o_arg(L,1);
	SAFE(o);
	OCT_empty(o);
	return 1;
}

/***
Print an octet in base64 notation or import a base64 string inside the
octet.

@string[opt] data_b64 a base64 string whose contents in bytes are imported
@function octet:base64(data_b64)
@usage

-- This method as well :string() and :hex() can be used both to set
-- from and print out in particular formats. If the argument is not
-- present, the method will print out converting to its format, else
-- will import its contents inside the octet.

-- create a small 128 bytes octet:
msg = octet.new(128)
-- set a string message inside the new octet:
msg:string("my message to be encoded in base64")
-- print the message in base64 notation:
print(msg:base64())

*/
static int getlen_base64(int len) {
	int res = ((3+(4*(len/3))) & ~0x03)+0x0f;
	func("base64 len: %u to %u",len,res);
	return(res);
}
static int base64 (lua_State *L) {
	octet *o = o_arg(L,1);	SAFE(o);
	if(lua_isnoneornil(L, 2)) {
		// export to base64
		if(!o->len) {
			lerror(L, "base64 import of empty string");
			return 0; }
		int newlen = getlen_base64(o->len);
		char *b = malloc(newlen);
		OCT_tobase64(b,o);
		b[newlen] = 0;
		lua_pushstring(L,b);
		free(b);
	} else {
		// import from base64
		const char *s = lua_tostring(L, 2);
		luaL_argcheck(L, s != NULL, 2, "base64 string expected");
		OCT_frombase64(o,(char*)s);
	}
	return 1;
}

/***
    Print an octet as string or import a string inside the octet.

    @string[opt] data_str a string whose contents in bytes are imported
    @function octet:string(data_str)
    @see octet:base64
*/
static int string(lua_State *L) {
	octet *o = o_arg(L,1);	SAFE(o);
	if(lua_isnoneornil(L, 2)) {
		// export to string
		char *s = malloc(o->len);
		OCT_toStr(o,s);
		s[o->len] = 0; // make sure string is NULL terminated
		lua_pushstring(L,s);
		free(s);
	} else {
		// import from string
		size_t len;
		const char *s = lua_tolstring(L, 2, &len);
		luaL_argcheck(L, s != NULL, 2, "string expected");
		o->len=0;
		OCT_jstring(o,(char*)s);
	}
	return 1;
}


/***
    Print an octet as a string of hexadecimal numbers or import a string of hex numbers.

    @string[opt] data_hex a string of hex numbers whose contents in bytes are imported
    @function octet:hex(data_hex)
    @see octet:base64
*/
static int hex(lua_State *L) {
	octet *o = o_arg(L,1);	SAFE(o);
	if(lua_isnoneornil(L, 2)) {
		// export to hex
		char *s = malloc(o->len*2);
		OCT_toHex(o,s);
		s[o->len*2] = 0;
		lua_pushstring(L,s);
		free(s);
	} else {
		// import from hex
		size_t len;
		const char *s = lua_tolstring(L, 2, &len);
		luaL_argcheck(L, s != NULL, 2, "string expected");
		OCT_fromHex(o,(char*)s);
	}
	return 1;
}

/***
    Randomize contents of an octet up to length, or to its maximum
    size if argument is omitted.

    @int[opt] length amount of random bytes to gather
    @function octet:random(length)
*/
static int o_random(lua_State *L) {
	octet *o = o_arg(L,1);	SAFE(o);
	const int len = luaL_optinteger(L, 2, o->max);
	char *buf = malloc(len);
	randombytes(buf,len);
	o->len=0;
	OCT_jbytes(o,buf,len);
	free(buf);
	return 1;
}


/***
    Pad an octet with leading zeroes up to indicated length or its
    maximum size.

    @int[opt=octet:max] length pad to this size, will use maximum octet size if omitted
    @function octet:pad(length)
*/
static int pad(lua_State *L) {
	octet *o = o_arg(L,1);	SAFE(o);
	const int len = luaL_optinteger(L, 2, o->max);
	OCT_pad(o,len);
	return 1;
}

static int eq(lua_State *L) {
	octet *x = o_arg(L,1);	SAFE(x);
	octet *y = o_arg(L,2);	SAFE(y);
	lua_pushboolean(L, OCT_comp(x,y));
	return 1;
}


/***
    Bitwise XOR operation on this octet and another one. Operates
    in-place, overwriting contents of this octet.

    @param const octet used in XOR operation
    @function octet:xor(const)
*/
static int xor_i(lua_State *L) {
	octet *x = o_arg(L,1);	SAFE(x);
	octet *y = o_arg(L,2);	SAFE(y);
	OCT_xor(x,y);
	return 1;
}

/***
    Concatenate a new octet, appending it to current contents.

    @param const octet whose contents will be appended to this.
    @function octet:concat(const)
*/
static int concat_i(lua_State *L) {
	octet *x = o_arg(L,1);	SAFE(x);
	octet *y = o_arg(L,2);	SAFE(y);
	OCT_joctet(x,y);
	return 1;
	// TODO: support strings
}

static int size(lua_State *L) {
	octet *o = o_arg(L,1); SAFE(o);
	luaL_argcheck(L, o != NULL, 1, "octet expected");
	lua_pushinteger(L,o->len);
	return 1;
}

static int max(lua_State *L) {
	octet *o = o_arg(L,1); SAFE(o);
	luaL_argcheck(L, o != NULL, 1, "octet expected");
	lua_pushinteger(L,o->max);
	return 1;
}

#define octet_common_methods  \
	{"empty", empty},         \
	{"base64", base64},       \
	{"hex"   , hex},          \
	{"string", string},       \
    {"size", size},           \
	{"random", o_random},       \
	{"pad", pad},             \
    {"eq", eq}

int luaopen_octet(lua_State *L) {
	const struct luaL_Reg octet_class[] = {
		{"new",newoctet},
		{"concat",concat_n},
		{"xor",xor_n},
		octet_common_methods,
		{NULL,NULL}
	};
	const struct luaL_Reg octet_methods[] = {
		octet_common_methods,
		// inplace methods
		{"concat", concat_i},
		{"xor", xor_i},
		{"max", max},
		// idiomatic operators
		{"__len",size},
		{"__concat",concat_n},
		{"__bxor",xor_n},
		{"__eq",eq},
		{"__gc", o_destroy},
		{"__tostring",string},
		{NULL,NULL}
	};
	zen_add_class(L, "octet", octet_class, octet_methods);
	return 1;
}
