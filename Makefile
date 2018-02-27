pwd := $(shell pwd)
luasand := ${pwd}/build/lua_sandbox
mil := ${pwd}/build/milagro

# default
gcc := gcc
cflags_protection := -fstack-protector-all -D_FORTIFY_SOURCE=2 -fno-strict-overflow
cflags := -O2 ${cflags_protection}

test-exec := ${pwd}/src/zenroom-shared -c ${pwd}/test/decode-test.conf

bootstrap-check:
	@if ! [ -r ${gcc} ]; then echo "\nRun 'make bootstrap' first to build the compiler.\n" && exit 0; fi

patches:
	./build/apply-patches

embed-lua:
	xxd -i src/lua/schema.lua | sed 's/src_lua_schema_lua/lualib_schema/g' > src/lualib_schema.c
	xxd -i src/lua/inspect.lua | sed 's/src_lua_inspect_lua/lualib_inspect/g' > src/lualib_inspect.c

# TODO: improve flags according to
# https://github.com/kripken/emscripten/blob/master/src/settings.js
js: gcc=${EMSCRIPTEN}/emcc
js: cflags := -O3 ${cflags_protection}
js: ldflags := -s "EXPORTED_FUNCTIONS='[\"_zenroom_exec\"]'" -s "EXTRA_EXPORTED_RUNTIME_METHODS='[\"ccall\",\"cwrap\"]'"
js: patches embed-lua luasandbox luazen milagro
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src js

wasm: gcc=${EMSCRIPTEN}/emcc
wasm: cflags := -O3 ${cflags_protection}
wasm: ldflags := -s WASM=1 -s "EXPORTED_FUNCTIONS='[\"_zenroom_exec\"]'" -s "EXTRA_EXPORTED_RUNTIME_METHODS='[\"ccall\",\"cwrap\"]'"
wasm: patches embed-lua luasandbox luazen milagro
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src js

html: gcc=${EMSCRIPTEN}/emcc
html: cflags := -O3 ${cflags_protection}
html: ldflags := -sEXPORTED_FUNCTIONS='["_main","_zenroom_exec"]'
html: patches embed-lua luasandbox luazen milagro
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src html

win: gcc=x86_64-w64-mingw32-gcc
win: cflags := -O3 ${cflags_protection}
win: patches embed-lua luasandbox luazen milagro-win
	CC=${gcc} CFLAGS="${cflags}" make -C src win

bootstrap: musl := ${pwd}/build/musl
bootstrap: gcc := ${musl}/obj/musl-gcc
bootstrap: cflags := -Os -static ${cflags_protection}
bootstrap:
	mkdir -p ${musl} && cd ${musl} && CFLAGS="${cflags}" ${pwd}/lib/musl/configure
	make -j2 -C ${musl}

static: musl := ${pwd}/build/musl
static: gcc := ${musl}/obj/musl-gcc
static: cflags := -Os -static ${cflags_protection}
static: bootstrap embed-lua patches luasandbox luazen milagro
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" make -C src static

system-static: cflags := -Os -static ${cflags_protection}
system-static: patches embed-lua luasandbox luazen milagro
	CC=${gcc} CFLAGS="${cflags}" make -C src system-static

shared: gcc := gcc
shared: cflags := -O2 -fPIC ${cflags_protection}
shared: patches embed-lua luasandbox luazen milagro
	CC=${gcc} CFLAGS="${cflags}" make -C src shared

gmp:
	cd ${pwd}/lib/gmp && CFLAGS="${cflags}" CC=${gcc} ./configure --disable-shared
	make -C ${pwd}/lib/gmp

pbc:
	mkdir -p ${pwd}/build/pbc
	if ! [ ${pwd}/build/pbc/.libs/libpbc.a ]; then cd ${pwd}/build/pbc && CFLAGS="${cflags}" CC=${gcc} ${pwd}/lib/pbc/configure --disable-shared &&	make -C ${pwd}/build/pbc LDFLAGS="-L${pwd}/lib/gmp/.libs -l:libgmp.a" CFLAGS="${cflags} -I${pwd}/lib/gmp -I${pwd}/lib/pbc/include"; return 0; fi

