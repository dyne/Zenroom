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

#include <zenroom.h>
#include <lauxlib.h>

typedef struct zen_extension_t {
	const char         *name;
	const unsigned int *size;
	const char         *code;
} zen_extension_t;

void zen_add_function(lua_State *L,
                      lua_CFunction func,
                      const char *func_name);
void zen_add_class(lua_State *L, char *name,
                   const luaL_Reg *_class, const luaL_Reg *methods);

