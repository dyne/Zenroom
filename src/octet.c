/// <h1>Base data type for cryptography</h1>
//
//  Octets are arrays of single bytes offering methods for various
//  useful operations when using them in cryptography. They are the
//  base data type for most operations in Zenroom and are implemented
//  to avoid any buffer overflow, but their maximum size must be known
//  at the time of instantiation with the .new() factory call.
//
//  @module octet
//  @author Denis "Jaromil" Roio
//  @license LGPLv3
//  @copyright Dyne.org foundation 2017-2018
//

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <jutils.h>
#include <zenroom.h>
#include <lua_functions.h>

#include <amcl.h>


// REMEMBER: newuserdata already pushes the object in lua's stack
octet* o_new(lua_State *L, int size) {
	if(size<=0) return NULL;
	octet *o = (octet *)lua_newuserdata(L, sizeof(octet));
	// TODO: check errors
	o->val=malloc(size);
	func("created octet of size %u",size);
	luaL_getmetatable(L, "zenroom.octet");
	lua_setmetatable(L, -2);
	o->len = 0;
	o->max = size;
	return(o);
}

octet* o_arg(lua_State *L,int n) {
	void *ud = luaL_checkudata(L, n, "zenroom.octet");
	luaL_argcheck(L, ud != NULL, n, "octet class expected");
	octet *o = (octet*)ud;
	if(o->len>MAX_STRING) {
		error("%s: octet too long (%u bytes)",__func__,o->len);
		return NULL; }
	return(o);
}

int o_destroy(lua_State *L) {
	octet *o = o_arg(L,1);
	if(o->val) free(o->val);
	return 0;
}
/// Constructor
// @section constructor

/***
Create a new octet with the specified maximum size
@function new
@param length maximum length in bytes
@return octet newly instantiated octet
@usage
octet_type = require "octet"
octet = octet_type.new(2048)
*/
static int newoctet (lua_State *L) {
	int n = luaL_checkinteger(L, 1);
	if(!n) {
		error("octet created with zero length");
		return 0; }
	octet *o = o_new(L,n);
	OCT_empty(o);
	return 1;  /* new userdatum is already on the stack */
}

/// Methods
// @section methods

// above we could use @type octet but rendering is ugly

/***
Empty an octet filling it with zeroes. It is already executed on every
new octet.

@function octet:empty
@usage
octet:empty()
*/
static int empty (lua_State *L) {	
	OCT_empty(o_arg(L,1));
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

-- To set a string message inside the octet:
octet:string("my message to be encoded in base64")
-- then to print the message in base64 notation
print(octet:base64())

*/
static int base64 (lua_State *L) {
	octet *o = o_arg(L,1);
	if(!o) return 0;
	if(lua_isnoneornil(L, 2)) {
		// export to base64
		char b[MAX_STRING];
		OCT_tobase64(b,o);
		lua_pushstring(L,b);
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
*/
static int string(lua_State *L) {
	octet *o = o_arg(L,1);
	if(!o) return 0;
	if(lua_isnoneornil(L, 2)) {
		// export to string
		char s[MAX_STRING];
		OCT_toStr(o,s);
		lua_pushstring(L,s);
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

    @string[opt] data_hex **optional** a string of hex numbers whose contents in bytes are imported
    @function octet:hex(data_hex)
*/
static int hex(lua_State *L) {
	octet *o = o_arg(L,1);
	if(!o) return 0;
	if(lua_isnoneornil(L, 2)) {
		// export to hex
		char s[MAX_STRING];
		OCT_toHex(o,s);
		lua_pushstring(L,s);
	} else {
		// import from hex
		size_t len;
		const char *s = lua_tolstring(L, 2, &len);
		luaL_argcheck(L, s != NULL, 2, "string expected");
		OCT_fromHex(o,(char*)s);
	}
	return 1;
}

static int jstring(lua_State *L) {
	octet *o = o_arg(L,1);
	if(!o) return 0;
    const char *s = lua_tostring(L, 2);
	luaL_argcheck(L, s != NULL, 2, "string expected");
	OCT_jstring(o,(char*)s);
	return 1;
}

/***
    Pad an octet with leading zeroes up to indicated length or its maximum size.

    @int[opt=octet:max] length **optional** pad to this size, will use maximum octet size if omitted
    @function octet:pad(length)
*/
static int pad(lua_State *L) {
	octet *o = o_arg(L,1);
	if(!o) return 0;
	const int len = luaL_optinteger(L, 2, o->max);	
	OCT_pad(o,len);
	return 1;
}

/***
    Bitwise XOR operation on two octets

    @param dest leftmost octet will be overwritten by result
    @param source rightmost octet used in XOR operation
    @function octet:xor(dest, source)
*/
static int xor(lua_State *L) {
	octet *x = o_arg(L,1);
	if(!x) return 0;
	octet *y = o_arg(L,2);
	if(!y) return 0;
	OCT_xor(x,y);
	return 1;
}
static int length(lua_State *L) {
	octet *o = (octet*)lua_touserdata(L, 1);
	luaL_argcheck(L, o != NULL, 1, "octet expected");
	lua_pushinteger(L,o->len);
	return 1;
}

int luaopen_octet(lua_State *L) {
	const struct luaL_Reg octet_class[]
		= {{"new",newoctet},{NULL,NULL}};
	const struct luaL_Reg octet_methods[] = {
		{"empty", empty},
		{"base64", base64},
		{"hex"   , hex},
		{"string", string},
		
		{"__len",length},
		{"len", length},
		{"length", length},
		{"size", length},

		{"pad", pad},
		{"xor", xor},
		{"jstring", jstring},
		{"__gc", o_destroy},
		{"__tostring",string},
		{NULL,NULL}
	};
	zen_add_class(L, "octet", octet_class, octet_methods);
	return 1;
}

