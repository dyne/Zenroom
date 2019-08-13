/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2019 Dyne.org foundation
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

// auxiliary functions for parsing Zencode, used inside zencode.lua
// optimizations also happen here

// #include <stdio.h>
#include <ctype.h>
// #include <errno.h>
// #include <jutils.h>

// #include <zenroom.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

// parse the first word until the first space, returns a new string
static int lua_parse_prefix(lua_State* L) { 
	const char *line;
	size_t size;
	line = luaL_checklstring(L,1,&size);
	register unsigned short int c;
	unsigned short fspace = 0;
	// skip space in front
	for(c=0; c<size && c<MAX_LINE && c<USHRT_MAX; c++) {
		if( !isspace(line[c]) ) break;
		fspace++; }
	char low[MAX_LINE];
	for(; c<size && c<MAX_LINE && c<USHRT_MAX; c++) {
		if( isspace(line[c]) ) {
			low[c] = '\0'; break; }
		low[c] = tolower(line[c]);
	}
	if(c==size || c==MAX_LINE) lua_pushnil(L);
	else lua_pushlstring(L,&low[fspace],c-fspace);
	return 1;
}

// trim whitespace in front and at end of string
static int lua_trim_string(lua_State* L) {
	const char* front;
	const char* end;
	size_t size;
	front = luaL_checklstring(L,1,&size);
	end = &front[size - 1];
	while (size && isspace(*front)) {
		size--;
		front++;
	}
	while (size && isspace(*end)) {
		size--;
		end--;
	}
	lua_pushlstring(L,front,(size_t)(end - front) + 1);
	return 1;
}

void zen_add_parse(lua_State *L) {
	// override print() and io.write()
	static const struct luaL_Reg custom_parser [] =
		{ {"parse_prefix", lua_parse_prefix},
		  {"trim", lua_trim_string},
		  {NULL, NULL} };
	lua_getglobal(L, "_G");
	luaL_setfuncs(L, custom_parser, 0);  // for Lua versions 5.2 or greater
	lua_pop(L, 1);
}
