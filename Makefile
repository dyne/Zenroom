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

# milagro settings
rsa_bits := ""
ecc_curves := ED25519,BLS383,GOLDILOCKS
milagro_cmake_flags := -DBUILD_SHARED_LIBS=OFF -DBUILD_PYTHON=OFF -DBUILD_DOXYGEN=OFF -DWORD_SIZE=32 -DAMCL_CURVE=${ecc_curves} -DAMCL_RSA=${rsa_bits} -DCMAKE_SHARED_LIBRARY_LINK_FLAGS="" -DC99=1 -DPAIRING_FRIENDLY_BLS383='BLS'

test-exec := ${pwd}/src/zenroom-shared -c ${pwd}/test/decode-test.conf

all:
	@echo "Choose a target:"
	@echo "- js, wasm, demo, html	(need EMSDK env loaded)"
	@echo "- shared, debug		(uses GCC, opt debugging symbols)"
	@echo "- osx			(uses default compiler on Apple/OSX)"
	@echo "- win			(cross-compile using MINGW on Linux)"
	@echo "- static		(fully static build using MUSLCC)"
	@echo "- system-static		(static build using system CC)"
	@echo "for android and ios see scripts in build/"

embed-lua:
	@echo "Embedding all files in src/lua"
	if ! [ -r build/luac ]; then ${gcc} -I${luasrc} -o build/luac ${luasrc}/luac.c ${luasrc}/liblua.a -lm; fi
	./build/embed-lualibs
	@echo "File generated: src/lualibs_detected.c"
	@echo "Must commit to git if modified, see git diff."

apply-patches:
	${pwd}/build/apply-patches

# TODO: improve flags according to
# https://github.com/kripken/emscripten/blob/master/src/settings.js
js: gcc=${EMSCRIPTEN}/emcc
js: ar=${EMSCRIPTEN}/emar
js: cflags := -O2 -D'ARCH=\"JS\"' -Wall -DARCH_JS
js: ldflags := -s "EXPORTED_FUNCTIONS='[\"_zenroom_exec\",\"_zenroom_exec_tobuf\",\"_zenroom_parse_ast\",\"_set_debug\"]'" -s "EXTRA_EXPORTED_RUNTIME_METHODS='[\"ccall\",\"cwrap\"]'" -s USE_SDL=0
js: apply-patches lua53 milagro-js lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src js
	@mkdir -p build/nodejs
	@cp -v src/zenroom.js 	 build/nodejs/
	@cp -v src/zenroom.js.mem build/nodejs/

wasm: gcc=${EMSCRIPTEN}/emcc
wasm: ar=${EMSCRIPTEN}/emar
wasm: cflags := -O2 -D'ARCH=\"WASM\"' -Wall -DARCH_WASM
wasm: ldflags := -s WASM=1 -s "EXPORTED_FUNCTIONS='[\"_zenroom_exec\",\"_zenroom_exec_tobuf\",\"_zenroom_parse_ast\",\"_set_debug\"]'" -s "EXTRA_EXPORTED_RUNTIME_METHODS='[\"ccall\",\"cwrap\"]'" -s MODULARIZE=1 -s USE_SDL=0 -s USE_PTHREADS=0
wasm: apply-patches lua53 milagro-js lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src js
	@mkdir -p build/wasm
	@cp -v src/zenroom.js   build/wasm/
	@cp -v src/zenroom.wasm build/wasm/

demo: gcc=${EMSCRIPTEN}/emcc
demo: ar=${EMSCRIPTEN}/emar
demo: cflags := -O2 -D'ARCH=\"WASM\"' -DARCH_WASM
demo: ldflags := -s WASM=1 -s "EXPORTED_FUNCTIONS='[\"_zenroom_exec\",\"_zenroom_exec_tobuf\",\"_zenroom_parse_ast\",\"_set_debug\"]'" -s "EXTRA_EXPORTED_RUNTIME_METHODS='[\"ccall\",\"cwrap\"]'" -s ASSERTIONS=1 --shell-file ${extras}/shell_minimal.html -s NO_EXIT_RUNTIME=1 -s USE_SDL=0 -s USE_PTHREADS=0
demo: apply-patches lua53 milagro-js lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src demo

