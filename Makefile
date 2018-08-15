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
ARCH=$(shell uname -m)

include ${pwd}/build/config.mk

test-exec := ${pwd}/src/zenroom-shared -c ${pwd}/test/decode-test.conf

all:
	@echo "Choose a target:"
	@echo "- js-node, js-wasm, js-demo   (need EMSDK env loaded)"
	@echo "- linux, linux-lib, linux-clang, linux-debug"
	@echo "- linux-python, linux-java        (language bindings)"
	@echo "- osx			(uses default compiler on Apple/OSX)"
	@echo "- win, win-dll	(cross-compile using MINGW on Linux)"
	@echo "- musl, musl-local, musl-system   (full static build)"

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
js-node: cflags += -DARCH_JS -D'ARCH=\"JS\"'
js-node: apply-patches lua53 milagro-js lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src js
	@mkdir -p build/nodejs
	@cp -v src/zenroom.js 	  build/nodejs/
	@cp -v src/zenroom.js.mem build/nodejs/

js-wasm: cflags += -DARCH_WASM -D'ARCH=\"WASM\"'
js-wasm: ldflags += -s WASM=1 -s MODULARIZE=1
js-wasm: apply-patches lua53 milagro-js lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src js
	@mkdir -p build/wasm
	@cp -v src/zenroom.js   build/wasm/
	@cp -v src/zenroom.wasm build/wasm/


js-demo: cflags  += -DARCH_WASM -D'ARCH=\"WASM\"'
js-demo: ldflags += -s WASM=1 -s ASSERTIONS=1 --shell-file ${extras}/shell_minimal.html -s NO_EXIT_RUNTIME=1
js-demo: apply-patches lua53 milagro-js lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src js-demo

win: apply-patches lua53 milagro-win lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src win-exe

win-dll: apply-patches lua53 milagro-win lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		 make -C src win-dll

linux-java: cflags += -I /opt/jdk/include -I /opt/jdk/include/win32
linux-java: apply-patches lua53 milagro-posix lpeglabel
	swig -java ${pwd}/build/swig.i
	${gcc} ${cflags} -c ${pwd}/build/swig_wrap.c -o src/zen_java.o
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src java

musl: ldadd += /usr/lib/${ARCH}-linux-musl/libc.a
musl: apply-patches lua53 milagro-posix lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src musl

musl-local: ldadd += /usr/local/musl/lib/libc.a
musl-local: apply-patches lua53 milagro-posix lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src musl

musl-system: gcc := gcc
musl-system: apply-patches lua53 milagro-posix lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src musl


linux: apply-patches lua53 milagro-posix lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src linux

linux-debug:
linux-debug: cflags := -O1 -ggdb -D'ARCH=\"LINUX\"' ${cflags_protection} -DARCH_LINUX -DDEBUG=1
linux-debug: apply-patches lua53 milagro-posix lpeglabel linux

linux-clang: gcc := clang
linux-clang: apply-patches lua53 milagro-posix lpeglabel linux

linux-sanitizer: gcc := clang
linux-sanitizer: cflags := -O1 -ggdb -D'ARCH=\"LINUX\"' ${cflags_protection} -DARCH_LINUX -DDEBUG=1 -fsanitize=address -fno-omit-frame-pointer
linux-sanitizer: apply-patches lua53 milagro-posix lpeglabel linux
	ASAN_OPTIONS=verbosity=1:log_threads=1 \
	ASAN_SYMBOLIZER_PATH=/usr/bin/asan_symbolizer \
	ASAN_OPTIONS=abort_on_error=1 \
		./src/zenroom-shared -i -d

linux-lib: cflags += -shared -DLIBRARY
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src linux-lib

linux-python: apply-patches lua53 milagro-posix lpeglabel
	swig -python ${pwd}/build/swig.i
	${gcc} ${cflags} -c ${pwd}/build/swig_wrap.c \
		 -o src/zen_python.o $(shell pkg-config python --cflags)
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src python

linux-java: cflags += -I /opt/jdk/include -I /opt/jdk/include/linux
linux-java: apply-patches lua53 milagro-posix lpeglabel
	swig -java ${pwd}/build/swig.i
	${gcc} ${cflags} -c ${pwd}/build/swig_wrap.c -o src/zen_java.o
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src java

osx: apply-patches lua53 milagro-osx lpeglabel
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src osx

osx-python: osx
	swig -python ${pwd}/build/swig.i
	${gcc} ${cflags} -c ${pwd}/build/swig_wrap.c \
		-o src/zen_python.o $(shell pkg-config python --cflags)
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src python

# ------------------
# ios build recepies
include ${pwd}/build/ios.mk

