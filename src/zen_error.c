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

#include <unistd.h>
#include <errno.h>

#ifdef __ANDROID__
#include <android/log.h>
#endif

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

#if defined(_WIN32)
/* Windows */
# include <windows.h>
#include <intrin.h>
#endif

#include <zenroom.h>

#include <zen_octet.h>
#include <zen_error.h>
#include <mutt_sprintf.h>
#include <encoding.h>

// simple inline duplicate function wrapper also in zen_io.c
static inline void _zen_error_write(int fd, const void *buf, size_t count) {
  register ssize_t res;
  res = write(fd, buf, count);
  if(res<0) {
	// spit errors hoping there is a stderr
	fprintf(stderr,"[!] Error on write() %lu bytes\n",count);
	fprintf(stderr,"[!] %s\n",strerror(errno));
  }
}

// from zen_io.c
extern int zen_log(lua_State *L, log_priority prio, octet *oct);
extern int printerr(lua_State *L, octet *in);

#define Z_FORMAT_ARG(l) zenroom_t *Z=NULL; (void)Z; if (l) { void *_zv; lua_getallocf(l, &_zv); Z = _zv; } else { _err(format, arg); return(0); }

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
  if(ZZ->logformat == LOG_JSON) { *p = '"'; p++; }
  strncpy(p, log_prefix[prio], 4);
}

// error reported with lua context
void lerror(void *LL, const char *fmt, ...) {
  char msg[MAX_ERRMSG+4];
  int len;
  lua_State *L = (lua_State*)LL;
  va_list argp, argp_copy;
  va_start(argp, fmt);
  va_copy(argp_copy, argp);
  len = mutt_vsnprintf(msg, MAX_ERRMSG, fmt, argp);
  msg[len] = 0x0;
  zerror(L, "%s", msg); // logs on all platforms
  luaL_where(L, 1); // 1 is the function which called the running function
  lua_pushvfstring(L, fmt, argp_copy);
  va_end(argp);
  va_end(argp_copy);
  lua_concat(L, 2);
  lua_error(L); // fatal
  HEDLEY_UNREACHABLE();
  exit(1);
}

// stdout message free from context
void _out(const char *fmt, ...) {
  char msg[MAX_STRING+4];
  va_list args;
  va_start(args, fmt);
  int len = mutt_vsnprintf(msg, MAX_STRING, fmt, args);
  va_end(args);
  msg[len+1] = 0x0; //safety
#if defined(__EMSCRIPTEN__)
  EM_ASM_({Module.print(UTF8ToString($0))}, msg);
#elif defined(ARCH_CORTEX)
  msg[len] = '\n'; msg[len+1] = 0x0;
  _zen_error_write(SEMIHOSTING_STDOUT_FILENO, msg, len+1);
#else
  msg[len] = '\n'; msg[len+1] = 0x0;
  _zen_error_write(STDOUT_FILENO, msg, len+1);
#endif
}

// error message free from context
void _err(const char *fmt, ...) {
  char msg[MAX_ERRMSG+4];
  int len;
  va_list args;
  va_start(args, fmt);
  len = mutt_vsnprintf(msg, MAX_ERRMSG, fmt, args);
  va_end(args);
  msg[len] = '\n';
  msg[len+1] = 0x0;
#if defined(__EMSCRIPTEN__)
  EM_ASM_({Module.printErr(UTF8ToString($0))}, msg);
#elif defined(__ANDROID__)
  __android_log_print(ANDROID_LOG_ERROR, "ZEN", "%s", msg);
#elif defined(ARCH_CORTEX)
  write_to_console(msg);
#else
  _zen_error_write(STDERR_FILENO, msg, len+1);
#endif
}

// context free results
#if defined(__EMSCRIPTEN__)
int OK() {
  EM_ASM({Module.exec_ok();});
  return 0;
}
int FAIL() {
  EM_ASM({Module.exec_error();});
  EM_ASM(Module.onAbort());
  return 1;
}
#else
int OK(void) { return 0; }
int FAIL(void) { return 1; }
#endif

