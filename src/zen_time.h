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

#ifndef __ZEN_TIME_H__
#define __ZEN_TIME_H__

#define AUTODETECTED_TIME_MIN 1500000000
#define AUTODETECTED_TIME_MAX 2000000000

typedef int ztime_t;

// new or dup already push the object in LUA's stack
ztime_t* time_new(lua_State *L);

ztime_t* time_dup(lua_State *L, ztime_t *c);

ztime_t* type_arg(lua_State *L, int n);

// internal conversion from float to octet
octet *new_octet_from_time(lua_State *L, ztime_t c);

#endif

