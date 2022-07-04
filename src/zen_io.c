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
#include <unistd.h>
#include <ctype.h>
#include <errno.h>


#include <zenroom.h>
#include <zen_error.h>
#include <zen_octet.h>

#include <lauxlib.h>

#ifdef __ANDROID__
#include <android/log.h>
#endif

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#ifndef MAX_JSBUF
#define MAX_JSBUF 4096000 // 4MiB
#endif
#endif

#include <zstd.h>

#if defined(ARCH_CORTEX)
extern int SEMIHOSTING_STDOUT_FILENO;
extern int write_to_console(const char* str);
#endif

int zen_write_err_va(zenroom_t *Z, const char *fmt, va_list va) {
	int res = 0;
#ifdef __ANDROID__
	res = __android_log_vprint(ANDROID_LOG_DEBUG, "ZEN", fmt, va);
#elif defined(ARCH_CORTEX)
	char buffer[MAX_STRING] = {0};
	vsnprintf(buffer, MAX_STRING, fmt, va);
	res = write_to_console(buffer);
#else
	if(!Z) res = vfprintf(stderr,fmt,va); // no init yet, print to stderr
	if(!res && Z->stderr_buf) { // print to configured buffer
		if(Z->stderr_full) {
			zerror(Z->lua, "Error buffer full, log message lost");
			return(0);
		}
		size_t max = Z->stderr_len - Z->stderr_pos;
		res = (*Z->vsnprintf)
			(Z->stderr_buf + Z->stderr_pos, // buffer start
			 Z->stderr_len - Z->stderr_pos,  // length max
			 fmt, va);
		if(res < 0) {

			zerror(Z->lua, "Fatal error writing error buffer: %s", strerror(errno));
			Z->exitcode = ERR_GENERIC;
			return(Z->exitcode);

		}
		if(res > (int)max) {
			zerror(Z->lua, "Error buffer too small, log truncated: %u bytes (max %u)", res, max);
			Z->stderr_full = 1;
			Z->stderr_pos += max;
		} else {
			Z->stderr_pos += res;
		}
	}
# ifdef __EMSCRIPTEN__
	char s[MAX_JSBUF];
	vsprintf(s,fmt,va);
	EM_ASM_({Module.printErr(UTF8ToString($0))}, s);
# else
	if(!res) res = vfprintf(stderr,fmt,va); // fallback no configured buffer
# endif
#endif
	return(res);
}

int zen_write_out_va(zenroom_t *Z, const char *fmt, va_list va) {
	int res = 0;
	if(!Z) res = vfprintf(stdout,fmt,va); // no init yet, print to stdout
	if(!res && Z->stdout_buf) { // print to configured buffer
		if(Z->stdout_full) {
			zerror(Z->lua, "Output buffer full, result data lost");
			return(0);
		}
		size_t max = Z->stdout_len - Z->stdout_pos;
		res = (*Z->vsnprintf)
			(Z->stdout_buf + Z->stdout_pos, // buffer start
			 Z->stdout_len - Z->stdout_pos,  // length max
			 fmt, va);
		if(res < 0) {

			zerror(Z->lua, "Fatal error writing output buffer: %s", strerror(errno));
			Z->exitcode = ERR_GENERIC;
			return(Z->exitcode);

		}
		if(res > (int)max) {
			zerror(Z->lua, "Output buffer too small, data truncated: %u bytes (max %u)", res, max);
			Z->stdout_full = 1;
			Z->stdout_pos += max;
		} else {
			Z->stdout_pos += res;
		}
	}
	if(!res) res = vfprintf(stdout,fmt,va); // fallback no configured buffer
	return(res);
	// size_t len = 0;
	// if(!Z) len = vfprintf(stdout,fmt,va);
	// if(!len && Z->stdout_buf) {
	// 	char *out = Z->stdout_buf;
	// 	len = (*Z->vsnprintf)(out+Z->stdout_pos,
	// 	                  Z->stdout_len-Z->stdout_pos,
	// 	                  fmt, va);
	// 	Z->stdout_pos+=len;
	// }
	// if(!len) len = vfprintf(stdout,fmt,va);
	// return len;
}

