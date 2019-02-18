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

#ifndef __ZEN_OCTET_H__
#define __ZEN_OCTET_H__

#include <amcl.h>

// REMEMBER: o_new and o_dup push a new object in lua's stack
octet* o_new(lua_State *L, const int size);

octet *o_dup(lua_State *L, octet *o);

octet* o_arg(lua_State *L,int n);

// internal use
// TODO: inverted function signature, see https://github.com/milagro-crypto/milagro-crypto-c/issues/291
#define push_octet_to_hex_string(o)	  \
	{ \
		int odlen = o->len<<1; \
		char *s = zen_memory_alloc(odlen+1); \
		int i; unsigned char ch; \
		for (i=0; i<o->len; i++) { \
		ch=o->val[i]; sprintf(&s[i<<1],"%02x", ch); } \
		s[odlen] = '\0'; \
		lua_pushstring(L,s); \
		zen_memory_free(s); \
	}

#endif
