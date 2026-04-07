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

#ifndef __ZEN_TIME_H__
#define __ZEN_TIME_H__

#include <stdint.h>

/* Conservative heuristic window used by TIME.detect_time_value(). */
#define AUTODETECTED_TIME_MIN 1500000000LL
#define AUTODETECTED_TIME_MAX 4102444800LL

/* Canonical TIME domain: signed 64-bit Unix seconds. */
typedef int64_t ztime_t;

/* Creates a fresh userdata-backed TIME value and pushes it onto the Lua stack. */
ztime_t* time_new(lua_State *L);

/* Clones an existing TIME value into fresh userdata and pushes the clone. */
ztime_t* time_dup(lua_State *L, ztime_t *c);

/* Returns a heap-owned TIME clone for userdata, strings, or numbers. */
ztime_t* time_arg(lua_State *L, int n);

/* Converts TIME to octet using the compatibility policy in zen_time.c. */
octet *new_octet_from_time(lua_State *L, ztime_t c);

#endif
