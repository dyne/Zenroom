/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2026 Dyne.org foundation
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

static int zen_stdout_reserve(lua_State *L, size_t need) {
  zenroom_t *Z = zen_get_context(L);
  if (!Z || !Z->stdout_buf) return 1;
  if (Z->stdout_pos + need > Z->stdout_len) {
    luaL_error(L, "No space left in output buffer");
    return 0;
  }
  return 1;
}

static int zen_stderr_reserve(lua_State *L, size_t need, const char *msg) {
  zenroom_t *Z = zen_get_context(L);
  if (!Z || !Z->stderr_buf) return 1;
  if (Z->stderr_pos + need > Z->stderr_len) {
    luaL_error(L, "%s", msg);
    return 0;
  }
  return 1;
}

static int zen_print (lua_State *L) {
  BEGIN();
  zenroom_t *Z = zen_get_context(L);
  char *failed_msg = NULL;
  int n_args = lua_gettop(L);
  
  if(n_args == 0) {
	if (Z && Z->stdout_buf) {
	  char *p = Z->stdout_buf+Z->stdout_pos;
	  if (!zen_stdout_reserve(L, 2)) END(0);
	  *p='\n'; Z->stdout_pos++;
	  Z->stdout_buf[Z->stdout_pos] = '\0';
	} else {
#if defined(__EMSCRIPTEN__)
	  EM_ASM_({Module.print("")});
#elif defined(ARCH_CORTEX)
	  _zen_io_write(SEMIHOSTING_STDOUT_FILENO, "\n", 1);
#else
	  _zen_io_write(STDOUT_FILENO, "\n", 1);
#endif
	}
	END(0);
  }
  
  for(int i = 1; i <= n_args; i++) {
	const octet *o = o_arg(L, i); SAFE_GOTO(o, "Could not allocate message to show");
	
	if (Z && Z->stdout_buf) {
	  char *p = Z->stdout_buf+Z->stdout_pos;
	  size_t required = o->len + (i < n_args ? 1 : 2);
	  if (!zen_stdout_reserve(L, required)) {
		o_free(L,o);
		goto end;
	  }
	  memcpy(p, o->val, o->len);
	  Z->stdout_pos += o->len;
	  if(i < n_args) {
		*(p + o->len) = '\t';
		Z->stdout_pos++;
	  } else {
		*(p + o->len) = '\n';
		*(p + o->len+1) = '\0';
		Z->stdout_pos++;
	  }
	} else if(o) {
#if defined(__EMSCRIPTEN__)
	  if(i < n_args) {
		o->val[o->len] = '\t';
		o->val[o->len+1] = 0x0;
	  } else {
		o->val[o->len] = '\n';
		o->val[o->len+1] = 0x0;
	  }
	  EM_ASM_({Module.print(UTF8ToString($0))}, o->val);
#elif defined(ARCH_CORTEX)
	  _zen_io_write(SEMIHOSTING_STDOUT_FILENO, o->val, o->len);
	  if(i < n_args) {
		_zen_io_write(SEMIHOSTING_STDOUT_FILENO, "\t", 1);
	  } else {
		_zen_io_write(SEMIHOSTING_STDOUT_FILENO, "\n", 1);
	  }
#else
	  _zen_io_write(STDOUT_FILENO, o->val, o->len);
	  if(i < n_args) {
		_zen_io_write(STDOUT_FILENO, "\t", 1);
	  } else {
		_zen_io_write(STDOUT_FILENO, "\n", 1);
	  }
#endif
	}
	o_free(L,o);
  }
end:
  if(failed_msg != NULL) {
	  lerror(L, "%s", failed_msg);
  }
  END(0);
}

int printerr(lua_State *L, const octet *o) {
  BEGIN();
  zenroom_t *Z = zen_get_context(L);
  if (Z && Z->stderr_buf) {
	char *p = Z->stderr_buf+Z->stderr_pos;
	if(!o) {
	  if (!zen_stderr_reserve(L, 2, "No space left in error buffer")) return 0;
	  *p='\n';
	  Z->stderr_pos++;
	  Z->stderr_buf[Z->stderr_pos] = '\0';
	  return 0;
	}
	if (!zen_stderr_reserve(L, o->len + 2, "No space left in error buffer"))
	  return 0;
	memcpy(p, o->val, o->len);
	*(p + o->len) = '\n';
	*(p + o->len + 1) = '\0';
	Z->stderr_pos += o->len + 1;
  } else if(o) {
	  char *t = calloc(o->len +8, sizeof(char));
	  memcpy(t, o->val, o->len);
	  t[o->len] = '\n';
	  t[o->len+1] = 0x0;
#if defined(__EMSCRIPTEN__)
	// octet safety buffer allows this: o->val = zmalloc(size +0x0f);
	EM_ASM_({Module.printErr(UTF8ToString($0))}, t);
#elif defined(__ANDROID__)
	__android_log_print(ANDROID_LOG_DEFAULT, "ZEN", "%s", t);
#elif defined(ARCH_CORTEX)
	write_to_console(t);
#else
	_zen_io_write(STDERR_FILENO, t, o->len+1);
#endif
	zfree(t);
  } else
	func(L, "printerr of an empty string");	
  END(0);
}

