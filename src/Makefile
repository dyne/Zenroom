CC?=gcc
LDD?=ld
PREFIX?=/usr/local
VERSION := $(shell cat ../VERSION)

CFLAGS  := -I. -I../lib/lua_sandbox/include
SOURCES := jutils.o timing.o decode-exec.o
LDADD   := ../build/lua_sandbox/src/libluasandbox.a
LDADD   += ../build/lua_sandbox/src/util/libluasandboxutil.a

all: musl

decode-exec: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o decode-exec ${LDFLAGS} ${LDADD}

shared: CFLAGS+=  -O3 -Wall
shared: LDADD+=   -lm -ldl
shared: ${SOURCES} decode-exec

#	${CC} ${CFLAGS} ${SOURCES} -o decode-exec ${LDFLAGS} ${LDADD}

musl: CC := ../build/musl/obj/musl-gcc
musl: CFLAGS += -O3 -Wall
musl: LDADD  += ../build/musl/lib/libc.a
musl: LDFLAGS += -static
musl: ${SOURCES} decode-exec

# musl:
# 	/usr/local/musl/bin/musl-gcc jutils.c decode-exec.c -Os -o decode-exec -DDEBUG=1 -Wall \
# 		-I. -I/usr/local/musl/include -I../lib/lua_sandbox/include \
# 		/usr/local/musl/lib/libc.a \
# 		../lib/lua_sandbox/src/libluasandbox.a \
# 		../lib/lua_sandbox/src/util/libluasandboxutil.a -lm \
# 		-static -o decode-exec

debug: CFLAGS+= -ggdb -DDEBUG=1 -Wall
debug: LDADD+= -lm -ldl
debug: clean ${SOURCES} decode-exec

clean:
	rm -f *.o
	rm -f decode-exec

.c.o:
	$(CC) $(CFLAGS) -c $< -o $@ -DVERSION=\"${VERSION}\"
