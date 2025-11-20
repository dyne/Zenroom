/*
 * This file is part of zenroom
 *
 * Copyright (C) 2025 Dyne.org foundation
 * designed, written and maintained by Denis Roio
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License v3.0
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * Along with this program you should have received a copy of the
 * GNU Affero General Public License v3.0
 * If not, see http://www.gnu.org/licenses/agpl.txt
 */

#include <lua_functions.h>
#include <zen_error.h>
#include <zen_octet.h>
#include <varint.h>

static int read_u64(lua_State *L) {
	BEGIN();
	const octet *oct = o_arg(L, 1); SAFE(oct, ALLOCATE_OCT_ERR);
	uint64_t dst;
	varint_read_u64(oct->val,oct->len,&dst);
	o_free(L,oct);
	lua_pushnumber(L,dst);
	octet *o = o_new(L, 4); SAFE(o, CREATE_OCT_ERR);
	// big endian output: most significant byte first
	for (int i = 0; i < 4; i++)
		o->val[i] = (dst >> ((3 - i) * 8)) & 0xFF;
	o->len = 4;
	END(2);
}

static int read_i64(lua_State *L) {
	BEGIN();
	const octet *oct = o_arg(L, 1); SAFE(oct, ALLOCATE_OCT_ERR);
	int64_t dst;
	varint_read_i64(oct->val,oct->len,&dst);
	o_free(L,oct);
	lua_pushnumber(L,dst);
	octet *o = o_new(L, 4); SAFE(o, CREATE_OCT_ERR);
	// big endian output: most significant byte first
	for (int i = 0; i < 4; i++)
		o->val[i] = (dst >> ((3 - i) * 8)) & 0xFF;
	o->len = 4;
	END(2);
}

int luaopen_varint(lua_State *L) {
	(void)L;
	const struct luaL_Reg varint_class[] = {
		{"read_u64", read_u64},
		{"read_i64", read_i64},
		{NULL, NULL}};
	const struct luaL_Reg varint_methods[] = {
		{NULL, NULL}};
	zen_add_class(L, "varint", varint_class, varint_methods);
	return 1;
}
