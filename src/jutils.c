/*  Jaromil's utility collection
 *
 *  (c) Copyright 2001-2021 Denis Rojo <jaromil@dyne.org>
 *
 * This source code is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Public License as published
 * by the Free Software Foundation; either version 2 of the License,
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

#ifdef __ANDROID__
#include <android/log.h>
#endif

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

#include <zenroom.h>
#include <zen_error.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#ifdef __ANDROID__
#include <android/log.h>
#endif

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

static int verbosity = 1;
int get_debug() { return(verbosity); }
void set_debug(int lev) {
  lev = lev<0 ? 0 : lev;
  lev = lev>3 ? 3 : lev;
  verbosity = lev;
}

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
	if(verbosity<1) return;
	va_list arg;
	va_start(arg, format);
	__android_log_vprint(ANDROID_LOG_WARN, "ZEN", format, arg);
	va_end(arg);
}
void notice(lua_State *L, const char *format, ...) {
	if(verbosity<1) return;
	va_list arg;
	va_start(arg, format);
	__android_log_vprint(ANDROID_LOG_INFO, "ZEN", format, arg);
	va_end(arg);
}
void act(lua_State *L, const char *format, ...) {
	if(verbosity<2) return;
	va_list arg;
	va_start(arg, format);
	__android_log_vprint(ANDROID_LOG_DEBUG, "ZEN", format, arg);
	va_end(arg);
}
void func(void *L, const char *format, ...) {
	if(verbosity<3) return;
	va_list arg;
	va_start(arg, format);
	__android_log_vprint(ANDROID_LOG_VERBOSE, "ZEN", format, arg);
	va_end(arg);
}
#else

void notice(lua_State *L, const char *format, ...) {
	(void)L;
	if(!verbosity) return;
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
	(void)L;
	if(verbosity<3) return;
	va_list arg;
	snprintf_t pr = Z ? Z->snprintf : &snprintf;
	(*pr)(pfx, MAX_STRING-1, "[D] %s\n",format);
	va_start(arg, format);
	zen_write_err_va(pfx, arg);
	va_end(arg);

}

void error(lua_State *L, const char *format, ...) {
	(void)L;
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
	// exit(1); // calls teardown (signal 11) TODO: check if OK with seccomp
}

void act(lua_State *L, const char *format, ...) {
	(void)L;
	if(!verbosity) return;
	va_list arg;
	snprintf_t pr = Z ? Z->snprintf : &snprintf;
	(*pr)(pfx, MAX_STRING-1, " .  %s\n",format);
	va_start(arg, format);
	zen_write_err_va(pfx, arg);
	va_end(arg);
}

void warning(lua_State *L, const char *format, ...) {
	(void)L;
	if(verbosity<2) return;
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

// secure comparison of null terminated strings
short compare(const char *left, const char *right, size_t len) {
	if(!left || !right) return 0;
	register unsigned int i;
	for (i=0; i<len; i++) {
		if(!left[i] || !right[i]) return 0; // no null
		if (left[i] ^ right[i]) return 0; // xor for equality
	}
	// check null termination
	if(left[i] || right[i]) return(0);
	return(1); // return success
}
