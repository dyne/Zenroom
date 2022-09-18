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

#if defined(_WIN32)
/* Windows */
# include <windows.h>
#include <intrin.h>
#endif

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <zenroom.h>
#include <zen_octet.h>
#include <zen_error.h>
#include <zen_memory.h>
#include <mutt_sprintf.h>

// from zen_io.c
extern int zen_log(lua_State *L, log_priority prio, octet *oct);
extern void printerr(lua_State *L, octet *in);

#define MAX_ERRMSG 256 // maximum length of an error message line

#define LOG_DEFAULT " .   "
// aligned to log_priority in error.h header
const char* log_prefix[] = {
  "[D]  ", // UNK
  LOG_DEFAULT, // DEF
  "[D]  ", // VERB
  " .   ", // DBUG
  "[*]  ", // INFO
  "[W]  ", // WARN
  "[!]  ", // ERR
  "[!]  ", // FATAL
  "[!]  " // SIL
};
void get_log_prefix(void *Z, log_priority prio, char dest[5]) {
  zenroom_t *ZZ = (zenroom_t*)Z;
  char *p = dest;
  if(ZZ->logformat == JSON) { *p = '"'; p++; }
  strncpy(p, log_prefix[prio], 4);
}

int lerror(void *LL, const char *fmt, ...) {
  lua_State *L = (lua_State*)LL;
  va_list argp;
  va_start(argp, fmt);
  zerror(L, fmt, argp);
  luaL_where(L, 1);
  lua_pushvfstring(L, fmt, argp);
  va_end(argp);
  lua_concat(L, 2);
  return lua_error(L);
}

static octet *o_malloc(int size) {
  octet *o = malloc(sizeof(octet));
  o->val = malloc(size+0x0f);
  o->max = size;
  o->len = 0;
  return(o);
}

static void o_free(octet *o) {
  free(o->val);
  free(o);
}

void json_start(void *L) {
  const char *logstart = "{ [ \"ZENROOM JSON LOG START\",";
  octet o;
  o.len = o.max = strlen(logstart);
  o.val = malloc(o.len+0x0f);
  memcpy(o.val, logstart, o.len);
  printerr(L, &o);
  free(o.val);
}

void json_end(void *L) {
  const char *logend = "\"ZENROOM JSON LOG END\" ] }";
  octet o;
  o.len = o.max = strlen(logend);
  o.val = malloc(o.len+0x0f);
  memcpy(o.val, logend, o.len);
  printerr(L, &o);
  free(o.val);
}

void notice(void *L, const char *format, ...) {
  Z(L);
  if(Z && Z->debuglevel<1) return;
  octet *o = o_malloc(MAX_ERRMSG); SAFE(o);
  va_list arg;
  va_start(arg, format);
  mutt_vsnprintf(o->val, o->max-5, format, arg);
  o->len = strlen(o->val);
  zen_log(L, LOG_INFO, o);
  o_free(o);
}

void func(void *L, const char *format, ...) {
  Z(L);
  if(Z && Z->debuglevel<3) return;
  octet *o = o_malloc(MAX_ERRMSG); SAFE(o);
  va_list arg;
  va_start(arg, format);
  mutt_vsnprintf(o->val, o->max-5, format, arg);
  o->len = strlen(o->val);
  zen_log(L, LOG_VERBOSE, o);
  o_free(o);
}

void zerror(void *L, const char *format, ...) {
  octet *o = o_malloc(MAX_ERRMSG); SAFE(o);
  va_list arg;
  va_start(arg, format);
  mutt_vsnprintf(o->val, o->max-5, format, arg);
  o->len = strlen(o->val);
  zen_log(L, LOG_ERROR, o);
  o_free(o);
}

void act(void *L, const char *format, ...) {
  Z(L);
  if(Z && Z->debuglevel<2) return;
  octet *o = o_malloc(MAX_ERRMSG); SAFE(o);
  // new octet is pushed to stack
  va_list arg;
  va_start(arg, format);
  mutt_vsnprintf(o->val, o->max-5, format, arg);
  o->len = strlen(o->val);
  zen_log(L, LOG_DEBUG, o);
  o_free(o);
}

void warning(void *L, const char *format, ...) {
  Z(L);
  if(Z && Z->debuglevel<1) return;
  octet *o = o_malloc(MAX_ERRMSG); SAFE(o);
  va_list arg;
  va_start(arg, format);
  mutt_vsnprintf(o->val, o->max-5, format, arg);
  o->len = strlen(o->val);
  zen_log(L, LOG_WARN, o);
  o_free(o);
}