void json_start(void *L) {
  const char *logstart = "[ \"ZENROOM JSON LOG START\",";
  octet o;
  o.len = o.max = strlen(logstart);
  o.val = malloc(o.len+0x0f);
  memcpy(o.val, logstart, o.len);
  printerr(L, &o);
  free(o.val);
}

void json_end(void *L) {
  const char *logend = "\"ZENROOM JSON LOG END\" ]";
  octet o;
  o.len = o.max = strlen(logend);
  o.val = malloc(o.len+0x0f);
  memcpy(o.val, logend, o.len);
  printerr(L, &o);
  free(o.val);
}

int notice(void *L, const char *format, ...) {
  va_list arg;
  va_start(arg, format);
  Z_FORMAT_ARG(L);
  if(Z && Z->debuglevel<1) return 0;
  octet *o = o_alloc(L, MAX_ERRMSG);
  mutt_vsnprintf(o->val, o->max-5, format, arg);
  o->len = strlen(o->val);
  zen_log(L, LOG_INFO, o);
  o_free((lua_State*)L,o);
  return 0;
}

int func(void *L, const char *format, ...) {
  va_list arg;
  va_start(arg, format);
  Z_FORMAT_ARG(L);
  if(Z && Z->debuglevel<3) return 0;
  octet *o = o_alloc(L, MAX_ERRMSG);
  mutt_vsnprintf(o->val, o->max-5, format, arg);
  o->len = strlen(o->val);
  zen_log(L, LOG_VERBOSE, o);
  o_free((lua_State*)L,o);
  return 0;
}

int trace(void *L, const char *format, ...) {
  va_list arg;
  va_start(arg, format);
  Z_FORMAT_ARG(L);
  if(Z && Z->debuglevel<4) return 0;
  octet *o = o_alloc(L, MAX_ERRMSG);
  mutt_vsnprintf(o->val, o->max-5, format, arg);
  o->len = strlen(o->val);
  zen_log(L, LOG_VERBOSE, o);
  o_free((lua_State*)L,o);
  return 0;
}

int zerror(void *L, const char *format, ...) {
  va_list arg;
  va_start(arg, format);
  Z_FORMAT_ARG(L);
  octet *o = o_alloc(L, MAX_ERRMSG);
  mutt_vsnprintf(o->val, o->max-5, format, arg);
  o->len = strlen(o->val);
  zen_log(L, LOG_ERROR, o);
  o_free((lua_State*)L,o);
  return 0;
}

int act(void *L, const char *format, ...) {
  va_list arg;
  va_start(arg, format);
  Z_FORMAT_ARG(L);
  if(Z && Z->debuglevel<2) return 0;
  octet *o = o_alloc(L, MAX_ERRMSG);
  // new octet is pushed to stack
  mutt_vsnprintf(o->val, o->max-5, format, arg);
  o->len = strlen(o->val);
  zen_log(L, LOG_DEBUG, o);
  o_free((lua_State*)L,o);
  return 0;
}

int warning(void *L, const char *format, ...) {
  va_list arg;
  va_start(arg, format);
  Z_FORMAT_ARG(L);
  if(Z && Z->debuglevel<1) return 0;
  octet *o = o_alloc(L, MAX_ERRMSG);
  mutt_vsnprintf(o->val, o->max-5, format, arg);
  o->len = strlen(o->val);
  zen_log(L, LOG_WARN, o);
  o_free((lua_State*)L,o);
  return 0;
}

int hexdump(void *L, const char *src, size_t len) {
  octet *o = o_alloc(L, (len*2)+2);
  buf2hex(o->val,src,len);
  o->len = strlen(o->val);
  zen_log(L, LOG_VERBOSE, o);
  o_free((lua_State*)L,o);
  return 0;
}

int lua_fatal(lua_State *L) {
  return lua_error(L);
}
