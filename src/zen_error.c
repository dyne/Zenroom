/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2021 Dyne.org foundation
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


#ifdef __ANDROID__
#include <android/log.h>
#endif

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

#include <zenroom.h>
#include <zen_error.h>

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

// ANSI colors for terminal
const char* ANSI_RED     = "\x1b[1;31m";
const char* ANSI_GREEN   = "\x1b[1;32m";
const char* ANSI_YELLOW  = "\x1b[1;33m";
const char* ANSI_BLUE    = "\x1b[1;34m";
const char* ANSI_MAGENTA = "\x1b[35m";
const char* ANSI_CYAN    = "\x1b[36m";
const char* ANSI_RESET   = "\x1b[0m";

extern zenroom_t *Z;
static char pfx[MAX_STRING];

extern int zen_write_err_va(const char *fmt, va_list va);

#define CTXSAFE(lv) (void)L; if(Z) { if(Z->debuglevel < lv) return; }

static int color = 0;
void set_color(int on) { color = on; }

#ifdef __ANDROID__
void error(lua_State *L, const char *format, ...) {
	va_list arg;
	va_start(arg, format);
	__android_log_vprint(ANDROID_LOG_ERROR, "ZEN", format, arg);
	va_end(arg);
}
void warning(lua_State *L, const char *format, ...) {
	if(Z->debuglevel<1) return;
	va_list arg;
	va_start(arg, format);
	__android_log_vprint(ANDROID_LOG_WARN, "ZEN", format, arg);
	va_end(arg);
}
void notice(lua_State *L, const char *format, ...) {
	if(Z->debuglevel<1) return;
	va_list arg;
	va_start(arg, format);
	__android_log_vprint(ANDROID_LOG_INFO, "ZEN", format, arg);
	va_end(arg);
}
void act(lua_State *L, const char *format, ...) {
	if(Z->debuglevel<2) return;
	va_list arg;
	va_start(arg, format);
	__android_log_vprint(ANDROID_LOG_DEBUG, "ZEN", format, arg);
	va_end(arg);
}
void func(void *L, const char *format, ...) {
	if(Z->debuglevel<3) return;
	va_list arg;
	va_start(arg, format);
	__android_log_vprint(ANDROID_LOG_VERBOSE, "ZEN", format, arg);
	va_end(arg);
}
#else

void notice(lua_State *L, const char *format, ...) {
	CTXSAFE(1);
	va_list arg;
	snprintf_t pr = Z ? Z->snprintf : &snprintf;
	if(color)
		(*pr)(pfx, MAX_STRING-1, "%s[*]%s %s\n",ANSI_GREEN,ANSI_RESET,format);
	else
		(*pr)(pfx, MAX_STRING-1, "[*] %s\n",format);
	va_start(arg, format);
	zen_write_err_va(pfx, arg);
	va_end(arg);
}

void func(void *L, const char *format, ...) {
	CTXSAFE(3);
	va_list arg;
	snprintf_t pr = Z ? Z->snprintf : &snprintf;
	(*pr)(pfx, MAX_STRING-1, "[D] %s\n",format);
	va_start(arg, format);
	zen_write_err_va(pfx, arg);
	va_end(arg);

}

extern int EXITCODE;
void error(lua_State *L, const char *format, ...) {
	CTXSAFE(0);
	if(!format) return;
	va_list arg;
	snprintf_t pr = Z ? Z->snprintf : &snprintf;
	if(color)
		(*pr)(pfx, MAX_STRING-1, "%s[!]%s %s\n",ANSI_RED,ANSI_RESET,format);
	else
		(*pr)(pfx, MAX_STRING-1, "[!] %s\n",format);
	va_start(arg, format);
	zen_write_err_va(pfx, arg);
	va_end(arg);
	if(Z) Z->errorlevel = 3;
	EXITCODE=1;
	// exit(1); // calls teardown (signal 11) TODO: check if OK with seccomp
}

void act(lua_State *L, const char *format, ...) {
	CTXSAFE(2);
	va_list arg;
	snprintf_t pr = Z ? Z->snprintf : &snprintf;
	(*pr)(pfx, MAX_STRING-1, " .  %s\n",format);
	va_start(arg, format);
	zen_write_err_va(pfx, arg);
	va_end(arg);
}

void warning(lua_State *L, const char *format, ...) {
	CTXSAFE(1);
	va_list arg;
	snprintf_t pr = Z ? Z->snprintf : &snprintf;
	if(color)
		(*pr)(pfx, MAX_STRING-1, "%s[W]%s %s\n",ANSI_YELLOW,ANSI_RESET,format);
	else
		(*pr)(pfx, MAX_STRING-1, "[W] %s\n",format);
	va_start(arg, format);
	zen_write_err_va(pfx, arg);
	va_end(arg);
	if(Z) Z->errorlevel = 2;
}

#endif
