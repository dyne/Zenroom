/* SPDX-FileCopyrightText: 2025-2026 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 *
 * Copyright (C) 2025-2026 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Affero General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program.  If not, see
 * <https://www.gnu.org/licenses/>.
 *
 */

#ifndef __SFPOOL_H__
#define __SFPOOL_H__

// This header carries both declarations and implementation.
// All functions use internal linkage, so it is safe to include it
// from multiple translation units in the same program.

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <assert.h>
#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#elif defined(_WIN32)
#include <windows.h>
#else // lucky shot on POSIX
// defined(__unix__) || defined(__linux__) || defined(__APPLE__) ||  defined(__DragonFly__) || defined(__FreeBSD__) || defined(__NetBSD__) || defined(__OpenBSD__)
#include <unistd.h> // for geteuid to switch protected memory map
#include <sys/resource.h>
#include <sys/mman.h>
#endif

// Configuration
#define SECURE_ZERO // Enable secure zeroing
#define PROFILING // Profile most used sizes allocated

#if defined(__x86_64__) || defined(_M_X64) || defined(__ppc64__) || defined(__LP64__)
#define ptr_t uint64_t
#define ptr_align 8
#define struct_align 16
#else
#define ptr_t uint32_t
#define ptr_align 4
#define struct_align 8
#endif

// Memory pool structure
typedef struct __attribute__((aligned(struct_align))) sfpool_t {
  uint8_t *buffer; // raw
  uint8_t *data; // aligned
  uint8_t *free_list;
  uint32_t free_count;
  uint32_t total_blocks;
  uint32_t total_bytes;
  uint32_t block_size;
#ifdef PROFILING
  uint32_t *hits;
  uint32_t hits_total;
  size_t   hits_bytes;
  uint32_t miss_total;
  size_t   miss_bytes;
  size_t   alloc_total;
#endif
} sfpool_t;


#if !defined(__MUSL__)
static_assert(sizeof(ptr_t) == sizeof(void*), "Unknown memory pointer size detected");
#endif
static inline bool _is_in_pool(sfpool_t *pool, const void *ptr) {
  volatile ptr_t p = (ptr_t)ptr;
  return(p >= (ptr_t)pool->data
         && p < (ptr_t)(pool->data + pool->total_bytes));
}

/**
 * @defgroup sfutil Internal Utilities
 * @{
 */

/**
 * @brief Zeroes out a block of memory.
 *
 * This function sets every byte in a block of memory to zero.
 *
 * @param ptr Pointer to the memory block to zero out.
 * @param size Size of the memory block in bytes.
 */
static inline void sfutil_zero(void *ptr, uint32_t size) {
  volatile uint8_t *p = (volatile uint8_t*)ptr;
  while (size--) *p++ = 0;
}

/**
 * @brief Aligns a pointer to the nearest boundary.
 *
 * This function aligns the given pointer to the nearest boundary specified by `ptr_align`.
 *
 * @param ptr Pointer to align.
 * @return Aligned pointer.
 */
static inline void *sfutil_memalign(const void* ptr) {
    register ptr_t mask = ptr_align - 1;
    ptr_t aligned = ((ptr_t)ptr + mask) & ~mask;
    return (void*)aligned;
}

/**
 * @brief Allocates memory securely.
 *
 * This function allocates memory securely, ensuring it is aligned and locked (if supported by the platform).
 *
 * @param size Size of the memory block to allocate.
 * @return Pointer to the allocated memory block, or NULL on failure.
 */
