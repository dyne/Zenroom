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
#include <unistd.h>
#include <ctype.h>
#include <errno.h>

#include <mutt_sprintf.h>

#include <lauxlib.h>

#include <zenroom.h>
#include <zen_error.h>
#include <zen_octet.h>

#ifdef __ANDROID__
#include <android/log.h>
#endif

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

#include <zstd.h>

#if defined(ARCH_CORTEX)
extern int SEMIHOSTING_STDOUT_FILENO;
extern int write_to_console(const char* str);
#endif

static int zen_print (lua_State *L) {
  Z(L);
  octet *o = o_arg(L, 1); // it may be null (empty string)
  if (Z->stdout_buf) {
	char *p = Z->stdout_buf+Z->stdout_pos;
	if(!o) { *p='\n'; Z->stdout_pos++; return 0; }
	if (Z->stdout_pos+o->len+1 > Z->stdout_len)
	  zerror(L, "No space left in output buffer");
	memcpy(p, o->val, o->len);
	*(p + o->len) = '\n';
	Z->stdout_pos += o->len + 1;
  } else if(o) {
	o->val[o->len] = '\n'; // add newline
	o->val[o->len+1] = 0x0; // add string termination
	// octet safety buffer allows this: o->val = malloc(size +0x0f);
#ifdef __EMSCRIPTEN__
	EM_ASM_({Module.print(UTF8ToString($0))}, o->val);
#elseif ARCH_CORTEX
	write(SEMIHOSTING_STDOUT_FILENO, o->val, o->len+1);
#else
	write(STDOUT_FILENO, o->val, o->len+1);
#endif
  } else
	func(L, "print of an empty string");
  return 0;
}

void printerr(lua_State *L, octet *o) {
  Z(L);
  if (Z->stderr_buf) {
	char *p = Z->stderr_buf+Z->stderr_pos;
	if(!o) { *p='\n'; Z->stderr_pos++; return; }
	if (Z->stderr_pos+o->len+1 > Z->stderr_len)
	  zerror(L, "No space left in output buffer");
	memcpy(p, o->val, o->len);
	*(p + o->len) = '\n';
	Z->stderr_pos += o->len + 1;
  } else if(o) {
	o->val[o->len] = '\n';
	o->val[o->len+1] = 0x0; // add string termination
#ifdef __EMSCRIPTEN__
	// octet safety buffer allows this: o->val = malloc(size +0x0f);
	EM_ASM_({Module.print(UTF8ToString($0))}, o->val);
#elseif __ANDROID__
	__android_log_print(ANDROID_LOG_DEFAULT, "ZEN", "%s", o->val);
#elseif ARCH_CORTEX
	write_to_console(o->val);
#else
	write(STDERR_FILENO, o->val, o->len+1);
#endif
  } else
	func(L, "printerr of an empty string");	
  return;
}

// print without an ending newline
static int zen_write (lua_State *L) {
  Z(L);
  octet *o = o_arg(L, 1); // it may be null (empty string)
  if(!o) return 0;
  if (Z->stdout_buf) {
	char *p = Z->stderr_buf+Z->stderr_pos;
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
	write(STDOUT_FILENO, o->val, o->len);
#endif
  } else
	func(L, "write of an empty string");
  return 0;
}

int zen_log(lua_State *L, log_priority prio, octet *o) {
  Z(L);
  if(!o) return 0;
#ifdef __ANDROID__
  o->val[o->len] = 0x0;
  __android_log_print(prio, "ZEN", "%s", o->val);
  return 0;
#endif
  if (Z->stderr_buf
	  && Z->stderr_pos+o->len+5 > Z->stderr_len) {
	  zerror(L, "No space left in error buffer");
	  return 1;
  }
  char *p = o->val + o->len;
  int tlen = o->len;
  if(Z->logformat == JSON) {
	// JSON termination
	*p='"'; p++; *p=','; p++; tlen+=2;
  } // newline termination
  *p='\n'; p++; *p=0x0; p++; tlen+=2;
  char prefix[5] = "     ";
  get_log_prefix(Z,prio,prefix);
  if (Z->stderr_buf) {
	p = Z->stderr_buf+Z->stderr_pos;
	strncpy(p, prefix, 5);
	memcpy(p + 5, o->val, tlen);
	Z->stderr_pos += 5 + tlen;
  } else {
#ifdef __EMSCRIPTEN__
	EM_ASM_({Module.printErr(UTF8ToString($0))}, prefix);
	EM_ASM_({Module.printErr(UTF8ToString($0))}, o->val);
#elseif ARCH_CORTEX
	write(SEMIHOSTING_STDOUT_FILENO, prefix, 5);
	write(SEMIHOSTING_STDOUT_FILENO, o->val, tlen);
#else
	write(STDERR_FILENO, prefix, 5);
	write(STDERR_FILENO, o->val, tlen);
#endif
  }
  return 0;
}

// print to stderr without prefix with newline
static int zen_printerr(lua_State *L) {
  octet *o = o_arg(L, 1); // it may be null (empty string)
  printerr(L, o);
  return 0;
}

static int zen_warn (lua_State *L) {
  zen_log(L, LOG_WARN, o_arg(L, 1));
  return 0;
}

static int zen_act (lua_State *L) {
  zen_log(L, LOG_DEBUG, o_arg(L, 1));
  return 0;
}

static int zen_notice (lua_State *L) {
  zen_log(L, LOG_INFO, o_arg(L, 1));
  return 0;
}

static int zen_debug (lua_State *L) {
  zen_log(L, LOG_VERBOSE, o_arg(L, 1) );
  return 0;
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
  }
  return 1;
}

static int zen_random_seed(lua_State *L) {
  Z(L);
  octet *seed = o_arg(L, 1); SAFE(seed);
  if(seed->len <4) {
    lerror(L,"Random seed error: too small (%u bytes)",seed->len);
	return 0;
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
		  {"notice", zen_notice},
		  {"warn", zen_warn},
		  {"act", zen_act},
		  {"xxx", zen_debug},
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