int zen_write_err(zenroom_t *Z, const char *fmt, ...) {
// #ifdef __ANDROID__
// 	// __android_log_print(ANDROID_LOG_VERBOSE, "KZK", "%s -- %s", pfx, msg);
// 	// __android_log_print(ANDROID_LOG_VERBOSE, "KZK", fmt, va); // TODO: test
// #endif
	va_list arg;
	size_t len;
	va_start(arg,fmt);
	len = zen_write_err_va(Z, fmt,arg);
	va_end(arg);
	return len;
}

int zen_write_out(zenroom_t *Z, const char *fmt, ...) {
// #ifdef __ANDROID__
// 	// __android_log_print(ANDROID_LOG_VERBOSE, "KZK", "%s -- %s", pfx, msg);
// 	// __android_log_print(ANDROID_LOG_VERBOSE, "KZK", fmt, va); // TODO: test
// #endif
	va_list arg;
	size_t len;
	va_start(arg,fmt);
	len = zen_write_out_va(Z, fmt,arg);
	va_end(arg);
	return len;
}

// passes the string to be printed through the 'tostring'
// meta-function configured in Lua, taking care of conversions
const char *lua_print_format(lua_State *L,
		int pos, size_t *len) {
	const char *s;
	lua_pushvalue(L, -1);  /* function to be called */
	lua_pushvalue(L, pos);   /* value to print */
	lua_call(L, 1, 1);
	s = lua_tolstring(L, -1, len);  /* get result */
	if (s == NULL)
		luaL_error(L, LUA_QL("tostring") " must return a string to "
				LUA_QL("print"));
	return s;
}

// retrieves output buffer if configured in _Z and append to that the
// output without exceeding its length. Return 1 if output buffer was
// configured so calling function can decide if to proceed with other
// prints (stdout) or not
static int lua_print_stdout_tobuf(lua_State *L, char newline) {
	Z(L);
	if(Z->stdout_buf && (Z->stdout_pos < Z->stdout_len)) {
		int i;
		int n = lua_gettop(L);  /* number of arguments */
		size_t len;
		const char *s;
		lua_getglobal(L, "tostring");
		for (i=1; i<=n; i++) {
			s = lua_print_format(L, i, &len);
			if(i>1) 
				zen_write_out(Z, "\t%s%c",s,newline);
			else
				zen_write_out(Z, "%s%c",s,newline);
			lua_pop(L, 1);
		}
		return 1;
	}
	return 0;
}

static int lua_print_stderr_tobuf(lua_State *L, char newline) {
	Z(L);
	if(Z->stderr_buf && (Z->stderr_pos < Z->stderr_len)) {
		int i;
		int n = lua_gettop(L);  /* number of arguments */
		size_t len;
		const char *s;
		lua_getglobal(L, "tostring");
		for (i=1; i<=n; i++) {
			s = lua_print_format(L, i, &len);
			if(i>1) 
				zen_write_err(Z, "\t%s%c",s,newline);
			else
				zen_write_err(Z, "%s%c",s,newline);
			lua_pop(L, 1);
		}
		return 1;
	}
	return 0;
}

// optimized printing functions for wasm
// these are about double the speed than the normal stdout/stderr wrapper
#ifdef __EMSCRIPTEN__
static char out[MAX_JSBUF];
static int zen_print (lua_State *L) {
	size_t pos = 0;
	int nargs = lua_gettop(L) +1;
	int arg = 0;
	char *s;
	for (; nargs--; arg++) {
		size_t len;
		s = lua_tolstring(L, arg, &len);
	}
	EM_ASM_({Module.print(UTF8ToString($0))}, s);
	return 0;
}
static int zen_printerr (lua_State *L) {
	size_t pos = 0;
	int nargs = lua_gettop(L) +1;
	int arg = 0;
	char *s;
	for (; nargs--; arg++) {
		size_t len;
		s = lua_tolstring(L, arg, &len);
	}
	EM_ASM_({Module.printErr(UTF8ToString($0))}, s);
	return 0;
}

