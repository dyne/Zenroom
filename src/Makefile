CC?=gcc
VERSION := $(shell cat ../VERSION)

CFLAGS  += -I. -I../lib/lua_sandbox/include
SOURCES := jutils.o lua_functions.o zenroom.o frozen.o
LDADD   := ../build/lua_sandbox/src/libluasandbox.a
LDADD   += ../build/lua_sandbox/src/util/libluasandboxutil.a
LDADD   += ../build/luazen/libluazen.a
LDADD   += ../lib/milagro-c/libmilagro.a

all: shared

js: CFLAGS += -I ${EMSCRIPTEN}/system/include/libc
js: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom.js ${LDFLAGS} ${LDADD}

html: CFLAGS += -I ${EMSCRIPTEN}/system/include/libc
html: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom.html ${LDFLAGS} ${LDADD}

static: LDADD	+= ../build/jemalloc/lib/libjemalloc.a
static: CC := ../build/musl/obj/musl-gcc
static: CFLAGS += -Os -Wall -Wextra -pedantic -std=gnu99
static: LDADD  += ../build/musl/lib/libc.a
static: LDFLAGS += -static
static: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom-static ${LDFLAGS} ${LDADD}

system-static: LDADD += ../build/jemalloc/lib/libjemalloc.a
system-static: CFLAGS += -Os -Wall -Wextra -pedantic -std=gnu99
system-static: LDFLAGS += -static
system-static: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom-static ${LDFLAGS} ${LDADD}

shared: CFLAGS+=  -O3 -Wall
shared: LDADD+=   -lm -lpthread -ljemalloc
shared: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom-shared ${LDFLAGS} ${LDADD}

win: CFLAGS +=  -O3 -Wall -Wextra -pedantic -std=gnu99
win: LDFLAGS += -L/usr/x86_64-w64-mingw32/lib -static
win: LDADD +=  -l:libm.a -l:libpthread.a
win: ${SOURCES}
	./stamp-exe.sh
	${CC} ${CFLAGS} ${LDFLAGS} -o zenroom.exe zenroom.res ${SOURCES} ${LDADD}
	x86_64-w64-mingw32-strip zenroom.exe


debug: CFLAGS+= -ggdb -DDEBUG=1 -Wall
debug: LDADD+= -lm
debug: clean ${SOURCES}

clean:
	rm -f *.o
	rm -f zenroom-static
	rm -f zenroom.js

.c.o:
	$(CC) $(CFLAGS) -c $< -o $@ -DVERSION=\"${VERSION}\"
