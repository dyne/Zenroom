/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2022 Dyne.org foundation
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
#include <ctype.h>
#include <errno.h>


#include <zenroom.h>
#include <mutt_sprintf.h>

#include <lauxlib.h>

#include <zen_error.h>
#include <zen_octet.h>
#include <zen_memory.h>

#ifdef __ANDROID__
#include <android/log.h>
#endif

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif


#if defined(ARCH_CORTEX)
extern int SEMIHOSTING_STDOUT_FILENO;
extern int write_to_console(const char* str);
#endif

// simple inline duplicate function wrapper also in zen_error.c
static inline void _zen_io_write(int fd, const void *buf, size_t count) {
  register ssize_t res;
  res = write(fd, buf, count);
  if(res<0) {
	// spit errors hoping there is a stderr
	fprintf(stderr,"[!] Error on write() %lu bytes\n",count);
	fprintf(stderr,"[!] %s\n",strerror(errno));
  }
}

static int zen_print (lua_State *L) {
  BEGIN();
  Z(L);
  char *failed_msg = NULL;
  const octet *o = o_arg(L, 1);
  if(o == NULL) {
	  failed_msg = "Could not allocate message to show";
	  goto end;
  }
  if (Z->stdout_buf) {
	char *p = Z->stdout_buf+Z->stdout_pos;
	if(!o) { *p='\n'; Z->stdout_pos++; return 0; }
	if (Z->stdout_pos+o->len+1 > Z->stdout_len)
	  zerror(L, "No space left in output buffer");
	memcpy(p, o->val, o->len);
	*(p + o->len) = '\n';
	*(p + o->len+1) = '\0';
	Z->stdout_pos += o->len + 1;
  } else if(o) {
	o->val[o->len] = '\n'; // add newline
	o->val[o->len+1] = 0x0; // add string termination
	// octet safety buffer allows this: o->val = malloc(size +0x0f);
#if defined(__EMSCRIPTEN__)
	EM_ASM_({Module.print(UTF8ToString($0))}, o->val);
#elif defined(ARCH_CORTEX)
	_zen_io_write(SEMIHOSTING_STDOUT_FILENO, o->val, o->len+1);
#else
	_zen_io_write(STDOUT_FILENO, o->val, o->len+1);
#endif
  } else
	func(L, "print of an empty string");
end:
  o_free(L,o);
  if(failed_msg != NULL) {
	  lerror(L, "%s", failed_msg);
  }
  END(0);
}

int printerr(lua_State *L, const octet *o) {
  BEGIN();
  Z(L);
  if (Z->stderr_buf) {
	char *p = Z->stderr_buf+Z->stderr_pos;
	if(!o) { *p='\n'; Z->stderr_pos++; return 0; }
	if (Z->stderr_pos+o->len+1 > Z->stderr_len)
	  zerror(L, "No space left in output buffer");
	memcpy(p, o->val, o->len);
	*(p + o->len) = '\n';
	Z->stderr_pos += o->len + 1;
  } else if(o) {
	  char *t = calloc(o->len +8, sizeof(char));
	  memcpy(t, o->val, o->len);
	  t[o->len] = '\n';
	  t[o->len+1] = 0x0;
#if defined(__EMSCRIPTEN__)
	// octet safety buffer allows this: o->val = malloc(size +0x0f);
	EM_ASM_({Module.printErr(UTF8ToString($0))}, t);
#elif defined(__ANDROID__)
	__android_log_print(ANDROID_LOG_DEFAULT, "ZEN", "%s", t);
#elif defined(ARCH_CORTEX)
	write_to_console(t);
#else
	_zen_io_write(STDERR_FILENO, t, o->len+1);
#endif
	free(t);
  } else
	func(L, "printerr of an empty string");	
  END(0);
}