static int zen_write (lua_State *L) {
	size_t pos = 0;
	int nargs = lua_gettop(L) +1;
	int arg = 0;
	char *s;
	for (; nargs--; arg++) {
		size_t len;
		const char *s = lua_tolstring(L, arg, &len);
	}
	EM_ASM_({Module.print(UTF8ToString($0))}, s);
	lua_pushboolean(L, 1);
	return 1;
}

// static int zen_error (lua_State *L) {
// 	size_t pos = 0;
// 	size_t len = 0;
// 	int n = lua_gettop(L);  /* number of arguments */
// 	int i;
// 	lua_getglobal(L, "tostring");
// 	out[0] = '['; out[1] = '!';	out[2] = ']'; out[3] = ' ';	pos = 4;
// 	for (i=1; i<=n; i++) {
// 		const char *s = lua_print_format(L, i, &len);
// 		if (i>1) { out[pos]='\t'; pos++; }
// 		(*Z->snprintf)(out+pos,MAX_JSBUF-pos,"%s",s);
// 		pos+=len;
// 		lua_pop(L, 1);  /* pop result */
// 	}
// 	EM_ASM_({Module.printErr(UTF8ToString($0))}, out);
// 	return 0;
// }

static int zen_warn (lua_State *L) {
	size_t pos = 0;
	size_t len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i;
	Z(L);
	lua_getglobal(L, "tostring");
	out[0] = '['; out[1] = 'W';	out[2] = ']'; out[3] = ' ';	pos = 4;
	for (i=1; i<=n; i++) {
		const char *s = lua_print_format(L, i, &len);
		if (i>1) { out[pos]='\t'; pos++; }
		(*Z->snprintf)(out+pos,MAX_JSBUF-pos,"%s\n",s);
		pos+=len;
		lua_pop(L, 1);  /* pop result */
	}
	EM_ASM_({Module.printErr(UTF8ToString($0))}, out);
	return 0;
}

static int zen_act (lua_State *L) {
	size_t pos = 0;
	size_t len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i;
	Z(L);
	lua_getglobal(L, "tostring");
	out[0] = ' '; out[1] = '.';	out[2] = ' '; out[3] = ' ';	pos = 4;
	for (i=1; i<=n; i++) {
		const char *s = lua_print_format(L, i, &len);
		if (i>1) { out[pos]='\t'; pos++; }
		(*Z->snprintf)(out+pos,MAX_JSBUF-pos,"%s\n",s);
		pos+=len;
		lua_pop(L, 1);  /* pop result */
	}
	EM_ASM_({Module.printErr(UTF8ToString($0))}, out);
	return 0;
}

#elif defined(ARCH_CORTEX)

static int zen_print (lua_State *L) {
	if( lua_print_stdout_tobuf(L,'\n') ) return 0;

	int status = 1;
	size_t len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i, w;
	lua_getglobal(L, "tostring");
	for (i=1; i<=n; i++) {
		const char *s = lua_print_format(L, i, &len);
		if(i>1)
            w = write(SEMIHOSTING_STDOUT_FILENO, "\t", 1);
        (void)w;
		status = status &&
			(write(SEMIHOSTING_STDOUT_FILENO, s,  len) == (int)len);
		lua_pop(L, 1);  /* pop result */
	}
	w = write(SEMIHOSTING_STDOUT_FILENO,"\n",sizeof(char));
    (void)w;
	return 0;
}

// print to stderr without raising errors
static int zen_printerr(lua_State *L) {
	if( lua_print_stderr_tobuf(L,'\n') ) return 0;

	int status = 1;
	size_t len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i, w;
	lua_getglobal(L, "tostring");
	for (i=1; i<=n; i++) {
		const char *s = lua_print_format(L, i, &len);
		if(i>1)
			w = write_to_console("\t");
		(void)w;
		status = status &&
			(write_to_console(s) == (int)len);
		lua_pop(L, 1);  /* pop result */
	}
	w = write_to_console("\n");
	(void)w;
	return 0;
}

