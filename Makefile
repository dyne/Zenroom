pwd := $(shell pwd)
luasand := ${pwd}/build/lua_sandbox
musl := ${pwd}/build/musl
musl-gcc := ${musl}/obj/musl-gcc

all: bootstrap-check patches luasandbox luanacha
	make -C src

bootstrap-check:
	@if ! [ -r ${musl-gcc} ]; then echo "\nRun 'make bootstrap' first to build the compiler.\n" && exit 1; fi

patches:
	./build/apply-patches

bootstrap:
	if ! [ -r ${musl-gcc} ]; then mkdir -p ${musl} && cd ${musl} && ${pwd}/lib/musl/configure; fi
	make -j2 -C ${musl}

luasandbox:
	if ! [ -r ${luasand}/CMakeCache.txt ]; then mkdir -p ${luasand} && cd ${luasand} && CC=${musl-gcc} cmake ${pwd}/lib/lua_sandbox -DCMAKE_C_FLAGS="-static -Os" ; fi
	make -C ${luasand} luasandbox

luanacha:
	make -C ${pwd}/build/luanacha

# needed for yices2, in case useful (WIP)
# gmp:
# 	if ! [ -r lib/gmp/Makefile ]; then cd lib/gmp && CC=${musl-gcc} ./configure --disable-shared --enable-static; fi
# 	make -C lib/gmp -j2

check:
	src/decode-exec -c src/decode-exec.conf test/test_luanacha.lua

clean:
	rm -rf ${luasand}
	make -C src clean
	make -C ${pwd}/build/luanacha clean

distclean:
	rm -rf ${musl}
