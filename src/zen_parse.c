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

#include <zenroom.h>
#include <zen_memory.h>
#include <zen_error.h>

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
	if(c>size || c==MAX_LINE) lua_pushnil(L);
	else lua_pushlstring(L,&low[fspace],c-fspace);
	return 1;
}

// internal use, trims the string to a provided destination which is
// pre-allocated
static size_t trimto(char *dest, const char *src, const size_t len) {
	register unsigned short int c;
	register unsigned short int d;
	for(c=0; c<len && isspace(src[c]); c++); // skip front space
	for(d=0; c<len; c++, d++) dest[d] = src[c];
	dest[d] = '\0'; // null termination
	return(d);
}

static int lua_strcasecmp(lua_State *L) {
	const char *a, *b;
	size_t la, lb;
	char *ta, *tb;
	a = luaL_checklstring(L,1,&la); SAFE(a);
	b = luaL_checklstring(L,2,&lb); SAFE(b);
	if(la>MAX_LINE) lerror(L, "strcasecmp: arg #1 MAX_LINE limit hit");
	if(lb>MAX_LINE) lerror(L, "strcasecmp: arg #2 MAX_LINE limit hit");
	ta = malloc(la+1);
	tb = malloc(lb+1);
	la = trimto(ta, a, la);
	lb = trimto(tb, b, lb);
	if(la != lb) { lua_pushboolean(L,0); goto end; }
	if( strcasecmp(ta,tb) == 0 ) { lua_pushboolean(L,1); goto end; }
// else
	lua_pushboolean(L,0);
end:
	free(ta);
	free(tb);
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


static int lua_unserialize_json(lua_State* L) {
	const char *in;
	size_t size;
	register int level = 0;
	register char *p;
	register char in_literal_str = 0;
	in = luaL_checklstring(L, 1, &size);
	p = (char*)in;
	while (size && isspace(*p) ) { size--; p++; } // first char
	while (size && (*p == 0x0) ) { size--; p++; } // first char
	if(!size) {	lua_pushnil(L);	return 1; }
	if (*p == '{' || *p == '[') {
		size--;
		level++;
	} else {
		func(L, "JSON doesn't starts with '{', char found: %c (%02x)", *p, *p);
		lua_pushnil(L);
		return 1;
	} // ok, level is 1
	for( p++ ; size>0 ; size--, p++ ) {
		if(in_literal_str) {
			// a string literal end with a " which is not escaped, i.e. \"
			// in case a string literal ends with \\", it ends
			// p-1 and p-2 cannot be outside buffer because a JSON dictionary
			// starts at least with {"
			if(*p == '"' && (*(p-1) != '\\' || *(p-2) == '\\')) {
				in_literal_str = 0;
			}
		} else {
			if(*p=='"') in_literal_str = 1;
			else {
				if(*p=='{' || *p=='[') level++;
				if(*p=='}' || *p==']') level--;
				if(level==0) { // end of first block
					lua_pushlstring(L, in, (size_t)(p - in)+1);
					lua_pushlstring(L, ++p, size);
					return 2;
				}
			}
		}
	}
	// should never be here
	lerror(L, "JSON has malformed beginning or end");
	return 0;
}

char* strtok_single(char* str, char const* delims)
{
    static char* src = NULL;
    char *p, *ret = NULL;

    if (str != NULL)
        src = str;

    if (src == NULL)
        return NULL;

    if ((p = strpbrk(src, delims)) != NULL) {
        *p = 0;
        ret = src;
        src = ++p;
    } else {
        ret = src;
        src = NULL;
    }

    return ret;
}

static int lua_strtok(lua_State* L) {
	const char DEFAULT_SEP[] = " ";

	char copy[MAX_FILE];
	char *sep = DEFAULT_SEP;

	const char *in;
	size_t size;
	register int i = 1;
	register char *token;

	in = luaL_checklstring(L, 1, &size);

	if (lua_gettop(L) > 1) {
		sep = luaL_checklstring(L, 2, NULL);
	}

	lua_newtable(L);

	memcpy(copy, in, size+1);

	token = strtok_single(copy, sep);
	while(token != NULL) {
		lua_pushlstring(L, token, strlen(token));

		lua_rawseti(L, -2, i);

		token = strtok_single(NULL, sep);
		i = i + 1;
	}
	return 1;
}

void zen_add_parse(lua_State *L) {
	// override print() and io.write()
	static const struct luaL_Reg custom_parser [] =
		{ {"parse_prefix", lua_parse_prefix},
		  {"strcasecmp", lua_strcasecmp},
		  {"trim", lua_trim_spaces},
		  {"trimq", lua_trim_quotes},
		  {"jsontok", lua_unserialize_json},
		  {"strtok", lua_strtok},
		  {NULL, NULL} };
	lua_getglobal(L, "_G");
	luaL_setfuncs(L, custom_parser, 0);  // for Lua versions 5.2 or greater
	lua_pop(L, 1);
}
