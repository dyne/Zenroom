#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <jutils.h>
#include <zenroom.h>
#include <amcl.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif


int print_hex(lua_State *L) {
	size_t l;
	char out[MAX_STRING];
	const unsigned char *s =
		(const unsigned char*)lua_touserdata(L, 1);
	int length = (
		lua_isnoneornil(L, 2) ? (int)l : luaL_checkinteger(L, 2));
	int outlen = 0;
	int i;
	for (i = 0; i < length; i++) {
		sprintf(out+outlen,"[%02x]", (unsigned char) s[i]);
		outlen+=4;
	}
#ifdef __EMSCRIPTEN__
	EM_ASM_({Module.print(UTF8ToString($0))}, out);
#else
	fwrite(out,sizeof(char),outlen+1,stdout);
	fputc('\n',stdout);
	fflush(stdout);
#endif
	return 1;
}

static octet* _new(lua_State *L, int size) {
	if(size<=0) return NULL;
	octet *o = (octet *)lua_newuserdata(L, sizeof(octet));
	o->val=malloc(size);
	func("created octet of size %u",size);
	luaL_getmetatable(L, "zenroom.octet");
	lua_setmetatable(L, -2);
	o->len = 0;
	o->max = size;
	return(o);
}

static octet* _arg(lua_State *L) {
	void *ud = luaL_checkudata(L, 1, "zenroom.octet");
	luaL_argcheck(L, ud != NULL, 1, "octet expected");
	octet *o = (octet*)ud;
	if(o->len>MAX_STRING) {
		error("%s: octet too long (%u bytes)",__func__,o->len);
		return NULL; }
	return(o);
}

static int _destroy(lua_State *L) {
	octet *o = _arg(L);
	if(o->val) free(o->val);
	return 0;
}

static int newoctet (lua_State *L) {
	int n = luaL_checkinteger(L, 1);
	if(!n) {
		error("octet created with zero length");
		return 0; }
	octet *o = _new(L,n);
	OCT_empty(o);
	return 1;  /* new userdatum is already on the stack */
}


static int empty (lua_State *L) {	
	OCT_empty(_arg(L));
	return 1;
}


static int base64 (lua_State *L) {
	octet *o = _arg(L);
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

static int string(lua_State *L) {
	octet *o = _arg(L);
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

static int hex(lua_State *L) {
	octet *o = _arg(L);
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
	octet *o = _arg(L);
    const char *s = lua_tostring(L, 2);
	luaL_argcheck(L, s != NULL, 2, "string expected");
	OCT_jstring(o,(char*)s);
	return 1;
}

static int length(lua_State *L) {
	octet *o = (octet*)lua_touserdata(L, 1);
	luaL_argcheck(L, o != NULL, 1, "octet expected");
	lua_pushinteger(L,o->len);
	return 1;
}

int luaopen_octet(lua_State *L) {
	const struct luaL_Reg octet[] = {{"new",newoctet},{NULL,NULL}};
	const struct luaL_Reg octet_methods[] = {
		{"empty", empty},
		{"base64", base64},
		{"hex"   , hex},
		{"string", string},
		
		{"__len",length},
		{"len", length},
		{"length", length},
		{"size", length},

		{"jstring", jstring},
		{"__gc", _destroy},
		{"__tostring",string},
		{NULL,NULL}
	};

	luaL_newmetatable(L, "zenroom.octet");
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);  /* pushes the metatable */
	lua_settable(L, -3);  /* metatable.__index = metatable */
	luaL_openlib(L, NULL, octet_methods, 0);
	luaL_openlib(L, "octet", octet, 0);
	// luaL_newlib(L, octet);
	// lua_getfield(L, -1, "octet");
	// lua_setglobal(L, "octet");
	return 1;
}

