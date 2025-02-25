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

#ifndef __ZEN_MEMORY_H__
#define __ZEN_MEMORY_H__

#if defined(_WIN32)
#include <malloc.h>
#else
#include <stdlib.h>
#endif

extern void *restrict ZMM;

// internal functions use this define to switch memory manager
extern void *fastalloc32_malloc  (void *restrict manager, size_t size);
extern void *fastalloc32_realloc (void *restrict manager, void *ptr, size_t size);
extern void  fastalloc32_free    (void *restrict manager, void *ptr);

#define malloc(size)       fastalloc32_malloc  (ZMM, size)
#define free(ptr)          fastalloc32_free    (ZMM, ptr)
#define realloc(ptr, size) fastalloc32_realloc (ZMM, ptr, size)

#endif
