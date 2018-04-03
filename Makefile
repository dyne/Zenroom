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

pwd := $(shell pwd)
mil := ${pwd}/build/milagro
extras := ${pwd}/docs/demo

# default
gcc := gcc
ar := ar
ranlib := ranlib
cflags_protection := -fstack-protector-all -D_FORTIFY_SOURCE=2 -fno-strict-overflow
cflags := -O2 ${cflags_protection}
musl := ${pwd}/build/musl
platform := posix
luasrc := ${pwd}/lib/lua53/src

rsa_bits := ""
ecc_curves := ED25519,NIST256,GOLDILOCKS,BN254CX,FP256BN

test-exec := ${pwd}/src/zenroom-shared -c ${pwd}/test/decode-test.conf

patches:
	./build/apply-patches

embed-lua:
	@echo "Embedding all files in src/lua"
	${gcc} -I${luasrc} -o build/luac ${luasrc}/luac.c ${luasrc}/liblua.a -lm
	./build/embed-lualibs
	@echo "File generated: src/lualibs_detected.c"
	@echo "    and lualbs: src/lualib_*.c"
	@echo "Must commit to git if modified, see git diff."

# TODO: improve flags according to
# https://github.com/kripken/emscripten/blob/master/src/settings.js
js: gcc=${EMSCRIPTEN}/emcc
js: ar=${EMSCRIPTEN}/emar
js: cflags := --memory-init-file 0 -O2 -D'ARCH=\"JS\"'
js: ldflags := -s "EXPORTED_FUNCTIONS='[\"_zenroom_exec\"]'" -s "EXTRA_EXPORTED_RUNTIME_METHODS='[\"ccall\",\"cwrap\"]'" -s ALLOW_MEMORY_GROWTH=1 -s USE_SDL=0
js: patches lua53 milagro-js
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src js

wasm: gcc=${EMSCRIPTEN}/emcc
wasm: ar=${EMSCRIPTEN}/emar
wasm: cflags := -O2 -D'ARCH=\"WASM\"'
wasm: ldflags := -s WASM=1 -s "EXPORTED_FUNCTIONS='[\"_zenroom_exec\"]'" -s "EXTRA_EXPORTED_RUNTIME_METHODS='[\"ccall\",\"cwrap\"]'" -s MODULARIZE=1
wasm: patches lua53 milagro-js
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src js

demo: gcc=${EMSCRIPTEN}/emcc
demo: ar=${EMSCRIPTEN}/emar
demo: cflags := -O2 -D'ARCH=\"WASM\"'
demo: ldflags := -s WASM=1 -s "EXPORTED_FUNCTIONS='[\"_zenroom_exec\"]'" -s "EXTRA_EXPORTED_RUNTIME_METHODS='[\"ccall\",\"cwrap\"]'" -s ASSERTIONS=1 --shell-file ${extras}/shell_minimal.html -s NO_EXIT_RUNTIME=1 -s USE_SDL=0 -s USE_PTHREADS=0
demo: patches lua53 milagro-js
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src demo

html: gcc=${EMSCRIPTEN}/emcc
html: ar=${EMSCRIPTEN}/emar
html: cflags := -O2 -D'ARCH=\"JS\"'
html: ldflags := -sEXPORTED_FUNCTIONS='["_main","_zenroom_exec"]'
html: patches  lua53 milagro-js
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src html

win: gcc=x86_64-w64-mingw32-gcc
win: ar=x86_64-w64-mingw32-ar
win: ranlib=x86_64-w64-mingw32-ranlib
win: cflags += -D'ARCH=\"WIN\"' -std=c99
win: platform = posix
win: patches lua53 milagro-win
	CC=${gcc} CFLAGS="${cflags}" make -C src win

static: gcc := musl-gcc
static: cflags := -Os -static -Wall -std=gnu99 ${cflags_protection} -D'ARCH=\"MUSL\"'
static: ldflags := -static
static: patches lua53 milagro
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src static

system-static: cflags := -Os -static -Wall -std=gnu99 ${cflags_protection} -D'ARCH=\"UNIX\"'
system-static: ldflags := -static
system-static: patches lua53 milagro
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src system-static

