#ifndef __ZENROOM_H__
#define __ZENROOM_H__

#define MAX_MEMORY 1024*1024
#define MAX_FILE 512000 // load max 500Kb files
#define MAX_STRING 4096

#define ZEN_BITS 32
#if ZEN_BITS == 32
#define SIZE_MAX 4294967296
#elif ZEN_BITS == 8
#define SIZE_MAX 65536
#endif

#endif
