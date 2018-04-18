#ifndef __ZEN_MEMORY_H__
#define __ZEN_MEMORY_H__

// header to inject our own memory allocation functions

void *zen_memory_alloc(size_t size);
void *zen_memory_realloc(void *ptr, size_t size);
void  zen_memory_free(void *ptr);
void *system_alloc(size_t size);
void *system_realloc(void *ptr, size_t size);
void  system_free(void *ptr);
// TODO: calloc
#define free(p) zen_memory_free(p)
#define malloc(p) zen_memory_alloc(p)
#define realloc(p, s) zen_memory_realloc(p, s)

#endif
