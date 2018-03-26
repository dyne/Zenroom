#ifndef __ZENROOM_H__
#define __ZENROOM_H__

#define MAX_MEMORY 1024*1024
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

#define ERROR() error("Error in %s",__func__)
#define SAFE(x) if(!x){error("NULL variable in %s",__func__);return 0;}
#define FREE(p) if(p){func("free(%p)",p); free(p);}
#define HERE() func("%s",__func__)
#endif
