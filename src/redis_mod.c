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

// Zenroom global context (zenroom.c)
extern zenroom_t *Z;   // STACK
extern zen_mem_t *MEM; // HEAP

// get rid of the annoying camel-case in Redis, all its types are
// distinguished by being uppercase
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
extern void zen_unset(lua_State *L, char *key);

extern void *zen_memory_manager(void *ud, void *ptr, size_t osize, size_t nsize);

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
	return mem;
}

zenroom_t *zen_redis_init() {
	notice(NULL, "Initializing Zenroom");
	lua_State *L = NULL;
	MEM = redis_memory_init();
	func(NULL,"memory init: %p",MEM);
	L = lua_newstate(zen_memory_manager, MEM);
	if(!L) {
		//error(L,"%s: %s", __func__, "lua state creation failed");
		return NULL;
	}
	// create the zenroom_t global context
	Z = (*MEM->malloc)(sizeof(zenroom_t));
	Z->lua = L;
	Z->mem = MEM;
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

	lua_gc(L, LUA_GCCOLLECT, 0);
	lua_gc(L, LUA_GCCOLLECT, 0);
	// allow further requires
	// zen_require_override(L,1);

	return(Z);
}

// TODO: allocated memory and wastes a memcpy on each get; freeing is
// up to the caller.
char* get(CTX *ctx, const STR * key, size_t *len) {
    REPLY *reply;
    reply = RedisModule_Call(ctx,"GET","s", key);
    if (reply_type(reply) == REDISMODULE_REPLY_ERROR) {
	    RedisModule_ReplyWithCallReply(ctx, reply);
        reply_free(reply);
        return NULL;
    }
    if (reply_type(reply) == REDISMODULE_REPLY_NULL ) {
	    RedisModule_ReplyWithCallReply(ctx, reply);
        reply_free(reply);
        return NULL;
    }
    const char *tmpval = RedisModule_CallReplyStringPtr(reply, len);
    char *res = r_alloc(*len);
    memcpy(res, tmpval, *len);
    reply_free(reply);
    res[*len] = '\0';
    return(res);
}

// ZENROOM.RESET
int zenroom_reset_rediscmd(CTX *ctx, STR **argv, int argc) {
	if (argc != 1) return RedisModule_WrongArity(ctx);
	(void)argv;
	if(Z) zen_teardown(Z);
	Z = NULL; // nop
	Z = zen_redis_init();
	if(!Z) {
		reply_error(ctx, "ERR zenroom initialization failure");
		return REDISMODULE_ERR;
	}
	reply_ok(ctx, "OK zenroom.reset");
	return REDISMODULE_OK;
}

// ZENROOM.DEBUG <int>
int zenroom_debug_rediscmd(CTX *ctx, STR **argv, int argc) {
	const char *arg; size_t arg_len;
	if (argc != 2) return RedisModule_WrongArity(ctx);
	arg = RedisModule_StringPtrLen(argv[1], &arg_len);
	if(arg_len < 1) {
		reply_error(ctx, "ERR zenroom.debug invalid argument");
		return REDISMODULE_ERR;	}
	switch(arg[0]) {
	case '1': set_debug(1); break;
	case '2': set_debug(2); break;
	case '3': set_debug(3); break;
	default:
		reply_error(ctx, "ERR zenroom.debug invalid argument");
		return REDISMODULE_ERR;
		break;
	}
	reply_ok(ctx, "OK zenroom.debug");
	return REDISMODULE_OK;
}

// ZENROOM.VERSION
int zenroom_version_rediscmd(CTX *ctx, STR **argv, int argc) {
	(void)argv;
	if (argc != 1) return RedisModule_WrongArity(ctx);
	char r[256];
	snprintf(r,255,"OK zenroom.version %s",VERSION);
	reply_ok(ctx, r);
	return REDISMODULE_OK;
}

// ZENROOM.EXEC <script> [<keys> <data>]
int zenroom_exec_rediscmd(CTX *ctx, STR **argv, int argc) {
	// we must have at least 2 args
	if (argc < 2) return RedisModule_WrongArity(ctx);
	char out[MAX_STRING];
	char err[MAX_STRING];
	char *script; size_t script_len;
	char *data; size_t data_len;
	char *keys; size_t keys_len;
	// alloc'd by get, needs r_free
	script = get(ctx, argv[1], &script_len);
	if(!script) return REDISMODULE_ERR;
	zen_unset(Z->lua, "DATA"); zen_unset(Z->lua, "KEYS");
	if(argc > 2) {
		data = get(ctx, argv[2], &data_len);
		if(data) zen_setenv(Z->lua, "DATA", data); }
	if(argc > 3) {
		keys = get(ctx, argv[3], &keys_len);
		if(keys) zen_setenv(Z->lua, "KEYS", keys); }
	if(!Z) return REDISMODULE_ERR;
	Z->stdout_buf = out; Z->stdout_len = MAX_STRING; Z->stdout_pos = 0;
	Z->stderr_buf = err; Z->stderr_len = MAX_STRING; Z->stderr_pos = 0;
	int res = zen_exec_script(Z, script);
	if(res != 0) {
		reply_error(ctx,"ERR zenroom execution failure");
		r_free(script);
		return REDISMODULE_ERR;
	}
	RedisModule_ReplyWithStringBuffer(ctx, Z->stdout_buf,
	                                  Z->stdout_pos);
	warning(Z->lua, Z->stderr_buf);
	lua_gc(Z->lua, LUA_GCCOLLECT, 0);
	r_free(script);
	return REDISMODULE_OK;
}

