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

#include <stdio.h>
#include <ctype.h>
#include <errno.h>
#include <jutils.h>

#include <lauxlib.h>

#include <zenroom.h>
#include <zen_error.h>

extern zenroom_t *Z;

// passes the string to be printed through the 'tosting' function
// inside lua, taking care of some sanitization and conversions
static const char *lua_print_format(lua_State *L,
		int pos, size_t *len) {
	const char *s;
	lua_pushvalue(L, -1);  /* function to be called */
	lua_pushvalue(L, pos);   /* value to print */
	lua_call(L, 1, 1);
	s = lua_tolstring(L, -1, len);  /* get result */
	if (s == NULL)
		luaL_error(L, LUA_QL("tostring") " must return a string to "
				LUA_QL("print"));
	return s;
}

// retrieves output buffer if configured in _Z and append to that the
// output without exceeding its length. Return 1 if output buffer was
// configured so calling function can decide if to proceed with other
// prints (stdout) or not
static int lua_print_stdout_tobuf(lua_State *L, char newline) {
	SAFE(Z);
	if(Z->stdout_buf && (Z->stdout_pos < Z->stdout_len)) {
		int i;
		int n = lua_gettop(L);  /* number of arguments */
		char *out = (char*)Z->stdout_buf;
		size_t len;
		lua_getglobal(L, "tostring");
		for (i=1; i<=n; i++) {
			const char *s = lua_print_format(L, i, &len);
			if(i>1) { out[Z->stdout_pos]='\t'; Z->stdout_pos++; }
			snprintf(out+Z->stdout_pos,
					Z->stdout_len - Z->stdout_pos,
					"%s%c", s, newline);
			Z->stdout_pos+=len+1;
			lua_pop(L, 1);
		}
		return 1;
	}
	return 0;
}
static int lua_print_stderr_tobuf(lua_State *L, char newline) {
	SAFE(Z);
	if(Z->stderr_buf && (Z->stderr_pos < Z->stderr_len)) {
		int i;
		int n = lua_gettop(L);  /* number of arguments */
		char *out = (char*)Z->stderr_buf;
		size_t len;
		lua_getglobal(L, "tostring");
		for (i=1; i<=n; i++) {
			const char *s = lua_print_format(L, i, &len);
			if(i>1) { out[Z->stderr_pos]='\t'; Z->stderr_pos++; }
			snprintf(out+Z->stderr_pos,
					Z->stderr_len - Z->stderr_pos,
					"%s%c", s, newline);
			Z->stderr_pos+=len+1;
			lua_pop(L, 1);
		}
		return 1;
	}
	return 0;
}

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
static char out[MAX_STRING];

static int zen_print (lua_State *L) {
	if( lua_print_stdout_tobuf(L,' ') ) return 0;

	size_t pos = 0;
	size_t len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i;
	lua_getglobal(L, "tostring");
	for (i=1; i<=n; i++) {
		const char *s = lua_print_format(L, i, &len);
		if (i>1) { out[pos]='\t'; pos++; }
		snprintf(out+pos,MAX_STRING-pos,"%s",s);
		pos+=len;
		lua_pop(L, 1);  /* pop result */
	}
	EM_ASM_({Module.print(UTF8ToString($0))}, out);
	return 0;
}

static int zen_error (lua_State *L) {
	if( lua_print_stderr_tobuf(L,' ') ) return 0;
	size_t pos = 0;
	size_t len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i;
	lua_getglobal(L, "tostring");
	out[0] = '['; out[1] = '!';	out[2] = ']'; out[3] = ' ';	pos = 4;
	for (i=1; i<=n; i++) {
		const char *s = lua_print_format(L, i, &len);
		if (i>1) { out[pos]='\t'; pos++; }
		snprintf(out+pos,MAX_STRING-pos,"%s",s);
		pos+=len;
		lua_pop(L, 1);  /* pop result */
	}
	EM_ASM_({Module.print(UTF8ToString($0))}, out);
	return 0;
}

static int zen_warn (lua_State *L) {
	if( lua_print_stderr_tobuf(L,' ') ) return 0;
	size_t pos = 0;
	size_t len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i;
	lua_getglobal(L, "tostring");
	out[0] = '['; out[1] = 'W';	out[2] = ']'; out[3] = ' ';	pos = 4;
	for (i=1; i<=n; i++) {
		const char *s = lua_print_format(L, i, &len);
		if (i>1) { out[pos]='\t'; pos++; }
		snprintf(out+pos,MAX_STRING-pos,"%s",s);
		pos+=len;
		lua_pop(L, 1);  /* pop result */
	}
	EM_ASM_({Module.print(UTF8ToString($0))}, out);
	return 0;
}

static int zen_write (lua_State *L) {
	size_t pos = 0;
	int nargs = lua_gettop(L) +1;
	int arg = 0;
	for (; nargs--; arg++) {
		size_t len;
		const char *s = lua_tolstring(L, arg, &len);
		if (arg>1) { out[pos]='\t'; pos++; }
		snprintf(out+pos,MAX_STRING-pos,"%s",s);
		pos+=len;
	}
	EM_ASM_({Module.print(UTF8ToString($0))}, out);
	lua_pushboolean(L, 1);
	return 1;
}

