pwd := $(shell pwd)
luasand := ${pwd}/build/lua_sandbox
musl := ${pwd}/build/musl
musl-gcc := ${musl}/obj/musl-gcc
test-exec := ${pwd}/src/decode-exec -c ${pwd}/test/decode-test.conf
cflags := -Os -fstack-protector -static

all: bootstrap-check patches jemalloc luasandbox gmp pbc luazen
	make -C src

gmp:
	cd ${pwd}/lib/gmp && CFLAGS="${cflags}" CC=${musl-gcc} ./configure --disable-shared
	make -C ${pwd}/lib/gmp

pbc:
	mkdir -p ${pwd}/build/pbc
	cd ${pwd}/build/pbc && CFLAGS="${cflags}" CC=${musl-gcc} ${pwd}/lib/pbc/configure --disable-shared
	make -C ${pwd}/build/pbc LDFLAGS="-L${pwd}/lib/gmp/.libs -l:libgmp.a" CFLAGS="${cflags} -I${pwd}/lib/gmp -I${pwd}/lib/pbc/include"; return 0

jemalloc:
	mkdir -p ${pwd}/build/jemalloc
	cd ${pwd}/build/jemalloc && CFLAGS="${cflags}" CC=${musl-gcc} ${pwd}/lib/jemalloc/configure --disable-cxx
	make -C ${pwd}/build/jemalloc

bootstrap-check:
	@if ! [ -r ${musl-gcc} ]; then echo "\nRun 'make bootstrap' first to build the compiler.\n" && exit 1; fi

patches:
	./build/apply-patches

bootstrap:
	if ! [ -r ${musl-gcc} ]; then mkdir -p ${musl} && cd ${musl} && CFLAGS="-Os -fstack-protector" ${pwd}/lib/musl/configure; fi
	make -j2 -C ${musl}

luasandbox:
	if ! [ -r ${luasand}/CMakeCache.txt ]; then mkdir -p ${luasand} && cd ${luasand} && CC=${musl-gcc} cmake ${pwd}/lib/lua_sandbox -DCMAKE_C_FLAGS="-static -Os -fstack-protector" ; fi
	make -C ${luasand} luasandbox

luazen:
	make -C ${pwd}/build/luazen

# needed for yices2, in case useful (WIP)
# gmp:
# 	if ! [ -r lib/gmp/Makefile ]; then cd lib/gmp && CC=${musl-gcc} ./configure --disable-shared --enable-static; fi
# 	make -C lib/gmp -j2

check:
	${test-exec} test/vararg.lua && \
	${test-exec} test/pm.lua && \
	${test-exec} test/nextvar.lua && \
	${test-exec} test/locals.lua && \
	${test-exec} test/constructs.lua && \
	${test-exec} test/test_luazen.lua && \
	echo "----------------\nAll tests passed\n----------------"

clean:
	rm -rf ${luasand}
	make -C src clean
	make -C ${pwd}/build/luazen clean

distclean:
	rm -rf ${musl}
