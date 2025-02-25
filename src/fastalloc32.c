/* SPDX-FileCopyrightText: 2025 Dyne.org foundation
 * SPDX-License-Identifier: AGPL-3.0-or-later
 *
 * Fast memory allocator for 32 bit 'puters
 *
 * Copyright (C) 2025 Dyne.org foundation
 * designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This program is free software: you can redistribute it and/or
 * modify it under the terms of the GNU Affero General Public License
 * as published by the Free Software Foundation, either version 3 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public
 * License along with this program.  If not, see
 * <https://www.gnu.org/licenses/>.
 *
 */

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <assert.h>

// Configuration
#define POOL_SIZE (1024 * 4 * 128)
#define BLOCK_SIZE 128
#define ALIGNMENT 4
#define HASH_TABLE_SIZE 1024 // Number of buckets in the hash table

// Ensure BLOCK_SIZE and ALIGNMENT are powers of two
static_assert((BLOCK_SIZE & (BLOCK_SIZE - 1)) == 0, "BLOCK_SIZE must be a power of two");
static_assert((ALIGNMENT & (ALIGNMENT - 1)) == 0, "ALIGNMENT must be a power of two");

// Memory pool structure
typedef struct pool {
  unsigned char *data;
  unsigned char **free_list;
  size_t free_count;
  size_t total_blocks;
} pool;

// Large allocation structure
typedef struct large_allocation {
  void *ptr;
  size_t size;
  struct large_allocation *next;
} large_allocation;

// Memory manager structure
typedef struct fastalloc32_mm {
  pool pool;
  large_allocation *hash_table[HASH_TABLE_SIZE]; // Hash table for large allocations
} fastalloc32_mm;

// Utility functions
static inline size_t align_up(size_t size, size_t alignment) {
  return (size + alignment - 1) & ~(alignment - 1);
}

static inline void secure_zero(void *ptr, size_t size) {
  volatile unsigned char *p = ptr;
  while (size--) *p++ = 0;
}

static inline fastalloc32_mm *arg_manager(void *mm) {
  return (fastalloc32_mm *)mm;
}

// Hash function for pointers
static inline size_t hash_ptr(void *ptr) {
  return ((uintptr_t)ptr >> 4) % HASH_TABLE_SIZE; // Simple hash function
}

// Pool initialization
static inline void pool_init(pool *pool, size_t initial_size) {
  pool->data = (unsigned char *)malloc(initial_size);
  if (pool->data == NULL) {
    fprintf(stderr, "Failed to allocate pool memory\n");
    exit(EXIT_FAILURE);
  }

  pool->total_blocks = initial_size / BLOCK_SIZE;
  pool->free_list = (unsigned char **)
    calloc(pool->total_blocks, sizeof(unsigned char *));
  if (pool->free_list == NULL) {
    free(pool->data);
    fprintf(stderr, "Failed to allocate free list\n");
    exit(EXIT_FAILURE);
  }

  pool->free_count = pool->total_blocks;
  for (size_t i = 0; i < pool->total_blocks; ++i) {
    pool->free_list[i] = &pool->data[i * BLOCK_SIZE];
  }
}

// Pool allocation
static inline void *pool_alloc(pool *pool) {
  if (pool->free_count == 0) {
    return NULL; // Pool exhausted
  }
  return pool->free_list[--pool->free_count];
}

// Pool deallocation
static inline void pool_free(pool *pool, void *ptr) {
  pool->free_list[pool->free_count++] = (unsigned char *)ptr;
}

// Create memory manager
void *fastalloc32_create() {
  fastalloc32_mm *manager = (fastalloc32_mm *)
    malloc(sizeof(fastalloc32_mm));
  if (manager == NULL) {
    fprintf(stderr, "Failed to allocate memory manager\n");
    return NULL;
  }

  pool_init(&manager->pool, POOL_SIZE);
  // Initialize hash table
  memset(manager->hash_table, 0, sizeof(manager->hash_table));
  return (void *)manager;
}

// Destroy memory manager
void fastalloc32_destroy(void *restrict mm) {
  fastalloc32_mm *restrict manager = arg_manager(mm);

  // Free large allocations in the hash table
  for (size_t i = 0; i < HASH_TABLE_SIZE; ++i) {
    large_allocation *current = manager->hash_table[i];
    while (current) {
      large_allocation *next = current->next;
      secure_zero(current->ptr, current->size);
      free(current->ptr);
      free(current);
      current = next;
    }
  }

  // Free pool memory
  free(manager->pool.data);
  free(manager->pool.free_list);

  // Free manager
  free(manager);
}

// Allocate memory
void *fastalloc32_malloc(void *restrict mm, size_t size) {
  fastalloc32_mm *restrict manager = arg_manager(mm);
  size = align_up(size, ALIGNMENT);

  if (size <= BLOCK_SIZE) {
    void *ptr = pool_alloc(&manager->pool);
    if (ptr != NULL) {
      return ptr;
    }
  }

  void *ptr = malloc(size);
  if (ptr == NULL) {
    return NULL; // malloc failed
  }

  large_allocation *large_alloc = (large_allocation *)
    malloc(sizeof(large_allocation));
  if (large_alloc == NULL) {
    free(ptr);
    return NULL; // malloc failed
  }

  large_alloc->ptr = ptr;
  large_alloc->size = size;

  // Add to hash table
  size_t bucket = hash_ptr(ptr);
  large_alloc->next = manager->hash_table[bucket];
  manager->hash_table[bucket] = large_alloc;

  return ptr;
}