#elif defined(ARCH_CORTEX)
static int zen_print (lua_State *L)
{
    return 1;
}

static int zen_error (lua_State *L)
{
    return 1;
}

static int zen_warn (lua_State *L)
{
    return 1;
}

static int zen_write (lua_State *L)
{
    return 1;
}

#else


static int zen_print (lua_State *L) {
	if( lua_print_stdout_tobuf(L,'\n') ) return 0;

	int status = 1;
	size_t len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i, w;
	lua_getglobal(L, "tostring");
	for (i=1; i<=n; i++) {
		const char *s = lua_print_format(L, i, &len);
		if(i>1)
            w = write(STDOUT_FILENO, "\t", 1);
        (void)w;
		status = status &&
			(write(STDOUT_FILENO, s,  len) == (int)len);
		lua_pop(L, 1);  /* pop result */
	}
	w = write(STDOUT_FILENO,"\n",sizeof(char));
    (void)w;
	return 0;
}

// print without an ending newline
static int zen_write (lua_State *L) {
	if( lua_print_stdout_tobuf(L,' ') ) return 0;

	int status = 1;
	size_t len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i, w;
	lua_getglobal(L, "tostring");
	for (i=1; i<=n; i++) {
		const char *s = lua_print_format(L, i, &len);
		if(i>1)
			w = write(STDOUT_FILENO, "\t", 1);
		(void)w;
		status = status &&
			(write(STDOUT_FILENO, s,  len) == (int)len);
		lua_pop(L, 1);  /* pop result */
	}
	(void)w;
	return 0;
}

static int zen_warn (lua_State *L) {
	if( lua_print_stderr_tobuf(L,'\n') ) return 0;
	int status = 1;
	size_t len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i, w;
	lua_getglobal(L, "tostring");
	w = write(STDERR_FILENO, "[W] ",4* sizeof(char));
	(void)w;
	for (i=1; i<=n; i++) {
		const char *s = lua_print_format(L, i, &len);
		if(i>1)
			w = write(STDERR_FILENO, "\t",sizeof(char));
		(void)w;
		status = status &&
			(write(STDERR_FILENO, s, len) == (int)len);
		lua_pop(L, 1);  /* pop result */
	}
	w = write(STDERR_FILENO,"\n",sizeof(char));
	(void)w;
	return 0;
}

static int zen_act (lua_State *L) {
	if( lua_print_stderr_tobuf(L,'\n') ) return 0;
	int status = 1;
	size_t len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i, w;
	lua_getglobal(L, "tostring");
	w = write(STDERR_FILENO, " .  ",4* sizeof(char));
	(void)w;
	for (i=1; i<=n; i++) {
		const char *s = lua_print_format(L, i, &len);
		if(i>1)
			w = write(STDERR_FILENO, "\t",sizeof(char));
		(void)w;
		status = status &&
			(write(STDERR_FILENO, s, len) == (int)len);
		lua_pop(L, 1);  /* pop result */
	}
	w = write(STDERR_FILENO,"\n",sizeof(char));
	(void)w;
	return 0;
}

// lua_error from lapi.c
// #include <lapi.h>
// api_checknelems(L, 1);
// luaG_errormsg(L);

static int zen_error (lua_State *L) {
	int n = lua_gettop(L);  /* number of arguments */
	int w;

	if( lua_print_stderr_tobuf(L,'\n') ) return 0;

	int status = 1;
	size_t len = 0;
	int i;
	lua_getglobal(L, "tostring");
	w = write(STDERR_FILENO, "[!] ",4* sizeof(char));
    (void)w;
	for (i=1; i<=n; i++) {
		const char *s = lua_print_format(L, i, &len);
		if(i>1)
			w = write(STDERR_FILENO, "\t",sizeof(char));
        (void)w;
		status = status &&
			(write(STDERR_FILENO, s, len) == (int)len);
		lua_pop(L, 1);  /* pop result */
	}
	w = write(STDERR_FILENO,"\n",sizeof(char));

	// output the zencode line if active
	lua_getglobal(L,"ZEN_traceback");
	size_t zencode_line_len;
	const char *zencode_line = lua_tolstring(L,3,&zencode_line_len);
	if(zencode_line) {
		w = write(STDERR_FILENO, "[!] ",4* sizeof(char));
		w = write(STDERR_FILENO, zencode_line, zencode_line_len);
	}
	lua_pop(L,1); // lua_getglobal ZEN_tracebak

    (void)w;
	return 0;
}

#endif

static int zen_trim(lua_State* L) {
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

void zen_add_io(lua_State *L) {
	// override print() and io.write()
	static const struct luaL_Reg custom_print [] =
		{ {"print", zen_print},
		  {"write", zen_write},
		  {"error", zen_error},
		  {"warn", zen_warn},
		  {"act", zen_act},
		  {"trim", zen_trim},
		  {NULL, NULL} };
	lua_getglobal(L, "_G");
	luaL_setfuncs(L, custom_print, 0);  // for Lua versions 5.2 or greater
	lua_pop(L, 1);

	static const struct luaL_Reg custom_iowrite [] =
		{ {"write", zen_write}, {NULL, NULL} };
	lua_getglobal(L, "io");
	luaL_setfuncs(L, custom_iowrite, 0);
	lua_pop(L, 1);
}
