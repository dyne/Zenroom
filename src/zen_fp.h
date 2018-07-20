/*  Zenroom (DECODE project)
 *
 *  (c) Copyright 2017-2018 Dyne.org foundation
 *  designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This source code is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Public License as published
 * by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 *
 * This source code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * Please refer to the GNU Public License for more details.
 *
 * You should have received a copy of the GNU Public License along with
 * this source code; if not, write to:
 * Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#ifndef __ZEN_FP_H__
#define __ZEN_FP_H__

#define BIGSIZE 384
#include <zen_big.h>

typedef struct {
	char name[16];
	int  len;
	int  chunk;
	FP  val;
} fp;

// new or dup already push the object in LUA's stack
fp* fp_new(lua_State *L);

fp* fp_dup(lua_State *L, fp *c);

fp* fp_arg(lua_State *L, int n);

#endif
