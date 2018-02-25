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

#include <jutils.h>
#include <zenroom.h>
#include <linenoise.h>
#include <luasandbox.h>
#include <luasandbox/lauxlib.h>

extern const struct luaL_Reg luazen;
extern const struct luaL_Reg bit_funcs;
extern const struct luaL_Reg base_funcs;
extern const struct luaL_Reg mathlib;

#define CMATCH(n) { \
	const struct luaL_Reg *lib = &n; \
	for(;lib->func;lib++) { \
		const char *sel = lib->name; \
		if(strncmp(sel,buf,len) ==0) { \
			linenoiseAddCompletion(lc, sel); \
		} } }

void completion(const char *buf, linenoiseCompletions *lc) {
	int len = strlen(buf);
	len = (len>64)?64:len;

	CMATCH(luazen);
	CMATCH(bit_funcs);
	CMATCH(base_funcs);
	CMATCH(mathlib);
}