shared: gcc := gcc
shared: cflags := -O2 -fPIC ${cflags_protection} -D'ARCH=\"LINUX\"'
shared: ldflags := -lm
shared: platform := linux
shared: patches lua53 milagro
	CC=${gcc} CFLAGS="${cflags}" make -C src shared


osx: gcc := gcc
osx: cflags := -O2 -fPIC ${cflags_protection} -D'ARCH=\"OSX\"'
osx: ldflags := -lm
osx: platform := macosx
osx: patches lua53 milagro
	CC=${gcc} CFLAGS="${cflags}" make -C src shared

ios-armv7: ARCH := armv7
ios-armv7: OS := iphoneos
ios-armv7: gcc := $(shell xcrun --sdk iphoneos -f gcc 2>/dev/null)
ios-armv7: ar := $(shell xcrun --sdk iphoneos -f ar 2>/dev/null)
ios-armv7: ld := $(shell xcrun --sdk iphoneos -f ld 2>/dev/null)
ios-armv7: ranlib := $(shell xcrun --sdk iphoneos -f ranlib 2>/dev/null)
ios-armv7: SDK := $(shell xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
ios-armv7: cflags := -O2 -fPIC ${cflags_protection} -D'ARCH=\"OSX\"' -isysroot ${SDK} -arch ${ARCH} -D NO_SYSTEM
ios-armv7: ldflags := -lm
ios-armv7: platform := ios
ios-armv7: patches lua53 milagro
	CC=${gcc} CFLAGS="${cflags}" make -C src library
	${AR} rcs zenroom-armv7.a `find . -name \*.o`

ios-arm64: ARCH := arm64
ios-arm64: OS := iphoneos
ios-arm64: gcc := $(shell xcrun --sdk iphoneos -f gcc 2>/dev/null)
ios-arm64: ar := $(shell xcrun --sdk iphoneos -f ar 2>/dev/null)
ios-arm64: ld := $(shell xcrun --sdk iphoneos -f ld 2>/dev/null)
ios-arm64: ranlib := $(shell xcrun --sdk iphoneos -f ranlib 2>/dev/null)
ios-arm64: SDK := $(shell xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
ios-arm64: cflags := -O2 -fPIC ${cflags_protection} -D'ARCH=\"OSX\"' -isysroot ${SDK} -arch ${ARCH} -D NO_SYSTEM
ios-arm64: ldflags := -lm
ios-arm64: platform := ios
ios-arm64: patches lua53 milagro
	CC=${gcc} CFLAGS="${cflags}" make -C src library
	${AR} rcs zenroom-arm64.a `find . -name \*.o`

ios-sim: ARCH := x86_64
ios-sim: OS := iphonesimulator
ios-sim: gcc := $(shell xcrun --sdk iphonesimulator -f gcc 2>/dev/null)
ios-sim: ar := $(shell xcrun --sdk iphonesimulator -f ar 2>/dev/null)
ios-sim: ld := $(shell xcrun --sdk iphonesimulator -f ld 2>/dev/null)
ios-sim: ranlib := $(shell xcrun --sdk iphonesimulator -f ranlib 2>/dev/null)
ios-sim: SDK := $(shell xcrun --sdk iphonesimulator --show-sdk-path 2>/dev/null)
ios-sim: cflags := -O2 -fPIC ${cflags_protection} -D'ARCH=\"OSX\"' -isysroot ${SDK} -arch ${ARCH} -D NO_SYSTEM
ios-sim: ldflags := -lm
ios-sim: platform := ios
ios-sim: patches lua53 milagro
	CC=${gcc} CFLAGS="${cflags}" make -C src library
	${AR} rcs zenroom-x86_64.a `find . -name \*.o`


ios-fat:
	lipo -create zenroom-x86_64.a zenroom-arm64.a zenroom-armv7.a -output zenroom.a

android: gcc := $(CC)
android: ar := $(AR)
android: ranlib := $(RANLIB)
android: ld := $(ld)
android: cflags := ${cflags} -std=c99 -shared -DLUA_USE_DLOPEN
android: patches lua53 luazen milagro
	LDFLAGS="--sysroot=/tmp/ndk-arch-21/sysroot" CC=${gcc} CFLAGS="${cflags}" make -C src android


debug: gcc := gcc
debug: cflags := -O0 -ggdb -D'ARCH=\"LINUX\"' ${cflags_protection}
debug: patches lua53 milagro
	CC=${gcc} CFLAGS="${cflags}" make -C src shared

lua53:
	CC=${gcc} CFLAGS="${cflags} \
	-DLUA_COMPAT_5_3 -DLUA_COMPAT_MODULE" \
	LDFLAGS="${ldflags}" AR="${ar}" RANLIB=${ranlib} \
	make -C ${pwd}/lib/lua53/src ${platform}

gmp:
	cd ${pwd}/lib/gmp && CFLAGS="${cflags}" CC=${gcc} ./configure --disable-shared
	make -C ${pwd}/lib/gmp

pbc:
	mkdir -p ${pwd}/build/pbc
	if ! [ ${pwd}/build/pbc/.libs/libpbc.a ]; then cd ${pwd}/build/pbc && CFLAGS="${cflags}" CC=${gcc} ${pwd}/lib/pbc/configure --disable-shared &&	make -C ${pwd}/build/pbc LDFLAGS="-L${pwd}/lib/gmp/.libs -l:libgmp.a" CFLAGS="${cflags} -I${pwd}/lib/gmp -I${pwd}/lib/pbc/include"; return 0; fi

luazen:
	CC=${gcc} AR=${ar} CFLAGS="${cflags}" make -C ${pwd}/build/luazen

milagro:
	@echo "-- Building milagro (POSIX)"
	if ! [ -r ${pwd}/lib/milagro-crypto-c/CMakeCache.txt ]; then cd ${pwd}/lib/milagro-crypto-c && CC=${gcc} cmake . -DBUILD_SHARED_LIBS=OFF -DBUILD_PYTHON=OFF -DBUILD_DOXYGEN=OFF -DCMAKE_C_FLAGS="${cflags}" -DAMCL_CHUNK=32 -DAMCL_CURVE="${ecc_curves}" -DAMCL_RSA="${rsa_bits}"; fi
	if ! [ -r ${pwd}/lib/milagro-crypto-c/lib/libamcl_core.a ]; then CC=${gcc} CFLAGS="${cflags}" make -C ${pwd}/lib/milagro-crypto-c VERBOSE=1; fi

milagro-win:
	@echo "-- Building milagro (Windows)"
	sed -i 's/project (AMCL)/project (AMCL C)/' ${pwd}/lib/milagro-crypto-c/CMakeLists.txt
	if ! [ -r ${pwd}/lib/milagro-crypto-c/CMakeCache.txt ]; then cd ${pwd}/lib/milagro-crypto-c && CC=${gcc} cmake . -DBUILD_SHARED_LIBS=OFF -DBUILD_PYTHON=OFF -DBUILD_DOXYGEN=OFF -DCMAKE_C_FLAGS="${cflags}" -DAMCL_CHUNK=32 -DAMCL_CURVE=${ecc_curves} -DAMCL_RSA=${rsa_bits} -DCMAKE_SHARED_LIBRARY_LINK_FLAGS="" -DCMAKE_SYSTEM_NAME="Windows"; fi
	if ! [ -r ${pwd}/lib/milagro-crypto-c/lib/libamcl_core.a ]; then CC=${gcc} CFLAGS="${cflags}" make -C ${pwd}/lib/milagro-crypto-c; fi

milagro-js:
	@echo "-- Building milagro (JS Emscripten)"
	sed -i 's/project (AMCL)/project (AMCL C)/' ${pwd}/lib/milagro-crypto-c/CMakeLists.txt
	if ! [ -r ${pwd}/lib/milagro-crypto-c/CMakeCache.txt ]; then cd ${pwd}/lib/milagro-crypto-c && CC=${gcc} cmake . -DBUILD_SHARED_LIBS=OFF -DBUILD_PYTHON=OFF -DBUILD_DOXYGEN=OFF -DCMAKE_C_FLAGS="${cflags}" -DAMCL_CHUNK=32 -DAMCL_CURVE=${ecc_curves} -DAMCL_RSA=${rsa_bits} -DCMAKE_SHARED_LIBRARY_LINK_FLAGS="" -DCMAKE_SYSTEM_NAME="Javascript"; fi
	if ! [ -r ${pwd}/lib/milagro-crypto-c/lib/libamcl_core.a ]; then CC=${gcc} CFLAGS="${cflags}" make -C ${pwd}/lib/milagro-crypto-c; fi

#-DCMAKE_TOOLCHAIN_FILE="${pwd}/lib/milagro-crypto-c/resources/cmake/emscripten-cross.cmake"


check-milagro: milagro
	CC=${gcc} CFLAGS="${cflags}" make -C ${pwd}/lib/milagro-crypto-c test

## tests that require too much memory
himem-tests = \
 @${1} test/sort.lua && \
 ${1} test/literals.lua && \
 ${1} test/calls.lua && \
 ${1} test/pm.lua && \
 ${1} test/nextvar.lua && \
 ${1} test/constructs.lua && \
 ${1} test/cjson-test.lua

## GC tests break memory management with umm
# in particular steps (2)
# ${1} test/gc.lua && \


lowmem-tests = \
		@${1} test/vararg.lua && \
		${1} test/utf8.lua && \
		${1} test/tpack.lua && \
		${1} test/strings.lua && \
		${1} test/math.lua && \
		${1} test/goto.lua && \
		${1} test/events.lua && \
		${1} test/coroutine.lua && \
		${1} test/code.lua && \
		${1} test/closure.lua && \
		${1} test/locals.lua && \
		${1} test/schema.lua && \
		${1} test/octet.lua && \
		${1} test/ecdh.lua


check-shared: test-exec-lowmem := ${pwd}/src/zenroom-shared -c umm
check-shared: test-exec := ${pwd}/src/zenroom-shared
check-shared:
	$(call lowmem-tests,${test-exec-lowmem})
	$(call himem-tests,${test-exec})
	./test/octet-json.sh ${test-exec}
	@echo "----------------"
	@echo "All tests passed for SHARED binary build"
	@echo "----------------"


check-static: test-exec := ${pwd}/src/zenroom-static
check-static: test-exec-lowmem := ${pwd}/src/zenroom-static -c umm
check-static:
	$(call lowmem-tests,${test-exec-lowmem})
	$(call himem-tests,${test-exec})
	./test/octet-json.sh ${test-exec}
	@echo "----------------"
	@echo "All tests passed for SHARED binary build"
	@echo "----------------"

check-js: test-exec := nodejs ${pwd}/test/zenroom_exec.js ${pwd}/src/zenroom.js
check-js:
	$(call lowmem-tests,${test-exec})
	$(call himem-tests,${test-exec})
	@echo "----------------"
	@echo "All tests passed for SHARED binary build"
	@echo "----------------"

check-debug: test-exec-lowmem := valgrind --max-stackframe=2064480 ${pwd}/src/zenroom-shared -c umm
check-debug: test-exec := valgrind --max-stackframe=2064480 ${pwd}/src/zenroom-shared
check-debug:
	$(call lowmem-tests,${test-exec-lowmem})
	$(call himem-tests,${test-exec})
	./test/octet-json.sh ${test-exec}
	@echo "----------------"
	@echo "All tests passed for SHARED binary build"
	@echo "----------------"

check-osx: test-exec-lowmem := ${pwd}/src/zenroom-shared -c umm
check-osx: test-exec := ${pwd}/src/zenroom-shared
check-osx:
	$(call lowmem-tests,${test-exec-lowmem})
	$(call himem-tests,${test-exec})
	@echo "----------------"
	@echo "All tests passed for OSX binary build"
	@echo "----------------"

clean:
	make clean -C ${pwd}/lib/lua53/src
	make clean -C ${pwd}/lib/milagro-crypto-c && \
		rm -f ${pwd}/lib/milagro-crypto-c/CMakeCache.txt
	make clean -C src
	rm -f ${extras}/index.*

distclean:
	rm -rf ${musl}
