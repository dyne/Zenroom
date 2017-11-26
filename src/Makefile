CC?=gcc
VERSION := $(shell cat ../VERSION)

CFLAGS  := -I. -I../lib/lua_sandbox/include
SOURCES := jutils.o timing.o decode-exec.o
LDADD   := ../build/lua_sandbox/src/libluasandbox.a
LDADD   += ../build/lua_sandbox/src/util/libluasandboxutil.a
LDADD   += ../build/luanacha/libluanacha.a

all: musl

decode-exec: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o decode-exec ${LDFLAGS} ${LDADD}

musl: CC := ../build/musl/obj/musl-gcc
musl: CFLAGS += -Os -Wall -Wextra -pedantic -std=gnu99
musl: LDADD  += ../build/musl/lib/libc.a
musl: LDFLAGS += -static
musl: ${SOURCES} decode-exec

shared: CFLAGS+=  -O3 -Wall
shared: LDADD+=   -lm -ldl
shared: ${SOURCES} decode-exec

debug: CFLAGS+= -ggdb -DDEBUG=1 -Wall
debug: LDADD+= -lm -ldl
debug: clean ${SOURCES} decode-exec

clean:
	rm -f *.o
	rm -f decode-exec

.c.o:
	$(CC) $(CFLAGS) -c $< -o $@ -DVERSION=\"${VERSION}\"
