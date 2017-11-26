pwd := $(shell pwd)
luasand := ${pwd}/build/lua_sandbox
musl := ${pwd}/build/musl
musl-gcc := ${musl}/obj/musl-gcc

all: musl patches luasandbox luanacha
	make -C src

patches:
	./build/apply-patches

musl:
	if ! [ -r ${musl-gcc} ]; then mkdir -p ${musl} && cd ${musl} && ${pwd}/lib/musl/configure; fi
	make -j2 -C ${musl}

luasandbox:
	if ! [ -r ${luasand}/CMakeCache.txt ]; then mkdir -p ${luasand} && cd ${luasand} && CC=${musl-gcc} CFLAGS='-Os' cmake ${pwd}/lib/lua_sandbox ; fi
	make -C ${luasand} luasandbox

luanacha:
	make -C ${pwd}/build/luanacha

# needed for yices2, in case useful (WIP)
# gmp:
# 	if ! [ -r lib/gmp/Makefile ]; then cd lib/gmp && CC=${musl-gcc} ./configure --disable-shared --enable-static; fi
# 	make -C lib/gmp -j2

clean:
	rm -rf ${luasand}
	rm -rf ${musl}
	make -C src clean
	make -C ${pwd}/build/luanacha clean
