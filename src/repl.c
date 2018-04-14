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

#include <unistd.h>
#include <ctype.h>
#include <jutils.h>
#include <zenroom.h>

#include <lua.h>
#include <lauxlib.h>

#include <lua_functions.h>

extern void lsb_load_extensions(lua_State *L);

int repl_read(lua_State *lua) {
	char line[MAX_STRING];
	size_t len =0;
	len = read(STDIN_FILENO, line, MAX_STRING);
	line[len] = '\0';
	lua_pushlstring(lua, line, len);
	return 1;
}

int repl_flush(lua_State *lua) {
	(void)lua;
	fflush(stdout);
	return 0;
}

int repl_write(lua_State *lua) {
	size_t len;
	const char *line = luaL_checklstring(lua,1,&len);
	if(len>MAX_STRING) {
		error(lua, "Error: LUA string too long");
		return 0; }
	write(STDOUT_FILENO, line, len);
	return 0;
}

size_t repl_prompt(int ret, char *line) {
	size_t len = 0;
	char *prompt;
	if(ret) prompt="zen! \0";
	else prompt="zen> \0";
	write(STDOUT_FILENO, prompt, 5);
	len = read(STDIN_FILENO, line, MAX_STRING);
	line[len] = '\0';
	return(len);
}

void repl_loop(lua_State *L) {
	char line[MAX_STRING];
	if(!L) return;
	int ret =0;
	while(repl_prompt(ret, line)) {
		ret = zen_exec_script(L, line);
	}
}

