/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2025 Dyne.org foundation
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

#ifndef LIBRARY

#include <stdlib.h>
#include <unistd.h>
#include <ctype.h>
#include <zen_error.h>
#include <zenroom.h>

#include <lua.h>
#include <lauxlib.h>

#include <lua_functions.h>

#ifdef ARCH_LINUX
#include <readline/readline.h>
#include <readline/history.h>
#endif

extern int zen_exec_lua(zenroom_t *Z, const char *script);

int repl_read(lua_State *lua) {
	char *line = NULL;
	line = malloc(MAX_STRING);
	size_t len =0;
	len = read(STDIN_FILENO, line, MAX_STRING);
	line[len] = '\0';
	lua_pushlstring(lua, line, len);
	free(line);
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
		zerror(lua, "Error: LUA string too long");
		return 0; }
	int nop = write(STDOUT_FILENO, line, len);
	(void)nop;
	return 0;
}

size_t repl_prompt(int ret, char *line) {
	size_t len = 0;
	char *prompt;
	if(ret) prompt="lua! \0";
	else prompt="lua> \0";
#ifdef ARCH_LINUX
	char *r = NULL;
	r = readline(prompt);
	if(!r) return 0; // quit
	len = strlen(r);
	memcpy(line, r, len);
#else
	int nop = write(STDOUT_FILENO, prompt, 5);
	(void)nop;
	len = read(STDIN_FILENO, line, MAX_STRING);
#endif
	line[len] = '\0';
	return(len);
}

int repl_loop(void *Z) {
	if(!Z) return EXIT_FAILURE;
	zenroom_t *ZZ = (zenroom_t*)Z;
	char *line = malloc(MAX_STRING);
	int ret =0;
	while(repl_prompt(ret, line)) {
		ret = zen_exec_lua(ZZ, line);
		if(ret) break;
	}
	free(line);
	return(ret);
}

#endif
