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

#include <ctype.h>
#include <errno.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <jutils.h>

#include <zenroom.h>
#include <zen_error.h>
#include <lua_functions.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif


#if !defined(ARCH_CORTEX)

// This function exits the process on failure.
void load_file(char *dst, FILE *fd) {
	char firstline[MAX_STRING];
	long file_size = 0L;
	size_t offset = 0;
	size_t bytes = 0;
	if(!fd) {
		error(0, "Error opening %s", strerror(errno));
		exit(1); }
	if(fd!=stdin) {
		if(fseek(fd, 0L, SEEK_END)<0) {
			error(0, "fseek(end) error in %s: %s",__func__,
			      strerror(errno));
			exit(1); }
		file_size = ftell(fd);
		if(fseek(fd, 0L, SEEK_SET)<0) {
			error(0, "fseek(start) error in %s: %s",__func__,
			      strerror(errno));
			exit(1); }
		func(0, "size of file: %u",file_size);
	}
	// skip shebang on firstline
	if(!fgets(firstline, MAX_STRING, fd)) {
		if(errno==0) { // file is empty
			error(0, "Error reading, file is empty");
			exit(1); }
		error(0, "Error reading first line: %s", strerror(errno));
		exit(1); }
	if(firstline[0]=='#' && firstline[1]=='!')
		func(0, "Skipping shebang");
	else {
		offset+=strlen(firstline);
		strncpy(dst,firstline,MAX_STRING);
	}

	size_t chunk;
	while(1) {
		chunk = MAX_STRING;
		if( offset+MAX_STRING>MAX_FILE )
			chunk = MAX_FILE-offset-1;
		if(!chunk) {
			warning(0, "File too big, truncated at maximum supported size");
			break; }
		bytes = fread(&dst[offset],1,chunk,fd);

		if(!bytes) {
			if(feof(fd)) {
				if((fd!=stdin) && (long)offset!=file_size) {
					warning(0, "Incomplete file read (%u of %u bytes)",
					      offset, file_size);
				} else {
					func(0, "EOF after %u bytes",offset);
				}
 				dst[offset] = '\0';
				break;
			}
			if(ferror(fd)) {
				error(0, "Error in %s: %s",__func__,strerror(errno));
				fclose(fd);
				exit(1); }
		}
		offset += bytes;
	}
	if(fd!=stdin) fclose(fd);
	if(get_debug())	act(0, "loaded file (%u bytes)", offset);
}
#endif

int zen_unset(lua_State *L, char *key) {
	lua_pushnil(L);
	lua_setglobal(L, key);
	return 0;
}

int zen_setenv(lua_State *L, char *key, char *val) {
	if(!val) {
		warning(L, "setenv: NULL string detected");
		return 1; }
	if(val[0]=='\0') {
		warning(L, "setenv: empty string detected");
		return 1; }
	lua_pushstring(L, val);
	lua_setglobal(L, key);
	return 0;
}

int zen_add_package(lua_State *L, char *name, lua_CFunction func) {
	lua_register(L,name,func);
	char cmd[MAX_STRING];
	snprintf(cmd,MAX_STRING,
	         "table.insert(package.searchers, 2, %s",name);
	return luaL_dostring(L,cmd);
}

void zen_add_function(lua_State *L,
                      lua_CFunction func,
                      const char *func_name) {
	if (!L || !func || !func_name) return;
	lua_pushcfunction(L, func);
	lua_setglobal(L, func_name);
}


static const char *zen_lua_findtable (lua_State *L, int idx,
                                   const char *fname, int szhint) {
	const char *e;
	if (idx) lua_pushvalue(L, idx);
	do {
		e = strchr(fname, '.');
		if (e == NULL) e = fname + strlen(fname);
		lua_pushlstring(L, fname, e - fname);
		if (lua_rawget(L, -2) == LUA_TNIL) {  /* no such field? */
			lua_pop(L, 1);  /* remove this nil */
			lua_createtable(L, 0, (*e == '.' ? 1 : szhint)); /* new table for field */
			lua_pushlstring(L, fname, e - fname);
			lua_pushvalue(L, -2);
			lua_settable(L, -4);  /* set new table into field */
		}
		else if (!lua_istable(L, -1)) {  /* field has a non-table value? */
			lua_pop(L, 2);  /* remove table and value */
			return fname;  /* return problematic part of the name */
		}
		lua_remove(L, -2);  /* remove previous table */
		fname = e + 1;
	} while (*e == '.');
	return NULL;
}

void zen_add_class(lua_State *L, char *name,
                  const luaL_Reg *_class, const luaL_Reg *methods) {
	char classmeta[512];
	snprintf(classmeta,511,"zenroom.%s", name);
	luaL_newmetatable(L, classmeta);
	lua_pushstring(L, "__index");
	lua_pushvalue(L, -2);  /* pushes the metatable */
	lua_settable(L, -3);  /* metatable.__index = metatable */
	luaL_setfuncs(L,methods,0);

	zen_lua_findtable(L, LUA_REGISTRYINDEX, LUA_LOADED_TABLE, 1);
	if (lua_getfield(L, -1, name) != LUA_TTABLE) {
		// no LOADED[modname]?
		lua_pop(L, 1);  // remove previous result
		// try global variable (and create one if it does not exist)
		lua_pushglobaltable(L);
		// TODO: 'sizehint' 1 here is for new() constructor. if more
		// than one it should be counted on the class
		if (zen_lua_findtable(L, 0, name, 1) != NULL)
			luaL_error(L, "name conflict for module '%s'", name);
		lua_pushvalue(L, -1);
		lua_setfield(L, -3, name);  /* LOADED[modname] = new table */
	}
	lua_remove(L, -2);  /* remove LOADED table */

	// in lua 5.1 was: luaL_pushmodule(L,name,1);

	lua_insert(L,-1);
	luaL_setfuncs(L,_class,0);
}
