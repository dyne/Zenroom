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

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <errno.h>

#if defined(_WIN32)
/* Windows */
# include <windows.h>
#include <intrin.h>
#include <malloc.h>
#endif

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <jutils.h>
#include <zenroom.h>



int lerror(lua_State *L, const char *fmt, ...) {
	va_list argp;
	va_start(argp, fmt);
	error(0,fmt,argp);
	luaL_where(L, 1);
	lua_pushvfstring(L, fmt, argp);
	va_end(argp);
	lua_concat(L, 2);
	return lua_error(L);
}

// #define UMM 2
// #define MEMMANAGER UMM
// extern void *zen_memory_alloc(size_t size);
// // our own LUA aware memory allocation function
// void *zalloc(lua_State *L, size_t size) {
// 	if(!size) {
// 		lerror(L, "zero length allocation.");
// 		return NULL; }
// 	void *mem;
// #if MEMMANAGER == UMM
// 	mem = zen_memory_alloc(size);
// #else // fallback to standard libc posix memalign
// # if defined(_WIN32)
// 	mem = __mingw_aligned_malloc(size, 16);
// 	if(!mem) {
// 		lerror(L, "error in memory allocation.");
// 		return NULL; }
// # else
// 	int res;
// 	res = posix_memalign(&mem, 16, size);
// 	if(res == ENOMEM) {
// 		lerror(L, "insufficient memory to allocate %u bytes.", size);
// 		return NULL; }
// 	if(res == EINVAL) {
// 		lerror(L, "invalid memory alignment at 16 bytes.");
// 		return NULL; }
// # endif
// #endif
// 	return(mem);
// }