// ZENCODE.EXEC <script> [<keys> <data>]
int zencode_exec_rediscmd(CTX *ctx, STR **argv, int argc) {
	// we must have at least 2 args
	if (argc < 2) return RedisModule_WrongArity(ctx);
	char out[MAX_STRING];
	char err[MAX_STRING];
	char *script; size_t script_len;
	char *data; size_t data_len;
	char *keys; size_t keys_len;
	// alloc'd by get, needs r_free
	script = get(ctx, argv[1], &script_len);
	if(!script) return REDISMODULE_ERR;
	zen_unset(Z->lua, "DATA"); zen_unset(Z->lua, "KEYS");
	if(argc > 2) {
		data = get(ctx, argv[2], &data_len);
		if(data) zen_setenv(Z->lua, "DATA", data); }
	if(argc > 3) {
		keys = get(ctx, argv[3], &keys_len);
		if(keys) zen_setenv(Z->lua, "KEYS", keys); }
	if(!Z) return REDISMODULE_ERR;
	Z->stdout_buf = out; Z->stdout_len = MAX_STRING; Z->stdout_pos = 0;
	Z->stderr_buf = err; Z->stderr_len = MAX_STRING; Z->stderr_pos = 0;
	int res = zen_exec_zencode(Z, script);
	Z->stdout_buf[Z->stdout_pos] = '\0'; Z->stderr_buf[Z->stderr_pos] = '\0';
	if(res != 0) {
		char errmsg[MAX_STRING];
		sprintf(errmsg,"ERR zencode.exec :: %s", Z->stderr_buf);
		RedisModule_ReplyWithStringBuffer(ctx, errmsg, strlen(errmsg));
		r_free(script);
		return REDISMODULE_ERR;
	}
	RedisModule_ReplyWithStringBuffer(ctx, Z->stdout_buf,strlen(Z->stdout_buf));
	// Z->stdout_pos);
//	warning(Z->lua, Z->stderr_buf);
	lua_gc(Z->lua, LUA_GCCOLLECT, 0);
	r_free(script);
	return REDISMODULE_OK;
}

// main entrypoint symbol
int RedisModule_OnLoad(CTX *ctx) {
	// Register the module itself
	if (RedisModule_Init(ctx, "zenroom", 1, REDISMODULE_APIVER_1) ==
	    REDISMODULE_ERR)
		return REDISMODULE_ERR;
	//
	set_debug(1);
	Z = zen_redis_init();
	if(!Z) {
		reply_error(ctx, "ERR zenroom initialization failure");
		return REDISMODULE_ERR;
	}
	//
	if (RedisModule_CreateCommand(ctx, "zenroom.exec",
	                              zenroom_exec_rediscmd,
	                              "readonly deny-oom no-monitor",
	                              1, 3, 1) == REDISMODULE_ERR)
		return REDISMODULE_ERR;
	//
	if (RedisModule_CreateCommand(ctx, "zencode.exec",
	                              zencode_exec_rediscmd,
	                              "readonly deny-oom no-monitor",
	                              1, 3, 1) == REDISMODULE_ERR)
		return REDISMODULE_ERR;
	//
	if (RedisModule_CreateCommand(ctx, "zenroom.reset",
	                              zenroom_reset_rediscmd,
	                              "deny-oom",
	                              0, 0, 0) == REDISMODULE_ERR)
		return REDISMODULE_ERR;
	//
	if (RedisModule_CreateCommand(ctx, "zenroom.debug",
	                              zenroom_debug_rediscmd,
	                              "", 0, 0, 0) == REDISMODULE_ERR)
		return REDISMODULE_ERR;
	//
	if (RedisModule_CreateCommand(ctx, "zenroom.version",
	                              zenroom_version_rediscmd,
	                              "", 0, 0, 0) == REDISMODULE_ERR)
		return REDISMODULE_ERR;

	return REDISMODULE_OK;
}

#endif
