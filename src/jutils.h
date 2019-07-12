/*  Jaromil's utility collection
 *
 *  (c) Copyright 2001-2006 Denis Rojo <jaromil@dyne.org>
 *
 * This source code is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Public License as published 
 * by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 *
 * This source code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * Please refer to the GNU Public License for more details.
 *
 * You should have received a copy of the GNU Public License along with
 * this source code; if not, write to:
 * Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#ifndef __JUTILS_H__
#define __JUTILS_H__

#include <stdio.h>

#include <stdlib.h>
#include <stdarg.h>
#include <time.h>
#include <sys/time.h>
#include <unistd.h>
#include <string.h>

#include <lauxlib.h>

#define MAX_DEBUG 2

#define FUNC 2 /* se il debug level e' questo
		  ci sono le funzioni chiamate */
#define WARN 1 /* ... blkbblbl */

void set_debug(int lev);
int get_debug();

void notice(lua_State *L, const char *format, ...);
void func(void *L, const char *format, ...);
void error(lua_State *L, const char *format, ...);
void act(lua_State *L, const char *format, ...);
void warning(lua_State *L, const char *format, ...);

double dtime();

void jsleep(int sec, long nsec);

#endif