html: gcc=${EMSCRIPTEN}/emcc
html: ar=${EMSCRIPTEN}/emar
html: cflags := -O2 -D'ARCH=\"JS\"' -DARCH_JS
html: ldflags := -sEXPORTED_FUNCTIONS='["_main","_zenroom_exec",\"_zenroom_exec_tobuf\",\"_zenroom_parse_ast\",\"_set_debug\"]'
html: apply-patches lua53 milagro-js lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src html

win: gcc=x86_64-w64-mingw32-gcc
win: ar=x86_64-w64-mingw32-ar
win: ranlib=x86_64-w64-mingw32-ranlib
win: cflags += -D'ARCH=\"WIN\"' -std=c99 -DARCH_WIN
win: platform = posix
win: apply-patches lua53 milagro-win lpeglabel
	CC=${gcc} CFLAGS="${cflags}" make -C src win-exe

win-dll: gcc=x86_64-w64-mingw32-gcc
win-dll: ar=x86_64-w64-mingw32-ar
win-dll: ranlib=x86_64-w64-mingw32-ranlib
win-dll: cflags += -D'ARCH=\"WIN\"' -std=c99 -DARCH_WIN
win-dll: platform = posix
win-dll: apply-patches lua53 milagro-win lpeglabel
	CC=${gcc} CFLAGS="${cflags}" make -C src win-dll



static: gcc := musl-gcc
static: cflags := -Os -static -Wall -std=gnu99 ${cflags_protection} -D'ARCH=\"MUSL\"' -D__MUSL__ -DARCH_MUSL
static: ldflags := -static
static: apply-patches lua53 milagro lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src static

system-static: cflags := -Os -static -Wall -std=gnu99 ${cflags_protection} -D'ARCH=\"UNIX\"' -D__MUSL__ -DARCH_MUSL
system-static: ldflags := -static
system-static: apply-patches lua53 milagro lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src system-static

shared: gcc := gcc
shared: cflags := -O2 -fPIC ${cflags_protection} -D'ARCH=\"LINUX\"' -DARCH_LINUX
shared: ldflags := -lm
shared: platform := linux
shared: apply-patches lua53 milagro lpeglabel
	CC=${gcc} CFLAGS="${cflags}" make -C src shared

shared-lib: gcc := gcc
shared-lib: cflags := -O2 -fPIC ${cflags_protection} -D'ARCH=\"LINUX\"' -shared -DARCH_LINUX
shared-lib: ldflags := -lm
shared-lib: platform := linux
shared-lib: apply-patches lua53 milagro lpeglabel
	CC=${gcc} CFLAGS="${cflags}" make -C src shared-lib

osx: gcc := gcc
osx: cflags := -O2 -fPIC ${cflags_protection} -D'ARCH=\"OSX\"' -DARCH_OSX
osx: ldflags := -lm
osx: platform := macosx
osx: apply-patches lua53 milagro lpeglabel
	CC=${gcc} CFLAGS="${cflags}" make -C src shared

ios-lib:
	TARGET=${ARCH} AR=${ar} CC=${gcc} CFLAGS="${cflags}" make -C src ios-lib
	cp -v src/zenroom-ios-${ARCH}.a build/