static inline void *sfutil_secalloc(size_t size) {
	if (size > (SIZE_MAX - ptr_align)) return NULL;
	// add bytes to every allocation to support alignment
	size_t alloc_size = size + ptr_align;
	void *res = NULL;
#if defined(__EMSCRIPTEN__)
	res = (uint8_t *)malloc(alloc_size);
#elif defined(_WIN32)
	res = VirtualAlloc(NULL, alloc_size,
					   MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
#elif defined(__APPLE__)
	int flags = MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE;
	res = mmap(NULL, alloc_size, PROT_READ | PROT_WRITE, flags, -1, 0);
	if (res == MAP_FAILED) return NULL;
	(void)mlock(res, alloc_size);
#else // assume POSIX
	int flags = MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE;
	struct rlimit rl;
	if (getrlimit(RLIMIT_MEMLOCK, &rl) == 0)
		if(alloc_size<=rl.rlim_cur) flags |= MAP_LOCKED;
	res = mmap(NULL, alloc_size, PROT_READ | PROT_WRITE, flags, -1, 0);
	if (res == MAP_FAILED) return NULL;
#endif
	return res;
}

/**
 * @brief Frees memory allocated securely.
 *
 * This function frees memory that was allocated using `sfutil_secalloc`.
 *
 * @param ptr Pointer to the memory block to free.
 * @param size Size of the memory block in bytes.
 */
static inline void sfutil_secfree(void *ptr, size_t size) {
	if (ptr == NULL) return;
	size_t alloc_size = size + ptr_align;
#if defined(__EMSCRIPTEN__)
	free(ptr);
#elif defined(_WIN32)
	VirtualFree(ptr, 0, MEM_RELEASE);
#else // Posix
	munmap(ptr, alloc_size);
#endif
}

/** @} */ // End of sfutil group


/**
 * @defgroup sfpool High-Level API
 * @{
 */

/**
 * @brief Initializes a memory pool.
 *
 * This function initializes a memory pool with a specified number of blocks and block size.
 * The block size must be a power of two.
 *
 * @param pool Pointer to the memory pool structure to initialize.
 * @param nmemb Number of blocks in the pool.
 * @param blocksize Size of each block in bytes.
 * @return Total size of the memory pool in bytes, or 0 on failure.
 */
static inline size_t sfpool_init(sfpool_t *pool, size_t nmemb, size_t blocksize) {
  if (pool == NULL) return 0;
  memset(pool, 0, sizeof(sfpool_t));
  if (nmemb == 0) return 0;
  if (blocksize < sizeof(void*)) return 0;
  if((blocksize & (blocksize - 1)) != 0) return 0;
  if (nmemb > (SIZE_MAX / blocksize)) return 0;
  // SFPool blocksize must be a power of two
  size_t totalsize = nmemb * blocksize;
  pool->buffer = sfutil_secalloc(totalsize);
  if (pool->buffer == NULL) return 0;
  // Failed to allocate pool memory
  pool->data   = sfutil_memalign(pool->buffer);
  if (pool->data == NULL) return 0;
  // Failed to allocate pool memory
  pool->total_bytes  = totalsize;
  pool->total_blocks = nmemb;
  pool->block_size   = blocksize;
  // Initialize the embedded free list
  pool->free_list = pool->data;
  register uint32_t i, bi;
  for (i = 0; i < pool->total_blocks - 1; ++i) {
    bi = i*blocksize;
    *(uint8_t **)(pool->data + bi) =
      pool->data + bi + blocksize;
  }
  pool->free_count = pool->total_blocks;
  *(uint8_t **)
    (pool->data + (pool->total_blocks - 1) * blocksize) = NULL;
#ifdef PROFILING
  pool->miss_total = pool->miss_bytes = 0;
  pool->hits_total = pool->hits_bytes = 0;
  pool->alloc_total = 0;
#endif
  return totalsize;
}


/**
 * @brief Tears down a memory pool.
 *
 * This function releases all resources associated with the memory pool.
 *
 * @param pool Pointer to the memory pool structure to tear down.
 */
static inline void sfpool_teardown(sfpool_t *restrict pool) {
  if (pool == NULL) return;
  // Free pool memory
  sfutil_secfree(pool->buffer, pool->total_bytes);
  pool->buffer = NULL;
  pool->data = NULL;
  pool->free_list = NULL;
  pool->free_count = 0;
  pool->total_blocks = 0;
  pool->total_bytes = 0;
  pool->block_size = 0;
#ifdef PROFILING
  pool->miss_total = pool->miss_bytes = 0;
  pool->hits_total = pool->hits_bytes = 0;
  pool->alloc_total = 0;
#endif
}

/**
 * @brief Allocates memory from the pool.
 *
 * This function allocates memory from the pool if the requested size is within the block size.
 * Otherwise, it falls back to system malloc.
 *
 * @param opaque Pointer to the memory pool structure.
 * @param size Size of the memory block to allocate.
 * @return Pointer to the allocated memory block, or NULL on failure.
 */
static inline void *sfpool_malloc(void *restrict opaque, const size_t size) {
  sfpool_t *pool = (sfpool_t*)opaque;
  void *ptr;
  if (pool != NULL
      && pool->buffer != NULL
      && size <= pool->block_size
      && pool->free_list != NULL) {
#ifdef PROFILING
    pool->hits_total++;
    pool->hits_bytes+=size;
    pool->alloc_total+=size;
#endif
    // Remove the first block from the free list
    uint8_t *block = pool->free_list;
    pool->free_list = *(uint8_t **)block;
    pool->free_count-- ;
    return block;
  }
  // Fallback to system malloc for large allocations
  ptr = malloc(size);
  if(ptr == NULL) perror("system malloc error");
#ifdef PROFILING
  pool->miss_total++;
  pool->miss_bytes+=size;
  pool->alloc_total+=size;
#endif
  return ptr;
}


/**
 * @brief Frees memory allocated from the pool.
 *
 * This function frees memory that was allocated from the pool. If the memory was not allocated
 * from the pool, it falls back to system free.
 *
 * @param opaque Pointer to the memory pool structure.
 * @param ptr Pointer to the memory block to free.
 */
static inline void sfpool_free(void *restrict opaque, void *ptr) {
  sfpool_t *pool = (sfpool_t*)opaque;
  if (ptr == NULL) return; // Freeing NULL is a no-op
  if (pool != NULL
      && pool->buffer != NULL
      && _is_in_pool(pool,ptr)) {
#ifdef SECURE_ZERO
    // Zero the user-visible contents before restoring the free-list link.
    sfutil_zero(ptr, pool->block_size);
#endif
    // Add the block back to the free list
    *(uint8_t **)ptr = pool->free_list;
    pool->free_list = (uint8_t *)ptr;
    pool->free_count++ ;
    return;
  } else {
    free(ptr);
  }
}


/**
 * @brief Reallocates memory from the pool.
 *
 * This function reallocates memory from the pool. If the new size is larger than the block size,
 * it allocates new memory using system malloc and copies the old data. If that grow allocation
 * fails, the original pool allocation is left untouched and NULL is returned.
 *
 * @param opaque Pointer to the memory pool structure.
 * @param ptr Pointer to the memory block to reallocate.
 * @param size New size of the memory block.
 * @return Pointer to the reallocated memory block, or NULL on failure.
 */
static inline void *sfpool_realloc(void *restrict opaque, void *ptr, const size_t size) {
  sfpool_t *pool = (sfpool_t*)opaque;
  if (ptr == NULL) {
    return sfpool_malloc(pool, size);
  }
  if (size == 0) {
    sfpool_free(pool, ptr);
    return NULL;
  }
  if (pool != NULL
      && pool->buffer != NULL
      && _is_in_pool(pool,ptr)) {
    if (size <= pool->block_size) {
#ifdef PROFILING
      pool->hits_total++;
      pool->hits_bytes+=size;
      pool->alloc_total+=size;
#endif
      return ptr; // No need to reallocate
    } else {
      void *new_ptr = malloc(size);
      if (new_ptr == NULL) return NULL;
      memcpy(new_ptr, ptr, pool->block_size); // Copy only BLOCK_SIZE bytes
#ifdef SECURE_ZERO
      // Zero the old pool block before relinking it into the free list.
      sfutil_zero(ptr, pool->block_size);
#endif
      // Add the block back to the free list
      *(uint8_t **)ptr = pool->free_list;
      pool->free_list = (uint8_t *)ptr;
      pool->free_count++ ;
#ifdef PROFILING
      pool->miss_total++;
      pool->miss_bytes+=size;
      pool->alloc_total+=size;
#endif
      return new_ptr;
    }
  } else {
    // Handle large allocations
#ifdef PROFILING
    if (pool != NULL) {
      pool->miss_total++;
      pool->miss_bytes+=size;
      pool->alloc_total+=size;
    }
#endif
    return realloc(ptr, size);
  }
}

/**
 * @brief Checks if a pointer is within the memory pool.
 *
 * This function checks if the given pointer is within the memory pool.
 *
 * @param opaque Pointer to the memory pool structure.
 * @param ptr Pointer to check.
 * @return 1 if the pointer is within the pool, 0 otherwise.
 */
static inline int sfpool_contains(void *restrict opaque, const void *ptr) {
  sfpool_t *pool = (sfpool_t*)opaque;
  int res = 0;
  if(pool != NULL && pool->buffer != NULL && _is_in_pool(pool,ptr)) res = 1;
  return res;
}


/**
 * @brief Prints the status of the memory pool.
 *
 * This function prints the current status of the memory pool, including the number of blocks,
 * block size, and profiling information (if enabled).
 *
 * @param p Pointer to the memory pool structure.
 */
static inline void sfpool_status(sfpool_t *restrict p) {
  fprintf(stderr,"\n🌊 sfpool: %u blocks %u B each\n",
          p->total_blocks, p->block_size);
#ifdef PROFILING
  fprintf(stderr,"🌊 Total:  %lu K\n",
          p->alloc_total/1024);
  fprintf(stderr,"🌊 Misses: %lu K (%u calls)\n",p->miss_bytes/1024,p->miss_total);
  fprintf(stderr,"🌊 Hits:   %lu K (%u calls)\n",p->hits_bytes/1024,p->hits_total);
#endif
}

/** @} */ // End of sfpool group

#endif