// print without an ending newline
static int zen_write (lua_State *L) {
	if( lua_print_stdout_tobuf(L,' ') ) return 0;
	octet *o = o_arg(L, 1); SAFE(o);
	short res;
	int w;
	w = write(SEMIHOSTING_STDOUT_FILENO, o->val, o->len);
	res = (w == o->len) ? 0 : 1;
	return(res);
}

static int zen_warn (lua_State *L) {
	if( lua_print_stderr_tobuf(L,'\n') ) return 0;
	int status = 1;
	size_t len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i, w;
	lua_getglobal(L, "tostring");
	w = write_to_console("[W] ");
	(void)w;
	for (i=1; i<=n; i++) {
		const char *s = lua_print_format(L, i, &len);
		if(i>1)
			w = write_to_console("\t");
		(void)w;
		status = status &&
			(write_to_console(s) == (int)len);
		lua_pop(L, 1);  /* pop result */
	}
	w = write_to_console("\n");
	(void)w;
	return 0;
}

static int zen_act (lua_State *L) {
	if( lua_print_stderr_tobuf(L,'\n') ) return 0;
	int status = 1;
	size_t len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i, w;
	lua_getglobal(L, "tostring");
	w = write_to_console(" .  ");
	(void)w;
	for (i=1; i<=n; i++) {
		const char *s = lua_print_format(L, i, &len);
		if(i>1)
			w = write_to_console("\t");
		(void)w;
		status = status &&
			(write_to_console(s));
		lua_pop(L, 1);  /* pop result */
	}
	w = write_to_console("\n");
	(void)w;
	return 0;
}

#else

static int zen_print (lua_State *L) {
	if( lua_print_stdout_tobuf(L,'\n') ) return 0;

	int status = 1;
	size_t len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i, w;
	lua_getglobal(L, "tostring");
	for (i=1; i<=n; i++) {
		const char *s = lua_print_format(L, i, &len);
		if(i>1)
            w = write(STDOUT_FILENO, "\t", 1);
        (void)w;
		status = status &&
			(write(STDOUT_FILENO, s,  len) == (int)len);
		lua_pop(L, 1);  /* pop result */
	}
	w = write(STDOUT_FILENO,"\n",sizeof(char));
    (void)w;
	return 0;
}

// print to stderr without raising errors
static int zen_printerr(lua_State *L) {
	if( lua_print_stderr_tobuf(L,'\n') ) return 0;

	int status = 1;
	size_t len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i, w;
	lua_getglobal(L, "tostring");
	for (i=1; i<=n; i++) {
		const char *s = lua_print_format(L, i, &len);
		if(i>1)
			w = write(STDERR_FILENO, "\t", 1);
		(void)w;
		status = status &&
			(write(STDERR_FILENO, s,  len) == (int)len);
		lua_pop(L, 1);  /* pop result */
	}
	w = write(STDERR_FILENO,"\n",sizeof(char));
	(void)w;
	return 0;
}

// print without an ending newline
static int zen_write (lua_State *L) {
	if( lua_print_stdout_tobuf(L,' ') ) return 0;
	octet *o = o_arg(L, 1); SAFE(o);
	short res;
	int w;
	w = write(STDOUT_FILENO, o->val, o->len);
	res = (w == o->len) ? 0 : 1;
	return(res);
}

static int zen_warn (lua_State *L) {
	if( lua_print_stderr_tobuf(L,'\n') ) return 0;
	int status = 1;
	size_t len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i, w;
	lua_getglobal(L, "tostring");
	w = write(STDERR_FILENO, "[W] ",4* sizeof(char));
	(void)w;
	for (i=1; i<=n; i++) {
		const char *s = lua_print_format(L, i, &len);
		if(i>1)
			w = write(STDERR_FILENO, "\t",sizeof(char));
		(void)w;
		status = status &&
			(write(STDERR_FILENO, s, len) == (int)len);
		lua_pop(L, 1);  /* pop result */
	}
	w = write(STDERR_FILENO,"\n",sizeof(char));
	(void)w;
	return 0;
}

