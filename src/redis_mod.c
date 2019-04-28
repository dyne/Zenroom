#ifdef ARCH_REDIS

#define REDISMODULE_EXPERIMENTAL_API
#include <redismodule.h>
#include <string.h>
#include <stdlib.h>
#include <stddef.h>
#include <pthread.h>
#include <zenroom.h>

// get rid of the annoying camel-case in Redis, all its types are
// distinguished by being uppercase
typedef RedisModuleBlockedClient BLK;
typedef RedisModuleCtx           CTX;
typedef RedisModuleString        STR;
typedef RedisModuleKey           KEY;
// redis functions
#define r_alloc(p) RedisModule_Alloc(p)
#define r_free(p)  RedisModule_Free(p)

int Zenroom_Reply(CTX *ctx, STR **argv, int argc) {
	REDISMODULE_NOT_USED(argv);
	REDISMODULE_NOT_USED(argc);
	// int *myint = RedisModule_GetBlockedClientPrivateData(ctx);
	// return RedisModule_ReplyWithLongLong(ctx,*myint);
	// TODO:
	return RedisModule_ReplyWithSimpleString(ctx,"OK");
}
int Zenroom_Timeout(CTX *ctx, STR **argv, int argc) {
	REDISMODULE_NOT_USED(argv);
	REDISMODULE_NOT_USED(argc);
	return RedisModule_ReplyWithSimpleString(ctx,"Request timedout");
}
void Zenroom_FreeData(CTX *ctx, void *privdata) {
	REDISMODULE_NOT_USED(ctx);
	RedisModule_Free(privdata);
}
void Zenroom_Disconnected(CTX *ctx, BLK *bc) {
	RedisModule_Log(ctx,"warning","Blocked client %p disconnected!",
	                (void*)bc);
	/* Here you should cleanup your state / threads, and if possible
	 * call RedisModule_UnblockClient(), or notify the thread that will
	 * call the function ASAP. */
}

BLK *block_client(CTX *ctx) {
	BLK *bc =
		RedisModule_BlockClient(ctx,
		                        Zenroom_Reply,
		                        Zenroom_Timeout,
		                        Zenroom_FreeData,
		                        3000); // timeout msecs
	RedisModule_SetDisconnectCallback(bc,Zenroom_Disconnected);
	return(bc);
}

// parsed command structure passed to execution thread
typedef enum { EXEC } zcommand;
typedef struct {
	BLK      *bc;   // redis blocked client
	zcommand  cmd;  // zenroom command (enum)
	KEY      *scriptkey; // redis key for script string
	char     *script;    // script string
	size_t    scriptlen; // length of script string
} zcmd_t;

void *thread_exec(void *arg) {
	zcmd_t *z = arg;
	CTX *ctx = RedisModule_GetThreadSafeContext(z->bc);
	RedisModule_ThreadSafeContextLock(ctx);
	// debug then exec
	fprintf(stderr,"%u: %s\n", (int)z->scriptlen, z->script);
	zenroom_exec(z->script, NULL,NULL,NULL,3);
	// close, unlock and unblock after execution
	RedisModule_CloseKey(z->scriptkey);
	RedisModule_ThreadSafeContextUnlock(ctx);
	RedisModule_FreeThreadSafeContext(ctx);
	RedisModule_UnblockClient(z->bc,z);
	// z is allocated by caller, freed by thread
	return NULL;
}

int Zenroom_Command(CTX *ctx, STR **argv, int argc) {
	pthread_t tid;
	size_t larg;
	const char *carg;
	// we must have at least 2 args
	if (argc < 3) return RedisModule_WrongArity(ctx);

	// ZENROOM EXEC <script> [<keys> <data>]
	carg = RedisModule_StringPtrLen(argv[1], &larg);
	if (strncasecmp(carg,"EXEC",4) == 0) {
		zcmd_t *zcmd = r_alloc(sizeof(zcmd_t)); // to be freed at end of thread!
		zcmd->bc = block_client(ctx); zcmd->cmd = EXEC;
		// get the script variable name from the next argument
		zcmd->scriptkey = RedisModule_OpenKey(ctx, argv[2], REDISMODULE_READ);
		if (RedisModule_KeyType(zcmd->scriptkey) != REDISMODULE_KEYTYPE_STRING)
			return RedisModule_ReplyWithError(ctx, "ERR ZENROOM EXEC: no script found");
		zcmd->script = RedisModule_StringDMA(zcmd->scriptkey,&zcmd->scriptlen,REDISMODULE_READ);

		if (pthread_create(&tid, NULL, thread_exec, zcmd) != 0) {
			RedisModule_AbortBlock(zcmd->bc);
			r_free(zcmd); // reply not called from abort: free here
			return RedisModule_ReplyWithError(ctx,"-ERR Can't start thread");
		}
		return REDISMODULE_OK;
	}

	// no command recognized
	return RedisModule_ReplyWithError(ctx,"ERR invalid ZENROOM command");

}

// main entrypoint symbol
int RedisModule_OnLoad(CTX *ctx) {
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