// Free memory
void fastalloc32_free(void *restrict mm, void *ptr) {
  fastalloc32_mm *restrict manager = arg_manager(mm);
  if (ptr == NULL) return; // Freeing NULL is a no-op

  if ((uintptr_t)ptr >= (uintptr_t)manager->pool.data
      && (uintptr_t)ptr < (uintptr_t)
      (manager->pool.data + manager->pool.total_blocks * BLOCK_SIZE)) {
    pool_free(&manager->pool, ptr);
  } else {
    size_t bucket = hash_ptr(ptr);
    large_allocation **curr = &manager->hash_table[bucket];
    while (*curr) {
      if ((*curr)->ptr == ptr) {
        large_allocation *to_free = *curr;
        *curr = (*curr)->next;
        secure_zero(to_free->ptr, to_free->size);
        free(to_free->ptr);
        free(to_free);
        return;
      }
      curr = &(*curr)->next;
    }
    // If we reach here, ptr was not allocated by this memory manager
    free(ptr);
  }
}

// Reallocate memory
void *fastalloc32_realloc(void *restrict mm, void *ptr, size_t size) {
  fastalloc32_mm *restrict manager = arg_manager(mm);
  size = align_up(size, ALIGNMENT);

  if (ptr == NULL) {
    return fastalloc32_malloc(manager, size);
  }

  if (size == 0) {
    fastalloc32_free(manager, ptr);
    return NULL;
  }

  if ((uintptr_t)ptr >= (uintptr_t)manager->pool.data
      && (uintptr_t)ptr < (uintptr_t)
      (manager->pool.data + manager->pool.total_blocks * BLOCK_SIZE)) {
    if (size <= BLOCK_SIZE) {
      return ptr; // No need to reallocate
    } else {
      void *new_ptr = fastalloc32_malloc(manager, size);
      if (new_ptr) {
        memcpy(new_ptr, ptr, BLOCK_SIZE); // Copy only BLOCK_SIZE bytes
        pool_free(&manager->pool, ptr);
      }
      return new_ptr;
    }
  } else {
    size_t bucket = hash_ptr(ptr);
    large_allocation **curr = &manager->hash_table[bucket];
    while (*curr) {
      if ((*curr)->ptr == ptr) {
        size_t copy_size = ((*curr)->size < size)
          ? (*curr)->size : size; // Copy the smaller of the two sizes
        void *new_ptr = fastalloc32_malloc(manager, size);
        if (new_ptr) {
          memcpy(new_ptr, ptr, copy_size); // Copy only the minimum size
          fastalloc32_free(manager, ptr);
        }
        return new_ptr;
      }
      curr = &(*curr)->next;
    }

    // Handle realloc for memory allocated outside the manager's control
    return realloc(ptr, size);
  }
}

// Debug function to print memory manager state
void fastalloc32_debug(void *restrict mm) {
  fastalloc32_mm *restrict manager = arg_manager(mm);
  printf("Pool free blocks: %zu/%zu\n",
         manager->pool.free_count, manager->pool.total_blocks);

  for (size_t i = 0; i < HASH_TABLE_SIZE; ++i) {
    large_allocation *current = manager->hash_table[i];
    while (current) {
      printf("Large allocation: %p, size: %zu\n",
             current->ptr, current->size);
      current = current->next;
    }
  }
}

#if defined(FASTALLOC32_TEST)
#include <assert.h>
#include <time.h>

#define NUM_ALLOCATIONS 20000
#define MAX_ALLOCATION_SIZE 1024

int main(int argc, char **argv) {
  srand(time(NULL));
  fastalloc32_mm *manager = fastalloc32_create();

  void *pointers[NUM_ALLOCATIONS];

  fprintf(stderr,"Step 1: Allocate memory\n");
  for (int i = 0; i < NUM_ALLOCATIONS; i++) {
    size_t size = rand() % MAX_ALLOCATION_SIZE + 1;
    pointers[i] = fastalloc32_malloc(manager, size);
    assert(pointers[i] != NULL); // Ensure allocation was successful
  }

  fprintf(stderr,"Step 2: Free every other allocation\n");
  for (int i = 0; i < NUM_ALLOCATIONS; i += 2) {
    fastalloc32_free(manager, pointers[i]);
    pointers[i] = NULL;
  }

  fprintf(stderr,"Step 3: Reallocate remaining memory\n");
  for (int i = 1; i < NUM_ALLOCATIONS; i += 2) {
    size_t new_size = rand() % MAX_ALLOCATION_SIZE + 1;
    pointers[i] = fastalloc32_realloc(manager, pointers[i], new_size);
    assert(pointers[i] != NULL); // Ensure reallocation was successful
  }

  fprintf(stderr,"Step 4: Free all memory\n");
  for (int i = 0; i < NUM_ALLOCATIONS; i++) {
    if (pointers[i] != NULL) {
      fastalloc32_free(manager, pointers[i]);
      pointers[i] = NULL;
    }
  }

  fprintf(stderr,"Step 5: Final check for memory leaks\n");
  for (int i = 0; i < NUM_ALLOCATIONS; i++) {
    assert(pointers[i] == NULL); // Ensure all pointers are freed
  }

  fastalloc32_destroy(manager);
  printf("Fastalloc32 test passed successfully.\n");
  return 0;
}

#endif
