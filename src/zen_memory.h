#ifndef __ZEN_MEMORY_H__
#define __ZEN_MEMORY_H__

extern char *zen_heap;
extern size_t zen_heap_size;
extern void *zen_memory_alloc(size_t size);
extern void *zen_memory_realloc(void *ptr, size_t size);
extern void  zen_memory_free(void *ptr);
#define free(p) zen_memory_free(p)
#define malloc(p) zen_memory_alloc(p)
#define realloc(p, s) zen_memory_realloc(p, s)

#endif