ios-armv7: ARCH := armv7
ios-armv7: OS := iphoneos
ios-armv7: gcc := $(shell xcrun --sdk iphoneos -f gcc 2>/dev/null)
ios-armv7: ar := $(shell xcrun --sdk iphoneos -f ar 2>/dev/null)
ios-armv7: ld := $(shell xcrun --sdk iphoneos -f ld 2>/dev/null)
ios-armv7: ranlib := $(shell xcrun --sdk iphoneos -f ranlib 2>/dev/null)
ios-armv7: SDK := $(shell xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
ios-armv7: cflags := -O2 -fPIC ${cflags_protection} -D'ARCH=\"OSX\"' -isysroot ${SDK} -arch ${ARCH} -D NO_SYSTEM -DARCH_OSX
ios-armv7: ldflags := -lm
ios-armv7: platform := ios
ios-armv7: apply-patches lua53 milagro lpeglabel ios-lib

ios-arm64: ARCH := arm64
ios-arm64: OS := iphoneos
ios-arm64: gcc := $(shell xcrun --sdk iphoneos -f gcc 2>/dev/null)
ios-arm64: ar := $(shell xcrun --sdk iphoneos -f ar 2>/dev/null)
ios-arm64: ld := $(shell xcrun --sdk iphoneos -f ld 2>/dev/null)
ios-arm64: ranlib := $(shell xcrun --sdk iphoneos -f ranlib 2>/dev/null)
ios-arm64: SDK := $(shell xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
ios-arm64: cflags := -O2 -fPIC ${cflags_protection} -D'ARCH=\"OSX\"' -isysroot ${SDK} -arch ${ARCH} -D NO_SYSTEM -DARCH_OSX
ios-arm64: ldflags := -lm
ios-arm64: platform := ios
ios-arm64: apply-patches lua53 milagro lpeglabel ios-lib

ios-sim: ARCH := x86_64
ios-sim: OS := iphonesimulator
ios-sim: gcc := $(shell xcrun --sdk iphonesimulator -f gcc 2>/dev/null)
ios-sim: ar := $(shell xcrun --sdk iphonesimulator -f ar 2>/dev/null)
ios-sim: ld := $(shell xcrun --sdk iphonesimulator -f ld 2>/dev/null)
ios-sim: ranlib := $(shell xcrun --sdk iphonesimulator -f ranlib 2>/dev/null)
ios-sim: SDK := $(shell xcrun --sdk iphonesimulator --show-sdk-path 2>/dev/null)
ios-sim: cflags := -O2 -fPIC ${cflags_protection} -D'ARCH=\"OSX\"' -isysroot ${SDK} -arch ${ARCH} -D NO_SYSTEM -DARCH_OSX
ios-sim: ldflags := -lm
ios-sim: platform := ios
ios-sim: apply-patches lua53 milagro lpeglabel ios-lib

ios-fat:
	lipo -create build/zenroom-ios-x86_64.a build/zenroom-ios-arm64.a build/zenroom-ios-armv7.a -output build/zenroom-ios.a

android: gcc := $(CC)
android: ar := $(AR)
android: ranlib := $(RANLIB)
android: ld := $(ld)
android: cflags := ${cflags} -std=c99 -shared -DLUA_USE_DLOPEN
android: apply-patches lua53 milagro lpeglabel
	LDFLAGS="--sysroot=/tmp/ndk-arch-21/sysroot" CC=${gcc} CFLAGS="${cflags}" make -C src android


debug: gcc := gcc
debug: cflags := -O0 -ggdb -D'ARCH=\"LINUX\"' ${cflags_protection} -DARCH_LINUX -DDEBUG=1
debug: apply-patches lua53 milagro lpeglabel
	CC=${gcc} CFLAGS="${cflags}" make -C src shared

lpeglabel:
	CC=${gcc} CFLAGS="${cflags} -I${pwd}/lib/lua53/src" AR="${ar}" make -C lib/lpeglabel

zlib:
	CC=${gcc} CFLAGS="${cflags}" \
	LDFLAGS="${ldflags}" AR="${ar}" RANLIB=${ranlib} \
	pwd="${pwd}" make -C ${pwd}/build/zlib -f ZenMakefile

lua53:
	CC=${gcc} CFLAGS="${cflags} \
	-DLUA_COMPAT_5_3 -DLUA_COMPAT_MODULE" \
	LDFLAGS="${ldflags}" AR="${ar}" RANLIB=${ranlib} \
	make -C ${pwd}/lib/lua53/src ${platform}

milagro:
	@echo "-- Building milagro (POSIX)"
	if ! [ -r ${pwd}/lib/milagro-crypto-c/CMakeCache.txt ]; then cd ${pwd}/lib/milagro-crypto-c && CC=${gcc} cmake . -DCMAKE_C_FLAGS="${cflags}" ${milagro_cmake_flags}; fi
	if ! [ -r ${pwd}/lib/milagro-crypto-c/lib/libamcl_core.a ]; then CC=${gcc} CFLAGS="${cflags}" make -C ${pwd}/lib/milagro-crypto-c; fi

milagro-win:
	@echo "-- Building milagro (Windows)"
	sed -i 's/project (AMCL)/project (AMCL C)/' ${pwd}/lib/milagro-crypto-c/CMakeLists.txt
	if ! [ -r ${pwd}/lib/milagro-crypto-c/CMakeCache.txt ]; then cd ${pwd}/lib/milagro-crypto-c && CC=${gcc} AR=${ar} RANLIB=${ranlib} cmake . -DCMAKE_C_FLAGS="${cflags}" -DCMAKE_SYSTEM_NAME="Windows" ${milagro_cmake_flags}; fi
	if ! [ -r ${pwd}/lib/milagro-crypto-c/lib/libamcl_core.a ]; then CC=${gcc} CFLAGS="${cflags}" AR=${ar} RANLIB=${ranlib} make -C ${pwd}/lib/milagro-crypto-c VERBOSE=1; fi

milagro-js:
	@echo "-- Building milagro (JS Emscripten)"
	sed -i 's/project (AMCL)/project (AMCL C)/' ${pwd}/lib/milagro-crypto-c/CMakeLists.txt
	if ! [ -r ${pwd}/lib/milagro-crypto-c/CMakeCache.txt ]; then cd ${pwd}/lib/milagro-crypto-c && CC=${gcc} cmake . -DCMAKE_C_FLAGS="${cflags}" -DCMAKE_SYSTEM_NAME="Javascript" ${milagro_cmake_flags} ; fi
	if ! [ -r ${pwd}/lib/milagro-crypto-c/lib/libamcl_core.a ]; then CC=${gcc} CFLAGS="${cflags}" make -C ${pwd}/lib/milagro-crypto-c; fi

#-DCMAKE_TOOLCHAIN_FILE="${pwd}/lib/milagro-crypto-c/resources/cmake/emscripten-cross.cmake"


check-milagro: milagro
	CC=${gcc} CFLAGS="${cflags}" make -C ${pwd}/lib/milagro-crypto-c test

## tests that require too much memory
himem-tests = \
 @${1} test/sort.lua && \
 ${1} test/literals.lua && \
 ${1} test/pm.lua && \
 ${1} test/nextvar.lua

## GC tests break memory management with umm
# in particular steps (2)
# ${1} test/gc.lua && \
# ${1} test/calls.lua && \



lowmem-tests = \
		@${1} test/vararg.lua && \
		${1} test/utf8.lua && \
		${1} test/tpack.lua && \
		${1} test/strings.lua && \
		${1} test/math.lua && \
		${1} test/goto.lua && \
		${1} test/events.lua && \
		${1} test/code.lua && \
		${1} test/locals.lua && \
		${1} test/schema.lua && \
		${1} test/octet.lua && \
		${1} test/hash.lua && \
		${1} test/ecdh.lua && \
		${1} test/ecdh_aes-gcm_vectors.lua && \
		${1} test/ecp_bls383.lua

# ${1} test/closure.lua && \

# failing js tests due to larger memory required:
# abort("Cannot enlarge memory arrays. Either (1) compile with -s
# TOTAL_MEMORY=X with X higher than the current value 16777216, (2)
# compile with -s ALLOW_MEMORY_GROWTH=1 which allows increasing the
# size at runtime but prevents some optimizations, (3) set
# Module.TOTAL_MEMORY to a higher value before the program runs, or
# (4) if you want malloc to return NULL (0) instead of this abort,
# compile with -s ABORTING_MALLOC=0 ") at Error
# himem:
#  ${1} test/constructs.lua && \
#  ${1} test/cjson-test.lua
# lowmem:
#  ${1} test/coroutine.lua && \

# these all pass but require cjson_full to run
# 	${test-exec} test/cjson-test.lua

# these require the debug extension too much
# ${test-exec} test/coroutine.lua


check-shared: test-exec-lowmem := ${pwd}/src/zenroom-shared
check-shared: test-exec := ${pwd}/src/zenroom-shared
check-shared:
	$(call lowmem-tests,${test-exec-lowmem})
	$(call himem-tests,${test-exec})
	${test-exec} test/constructs.lua
	./test/octet-json.sh ${test-exec}
	./test/integration_asymmetric_crypto.sh ${test-exec}
	@echo "----------------"
	@echo "All tests passed for SHARED binary build"
	@echo "----------------"


check-static: test-exec := ${pwd}/src/zenroom-static
check-static: test-exec-lowmem := ${pwd}/src/zenroom-static
check-static:
	$(call lowmem-tests,${test-exec-lowmem})
	$(call himem-tests,${test-exec})
	${test-exec} test/constructs.lua
	./test/octet-json.sh ${test-exec}
	./test/integration_asymmetric_crypto.sh ${test-exec}
	@echo "----------------"
	@echo "All tests passed for STATIC binary build"
	@echo "----------------"

check-js: test-exec := nodejs ${pwd}/test/zenroom_exec.js ${pwd}/src/zenroom.js
check-js:
	$(call lowmem-tests,${test-exec})
	$(call himem-tests,${test-exec})
	@echo "----------------"
	@echo "All tests passed for JS binary build"
	@echo "----------------"

check-debug: test-exec-lowmem := valgrind --max-stackframe=2064480 ${pwd}/src/zenroom-shared -u -d
check-debug: test-exec := valgrind --max-stackframe=2064480 ${pwd}/src/zenroom-shared -u -d
check-debug:
	$(call lowmem-tests,${test-exec-lowmem})
	$(call himem-tests,${test-exec})
	./test/octet-json.sh  ${pwd}/src/zenroom-shared
	./test/integration_asymmetric_crypto.sh ${pwd}/src/zenroom-shared
	@echo "----------------"
	@echo "All tests passed for DEBUG binary build"
	@echo "----------------"

check-crypto: test-exec := ./src/zenroom-shared
check-crypto:
	${test-exec} test/octet.lua
	${test-exec} test/hash.lua
	${test-exec} test/ecdh.lua
	${test-exec} test/ecdh_aes-gcm_vectors.lua
	${test-exec} test/ecp_bls383.lua
	./test/octet-json.sh ${test-exec}
	./test/integration_asymmetric_crypto.sh ${test-exec}
	@echo "-----------------------"
	@echo "All CRYPTO tests passed"
	@echo "-----------------------"


debug-crypto: test-exec := valgrind --max-stackframe=2064480 ${pwd}/src/zenroom-shared -u -d
debug-crypto:
	${test-exec} test/octet.lua
	${test-exec} test/hash.lua
	${test-exec} test/ecdh.lua
	${test-exec} test/ecdh_aes-gcm_vectors.lua
	${test-exec} test/ecp_bls383.lua

#	./test/integration_asymmetric_crypto.sh ${test-exec}

#	./test/octet-json.sh ${test-exec}


clean:
	make clean -C ${pwd}/lib/lua53/src
	make clean -C ${pwd}/lib/milagro-crypto-c && \
		rm -f ${pwd}/lib/milagro-crypto-c/CMakeCache.txt
	make clean -C ${pwd}/lib/lpeglabel
	make clean -C src
	rm -f ${extras}/index.*

distclean:
	rm -rf ${musl}
