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

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <time.h> // nanosleep
#include <sys/time.h> // gettimeofday
#include <unistd.h>
#include <string.h>
#include <errno.h>

#include <zenroom.h>
#include <zen_error.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#define MAX_DEBUG 2
// #define MAX_STRING 1024
#define FUNC 2 /* se il debug level e' questo
		  ci sono le funzioni chiamate */
#define WARN 1 /* ... blkbblbl */

char msg[MAX_STRING];

static int verbosity = 1;

void set_debug(int lev) {
  lev = lev<0 ? 0 : lev;
  lev = lev>MAX_DEBUG ? MAX_DEBUG : lev;
  verbosity = lev;
}

int get_debug() {
  return(verbosity);
}

static zenroom_t *getzen(lua_State *L) {
	if(!L) return NULL;
	lua_getglobal(L, "_Z");
	zenroom_t *Z = lua_touserdata(L, -1);
	lua_pop(L, 1);
	return(Z);
}

static zenroom_t *stderr_tobuffer(lua_State *L) {
	if(!L) return NULL;
	zenroom_t *Z = getzen(L);
	if(Z->stderr_buf) return Z;
	return NULL;
}

static void _printf(zenroom_t *Z, char *pfx, char *msg) {
	if(!Z) {
		fprintf(stderr,"%s %s\n",pfx,msg);
	} else if(Z->stderr_buf) {
		char *err = Z->stderr_buf;
		size_t len = strlen(msg);
		snprintf(err+Z->stderr_pos,
		         Z->stderr_len-Z->stderr_pos,
		         "%s %s\n", pfx,msg);
		Z->stderr_pos+=len+5;
	} else {
		fprintf(stderr,"%s %s\n",pfx,msg);
	}
}

static void _printline(zenroom_t *Z, lua_State *L) {
	if(!Z || !L) return;
	lua_Debug ar;
	if(lua_getstack(L, 1, &ar) && lua_getinfo(L, "nSl", &ar)) {
		char err[MAX_STRING];
		snprintf(err,MAX_STRING-1,"%s:%u: ERROR",
		         ar.short_src, ar.currentline);
		_printf(Z,"[!]",err);
	} else
		_printf(Z,"[!]","[UKNOWN STACK]:?: ERROR");
}

void notice(lua_State *L, const char *format, ...) {
  va_list arg;
  va_start(arg, format);

  vsnprintf(msg, MAX_STRING, format, arg);
  _printf(stderr_tobuffer(L), "[*]", msg);
  va_end(arg);
}

void func(lua_State *L, const char *format, ...) {
  if(verbosity>=FUNC) {
    va_list arg;
    va_start(arg, format);
    
    vsnprintf(msg, MAX_STRING, format, arg);
    _printf(stderr_tobuffer(L), "[F]", msg);
    va_end(arg);
  }
}

void error(lua_State *L, const char *format, ...) {
  va_list arg;
  va_start(arg, format);
  vsnprintf(msg, MAX_STRING, format, arg);
  zenroom_t *Z = getzen(L);
  _printline(Z, L);
  _printf(Z, "[!]", msg);
  va_end(arg);
  Z->errorlevel = 3;
  // exit(1); // calls teardown (signal 11) TODO: check if OK with seccomp
}

void act(lua_State *L, const char *format, ...) {
  va_list arg;
  va_start(arg, format);
  
  vsnprintf(msg, MAX_STRING, format, arg);
  _printf(stderr_tobuffer(L), " . ", msg);
  va_end(arg);
}

void warning(lua_State *L, const char *format, ...) {
  if(verbosity>=WARN) {
    va_list arg;
    va_start(arg, format);
    
    vsnprintf(msg, MAX_STRING, format, arg);
    _printf(stderr_tobuffer(L), "[W]", msg);
    va_end(arg);
  }
  getzen(L)->errorlevel = 2;
}


#undef ARCH_X86
double dtime() {
#ifdef ARCH_X86
  double x;
  __asm__ volatile (".byte 0x0f, 0x31" : "=A" (x));
  return x;
#else
  struct timeval mytv;
  gettimeofday(&mytv,NULL);
  return((double)mytv.tv_sec+1.0e-6*(double)mytv.tv_usec);
#endif
}


/* From the manpage:
 * nanosleep  delays  the execution of the program for at least
 * the time specified in *req.  The function can return earlier
 * if a signal has been delivered to the process. In this case,
 * it returns -1, sets errno to EINTR, and writes the remaining
 * time into the structure pointed to by rem unless rem is
 * NULL.  The value of *rem can then be used to call nanosleep
 * again and complete the specified pause.
 */ 
void jsleep(int sec, long nsec) {
    struct timespec tmp_rem,*rem;
    rem = &tmp_rem;
    struct timespec timelap;
    timelap.tv_sec = sec;
    timelap.tv_nsec = nsec;
    while (nanosleep (&timelap, rem) == -1 && (errno == EINTR));
}


