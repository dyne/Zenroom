#ifndef __ZENROOM_H__
#define __ZENROOM_H__

#define MAX_HEAP (1048576) // 1 MiB
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

#endif
