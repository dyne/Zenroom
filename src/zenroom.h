#ifndef __ZENROOM_H__
#define __ZENROOM_H__

#define UMM_HEAP (64*1024) // 64KiB (masked with 0x7fff)
#define MAX_FILE (64*512) // load max 32KiB files
#define MAX_STRING 4097 // max 4KiB strings
#define MAX_OCTET 2049 // max 2KiB octets

#define LUA_BASELIBNAME "_G"

#define ZEN_BITS 8
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