// print without an ending newline
static int zen_write (lua_State *L) {
  BEGIN();
  zenroom_t *Z = zen_get_context(L);
  char *failed_msg = NULL;
  const octet *o = o_arg(L, 1); SAFE_GOTO(o, "Could not allocate message to show");
  if (Z && Z->stdout_buf) {
	char *p = Z->stdout_buf+Z->stdout_pos;
	if (!zen_stdout_reserve(L, o->len + 1))
	  goto end;
	memcpy(p, o->val, o->len);
	Z->stdout_pos += o->len;
	Z->stdout_buf[Z->stdout_pos] = '\0';
  } else if(o) {
#ifdef __EMSCRIPTEN_
	o->val[o->len] = 0x0; // add string termination
	// octet safety buffer allows this: o->val = zmalloc(size +0x0f);
	EM_ASM_({Module.print(UTF8ToString($0))}, o->val);
#else
	_zen_io_write(STDOUT_FILENO, o->val, o->len);
#endif
  } else
	func(L, "write of an empty string");
end:
  o_free(L, o);
  if(failed_msg != NULL) {
	  lerror(L, "%s", failed_msg);
  }
  END(0);
}

int zen_log(lua_State *L, log_priority prio, const octet *o) {
  zenroom_t *Z = zen_get_context(L);
  if(!o) return 0;
#ifdef __ANDROID__
  char *t = calloc(o->len+1,sizeof(char));
  memcpy(t,o->val,o->len);
  t[o->len] = 0x0;
  __android_log_print(prio, "ZEN", "%s", t);
  zfree(t);
  return 0;
#endif
  size_t suffix_len = (Z && Z->logformat == LOG_JSON) ? 3 : 1;
  char prefix[5] = "     ";
  get_log_prefix(Z,prio,prefix);
  if (Z && Z->stderr_buf) {
	if (!zen_stderr_reserve(L, 5 + o->len + suffix_len + 1,
						 "No space left in error buffer")) {
	  return 1;
	}
	char *p = Z->stderr_buf+Z->stderr_pos;
	strncpy(p, prefix, 5);
	memcpy(p + 5, o->val, o->len);
	p += 5 + o->len;
	if(Z && Z->logformat == LOG_JSON) {
	  *p='"'; p++;
	  *p=','; p++;
	}
	*p='\n'; p++;
	*p='\0';
	Z->stderr_pos += 5 + o->len + suffix_len;
	Z->stderr_buf[Z->stderr_pos] = '\0';
  } else {
#if defined(__EMSCRIPTEN__)
	size_t msg_len = 5 + o->len + suffix_len;
	char *msg = zmalloc(msg_len + 1);
	if (!msg) return 1;
	memcpy(msg, prefix, 5);
	memcpy(msg + 5, o->val, o->len);
	char *p = msg + 5 + o->len;
	if(Z && Z->logformat == LOG_JSON) {
	  *p='"'; p++;
	  *p=','; p++;
	}
	*p='\n'; p++;
	*p='\0';
	EM_ASM_({Module.printErr(UTF8ToString($0))}, msg);
	zfree(msg);
#elif defined(ARCH_CORTEX)
	_zen_io_write(SEMIHOSTING_STDOUT_FILENO, prefix, 5);
	_zen_io_write(SEMIHOSTING_STDOUT_FILENO, o->val, o->len);
	if(Z && Z->logformat == LOG_JSON) {
	  _zen_io_write(SEMIHOSTING_STDOUT_FILENO, "\",", 2);
	}
	_zen_io_write(SEMIHOSTING_STDOUT_FILENO, "\n", 1);
#else
	_zen_io_write(STDERR_FILENO, prefix, 5);
	_zen_io_write(STDERR_FILENO, o->val, o->len);
	if(Z->logformat == LOG_JSON) {
	  _zen_io_write(STDERR_FILENO, "\",", 2);
	}
	_zen_io_write(STDERR_FILENO, "\n", 1);
#endif
  }
  return 0;
}

#define ZEN_PRINT(FUN_NAME, PRINT_FUN) \
	static int (FUN_NAME)(lua_State *L) { \
		BEGIN(); \
		const octet *o = o_arg(L, 1); SAFE(o, "Could not allocate message to show"); \
		PRINT_FUN; \
		o_free(L,o); \
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
