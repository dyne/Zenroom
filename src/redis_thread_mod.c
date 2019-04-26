#ifdef ARCH_REDIS

#include <stdlib.h>
#include <stddef.h>
#include <pthread.h>
#define REDISMODULE_EXPERIMENTAL_API
#include <redismodule.h>
#include <zenroom.h>

// from rmutils and local redis_util.c
// extern int RMUtil_ParseArgs(RedisModuleString **argv, int argc, int offset, const char *fmt, ...);
extern int RMUtil_ParseArgsAfter(const char *token, RedisModuleString **argv,
                                 int argc, const char *fmt, ...);
#define __rmutil_register_cmd(ctx, cmd, f, mode)	  \
	if (RedisModule_CreateCommand(ctx, cmd, f, mode, 1, 1, 1) == REDISMODULE_ERR) \
		return REDISMODULE_ERR;
#define RMUtil_RegisterReadCmd(ctx, cmd, f) __rmutil_register_cmd(ctx, cmd, f, "readonly")
#define RMUtil_RegisterWriteCmd(ctx, cmd, f) __rmutil_register_cmd(ctx, cmd, f, "write")

RedisModuleString *script; //, *keys, *data;
RedisModuleKey *k_script; //, *k_keys, *k_data;
char *s_script = NULL;   //, *s_keys = NULL, *s_data = NULL;
size_t l_script;        //, l_keys, l_data;

int Zenroom_Reply(RedisModuleCtx *ctx, RedisModuleString **argv, int argc) {
	REDISMODULE_NOT_USED(argv);
	REDISMODULE_NOT_USED(argc);
	// int *myint = RedisModule_GetBlockedClientPrivateData(ctx);
	// return RedisModule_ReplyWithLongLong(ctx,*myint);
	// TODO:
	RedisModule_ReplyWithNull(ctx);
	return REDISMODULE_OK;
}
int Zenroom_Timeout(RedisModuleCtx *ctx, RedisModuleString **argv, int argc) {
	REDISMODULE_NOT_USED(argv);
	REDISMODULE_NOT_USED(argc);
	return RedisModule_ReplyWithSimpleString(ctx,"Request timedout");
}
void Zenroom_FreeData(RedisModuleCtx *ctx, void *privdata) {
	REDISMODULE_NOT_USED(ctx);
	(void)privdata;
	// RedisModule_Free(privdata);
}
void Zenroom_Disconnected(RedisModuleCtx *ctx, RedisModuleBlockedClient *bc) {
	RedisModule_Log(ctx,"warning","Blocked client %p disconnected!",
	                (void*)bc);
	/* Here you should cleanup your state / threads, and if possible
	 * call RedisModule_UnblockClient(), or notify the thread that will
	 * call the function ASAP. */
}

// ZENROOM [EXEC <script> <keys> <data>]
void *Zenroom_Thread(void *arg) {
	RedisModuleBlockedClient *bc = arg;
	RedisModuleCtx *ctx = RedisModule_GetThreadSafeContext(bc);
	RedisModule_ThreadSafeContextLock(ctx);
	fprintf(stderr,"%u: %s\n", l_script, s_script);
	zenroom_exec(s_script, NULL,NULL,NULL,3);
	RedisModule_ThreadSafeContextUnlock(ctx);
	RedisModule_FreeThreadSafeContext(ctx);
	RedisModule_UnblockClient(bc,NULL);
	return NULL;
}

int Zenroom_Command(RedisModuleCtx *ctx, RedisModuleString **argv, int argc) {
	// we must have at least 2 args
	if (argc < 2) return RedisModule_WrongArity(ctx);
	if (RMUtil_ParseArgsAfter("EXEC", argv, argc, "s", &script) !=
	    REDISMODULE_OK) {
		return RedisModule_ReplyWithError(ctx,"ERR invalid ZENROOM command");
	}
	// init auto memory for created strings
	RedisModule_AutoMemory(ctx);
	k_script = RedisModule_OpenKey(ctx, script, REDISMODULE_READ);
	if (RedisModule_KeyType(k_script) != REDISMODULE_KEYTYPE_STRING)
		return RedisModule_ReplyWithError(ctx, "ERR no ZENROOM script found");
	s_script = RedisModule_StringDMA(k_script,&l_script,REDISMODULE_READ);
	RedisModuleBlockedClient *bc =
		RedisModule_BlockClient(ctx,
		                        Zenroom_Reply,
		                        Zenroom_Timeout,
		                        Zenroom_FreeData,
		                        3); // timeout (secs?)
	RedisModule_SetDisconnectCallback(bc,Zenroom_Disconnected);
	pthread_t tid;
	if (pthread_create(&tid,NULL,Zenroom_Thread,bc) != 0) {
		RedisModule_AbortBlock(bc);
		return RedisModule_ReplyWithError(ctx,"-ERR Can't start thread");
	}
	// TODO: what to return
	// RedisModule_ReplyWithNull(ctx);
	return REDISMODULE_OK;
}

// main entrypoint symbol
int RedisModule_OnLoad(RedisModuleCtx *ctx) {
	// Register the module itself
	if (RedisModule_Init(ctx, "zenroom", 1, REDISMODULE_APIVER_1) ==
	    REDISMODULE_ERR)
		return REDISMODULE_ERR;
	if (RedisModule_CreateCommand(ctx, "zenroom", 
	                              Zenroom_Command, "readonly",
	                              1, 1, 1) == REDISMODULE_ERR)
		return REDISMODULE_ERR;
	return REDISMODULE_OK;
}

#endif
