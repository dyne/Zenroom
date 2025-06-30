/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2025 Dyne.org foundation
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

#ifndef __ZEN_OCTET_H__
#define __ZEN_OCTET_H__

#if defined(_WIN32)
#include <malloc.h>
#else
#include <stdlib.h>
#endif

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <amcl.h>
#include <hedley.h>

// REMEMBER: o_new and o_dup push a new object in lua's stack
HEDLEY_NON_NULL(1)
octet* o_new(lua_State *L, const int size);

HEDLEY_NON_NULL(1,2)
octet *o_dup(lua_State *L, const octet *o);

// REMEMBER: o_arg returns a new allocated octet to be freed with o_free
HEDLEY_NON_NULL(1)
const octet* o_arg(lua_State *L, int n);

HEDLEY_NON_NULL(1,2)
octet *o_push(lua_State *L, const char *buf, size_t len);

// These functions are internal and not exposed to lua's stack
// to make an octet visible to lua can be done using o_dup
HEDLEY_MALLOC
HEDLEY_NON_NULL(1)
octet *o_alloc(lua_State *L, int size);

HEDLEY_NON_NULL(1)
void o_free(lua_State *L, HEDLEY_NO_ESCAPE const octet *o);

void push_octet_to_hex_string(lua_State *L, octet *o);
void push_buffer_to_octet(lua_State *L, char *p, size_t len);
void push_string_to_octet(lua_State *L, char *p);

// all octet based types are forced to use our internal memory pool
extern void *ZMM;
extern void *sfpool_malloc (void *restrict opaque, const size_t size);
extern void  sfpool_free   (void *restrict opaque, void *ptr);
extern void *sfpool_realloc(void *restrict opaque, void *ptr, const size_t size);
#define malloc(size)       (ZMM?sfpool_malloc(ZMM, size):malloc(size))
#define free(ptr)          (ZMM?sfpool_free(ZMM, ptr):free(ptr))
#define realloc(ptr, size) (ZMM?sfpool_realloc(ZMM, ptr, size):realloc(ptr,size))

#endif

