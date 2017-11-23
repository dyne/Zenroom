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

#define MAX_DEBUG 2
#define MAX_STRING 1024
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


void notice(const char *format, ...) {
  va_list arg;
  va_start(arg, format);

  vsnprintf(msg, MAX_STRING, format, arg);

  fprintf(stderr,"[*] %s\n",msg);
  
  va_end(arg);
}

void func(const char *format, ...) {
  if(verbosity>=FUNC) {
    va_list arg;
    va_start(arg, format);
    
    vsnprintf(msg, MAX_STRING, format, arg);

    fprintf(stderr,"[F] %s\n",msg);

    va_end(arg);
  }
}

void error(const char *format, ...) {
  va_list arg;
  va_start(arg, format);
  
  vsnprintf(msg, MAX_STRING, format, arg);

  fprintf(stderr,"[!] %s\n",msg);

  va_end(arg);
}

void act(const char *format, ...) {
  va_list arg;
  va_start(arg, format);
  
  vsnprintf(msg, MAX_STRING, format, arg);

  fprintf(stderr," .  %s\n",msg);
  
  va_end(arg);
}

void warning(const char *format, ...) {
  if(verbosity>=WARN) {
    va_list arg;
    va_start(arg, format);
    
    vsnprintf(msg, MAX_STRING, format, arg);

    fprintf(stderr,"[W] %s\n",msg);
  
    va_end(arg);
  }
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


