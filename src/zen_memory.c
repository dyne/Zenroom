#include <stdlib.h>
#include <zenroom.h>
#include <umm_malloc.h>


// hardcoded heap for now
char *zen_heap[MAX_HEAP+0xff];
void  zen_memory_init() { umm_init(); }
void *zen_memory_alloc(size_t size) { return umm_malloc(size); }
void  zen_memory_free(void *ptr) { umm_free(ptr); }


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
	if(ptr == NULL) {
		// When ptr is NULL, osize encodes the kind of object that Lua
		// is allocating. osize is any of LUA_TSTRING, LUA_TTABLE,
		// LUA_TFUNCTION, LUA_TUSERDATA, or LUA_TTHREAD when (and only
		// when) Lua is creating a new object of that type. When osize
		// is some other value, Lua is allocating memory for something
		// else.
		return umm_malloc(nsize);

	} else {
		// When ptr is not NULL, osize is the size of the block
		// pointed by ptr, that is, the size given when it was
		// allocated or reallocated.
		if(nsize==0) {
			// When nsize is zero, the allocator must behave like free
			// and return NULL.
			umm_free(ptr);
			return NULL; }

		// When nsize is not zero, the allocator must behave like
		// realloc. The allocator returns NULL if and only if it
		// cannot fulfill the request. Lua assumes that the allocator
		// never fails when osize >= nsize.
		if(osize >= nsize) { // shrink
			return umm_realloc(ptr, nsize);
		} else { // extend
			return umm_realloc(ptr, nsize);
		}		
	}		
}
