#  Zenroom (GNU Makefile build system)
#
#  (c) Copyright 2017-2018 Dyne.org foundation
#  designed, written and maintained by Denis Roio <jaromil@dyne.org>
#
#  This program is free software: you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version
#  3 as published by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see
#  <http://www.gnu.org/licenses/>.

CC?=gcc
VERSION := $(shell cat ../VERSION)
ARCH := $(shell uname -m)
CFLAGS  += -I. -I../lib/lua53/src -I../lib/milagro-crypto-c/include -Wall -Wextra
SOURCES := jutils.o lua_functions.o zenroom.o lua_cjson.o strbuf.o fpconv.o repl.o lualibs_detected.o lua_modules.o lua_io.o crypto.o octet.o rsa.o randombytes.o
LDADD   := ../lib/lua53/src/liblua.a
LDADD   += ../build/luazen/libluazen.a

milib := ../lib/milagro-crypto-c/lib
LDADD += ${milib}/libamcl_core.a
LDADD += ${milib}/libamcl_rsa_2048.a ${milib}/libamcl_rsa_4096.a
LDADD += ${milib}/libamcl_curve_ED25519.a


all: shared

js: CFLAGS += -I ${EMSCRIPTEN}/system/include/libc
js: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom.js ${LDFLAGS} ${LDADD}

html: CFLAGS += -I ${EMSCRIPTEN}/system/include/libc
html: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom.html ${LDFLAGS} ${LDADD}

demo: CFLAGS += -I ${EMSCRIPTEN}/system/include/libc
demo: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o ../docs/demo/index.html ${LDFLAGS} ${LDADD}

static: LDADD  += /usr/lib/${ARCH}-linux-musl/libc.a
static: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom-static ${LDFLAGS} ${LDADD}

system-static: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom-static ${LDFLAGS} ${LDADD}

shared: LDADD+=   -lm -lpthread
shared: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom-shared ${LDFLAGS} ${LDADD}

win: CFLAGS +=  -O3 -Wall -Wextra -pedantic -std=gnu99
win: LDFLAGS += -L/usr/x86_64-w64-mingw32/lib -static
win: LDADD +=  -l:libm.a -l:libpthread.a -lssp
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
	rm -f zenroom-shared
	rm -f zenroom.js
	rm -f zenroom.js.mem
	rm -f zenroom.html

.c.o:
	$(CC) $(CFLAGS) -c $< -o $@ -DVERSION=\"${VERSION}\"
