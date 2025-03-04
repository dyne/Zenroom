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

#ifndef __ZEN_BIG_H__
#define __ZEN_BIG_H__

#include <zen_octet.h>
#include <zen_big_factory.h>

#define BIG_NEGATIVE -1
#define BIG_POSITIVE 1
#define BIG_OPPOSITE(SIGN) (-(SIGN))
#define BIG_MULSIGN(A, B) ((A) * (B))

typedef struct {
	char zencode_positive;
	int  len; // modbytes
	int  chunksize;
	chunk *val;
	chunk *dval;
	// BIG  val;
	// DBIG dval;
	short doublesize;
} big;

// new or dup already push the object in LUA's stack
HEDLEY_WARN_UNUSED_RESULT
HEDLEY_NON_NULL(1)
big* big_new(lua_State *L);

HEDLEY_WARN_UNUSED_RESULT
HEDLEY_NON_NULL(1,2)
big* big_dup(lua_State *L, big *c);

HEDLEY_NON_NULL(1)
void big_free(lua_State *L, HEDLEY_NO_ESCAPE big *c);

HEDLEY_WARN_UNUSED_RESULT
HEDLEY_NON_NULL(1)
big* big_arg(lua_State *L, int n);

// internal initialisation of double or single big
HEDLEY_NON_NULL(1,2)
int big_init(lua_State *L,big *n);
HEDLEY_NON_NULL(1,2)
int dbig_init(lua_State *L,big *n);

// internal conversion from d/big to octet
HEDLEY_WARN_UNUSED_RESULT
octet *new_octet_from_big(lua_State *L, big *c);

#endif