android: gcc := $(CC)
android: ar := $(AR)
android: ranlib := $(RANLIB)
android: ld := $(ld)
android: cflags := ${cflags} -std=c99 -shared -DLUA_USE_DLOPEN
android: apply-patches lua53 milagro-posix lpeglabel
	LDFLAGS="--sysroot=/tmp/ndk-arch-21/sysroot" CC=${gcc} CFLAGS="${cflags}" make -C src android



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
	@echo "-- Building milagro (${system})"
	if ! [ -r ${pwd}/lib/milagro-crypto-c/CMakeCache.txt ]; then cd ${pwd}/lib/milagro-crypto-c && CC=${gcc} AR=${ar} RANLIB=${ranlib} cmake . -DCMAKE_C_FLAGS="${cflags}" -DCMAKE_SYSTEM_NAME="${system}" ${milagro_cmake_flags}; fi
	if ! [ -r ${pwd}/lib/milagro-crypto-c/lib/libamcl_core.a ]; then CC=${gcc} CFLAGS="${cflags}" AR=${ar} RANLIB=${ranlib} make -C ${pwd}/lib/milagro-crypto-c VERBOSE=1; fi

milagro-osx: system:= Darwin
milagro-osx: milagro

milagro-posix: system:= Linux
milagro-posix: milagro

milagro-win: system := Windows
milagro-win: milagro

milagro-js: system:= Javascript
milagro-js: milagro


check-milagro: milagro-posix
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

crypto-tests = \
	@${1} test/octet.lua && \
	${1} test/hash.lua && \
	${1} test/ecdh.lua && \
	${1} test/ecdh_aes-gcm_vectors.lua && \
	${1} test/ecp_bls383.lua

shell-tests = \
	test/octet-json.sh ${1} && \
	test/integration_asymmetric_crypto.sh ${1}

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

# these may serve to verify the boundary of maximum memory
# since some trigger warnings when compiled with full debug
# $(call himem-tests,${test-exec})


check-osx: test-exec-lowmem := ${pwd}/src/zenroom.command 2>/dev/null
check-osx: test-exec := ${pwd}/src/zenroom.command 2>/dev/null
check-osx:
	${test-exec} test/constructs.lua
	$(call lowmem-tests,${test-exec-lowmem})
	$(call crypto-tests,${test-exec-lowmem})
	$(call shell-tests,${test-exec-lowmem})
	@echo "----------------"
	@echo "All tests passed for SHARED binary build"
	@echo "----------------"

check-shared: test-exec-lowmem := ${pwd}/src/zenroom-shared 2>/dev/null
check-shared: test-exec := ${pwd}/src/zenroom-shared 2>/dev/null
check-shared:
	${test-exec} test/constructs.lua
	$(call lowmem-tests,${test-exec-lowmem})
	$(call crypto-tests,${test-exec-lowmem})
	$(call shell-tests,${test-exec-lowmem})
	@echo "----------------"
	@echo "All tests passed for SHARED binary build"
	@echo "----------------"


check-static: test-exec := ${pwd}/src/zenroom-static
check-static: test-exec-lowmem := ${pwd}/src/zenroom-static
check-static:
	${test-exec} test/constructs.lua
	$(call lowmem-tests,${test-exec-lowmem})
	$(call crypto-tests,${test-exec-lowmem})
	$(call shell-tests,${test-exec-lowmem})
	@echo "----------------"
	@echo "All tests passed for STATIC binary build"
	@echo "----------------"

check-js: test-exec := nodejs ${pwd}/test/zenroom_exec.js ${pwd}/src/zenroom.js
check-js:
	cp src/zenroom.js.mem .
	$(call lowmem-tests,${test-exec})
	$(call crypto-tests,${test-exec})
	@echo "----------------"
	@echo "All tests passed for JS binary build"
	@echo "----------------"

check-debug: test-exec-lowmem := valgrind --max-stackframe=2064480 ${pwd}/src/zenroom-shared -u -d
check-debug: test-exec := valgrind --max-stackframe=2064480 ${pwd}/src/zenroom-shared -u -d
check-debug:
	$(call lowmem-tests,${test-exec-lowmem})
	$(call crypto-tests,${test-exec})
	@echo "----------------"
	@echo "All tests passed for DEBUG binary build"
	@echo "----------------"

check-crypto: test-exec := ./src/zenroom-shared -d
check-crypto:
	$(call crypto-tests,${test-exec})
	@echo "-----------------------"
	@echo "All CRYPTO tests passed"
	@echo "-----------------------"


debug-crypto: test-exec := valgrind --max-stackframe=2064480 ${pwd}/src/zenroom-shared -u -d
debug-crypto:
	$(call crypto-tests,${test-exec})
	$(call shell-tests,${test-exec-lowmem})

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
