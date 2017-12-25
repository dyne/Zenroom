pwd := $(shell pwd)
luasand := ${pwd}/build/lua_sandbox

# for js (emscripten)
gcc := gcc
cflags := -O2 -fstack-protector

test-exec := ${pwd}/src/zenroom-shared -c ${pwd}/test/decode-test.conf

bootstrap-check:
	@if ! [ -r ${gcc} ]; then echo "\nRun 'make bootstrap' first to build the compiler.\n" && exit 0; fi

patches:
	./build/apply-patches

js: gcc=${EMSCRIPTEN}/emcc
js: cflags := -O3 -fstack-protector
js: patches luasandbox luazen
	CC=${gcc} CFLAGS="${cflags}" make -C src js

bootstrap: musl := ${pwd}/build/musl
bootstrap: gcc := ${musl}/obj/musl-gcc
bootstrap: cflags := -Os -fstack-protector -static
bootstrap:
	if ! [ -r ${gcc} ]; then mkdir -p ${musl} && cd ${musl} && CFLAGS="${cflags}" ${pwd}/lib/musl/configure; fi
	make -j2 -C ${musl}

static: musl := ${pwd}/build/musl
static: gcc := ${musl}/obj/musl-gcc
static: cflags := -Os -fstack-protector -static
static: bootstrap patches jemalloc luasandbox gmp pbc luazen
	CC=${gcc} make -C src static

shared: gcc := gcc
shared: cflags := -O2 -fstack-protector
shared: patches jemalloc luasandbox luazen
	CC=${gcc} make -C src shared

gmp:
	cd ${pwd}/lib/gmp && CFLAGS="${cflags}" CC=${gcc} ./configure --disable-shared
	make -C ${pwd}/lib/gmp

pbc:
	mkdir -p ${pwd}/build/pbc
	cd ${pwd}/build/pbc && CFLAGS="${cflags}" CC=${gcc} ${pwd}/lib/pbc/configure --disable-shared
	make -C ${pwd}/build/pbc LDFLAGS="-L${pwd}/lib/gmp/.libs -l:libgmp.a" CFLAGS="${cflags} -I${pwd}/lib/gmp -I${pwd}/lib/pbc/include"; return 0

jemalloc:
	mkdir -p ${pwd}/build/jemalloc
	cd ${pwd}/build/jemalloc && CFLAGS="${cflags}" CC=${gcc} ${pwd}/lib/jemalloc/configure --disable-cxx
	make -C ${pwd}/build/jemalloc

luasandbox:
	if ! [ -r ${luasand}/CMakeCache.txt ]; then mkdir -p ${luasand} && cd ${luasand} && CC=${gcc} cmake ${pwd}/lib/lua_sandbox -DCMAKE_C_FLAGS="${cflags}" ; fi
	make -C ${luasand} luasandbox

luazen:
	make -C ${pwd}/build/luazen

# needed for yices2, in case useful (WIP)
# gmp:
# 	if ! [ -r lib/gmp/Makefile ]; then cd lib/gmp && CC=${gcc} ./configure --disable-shared --enable-static; fi
# 	make -C lib/gmp -j2

check-shared: test-exec := ${pwd}/src/zenroom-shared -c ${pwd}/test/decode-test.conf
check-shared:
	${test-exec} test/vararg.lua && \
	${test-exec} test/pm.lua && \
	${test-exec} test/nextvar.lua && \
	${test-exec} test/locals.lua && \
	${test-exec} test/constructs.lua && \
	${test-exec} test/test_luazen.lua && \
	echo "----------------\nAll tests passed for SHARED binary build\n----------------"

check-static: test-exec := ${pwd}/src/zenroom-static -c ${pwd}/test/decode-test.conf
check-static:
	${test-exec} test/vararg.lua && \
	${test-exec} test/pm.lua && \
	${test-exec} test/nextvar.lua && \
	${test-exec} test/locals.lua && \
	${test-exec} test/constructs.lua && \
	${test-exec} test/test_luazen.lua && \
	echo "----------------\nAll tests passed for STATIC binary build\n----------------"

clean:
	rm -rf ${luasand}
	make -C src clean
	make -C ${pwd}/build/luazen clean

distclean:
	rm -rf ${musl}