// print without an ending newline
static int zen_write (lua_State *L) {
  BEGIN();
  Z(L);
  char *failed_msg = NULL;
  const octet *o = o_arg(L, 1);
  if(o == NULL) {
	  failed_msg = "Could not allocate message to show";
	  goto end;
  }
  if (Z->stdout_buf) {
	char *p = Z->stdout_buf+Z->stdout_pos;
	if (Z->stdout_pos+o->len > Z->stdout_len)
	  zerror(L, "No space left in output buffer");
	memcpy(p, o->val, o->len);
	Z->stdout_pos += o->len;
  } else if(o) {
#ifdef __EMSCRIPTEN_
	o->val[o->len] = 0x0; // add string termination
	// octet safety buffer allows this: o->val = malloc(size +0x0f);
	EM_ASM_({Module.print(UTF8ToString($0))}, o->val);
#else
	_zen_io_write(STDOUT_FILENO, o->val, o->len);
#endif
  } else
	func(L, "write of an empty string");
end:
  o_free(L,o);
  if(failed_msg != NULL) {
	  lerror(L, "%s", failed_msg);
  }
  END(0);
}

int zen_log(lua_State *L, log_priority prio, const octet *o) {
  Z(L);
  if(!o) return 0;
#ifdef __ANDROID__
  char *t = calloc(o->len+1,sizeof(char));
  memcpy(t,o->val,o->len);
  t[o->len] = 0x0;
  __android_log_print(prio, "ZEN", "%s", t);
  free(t);
  return 0;
#endif
  if (Z->stderr_buf
	  && Z->stderr_pos+o->len+5 > Z->stderr_len) {
	  zerror(L, "No space left in error buffer");
	  return 1;
  }
  char *p = o->val + o->len;
  int tlen = o->len;
  if(Z->logformat == LOG_JSON) {
	// JSON termination
	*p='"'; p++; *p=','; p++; tlen+=2;
  } // newline termination
  *p='\n'; p++; *p=0x0; tlen++;
  char prefix[5] = "     ";
  get_log_prefix(Z,prio,prefix);
  if (Z->stderr_buf) {
	p = Z->stderr_buf+Z->stderr_pos;
	strncpy(p, prefix, 5);
	memcpy(p + 5, o->val, tlen);
	Z->stderr_pos += 5 + tlen;
	Z->stderr_buf[Z->stderr_pos] = '\0';
  } else {
#if defined(__EMSCRIPTEN__)
	EM_ASM_({Module.printErr(UTF8ToString($0)+UTF8ToString($1))}, prefix, o->val);
#elif defined(ARCH_CORTEX)
	_zen_io_write(SEMIHOSTING_STDOUT_FILENO, prefix, 5);
	_zen_io_write(SEMIHOSTING_STDOUT_FILENO, o->val, tlen);
#else
	_zen_io_write(STDERR_FILENO, prefix, 5);
	_zen_io_write(STDERR_FILENO, o->val, tlen);
#endif
  }
  return 0;
}

#define ZEN_PRINT(FUN_NAME, PRINT_FUN) \
	static int (FUN_NAME)(lua_State *L) { \
		BEGIN(); \
		const octet *o = o_arg(L, 1); \
		if(o != NULL) { \
			PRINT_FUN; \
			o_free(L,o); \
		} else { \
			lerror(L, "Could not allocate message to show"); \
		} \
		END(0); \
	}
// print to stderr without prefix with newline
ZEN_PRINT(zen_printerr, printerr(L, o))
ZEN_PRINT(zen_warn, zen_log(L, LOG_WARN, o))
ZEN_PRINT(zen_act, zen_log(L, LOG_DEBUG, o))
ZEN_PRINT(zen_notice, zen_log(L, LOG_INFO, o))
ZEN_PRINT(zen_debug, zen_log(L, LOG_VERBOSE, o))

void zen_add_io(lua_State *L) {
	// override print() and io.write()
	static const struct luaL_Reg custom_print [] =
		{ {"print", zen_print},
		  {"printerr", zen_printerr},
		  {"write", zen_write},
		  {"notice", zen_notice},
		  {"warn", zen_warn},
		  {"act", zen_act},
		  {"xxx", zen_debug},
//		  {"random_seed", zen_random_seed},
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
