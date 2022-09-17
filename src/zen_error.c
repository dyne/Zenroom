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
#include <zen_octet.h>
#include <zen_error.h>

#define MAX_ERRMSG 256 // maximum length of an error message line

int lerror(lua_State *L, const char *fmt, ...) {
	va_list argp;
	va_start(argp, fmt);
	zerror(L, fmt, argp);
	luaL_where(L, 1);
	lua_pushvfstring(L, fmt, argp);
	va_end(argp);
	lua_concat(L, 2);
	return lua_error(L);
}

int zencode_traceback(lua_State *L) {
    // output the zencode traceback lines
	int w; (void)w;
	lua_getglobal(L, "ZEN_traceback");
	size_t zencode_line_len;
	const char *zencode_line = lua_tolstring(L, lua_gettop(L), &zencode_line_len);
	if(zencode_line_len) {
		w = write(STDERR_FILENO, "[!] ", 4* sizeof(char));
		w = write(STDERR_FILENO, zencode_line, zencode_line_len);
	}
	lua_pop(L, 1);
	return 0;
}


extern int zen_write_err_va(zenroom_t *Z, const char *fmt, va_list va);

/* static inline zenroom_t* ZZ(lua_State *L) { */
/*   global_State *_g = G(L); */
/*   return((zenroom_t*)_g->ud); */
/* } */


#ifdef __ANDROID__
void zerror(void *L, const char *format, ...) {
	va_list arg;
	va_start(arg, format);
	__android_log_vprint(ANDROID_LOG_ERROR, "ZEN", format, arg);
	va_end(arg);
}
void warning(void *L, const char *format, ...) {
	va_list arg;
	va_start(arg, format);
	__android_log_vprint(ANDROID_LOG_WARN, "ZEN", format, arg);
	va_end(arg);
}
void notice(void *L, const char *format, ...) {
	va_list arg;
	va_start(arg, format);
	__android_log_vprint(ANDROID_LOG_INFO, "ZEN", format, arg);
	va_end(arg);
}
void act(void *L, const char *format, ...) {
	va_list arg;
	va_start(arg, format);
	__android_log_vprint(ANDROID_LOG_DEBUG, "ZEN", format, arg);
	va_end(arg);
}
void func(void *L, const char *format, ...) {
	va_list arg;
	va_start(arg, format);
	__android_log_vprint(ANDROID_LOG_VERBOSE, "ZEN", format, arg);
	va_end(arg);
}
#else

#include <mutt_sprintf.h>

void json_start(void *Z, const char *format, ...) {
  char pfx[MAX_ERRMSG];
  va_list arg;
  mutt_snprintf(pfx, MAX_ERRMSG-1, "{[\"ZENROOM JSON LOG START\",\n");
  va_start(arg, format);
  zen_write_err_va(Z, pfx, arg);
  va_end(arg);
}

void json_end(void *Z, const char *format, ...) {
  char pfx[MAX_ERRMSG];
  va_list arg;
  mutt_snprintf(pfx, MAX_ERRMSG-1, "\"ZENROOM JSON LOG END\"]}\n");
  va_start(arg, format);
  zen_write_err_va(Z, pfx, arg);
  va_end(arg);
}

static octet *o_malloc(int size) {
  octet *o = malloc(sizeof(octet));
  o->val = malloc(size);
  o->max = size;
  o->len = 0;
  return(o);
}

static void o_free(octet *o) {
  free(o->val);
  free(o);
}

// from zen_io.c
extern int zen_log(lua_State *L, const char *level, octet *oct);

void notice(void *L, const char *format, ...) {
  Z(L);
  if(Z && Z->debuglevel<1) return;
  octet *o = o_malloc(MAX_ERRMSG); SAFE(o);
  char *p = o->val;
  if(Z->logformat == JSON) { *p = '"'; p++; }
  va_list arg;
  va_start(arg, format);
  mutt_vsnprintf(p, o->max-4, format, arg);
  o->len = strlen(o->val);
  if(Z->logformat == JSON) {
	p+=o->len; *p='"'; p++; *p=','; p++; o->len+=2;
  }
  zen_log(L, "[*]  ", o);
  o_free(o);
}

void func(void *L, const char *format, ...) {
  Z(L);
  if(Z && Z->debuglevel<3) return;
  octet *o = o_malloc(MAX_ERRMSG); SAFE(o);
  char *p = o->val;
  if(Z->logformat == JSON) { *p = '"'; p++; }
  va_list arg;
  va_start(arg, format);
  mutt_vsnprintf(p, o->max-4, format, arg);
  o->len = strlen(o->val);
  if(Z->logformat == JSON) {
	p+=o->len; *p='"'; p++; *p=','; p++; o->len+=2;
  }
  zen_log(L, "[D]  ", o);
  o_free(o);
}

void zerror(void *L, const char *format, ...) {
  Z(L);
  octet *o = o_malloc(MAX_ERRMSG); SAFE(o);
  char *p = o->val;
  if(Z->logformat == JSON) { *p = '"'; p++; }
  va_list arg;
  va_start(arg, format);
  mutt_vsnprintf(p, o->max-4, format, arg);
  o->len = strlen(o->val);
  if(Z->logformat == JSON) {
	p+=o->len; *p='"'; p++; *p=','; p++; o->len+=2;
  }
  zen_log(L, "[!]  ", o);
  o_free(o);
}

void act(void *L, const char *format, ...) {
  Z(L);
  if(Z && Z->debuglevel<2) return;
  octet *o = o_malloc(MAX_ERRMSG); SAFE(o);
  // new octet is pushed to stack
  char *p = o->val;
  if(Z->logformat == JSON) { *p = '"'; p++; }
  va_list arg;
  va_start(arg, format);
  mutt_vsnprintf(p, o->max-4, format, arg);
  o->len = strlen(o->val);
  if(Z->logformat == JSON) {
	p+=o->len; *p='"'; p++; *p=','; p++; o->len+=2;
  }
  zen_log(L, " .  ", o); // pulls new octet from stack
  o_free(o);
}

void warning(void *L, const char *format, ...) {
  Z(L);
  if(Z && Z->debuglevel<1) return;
  octet *o = o_malloc(MAX_ERRMSG); SAFE(o);
  // new octet is pushed to stack
  char *p = o->val;
  if(Z->logformat == JSON) { *p = '"'; p++; }
  va_list arg;
  va_start(arg, format);
  mutt_vsnprintf(p, o->max-4, format, arg);
  o->len = strlen(o->val);
  if(Z->logformat == JSON) {
	p+=o->len; *p='"'; p++; *p=','; p++; o->len+=2;
  }
  zen_log(L, "[W]  ", o); // pulls new octet from stack
  o_free(o);
}
#endif
