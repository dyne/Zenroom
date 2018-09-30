#include <errno.h>
#include <stdlib.h>
#include <jutils.h>

#include <zenroom.h>
#include <umm_malloc.h>

extern void *umm_info(void*);

void *zen_memalign(const size_t size, const size_t align) {
	void *mem = NULL;
	// preserve const values as they seem to be overwritten by calls
	size_t vsize = size;
	size_t valign = align;
// TODO: Round up to the next highest power of 2
// uint32_t v = valign; // compute the next highest power of 2 of 32-bit v
// v--;
// v |= v >> 1;
// v |= v >> 2;
// v |= v >> 4;
// v |= v >> 8;
// v |= v >> 16;
// v++;
// // from https://graphics.stanford.edu/~seander/bithacks.html#RoundUpPowerOf2
	(void)valign;
# if defined(_WIN32)
	mem = __mingw_aligned_malloc(vsize, valign);
	if(!mem) {
		error(0, "error in %u byte aligned memory allocation of %u bytes.",
		      align, size);
		return NULL; }
# elif defined(__EMSCRIPTEN__)
	mem = malloc(vsize);
# else
	int res;
	res = posix_memalign(&mem, valign, vsize);
	if(res == ENOMEM) {
		error(0, "insufficient memory to allocate %u bytes.", size);
		return NULL; }
	if(res == EINVAL) {
		error(0, "invalid memory alignment at %u bytes.",align);
		return NULL; }
# endif
	return(mem);
}

// global memory manager saved here
// TODO: this is not reentrant (see also umm_malloc.c)
static zen_mem_t *zen_mem;

// Global HEAP pointer in the STACK
zen_mem_t *umm_memory_init(size_t S) {
	zen_mem_t *mem = malloc(sizeof(zen_mem_t));
	mem->heap = zen_memalign(S, 8);
	mem->heap_size = S;
	mem->malloc = umm_malloc;
	mem->realloc = umm_realloc;
	mem->free = umm_free;
	mem->sys_malloc = malloc;
	mem->sys_realloc = realloc;
	mem->sys_free = free;
	umm_init(mem->heap, mem->heap_size);
	zen_mem = mem;
	return mem;
	// pointers saved in umm_malloc.c (stack)
}

zen_mem_t *libc_memory_init() {
	zen_mem_t *mem = malloc(sizeof(zen_mem_t));
	mem->heap = NULL;
	mem->heap_size = 0;
	mem->malloc = malloc;
	mem->realloc = realloc;
	mem->free = free;
	mem->sys_malloc = malloc;
	mem->sys_realloc = realloc;
	mem->sys_free = free;
	zen_mem = mem;
	return mem;
}

void *zen_memory_alloc(size_t size) { return (*zen_mem->malloc)(size); }
void *zen_memory_realloc(void *ptr, size_t size) { return (*zen_mem->realloc)(ptr, size); }
void  zen_memory_free(void *ptr) { (*zen_mem->free)(ptr); }
void *system_alloc(size_t size) { return (*zen_mem->sys_malloc)(size); }
void *system_realloc(void *ptr, size_t size) { return (*zen_mem->sys_realloc)(ptr, size); }
void  system_free(void *ptr) { (*zen_mem->sys_free)(ptr); }



/**
 * Implementation of the memory allocator for the Lua state.
 *
 * See: http://www.lua.org/manual/5.3/manual.html#lua_Alloc
 *
 * @param ud User Data Pointer
 * @param ptr Pointer to the memory block being allocated/reallocated/freed.
 * @param osize The original size of the memory block.
 * @param nsize The new size of the memory block.
 *
 * @return void* A pointer to the memory block.
 */
void *zen_memory_manager(void *ud, void *ptr, size_t osize, size_t nsize) {
	zen_mem_t *mem = (zen_mem_t*)ud;
	if(!mem) return NULL;
	if(ptr == NULL) {
		// When ptr is NULL, osize encodes the kind of object that Lua
		// is allocating. osize is any of LUA_TSTRING, LUA_TTABLE,
		// LUA_TFUNCTION, LUA_TUSERDATA, or LUA_TTHREAD when (and only
		// when) Lua is creating a new object of that type. When osize
		// is some other value, Lua is allocating memory for something
		// else.
		if(nsize!=0) {
			void *ret = (*mem->malloc)(nsize);
			if(ret) return ret;
			error(NULL,"Malloc out of memory, requested %u B",nsize);
			return NULL;
		} else return NULL;

	} else {
		// When ptr is not NULL, osize is the size of the block
		// pointed by ptr, that is, the size given when it was
		// allocated or reallocated.
		if(nsize==0) {
			// When nsize is zero, the allocator must behave like free
			// and return NULL.
			(*mem->free)(ptr);
			return NULL; }

		// When nsize is not zero, the allocator must behave like
		// realloc. The allocator returns NULL if and only if it
		// cannot fulfill the request. Lua assumes that the allocator
		// never fails when osize >= nsize.
		if(osize >= nsize) { // shrink
			return (*mem->realloc)(ptr, nsize);
		} else { // extend
			return (*mem->realloc)(ptr, nsize);
		}
	}
}
