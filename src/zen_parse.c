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
#include <strings.h>
// #include <errno.h>
// #include <jutils.h>

#include <zenroom.h>
#include <zen_error.h>
#include <jutils.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

static char low[MAX_LINE]; // 1KB max for a single zencode line
// parse the first word until the first space, returns a new string
static int lua_parse_prefix(lua_State* L) { 
	const char *line;
	size_t size;
	line = luaL_checklstring(L,1,&size); SAFE(line);
	register unsigned short int c;
	unsigned short fspace = 0;
	// skip space in front
	for(c=0; c<size && c<MAX_LINE && c<USHRT_MAX; c++) {
		if( !isspace(line[c]) ) break;
		fspace++; }
	for(; c<size && c<MAX_LINE && c<USHRT_MAX; c++) {
		if( isspace(line[c]) ) {
			low[c] = '\0'; break; }
		low[c] = tolower(line[c]);
	}
	if(c==size || c==MAX_LINE) lua_pushnil(L);
	else lua_pushlstring(L,&low[fspace],c-fspace);
	return 1;
}

// internal use, trims the string to a provided destination which is
// pre-allocated
static void trimto(char *dest, const char *src, const size_t len) {
	register unsigned short int c;
	register unsigned short int d;
	for(c=0; c<len && isspace(src[c]); c++); // skip front space
	for(d=0; c<len; c++, d++) dest[d] = src[c];
	dest[d] = '\0'; // null termination
}
static char ta[MAX_LINE];
static char tb[MAX_LINE];
static int lua_strcasecmp(lua_State *L) {
	const char *a, *b;
	size_t la, lb;
	a = luaL_checklstring(L,1,&la); SAFE(a);
	b = luaL_checklstring(L,2,&lb); SAFE(b);
	if(la>MAX_LINE) lerror(L, "strcasecmp: arg #1 MAX_LINE limit hit");
	if(lb>MAX_LINE) lerror(L, "strcasecmp: arg #2 MAX_LINE limit hit");
	trimto(ta, a, la);
	trimto(tb, b, lb);
	if( strcasecmp(ta,tb) == 0 )
		lua_pushboolean(L,1);
	else
		lua_pushboolean(L,0);
	return 1;
}

// trim whitespace in front and at end of string
static int lua_trim_spaces(lua_State* L) {
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

// trim whitespace or single quote in front and at end of string
static int lua_trim_quotes(lua_State* L) {
	const char* front;
	const char* end;
	size_t size;
	front = luaL_checklstring(L,1,&size);
	end = &front[size - 1];
	while (size && (isspace(*front) || *front == '\'')) {
		size--;
		front++;
	}
	while (size && (isspace(*end) || *end == '\'')) {
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
		  {"strcasecmp", lua_strcasecmp},
		  {"trim", lua_trim_spaces},
		  {"trimq", lua_trim_quotes},
		  {NULL, NULL} };
	lua_getglobal(L, "_G");
	luaL_setfuncs(L, custom_parser, 0);  // for Lua versions 5.2 or greater
	lua_pop(L, 1);
}
