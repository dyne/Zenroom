/*
 * This file is part of zenroom
 * 
 * Copyright (C) 2017-2021 Dyne.org foundation
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

#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <lua.h>

// macro to obtain Z context from a lua_State
#define Z(l) zenroom_t *Z = NULL; if (l) { void *_zv; lua_getallocf(l, &_zv); Z = _zv; }

int lerror(lua_State *L, const char *fmt, ...);
// int zencode_traceback(lua_State *L);

void notice(void *L, const char *format, ...);
void func(void *L, const char *format, ...);
void zerror(void *L, const char *format, ...);
void act(void *L, const char *format, ...);
void warning(void *L, const char *format, ...);

// from stb_sprintf.h
int z_sprintf(char *buf, char const *fmt, ...);
int z_snprintf(char *buf, int count, char const *fmt, ...);
int z_vsprintf(char *buf, char const *fmt, va_list va);
int z_vsnprintf(char *buf, int count, char const *fmt, va_list va);

#define ERROR() zerror(0, "Error in %s",__func__)
#define SAFE(x) if(!x) lerror(L, "NULL variable in %s",__func__)

void set_debug(int lev);
int get_debug();
void set_color(int on);

// useful for debugging
#if DEBUG == 1
#define HERE() func(0, "-> %s()",__func__)
#define HEREs(s) func(0, "-> %s(%s)",__func__,s)
#define HEREp(p) func(0, "-> %s(%p)",__func__,p)
#define HEREn(n) func(0, "-> %s(%i)",__func__,n)
#define HEREc(c) func(0, "-> %s(%c)",__func__,c)
#define HEREoct(o) \
	func(0, "-> %s - octet %p (%i/%i)",__func__,o->val,o->len,o->max)
#define HEREecdh(e) \
	func(0, "--> %s - ecdh %p\n\tcurve[%s] type[%s]\n\t fieldsize[%i] hash[%i]\n\tpubkey[%p(%i/%i)] publen[%i]\n\tseckey[%p(%i/%i)] seclen[%i]",__func__, e, e->curve, e->type, e->fieldsize, e->hash, e->pubkey, e->pubkey?e->pubkey->len:0x0, e->pubkey?e->pubkey->max:0x0, e->publen, e->seckey, e->seckey?e->seckey->len:0x0, e->seckey?e->seckey->max:0x0, e->seclen)
#else
#define HERE() (void)__func__
#define HEREs(s) (void)__func__
#define HEREp(s) (void)__func__
#define HEREn(s) (void)__func__
#define HEREoct(o) (void)__func__
#define HEREecdh(o) (void)__func__
#endif

#endif
