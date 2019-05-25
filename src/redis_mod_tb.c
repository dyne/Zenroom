/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2019 Dyne.org foundation
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

// Redis module for multi-threaded blocking operations using Zenroom.
// This uses Redis' experimental API and is still a work in progress.

#ifdef ARCH_REDIS

#define REDISMODULE_EXPERIMENTAL_API
#include <redismodule.h>
#include <string.h>
#include <stdlib.h>
#include <stddef.h>

#include <jutils.h>
#include <zenroom.h>
#include <zen_memory.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <lstate.h>

// get rid of the annoying camel-case in Redis, all its types are
// distinguished by being uppercase
//typedef RedisModuleBlockedClient BLK;
typedef RedisModuleCtx           CTX;
typedef RedisModuleString        STR;
typedef RedisModuleKey           KEY;
typedef RedisModuleCallReply     REPLY;
// redis functions
#define r_alloc(p) RedisModule_Alloc(p)
#define r_free(p)  RedisModule_Free(p)

// TODO: defines
#define reply_ok(C, M) RedisModule_ReplyWithSimpleString(C, M)
#define reply_error(C, M) RedisModule_ReplyWithError(C, M)
#define reply_type(R) RedisModule_CallReplyType(R)
#define reply_free(R) RedisModule_FreeCallReply(R)

extern int zen_require_override(lua_State *L, const int restricted);
extern int zen_lua_init(lua_State *L);
extern void zen_add_io(lua_State *L);
extern void zen_setenv(lua_State *L, char *key, char *val);

extern void *zen_memory_manager(void *ud, void *ptr, size_t osize, size_t nsize);
extern zen_mem_t *zen_mem;
zen_mem_t *redis_memory_init() {
	zen_mem_t *mem = r_alloc(sizeof(zen_mem_t));
	mem->heap = NULL;
	mem->heap_size = 0;
	mem->malloc = RedisModule_Alloc;
	mem->realloc = RedisModule_Realloc;
	mem->free = RedisModule_Free;
	mem->sys_malloc = RedisModule_Alloc;
	mem->sys_realloc = RedisModule_Realloc;
	mem->sys_free = RedisModule_Free;
	zen_mem = mem;
	return mem;
}

zenroom_t *zen_redis_init() {
	notice(NULL, "Initializing Zenroom");
	lua_State *L = NULL;
	zen_mem_t *mem = NULL;
	mem = redis_memory_init();
	func(NULL,"memory init: %p",mem);
	L = lua_newstate(zen_memory_manager, mem);
	if(!L) {
		//error(L,"%s: %s", __func__, "lua state creation failed");
		return NULL;
	}
	// create the zenroom_t global context
	zenroom_t *Z = (*mem->malloc)(sizeof(zenroom_t));
	Z->lua = L;
	Z->mem = mem;
	Z->stdout_buf = NULL;
	Z->stdout_pos = 0;
	Z->stdout_len = 0;
	Z->stderr_buf = NULL;
	Z->stderr_pos = 0;
	Z->stderr_len = 0;
	Z->userdata = NULL;
	Z->errorlevel = 0;

	func(NULL,"global state: L[%p] _G[%p] _Z[%p]", L, L->l_G, Z);

	//Set zenroom context as a global in lua
	//this will be freed on lua_close
	lua_pushlightuserdata(L, Z);
	lua_setglobal(L, "_Z");

	// initialise global variables
#if defined(VERSION)
	zen_setenv(L, "VERSION", VERSION);
#endif
#if defined(ARCH)
	zen_setenv(L, "ARCH", ARCH);
#endif
#if defined(GITLOG)
	zen_setenv(L, "GITLOG", GITLOG);
#endif


	// open all standard lua libraries
	luaL_openlibs(L);

	// load our own openlibs and extensions
	zen_add_io(L);
	zen_require_override(L,0);
	if(!zen_lua_init(L)) {
		//error(L,"%s: %s", __func__, "initialisation of lua scripts failed");
		return NULL;
	}
	//////////////////// end of create

	// lua_gc(L, LUA_GCCOLLECT, 0);
	// lua_gc(L, LUA_GCCOLLECT, 0);
	// allow further requires
	// zen_require_override(L,1);

	return(Z);
}

// TODO: wastes a memcpy on each get. tried DMA access but no luck
char* get(CTX *ctx, const STR * key, size_t *len) {
    REPLY *reply;
    reply = RedisModule_Call(ctx,"GET","s", key);
    if (reply_type(reply) == REDISMODULE_REPLY_ERROR) {
	    RedisModule_ReplyWithCallReply(ctx, reply);
        reply_free(reply);
        return NULL;
    }
    if ( reply_type(reply) == REDISMODULE_REPLY_NULL ) {
        reply_free(reply);
        return NULL;
    }
    const char *tmpval = RedisModule_CallReplyStringPtr(reply, len);
    char *res = r_alloc(*len);
    memcpy(res, tmpval, *len);
    reply_free(reply);
    return(res);
}

// ZENROOM.EXEC <script> [<keys> <data>]
int zenroom_exec_rediscmd(CTX *ctx, STR **argv, int argc) {
	// we must have at least 2 args
	set_debug(3);
	if (argc < 2) return RedisModule_WrongArity(ctx);
	char out[MAX_STRING];
	char err[MAX_STRING];
	size_t script_len;
	char *script;
	// alloc'd by get, needs r_free
	script = get(ctx, argv[1], &script_len);
	if(!script) return REDISMODULE_ERR;
	// TODO: load arguments if present
	// if(data) {
	// 	func(L, "declaring global: DATA");
	// 	zen_setenv(L,"DATA",data);
	// }
	// if(keys) {
	// 	func(L, "declaring global: KEYS");
	// 	zen_setenv(L,"KEYS",keys);
	// }
	//
	zenroom_t *Z = zen_redis_init();
	if(!Z) {
		reply_error(ctx, "ERR zenroom initialization failure");
		return REDISMODULE_ERR;
	}
	// int res = zenroom_exec_tobuf((char*)script, NULL, NULL, NULL, 3,
	//                              out, MAX_STRING, err, MAX_STRING);
	int res = zen_exec_script(Z, script);
	if(res != 0) {
		reply_error(ctx,"ERR zenroom execution failure");
		r_free(script);
		return REDISMODULE_ERR;
	}
	RedisModule_ReplyWithStringBuffer(ctx, out, strlen(out));
	r_free(script);
	zen_teardown(Z);
	return REDISMODULE_OK;
}

// main entrypoint symbol
int RedisModule_OnLoad(CTX *ctx) {
	// Register the module itself
	if (RedisModule_Init(ctx, "zenroom", 1, REDISMODULE_APIVER_1) ==
	    REDISMODULE_ERR)
		return REDISMODULE_ERR;
	//
	if (RedisModule_CreateCommand(ctx, "zenroom.exec",
	                              zenroom_exec_rediscmd, "readonly",
	                              1, 1, 1) == REDISMODULE_ERR)
		return REDISMODULE_ERR;
	//
	return REDISMODULE_OK;
}

#endif
