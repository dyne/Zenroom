/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2020 Dyne.org foundation
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

#include <amcl.h>

// tracing wrappers for all C->Lua functions
#define BEGIN() trace(L, "vv begin %s",__func__)
#define END(n) trace(L, "^^ end %s",__func__); return(n)

#define THROW(ERR) \
	lerror(L, "fatal %s: %s", __func__, (ERR)); \
	lua_pushnil(L)

// REMEMBER: o_new and o_dup push a new object in lua's stack
octet* o_new(lua_State *L, const int size);

octet *o_dup(lua_State *L, octet *o);

// REMEMBER: o_arg returns a new allocated octet to be freed with o_free
octet* o_arg(lua_State *L, int n);

// These functions are internal and not exposed to lua's stack
// to make an octet visible to lua can be done using o_dup
octet *o_alloc(lua_State *L, int size);
void o_free(lua_State *L,octet *o);

void push_octet_to_hex_string(lua_State *L, octet *o);
void push_buffer_to_octet(lua_State *L, char *p, size_t len);
#endif

