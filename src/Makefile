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

ZENROOM_VERSION := 3.0.0
CC ?= gcc
# ARCH := $(shell uname -m)
BRANCH := $(shell git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')
COMMIT := $(shell git rev-parse --short HEAD)
VERSION := ${ZENROOM_VERSION}
CFLAGS  += -I. -I../lib/lua53/src \
	-I../lib/milagro-crypto-c/build/include \
	-I../lib/milagro-crypto-c/include \
	-I../lib/zstd \
	-I../lib/ed25519-donna \
	-I../lib/blake2 \
	-I../lib/mimalloc/include \
	-Wall -Wextra

CMSIS := ../lib/cmsis
CORTEX_M_SRC_ASM = $(CMSIS)/Device/ARM/ARMCM3/Source/GCC/startup_ARMCM3.S
CORTEX_M_SRC_C = $(CMSIS)/Device/ARM/ARMCM3/Source/system_ARMCM3.c
CMSIS_INCLUDE_FLAGS = -I$(CMSIS)/Device/ARM/ARMCM3/Include \
	-I$(CMSIS)/CMSIS/Core/Include
CORTEX_M_CFLAGS = \
	       $(CMSIS_INCLUDE_FLAGS) \
	       -mthumb \
	       -nostartfiles

SOURCES := \
	cli.o zenroom.o zen_error.o \
	lua_functions.o lua_modules.o lualibs_detected.o lua_shims.o \
	encoding.o base58.o rmd160.o segwit_addr.o \
	zen_memory.o mutt_sprintf.o \
	zen_io.o zen_parse.o repl.o zen_config.o \
	zen_octet.o zen_ecp.o zen_ecp2.o zen_big.o \
	zen_fp12.o zen_random.o zen_hash.o \
	zen_ecdh_factory.o zen_ecdh.o \
	zen_aes.o zen_qp.o zen_ed.o zen_float.o \
	api_hash.o randombytes.o \
	cortex_m.o

cortex_m_boot.o: $(CORTEX_M_SRC_ASM)
	${CC} ${CFLAGS} ${CORTEX_M_CFLAGS} -c $^ -o $@

# js: CFLAGS += -I ${EMSCRIPTEN}/system/include/libc -DLIBRARY
js: JSOUT ?= zenroom.js
js: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o ${JSOUT} ${LDFLAGS} ${LDADD} ${JSEXT}

# static: LDADD  += /usr/lib/${ARCH}-linux-musl/libc.a
# using default path for non-native installs of musl
musl: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom ${LDFLAGS} ${LDADD}

linux: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom ${LDFLAGS} ${LDADD}

linux-debug: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom ${LDFLAGS} ${LDADD}


# available vars to identify the build:
# ${ARCH} ${VERSION} ${BRANCH} ${HASH}
linux-lib: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o libzenroom-${ARCH}.so ${LDFLAGS} ${LDADD}

lib-static: ${SOURCES}
	ar x ../lib/lua53/src/liblua.a
	ar x ${MILIB}/libamcl_curve_${ECP}.a
	ar x ${MILIB}/libamcl_pairing_${ECP}.a
	ar x ${MILIB}/libamcl_curve_${ECDH}.a
	ar x ${MILIB}/libamcl_core.a
	ar x ../lib/zstd/libzstd.a
	ar x ../lib/mimalloc/build/libmimalloc-static.a
	ar x ../lib/ed25519-donna/libed25519.a
	${AR} rcs libzenroom-${ARCH}.a *.o

luarock: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o octet.so ${LDFLAGS} ${LDADD}
	${CC} ${CFLAGS} ${SOURCES} -o ecdh.so ${LDFLAGS} ${LDADD}

go: ${SOURCES}
	${CC} -shared ${SOURCES} zen_go.o -o libzenroomgo.so ${LDFLAGS} ${LDADD}

erlang: ${SOURCES} erlang.o
	${CC} -shared ${CFLAGS} ${SOURCES} erlang.o -o zenroom.so ${LDFLAGS} ${LDADD}

osx: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom.command ${LDFLAGS} ${LDADD}

# Call libzenroom.so to simplify python bindings
osx-shared: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o libzenroom-${ARCH}.so ${LDFLAGS} ${LDADD}

win-exe: LDFLAGS += -static
win-exe: ${SOURCES}
	./stamp-exe.sh
	${CC} ${CFLAGS} ${LDFLAGS} -o zenroom.exe zenroom.res ${SOURCES} ${LDADD}
#x86_64-w64-mingw32-strip zenroom.exe

win-dll: CFLAGS += -DLIBRARY
win-dll: LDFLAGS += -shared
win-dll: ${SOURCES}
	./stamp-exe.sh
	${CC} ${CFLAGS} ${LDFLAGS} -o zenroom.dll zenroom.res ${SOURCES} ${LDADD} -Wl,--out-implib,libzenroom_dll.lib

cyg-exe: LDFLAGS += -static
cyg-exe: ${SOURCES}
	./stamp-exe.sh
	${CC} ${CFLAGS} ${LDFLAGS} -o zenroom.exe zenroom.res ${SOURCES} ${LDADD}

cyg-dll: CFLAGS += -DLIBRARY
cyg-dll: LDFLAGS += -shared
cyg-dll: ${SOURCES}
	./stamp-exe.sh
	${CC} ${CFLAGS} ${LDFLAGS} -o zenroom.dll zenroom.res ${SOURCES} ${LDADD} -Wl,--out-implib,zenroom_dll.a



ios-lib: CFLAGS += -D LIBRARY
ios-lib: ${SOURCES}
	libtool -static -o zenroom-ios-${TARGET}.a ${SOURCES} $(shell find ../lib -name \*.a) ${LDADD}

android-arm android-x86 android-aarch64 java-x86_64 java-x86 java-arm java-aarch64: ${SOURCES} zenroom_jni.o
	${CC} ${CFLAGS} ${SOURCES} zenroom_jni.o -o zenroom.so ${LDFLAGS} ${LDADD}

arm: ${SOURCES} cortex_m_boot.o
	${CC} ${CFLAGS} ${CORTEX_M_CFLAGS} ${CORTEX_M_SRC_C} ${SOURCES} cortex_m_boot.o -o zenroom.elf ${LDFLAGS} ${LDADD}
	${OBJCOPY} -O binary zenroom.elf zenroom.bin

aarch64: ${SOURCES}
	${CC} ${CFLAGS} ${SOURCES} -o zenroom ${LDFLAGS} ${LDADD}

debug: CFLAGS+= -ggdb -DDEBUG=1 -Wall
debug: LDADD+= -lm
debug: clean ${SOURCES}

clean:
	rm -f *_factory.c
	rm -f zen_ecdh_factory.h
	rm -f lualibs_detected.c
	rm -f *.o
	rm -f *.so
	rm -f zenroom-static
	rm -f zenroom-shared
	rm -f zenroom.js
	rm -f zenroom.js.mem
	rm -f zenroom.wasm
	rm -f zenroom.html

.c.o:
	$(CC) $(CFLAGS) -c $< -o $@ -DVERSION=\"${VERSION}\" -DMAKETARGET=\"${MAKECMDGOALS}\" -DCOMMIT=\"${COMMIT}\" -DBRANCH=\"${BRANCH}\" -DCFLAGS="${CFLAGS}"
