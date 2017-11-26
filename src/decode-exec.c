/*  Lua based DECODE VM
 *
 *  (c) Copyright 2017 Dyne.org foundation
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <jutils.h>

#include <luasandbox.h>
#include <luasandbox/util/util.h>
#include <luasandbox/lauxlib.h>

#define CONF "decode-exec.conf"

extern const struct luaL_Reg luanachalib;

// from timing.c
// extern int set_hook(lua_State *L);

// void log_debug(lua_State *l, lua_Debug *d) {
// 	error("%s\n%s\n%s",d->name, d->namewhat, d->short_src);
// }

void logger(void *context, const char *component,
                   int level, const char *fmt, ...) {
	(void)context;
	va_list args;
	// fprintf(stderr, "%lld [%d] %s ", (long long)time(NULL), level,
	//         component ? component : "unnamed");
	va_start(args, fmt);
	vfprintf(stderr, fmt, args);
	va_end(args);
	fwrite("\n", 1, 1, stderr);
	fflush(stderr);
}
lsb_logger lsb_vm_logger = { .context = (char*)"DECODE", .cb = logger };

int main(int argc, char **argv) {
	lsb_lua_sandbox *lsb = NULL;
	char *conf = NULL;
	char *p;

#if DEBUG==1
	set_debug(3);
#endif

	if(argc <2) {
		act("usage: decode-exec script.lua");
		exit(1);
	}

	notice( "DECODE exec v%s",VERSION);
	act("code: %s", argv[1]);

	conf = lsb_read_file(CONF);
	if(!conf) error("Error loading configuration: %s",CONF);
	act("conf: %s", CONF);
	func("\n%s",conf);

	lsb = lsb_create(NULL, argv[1], conf, &lsb_vm_logger);
	if(!lsb) {
		error("Error creating sandbox: %s", lsb_get_error(lsb));
		goto teardown; }

	// load our own extensions
	{
		const luaL_Reg *lib = &luanachalib;
		notice("Loading crypto extensions");
		for (; lib->func; lib++) {
			func("%s",lib->name);
			lsb_add_function(lsb, lib->func, lib->name);
		}
			// lua_pushstring(lua, lib->name);
			// lua_pushcfunction(lua, lib->func);
			// lua_rawset(lua, -3);
	}


	{
		const char *r = lsb_init(lsb, NULL);
		if(r) {
			error(r);
			error(lsb_get_error(lsb));
			error("Error initialising sandbox. Execution aborted.");
			goto teardown; }
	}
	// // u = lsb_usage(lsb, LSB_UT_MEMORY, LSB_US_CURRENT);
	// // func("cur_mem %u", u);
	// // u = lsb_usage(lsb, LSB_UT_MEMORY, LSB_US_MAXIMUM);
	// // func("max_mem %u", u);
	// // u = lsb_usage(lsb, LSB_UT_MEMORY, LSB_US_LIMIT);
	// // func("mem_limit %u", u);
	// // u = lsb_usage(lsb, LSB_UT_INSTRUCTION, LSB_US_CURRENT);
	// // func("op: %u", u);

	// // while(lsb_get_state(lsb) == LSB_RUNNING)
	// // 	act("running...");

teardown:
	act("DECODE exec terminating.");
	if(conf) free(conf);
	if(lsb) {
		lsb_pcall_teardown(lsb);
		lsb_stop_sandbox_clean(lsb);
		p = lsb_destroy(lsb);
		if(p) free(p);
	}
	exit(0);
}
