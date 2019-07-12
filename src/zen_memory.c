/* This file is part of Zenroom (https://zenroom.dyne.org)
 *
 * Copyright (C) 2017-2019 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

#include <errno.h>
#include <stdlib.h>
#include <jutils.h>

#include <zenroom.h>
#include <umm_malloc.h>

#ifdef USE_JEMALLOC
#define JEMALLOC_NO_DEMANGLE
#include <jemalloc/jemalloc.h>
#endif

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
# elif defined(__EMSCRIPTEN__) || defined(ARCH_CORTEX)
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
// zen_mem_t *zen_mem;
extern zen_mem_t *MEM;

// Global HEAP pointer in the STACK
zen_mem_t *umm_memory_init(size_t S) {
	zen_mem_t *mem = (zen_mem_t*)malloc(sizeof(zen_mem_t));
	mem->heap = (char*)zen_memalign(S, 8);
	mem->heap_size = S;
	mem->malloc = umm_malloc;
	mem->realloc = umm_realloc;
	mem->free = umm_free;
	mem->sys_malloc = malloc;
	mem->sys_realloc = realloc;
	mem->sys_free = free;
	umm_init(mem->heap, mem->heap_size);
	return mem;
	// pointers saved in umm_malloc.c (stack)
}

zen_mem_t *libc_memory_init() {
	zen_mem_t *mem = (zen_mem_t*)malloc(sizeof(zen_mem_t));
	mem->heap = NULL;
	mem->heap_size = 0;
	mem->malloc = malloc;
	mem->realloc = realloc;
	mem->free = free;
	mem->sys_malloc = malloc;
	mem->sys_realloc = realloc;
	mem->sys_free = free;
	return mem;
}

#ifdef USE_JEMALLOC
zen_mem_t *jemalloc_memory_init() {
	zen_mem_t *mem = je_malloc(sizeof(zen_mem_t));
	mem->heap = NULL;
	mem->heap_size = 0;
	mem->malloc = je_malloc;
	mem->realloc = je_realloc;
	mem->free = je_free;
	mem->sys_malloc = mem->malloc;
	mem->sys_realloc = mem->realloc;
	mem->sys_free = mem->free;
	return mem;
}
#endif

void *zen_memory_alloc(size_t size) { return (*MEM->malloc)(size); }
void *zen_memory_realloc(void *ptr, size_t size) { return (*MEM->realloc)(ptr, size); }
void  zen_memory_free(void *ptr) { (*MEM->free)(ptr); }
void *system_alloc(size_t size) { return (*MEM->sys_malloc)(size); }
void *system_realloc(void *ptr, size_t size) { return (*MEM->sys_realloc)(ptr, size); }
void  system_free(void *ptr) { (*MEM->sys_free)(ptr); }



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
