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
#include <sfpool.h>

/* Creates a fresh userdata-backed OCTET and pushes it onto the Lua stack. */
HEDLEY_NON_NULL(1)
octet* o_new(lua_State *L, const int size);

/* Clones an OCTET into fresh userdata and pushes the clone. */
HEDLEY_NON_NULL(1,2)
octet *o_dup(lua_State *L, const octet *o);

/* Returns a heap-owned OCTET clone; callers release it with o_free(). */
HEDLEY_NON_NULL(1)
const octet* o_arg(lua_State *L, int n);

HEDLEY_NON_NULL(1,2)
octet *o_push(lua_State *L, const char *buf, size_t len);

/* Internal helper that allocates a heap-owned OCTET outside the Lua stack. */
HEDLEY_MALLOC
HEDLEY_NON_NULL(1)
octet *o_alloc(lua_State *L, int size);

/* Releases a heap-owned OCTET clone or internal buffer allocated via o_alloc(). */
HEDLEY_NON_NULL(1)
void o_free(lua_State *L, HEDLEY_NO_ESCAPE const octet *o);

void push_octet_to_hex_string(lua_State *L, octet *o);
void push_buffer_to_octet(lua_State *L, char *p, size_t len);
void push_string_to_octet(lua_State *L, char *p);

/* Explicit pool-backed wrappers for modules that used to inherit allocator
 * policy from this header. */
extern void *ZMM;

static inline void *zmalloc(size_t size) {
	return ZMM ? sfpool_malloc(ZMM, size) : malloc(size);
}

static inline void zfree(void *ptr) {
	if(ZMM) {
		sfpool_free(ZMM, ptr);
		return;
	}
	free(ptr);
}

static inline void *zrealloc(void *ptr, size_t size) {
	return ZMM ? sfpool_realloc(ZMM, ptr, size) : realloc(ptr, size);
}

#endif