static int zen_act (lua_State *L) {
	if( lua_print_stderr_tobuf(L,'\n') ) return 0;
	int status = 1;
	size_t len = 0;
	int n = lua_gettop(L);  /* number of arguments */
	int i, w;
	lua_getglobal(L, "tostring");
	w = write(STDERR_FILENO, " .  ",4* sizeof(char));
	(void)w;
	for (i=1; i<=n; i++) {
		const char *s = lua_print_format(L, i, &len);
		if(i>1)
			w = write(STDERR_FILENO, "\t",sizeof(char));
		(void)w;
		status = status &&
			(write(STDERR_FILENO, s, len) == (int)len);
		lua_pop(L, 1);  /* pop result */
	}
	w = write(STDERR_FILENO,"\n",sizeof(char));
	(void)w;
	return 0;
}

#endif


extern void lua_fatal(lua_State *L);
static int zen_fatal(lua_State *L) {
	// zencode_traceback(L);
	lua_fatal(L);
	return 0; // unreachable code
}

int zen_zstd_compress(lua_State *L) {
  octet *dst, *src;
  Z(L);
  if(!Z->zstd_c)
    Z->zstd_c = ZSTD_createCCtx();
  src = o_arg(L, 1); SAFE(src);
  dst = o_new(L, ZSTD_compressBound(src->len));
  dst->len = ZSTD_compressCCtx(Z->zstd_c,
			       dst->val, dst->max,
			       src->val, src->len,
			       ZSTD_maxCLevel());
  func(L, "octet compressed: %u -> %u",src->len, dst->len);
  if (ZSTD_isError(dst->len)) {
    fprintf(stderr,"ZSTD error: %s\n",ZSTD_getErrorName(dst->len));
    zen_fatal(L);
  }
  return 1;
}

int zen_zstd_decompress(lua_State *L) {
  octet *src, *dst;
  Z(L);
  if(!Z->zstd_d)
    Z->zstd_d = ZSTD_createDCtx();
  src = o_arg(L, 1); SAFE(src);
  dst = o_new(L, src->len * 3); // assuming max bound is *3
  SAFE(dst);
  func(L, "decompressing octet: %u", src->len);
  dst->len = ZSTD_decompressDCtx(Z->zstd_d,
		      dst->val, dst->max,
		      src->val, src->len);
  func(L, "octet uncompressed: %u -> %u",src->len, dst->len);
  if (ZSTD_isError(dst->len)) {
    fprintf(stderr,"ZSTD error: %s\n",ZSTD_getErrorName(dst->len));
    zen_fatal(L);
  }
  return 1;
}

static int zen_random_seed(lua_State *L) {
  Z(L);
  octet *seed = o_arg(L, 1); SAFE(seed);
  if(seed->len <4) {
    fprintf(stderr,"Random seed error: too small (%u bytes)\n",seed->len);
    zen_fatal(L);
  }
  AMCL_(RAND_seed)(Z->random_generator, seed->len, seed->val);
  // fast-forward to runtime_random (256 bytes) and 4 bytes lua
  octet *rr = o_new(L, PRNG_PREROLL); SAFE(rr);
  for(register int i=0;i<PRNG_PREROLL;i++)
    rr->val[i] = RAND_byte(Z->random_generator);
  rr->len = PRNG_PREROLL;
  // plus 4 bytes used by Lua init
  RAND_byte(Z->random_generator);
  RAND_byte(Z->random_generator);
  RAND_byte(Z->random_generator);
  RAND_byte(Z->random_generator);
  // return "runtime random" fingerprint
  return 1;
}
void zen_add_io(lua_State *L) {
	// override print() and io.write()
	static const struct luaL_Reg custom_print [] =
		{ {"print", zen_print},
		  {"printerr", zen_printerr},
		  {"write", zen_write},
//		  {"error", zen_error},
		  {"zen_fatal", zen_fatal},
		  {"warn", zen_warn},
		  {"act", zen_act},
		  {"compress", zen_zstd_compress},
		  {"decompress", zen_zstd_decompress},
		  {"random_seed", zen_random_seed},
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
