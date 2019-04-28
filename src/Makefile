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
BRANCH := $(shell git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')
HASH := $(shell git rev-parse --short HEAD)
CFLAGS  += -I. -I../lib/lua53/src -I../lib/milagro-crypto-c/include -Wall -Wextra
SOURCES := \
	jutils.o zenroom.o zen_error.o \
	lua_functions.o lua_modules.o lualibs_detected.o \
	json.o json_strbuf.o json_fpconv.o \
	base58.o cmsgpack.o \
	umm_malloc.o zen_memory.o \
	zen_io.o repl.o \
	zen_octet.o zen_ecp.o zen_ecp2.o zen_big.o \
	zen_fp12.o zen_random.o zen_hash.o \
	zen_ecdh.o zen_ecdh_factory.o \
	randombytes.o \
	cortex_m.o \
	redis_mod.o

all: shared

js: CFLAGS += -I ${EMSCRIPTEN}/system/include/libc -DLIBRARY
js: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom.js ${LDFLAGS} ${LDADD} --embed-file lua@/

js-demo: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o ../docs/demo/index.html ${LDFLAGS} ${LDADD} --preload-file lua@/

# static: LDADD  += /usr/lib/${ARCH}-linux-musl/libc.a
# using default path for non-native installs of musl
musl: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom-static ${LDFLAGS} ${LDADD}

linux: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom-shared ${LDFLAGS} ${LDADD}

linux-lib: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o libzenroom-${ARCH}-${VERSION}-${BRANCH}-${HASH}.so ${LDFLAGS} ${LDADD}

redis: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o redis_zenroom.so-${ARCH}-${VERSION}.so ${LDFLAGS} ${LDADD}

python: ${SOURCES}
	${CC} -shared ${SOURCES} zen_python.o -o _zenroom.so ${LDFLAGS} ${LDADD}

go: ${SOURCES}
	${LD} -shared ${SOURCES} zen_go.o -o libzenroomgo.so ${LDFLAGS} ${LDADD}

java: ${SOURCES}
	${LD} -shared ${SOURCES} zen_java.o -o zenroom-java-linux.so ${LDFLAGS} ${LDADD}

osx: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom.command ${LDFLAGS} ${LDADD}

win-exe: LDFLAGS += -static
win-exe: ${SOURCES}
	./stamp-exe.sh
	${CC} ${CFLAGS} ${LDFLAGS} -o zenroom.exe zenroom.res ${SOURCES} ${LDADD}
	x86_64-w64-mingw32-strip zenroom.exe

win-dll: CFLAGS += -DLIBRARY
win-dll: LDFLAGS += -shared
win-dll: ${SOURCES}
	./stamp-exe.sh
	${CC} ${CFLAGS} ${LDFLAGS} -o zenroom.dll zenroom.res ${SOURCES} ${LDADD} -Wl,--out-implib,zenroom_dll.a

cyg-exe: LDFLAGS += -static
cyg-exe: ${SOURCES}
	./stamp-exe.sh
	${CC} ${CFLAGS} ${LDFLAGS} -o zenroom.exe zenroom.res ${SOURCES} ${LDADD}
	strip zenroom.exe

cyg-dll: CFLAGS += -DLIBRARY
cyg-dll: LDFLAGS += -shared
cyg-dll: ${SOURCES}
	./stamp-exe.sh
	${CC} ${CFLAGS} ${LDFLAGS} -o zenroom.dll zenroom.res ${SOURCES} ${LDADD} -Wl,--out-implib,zenroom_dll.a



ios-lib: CFLAGS += -D LIBRARY
ios-lib: ${SOURCES}
	libtool -static -o zenroom-ios-${TARGET}.a ${SOURCES} $(shell find ../lib -name \*.a) ${LDADD}

android-arm android-x86: ${SOURCES} zenroom_jni.o
	${CC} ${CFLAGS} ${SOURCES} zenroom_jni.o -o zenroom.so ${LDFLAGS} ${LDADD}

cortex-arm: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom.elf ${LDFLAGS} ${LDADD}
	${OBJCOPY} -O binary zenroom.elf zenroom.bin

debug: CFLAGS+= -ggdb -DDEBUG=1 -Wall
debug: LDADD+= -lm
debug: clean ${SOURCES}

clean:
	rm -f *.o
	rm -f *.so
	rm -f zenroom-static
	rm -f zenroom-shared
	rm -f zenroom.js
	rm -f zenroom.js.mem
	rm -f zenroom.html

.c.o:
	$(CC) $(CFLAGS) -c $< -o $@ -DVERSION=\"${VERSION}\"
