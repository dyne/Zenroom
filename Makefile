pwd := $(shell pwd)
luasand := ${pwd}/build/lua_sandbox

# default
gcc := gcc
cflags_protection := -fstack-protector-all -D_FORTIFY_SOURCE=2 -fno-strict-overflow
cflags := -O2 ${cflags_protection}

test-exec := ${pwd}/src/zenroom-shared -c ${pwd}/test/decode-test.conf

bootstrap-check:
	@if ! [ -r ${gcc} ]; then echo "\nRun 'make bootstrap' first to build the compiler.\n" && exit 0; fi

patches:
	./build/apply-patches

js: gcc=${EMSCRIPTEN}/emcc
js: cflags := -O3 ${cflags_protection}
js: patches luasandbox luazen milagro
	CC=${gcc} CFLAGS="${cflags}" make -C src js

bootstrap: musl := ${pwd}/build/musl
bootstrap: gcc := ${musl}/obj/musl-gcc
bootstrap: cflags := -Os -static ${cflags_protection}
bootstrap:
	if ! [ -r ${gcc} ]; then mkdir -p ${musl} && cd ${musl} && CFLAGS="${cflags}" ${pwd}/lib/musl/configure; fi
	make -j2 -C ${musl}

static: musl := ${pwd}/build/musl
static: gcc := ${musl}/obj/musl-gcc
static: cflags := -Os -static ${cflags_protection}
static: bootstrap patches jemalloc luasandbox luazen milagro
	CC=${gcc} CFLAGS="${cflags}" make -C src static

system-static: cflags := -Os -static ${cflags_protection}
system-static: patches jemalloc luasandbox luazen milagro
	CC=${gcc} CFLAGS="${cflags}" make -C src system-static

shared: gcc := gcc
shared: cflags := -O2 -fPIC ${cflags_protection}
shared: patches jemalloc luasandbox luazen milagro
	CC=${gcc} CFLAGS="${cflags}" make -C src shared

gmp:
	cd ${pwd}/lib/gmp && CFLAGS="${cflags}" CC=${gcc} ./configure --disable-shared
	make -C ${pwd}/lib/gmp

pbc:
	mkdir -p ${pwd}/build/pbc
	if ! [ ${pwd}/build/pbc/.libs/libpbc.a ]; then cd ${pwd}/build/pbc && CFLAGS="${cflags}" CC=${gcc} ${pwd}/lib/pbc/configure --disable-shared &&	make -C ${pwd}/build/pbc LDFLAGS="-L${pwd}/lib/gmp/.libs -l:libgmp.a" CFLAGS="${cflags} -I${pwd}/lib/gmp -I${pwd}/lib/pbc/include"; return 0; fi

jemalloc:
	mkdir -p ${pwd}/build/jemalloc
	if ! [ -r ${pwd}/lib/jemalloc/configure ]; then cd ${pwd}/lib/jemalloc &&  ${pwd}/lib/jemalloc/autogen.sh; fi
	if ! [ -r ${pwd}/build/jemalloc/lib/libjemalloc.a ]; then cd ${pwd}/build/jemalloc && CFLAGS="${cflags}" CC=${gcc} ${pwd}/lib/jemalloc/configure --disable-cxx && make -C ${pwd}/build/jemalloc; fi

luasandbox:
	if ! [ -r ${luasand}/CMakeCache.txt ]; then mkdir -p ${luasand} && cd ${luasand} && CC=${gcc} cmake ${pwd}/lib/lua_sandbox -DCMAKE_C_FLAGS="${cflags}"; fi
	if ! [ -r ${pwd}/build/lua_sandbox/src/libluasandbox.a ]; then VERBOSE=1 CFLAGS="${cflags}" make -C ${luasand} luasandbox; fi

luazen:
	CC=${gcc} CFLAGS="${cflags}" make -C ${pwd}/build/luazen

milagro:
	CC=${gcc} CFLAGS="${cflags}" make -C ${pwd}/lib/milagro-c

check-milagro: milagro
	CC=${gcc} CFLAGS="${cflags}" make -C ${pwd}/test/milagro check

check-shared: test-exec := ${pwd}/src/zenroom-shared -c ${pwd}/test/decode-test.conf
check-shared: check-milagro
	@${test-exec} test/vararg.lua && \
	${test-exec} test/pm.lua && \
	${test-exec} test/nextvar.lua && \
	${test-exec} test/locals.lua && \
	${test-exec} test/constructs.lua && \
	${test-exec} test/test_luazen.lua && \
	echo "----------------\nAll tests passed for SHARED binary build\n----------------"

check-static: test-exec := ${pwd}/src/zenroom-static -c ${pwd}/test/decode-test.conf
check-static: check-milagro
	@${test-exec} test/vararg.lua && \
	${test-exec} test/pm.lua && \
	${test-exec} test/nextvar.lua && \
	${test-exec} test/locals.lua && \
	${test-exec} test/constructs.lua && \
	${test-exec} test/test_luazen.lua && \
	echo "----------------\nAll tests passed for STATIC binary build\n----------------"

# TODO: check js build

clean:
	rm -rf ${luasand}
	make -C src clean
	make -C ${pwd}/build/luazen clean

distclean:
	rm -rf ${musl}
