#ifndef __ZENROOM_H__
#define __ZENROOM_H__

#define MAX_HEAP (1048576*64) // 64 MiBs
#define MAX_FILE 512000 // load max 500Kb files
#define MAX_STRING 4096
#define MAX_OCTET 4096

#define LUA_BASELIBNAME "_G"

#define ZEN_BITS 32
#ifndef SIZE_MAX
 #if ZEN_BITS == 32
  #define SIZE_MAX 4294967296
 #elif ZEN_BITS == 8
  #define SIZE_MAX 65536
 #endif
#endif

int zenroom_exec(char *script, char *conf, char *keys,
                 char *data, int verbosity);

extern void *zen_memory_alloc(size_t size);
extern void  zen_memory_free(void *ptr);
#define free(p) zen_memory_free(p)
#define malloc(p) zen_memory_alloc(p)

#endif
