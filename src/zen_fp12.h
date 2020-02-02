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

#ifndef __ZEN_FP12_H__
#define __ZEN_FP12_H__

#include <zen_big.h>

typedef struct {
	char name[16];
	int  len;
	int  chunk;
	FP12 val;
} fp12;

// new or dup already push the object in LUA's stack
fp12* fp12_new(lua_State *L);

fp12* fp12_dup(lua_State *L, fp12 *c);

fp12* fp12_arg(lua_State *L, int n);

#endif
