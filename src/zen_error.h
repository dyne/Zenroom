/*
 * This file is part of zenroom
 *
 * Copyright (C) 2017-2025 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License v3.0
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * Along with this program you should have received a copy of the
 * GNU Affero General Public License v3.0
 * If not, see http://www.gnu.org/licenses/agpl.txt
 *
 * Last modified by Denis Roio
 * on Tuesday, 27th July 2021
 */

#ifndef __ZEN_ERROR_H__
#define __ZEN_ERROR_H__

#include <string.h>
#include <stdarg.h>
#include <hedley.h>

// macro to obtain Z context from a lua_State
// #define Z(l) zenroom_t *Z; lua_getallocf(l, (void**)&Z)
#define Z(l) zenroom_t *Z = ZEN

// tracing wrappers for all C->Lua functions
#define BEGIN() trace(L, "vv begin %s",__func__)
#define END(n) trace(L, "^^ end %s",__func__); return(n)

#define THROW(ERR) \
	lerror(L, "fatal %s: %s", __func__, (ERR)); \
	lua_pushnil(L)

// same as Android
typedef enum log_priority {
    LOG_UNKNOWN = 0,
    LOG_DEFAULT,
    LOG_VERBOSE,
    LOG_DEBUG,
    LOG_INFO,
    LOG_WARN,
    LOG_ERROR,
    LOG_FATAL,
    LOG_SILENT,
} log_priority;
#define LOG_DEFAULT " .   "

void get_log_prefix(void *Z, log_priority prio, char dest[5]);

// context free print and error messages
HEDLEY_PRINTF_FORMAT(1,2)
void _out(const char *fmt, ...);
HEDLEY_PRINTF_FORMAT(1,2)
void _err(const char *fmt, ...);
// context free results
int OK(void);
int FAIL(void);

// lua context error message
HEDLEY_PRINTF_FORMAT(2,3)
HEDLEY_NO_RETURN
void lerror(void *L, const char *fmt, ...);

HEDLEY_PRINTF_FORMAT(2,3)
int notice(void *L, const char *format, ...); // INFO
HEDLEY_PRINTF_FORMAT(2,3)
int func(void *L, const char *format, ...); // VERBOSE
HEDLEY_PRINTF_FORMAT(2,3)
int trace(void *L, const char *format, ...); // TRACE (VERY VERBOSE)
HEDLEY_PRINTF_FORMAT(2,3)
int zerror(void *L, const char *format, ...); // ERROR
HEDLEY_PRINTF_FORMAT(2,3)
int act(void *L, const char *format, ...); // DEBUG
HEDLEY_PRINTF_FORMAT(2,3)
int warning(void *L, const char *format, ...); // WARN
int hexdump(void *L, const char *src, size_t len); // DEBUG hex sequence

void json_start(void *L);
void json_end(void *L);

// #define SAFE(x) HEDLEY_REQUIRE(x != NULL)
// if(!x) lerror(L, "NULL variable in %s",__func__)

// useful for debugging
#if DEBUG == 1
#define HERE()   _err( "-> %s()\n",__func__)
#define HEREs(s) _err( "-> %s(%s)\n",__func__,s)
#define HEREp(p) _err( "-> %s(%p)\n",__func__,p)
#define HEREn(n) _err( "-> %s(%i)\n",__func__,n)
#define HEREc(c) _err( "-> %s(%c)\n",__func__,c)
#define HEREoct(o) \
	_err( "-> %s - octet %p (%i/%i) ref:%i\n",__func__,o->val,o->len,o->max,o->ref)
#define HEREecp(e) \
	_err( "-> %s - ecp %p ref:%i\n",__func__,o->val,o->ref)
#define HEREecdh(e) \
	_err( "--> %s - ecdh %p\n\tcurve[%s] type[%s]\n\t fieldsize[%i] hash[%i]\n\tpubkey[%p(%i/%i)] publen[%i]\n\tseckey[%p(%i/%i)] seclen[%i]\m",__func__, e, e->curve, e->type, e->fieldsize, e->hash, e->pubkey, e->pubkey?e->pubkey->len:0x0, e->pubkey?e->pubkey->max:0x0, e->publen, e->seckey, e->seckey?e->seckey->len:0x0, e->seckey?e->seckey->max:0x0, e->seclen)
#define HEREhex(b, len) \
  char *dst = malloc((len<<1)+2); buf2hex(dst, b, len); \
  dst[(len<<1)] = 0x0; _err("%s\n",dst); free(dst);
#else
#define HERE() (void)__func__
#define HEREs(s) (void)__func__
#define HEREp(s) (void)__func__
#define HEREn(s) (void)__func__
#define HEREoct(o) (void)__func__
#define HEREecdh(o) (void)__func__
#define HEREhex(b,len) (void)__func__
#endif

#endif