luasandbox:
	@echo "-- Building lua_sandbox"
	mkdir -p ${luasand} && cd ${luasand} && CC=${gcc} cmake ${pwd}/lib/lua_sandbox -DCMAKE_C_FLAGS="${cflags}"
	CC=${gcc} CFLAGS="${cflags}" make -C ${luasand} luasandbox

luazen:
	CC=${gcc} CFLAGS="${cflags}" make -C ${pwd}/build/luazen

milagro:
	@echo "-- Building milagro"
	cd ${pwd}/lib/milagro-crypto-c && CC=${gcc} cmake . -DBUILD_SHARED_LIBS=OFF -DBUILD_PYTHON=OFF -DBUILD_DOXYGEN=OFF -DCMAKE_C_FLAGS="${cflags}" -DAMCL_CHUNK=32 -DAMCL_CURVE=ED25519 -DAMCL_RSA=2048
	CC=${gcc} CFLAGS="${cflags}" make -C ${pwd}/lib/milagro-crypto-c

milagro-win:
	@echo "-- Building milagro"
	sed -i 's/project (AMCL)/project (AMCL C)/' ${pwd}/lib/milagro-crypto-c/CMakeLists.txt
	cd ${pwd}/lib/milagro-crypto-c && CC=${gcc} cmake . -DBUILD_SHARED_LIBS=OFF -DBUILD_PYTHON=OFF -DBUILD_DOXYGEN=OFF -DCMAKE_C_FLAGS="${cflags}" -DAMCL_CHUNK=32 -DAMCL_CURVE=ED25519 -DAMCL_RSA=2048 -DCMAKE_SHARED_LIBRARY_LINK_FLAGS="" -DCMAKE_SYSTEM_NAME="Windows"
	CC=${gcc} CFLAGS="${cflags}" make -C ${pwd}/lib/milagro-crypto-c

check-milagro: milagro
	CC=${gcc} CFLAGS="${cflags}" make -C ${pwd}/lib/milagro-crypto-c test

check-shared: test-exec := ${pwd}/src/zenroom-shared -c ${pwd}/test/decode-test.conf
check-shared: check-milagro
	@${test-exec} test/vararg.lua && \
	${test-exec} test/pm.lua && \
	${test-exec} test/nextvar.lua && \
	${test-exec} test/locals.lua && \
	${test-exec} test/constructs.lua && \
	${test-exec} test/bitbench.lua && \
	${test-exec} test/cjson-test.lua && \
	${test-exec} test/test_luazen.lua && \
	${test-exec} test/schema.lua && \
	test/integration_asymmetric_crypto.sh && \
	echo "----------------\nAll tests passed for SHARED binary build\n----------------"

check-static: test-exec := ${pwd}/src/zenroom-static -c ${pwd}/test/decode-test.conf
check-static: check-milagro
	@${test-exec} test/vararg.lua && \
	${test-exec} test/pm.lua && \
	${test-exec} test/nextvar.lua && \
	${test-exec} test/locals.lua && \
	${test-exec} test/constructs.lua && \
	${test-exec} test/bitbench.lua && \
	${test-exec} test/cjson-test.lua && \
	${test-exec} test/test_luazen.lua && \
	${test-exec} test/schema.lua && \
	test/integration_asymmetric_crypto.sh && \
	echo "----------------\nAll tests passed for STATIC binary build\n----------------"

# TODO: check js build

clean:
	rm -rf ${luasand}
	cd ${pwd}/lib/lua_sandbox && git clean -fd && git checkout .
	cd ${pwd}/build/luazen && git clean -fd && git checkout .
	cd ${pwd}/lib/milagro-crypto-c && git clean -fd && git checkout .
	make -C src clean

distclean:
	rm -rf ${musl}
