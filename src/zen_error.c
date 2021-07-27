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
#include <stdlib.h>
#include <unistd.h>
#include <stdarg.h>
#include <errno.h>

#if defined(_WIN32)
/* Windows */
# include <windows.h>
#include <intrin.h>
#include <malloc.h>
#endif

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <zen_error.h>
#include <zenroom.h>

int lerror(lua_State *L, const char *fmt, ...) {
	va_list argp;
	va_start(argp, fmt);
	error(0,fmt,argp);
	luaL_where(L, 1);
	lua_pushvfstring(L, fmt, argp);
	va_end(argp);
	lua_concat(L, 2);
	return lua_error(L);
}

int zencode_traceback(lua_State *L) {
    // output the zencode traceback lines
	int w; (void)w;
	lua_getglobal(L,"ZEN_traceback");
	size_t zencode_line_len;
	const char *zencode_line = lua_tolstring(L,lua_gettop(L),&zencode_line_len);
	if(zencode_line_len) {
		w = write(STDERR_FILENO, "[!] ",4* sizeof(char));
		w = write(STDERR_FILENO, zencode_line, zencode_line_len);
	}
	lua_pop(L,1);
	return 0;
}
