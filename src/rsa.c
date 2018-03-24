// Zenroom RSA module
//
// (c) Copyright 2017-2018 Dyne.org foundation
// designed, written and maintained by Denis Roio <jaromil@dyne.org>
//
// This program is free software: you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public License
// version 3 as published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this program.  If not, see
// <http://www.gnu.org/licenses/>.

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <jutils.h>
#include <zenroom.h>
#include <lua_functions.h>
#include <octet.h>

#include <rsa_2048.h>
#include <rsa_4096.h>
#include <rsa_support.h>

typedef struct {
	int bits;
	int hash;
	// may be extended: place here values that should be set upon
	// class instantiation.
} rsa;

static int bitchoice(int bits) {
	switch(bits) {
	case 2048: return HASH_TYPE_RSA_2048;
	case 4096: return HASH_TYPE_RSA_4096;
	default:
		error("RSA bit size not supported: %u",bits);
	}
	return 0;
}

rsa* rsa_new(lua_State *L, int bitsize) {
	if(bitsize<=0) return NULL;
	rsa *r = (rsa*)lua_newuserdata(L, sizeof(rsa));
	if(!r) return NULL;
	// check that the bit choice is supported and has an associated
	// hash type
	r->hash = bitchoice(bitsize);
	if(!r->hash) return NULL;
	r->bits = bitsize;
	func("Created RSA engine %u bits",r->bits);
	// TODO: check bitsize validity
	luaL_getmetatable(L, "zenroom.rsa");
	lua_setmetatable(L, -2);
	return(r);
}
rsa* rsa_arg(lua_State *L,int n) {
	void *ud = luaL_checkudata(L, n, "zenroom.rsa");
	luaL_argcheck(L, ud != NULL, n, "rsa class expected");
	rsa *r = (rsa*)ud;
	return(r);
}
// no destroy needed really since there is no dynamic buffer
// instantiation in the rsa class object

static int newrsa(lua_State *L) {
	const int bits = luaL_optinteger(L, 1, 2048);	
	rsa *r = rsa_new(L, bits);
	if(!r) return 0;
	// any action to be taken here?
	return 1;
}


static int pkcs15(lua_State *L) {
	rsa *r = rsa_arg(L,1);
	if(!r) return 0;
	octet *in = o_arg(L,2);
	if(!in) return 0;
	octet *out = o_new(L, r->bits/8);
	if(!out) return 0;
	if(!PKCS15(r->hash, in, out)) {
		error("error in %s RSA %u",__func__, r->bits);
		lua_pop(L,1); // remove the o_new from stack
		return 0;
	}
	return 1;
}

static int rsa_octet(lua_State *L) {
	octet *out = o_new(L,MAX_RSA_BYTES);
	// TODO: check appropriate maximum according to bits
	if(!out) return 0;
	return 1;
}
	

int luaopen_rsa(lua_State *L) {
	const struct luaL_Reg rsa_class[] = {{"new",newrsa},{NULL,NULL}};
	const struct luaL_Reg rsa_methods[] = {
		{"octet", rsa_octet},
		{"pkcs15",pkcs15},
		{NULL,NULL}
	};

	zen_add_class(L, "rsa", rsa_class, rsa_methods);
	return 1;
}
