CC?=gcc
VERSION := $(shell cat ../VERSION)

CFLAGS  := -I. -I../lib/lua_sandbox/include
SOURCES := jutils.o lua_functions.o decode-exec.o
LDADD   := ../build/lua_sandbox/src/libluasandbox.a
LDADD   += ../build/lua_sandbox/src/util/libluasandboxutil.a
LDADD   += ../build/luazen/libluazen.a

all: static

js: CFLAGS += -I ${EMSCRIPTEN}/system/include/libc
js: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom.js ${LDFLAGS} ${LDADD}

static: LDADD   += ../build/jemalloc/lib/libjemalloc.a
static: LDADD   += ../build/pbc/.libs/libpbc.a
static: CC := ../build/musl/obj/musl-gcc
static: CFLAGS += -Os -fstack-protector -Wall -Wextra -pedantic -std=gnu99
static: LDADD  += ../build/musl/lib/libc.a
static: LDFLAGS += -static
static: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom-static ${LDFLAGS} ${LDADD}

shared: CFLAGS+=  -O3 -Wall
shared: LDADD+=   -lm -ldl
shared: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom-shared ${LDFLAGS} ${LDADD}

debug: CFLAGS+= -ggdb -DDEBUG=1 -Wall
debug: LDADD+= -lm -ldl
debug: clean ${SOURCES}

clean:
	rm -f *.o
	rm -f zenroom-static
	rm -f zenroom.js

.c.o:
	$(CC) $(CFLAGS) -c $< -o $@ -DVERSION=\"${VERSION}\"
