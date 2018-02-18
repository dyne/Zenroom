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

# TODO: improve flags according to
# https://github.com/kripken/emscripten/blob/master/src/settings.js
js: gcc=${EMSCRIPTEN}/emcc
js: cflags := -O3 ${cflags_protection}
js: ldflags := -sEXPORTED_FUNCTIONS='["_zenroom_exec"]' -sEXTRA_EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]'
js: patches luasandbox luazen milagro
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src js

wasm: gcc=${EMSCRIPTEN}/emcc
wasm: cflags := -O3 ${cflags_protection}
wasm: ldflags := -sWASM=1 -s"BINARYEN_METHOD='native-wasm'" -sEXPORTED_FUNCTIONS='["_zenroom_exec"]' -sEXTRA_EXPORTED_RUNTIME_METHODS='["ccall", "cwrap"]'
wasm: patches luasandbox luazen milagro
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src js

html: gcc=${EMSCRIPTEN}/emcc
html: cflags := -O3 ${cflags_protection}
html: ldflags := -sEXPORTED_FUNCTIONS='["_main","_zenroom_exec"]'
html: patches luasandbox luazen milagro
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src html

bootstrap: musl := ${pwd}/build/musl
bootstrap: gcc := ${musl}/obj/musl-gcc
bootstrap: cflags := -Os -static ${cflags_protection}
bootstrap:
	mkdir -p ${musl} && cd ${musl} && CFLAGS="${cflags}" ${pwd}/lib/musl/configure
	make -j2 -C ${musl}

static: musl := ${pwd}/build/musl
static: gcc := ${musl}/obj/musl-gcc
static: cflags := -Os -static ${cflags_protection}
static: ldflags := /usr/lib/`uname -m`-linux-gnu/libjemalloc_pic.a
static: bootstrap patches luasandbox luazen milagro
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src static

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
	@echo "-- Building jemalloc"
	mkdir -p ${pwd}/build/jemalloc
	if ! [ -r ${pwd}/lib/jemalloc/configure ]; then cd ${pwd}/lib/jemalloc &&  ${pwd}/lib/jemalloc/autogen.sh; fi
	if ! [ -r ${pwd}/build/jemalloc/lib/libjemalloc.a ]; then cd ${pwd}/build/jemalloc && CFLAGS="${cflags}" CC=${gcc} ${pwd}/lib/jemalloc/configure --disable-cxx && make -C ${pwd}/build/jemalloc; fi

luasandbox:
	@echo "-- Building lua_sandbox"
	mkdir -p ${luasand} && cd ${luasand} && CC=${gcc} cmake ${pwd}/lib/lua_sandbox -DCMAKE_C_FLAGS="${cflags}"
	VERBOSE=1 CFLAGS="${cflags}" make -C ${luasand} luasandbox

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
	make -C ${pwd}/lib/milagro-c clean

distclean:
	rm -rf ${musl}
