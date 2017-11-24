luasand := build/lua_sandbox
musl := build/musl

all:
	./build/apply-patches
	if ! [ -r ${musl}/obj/musl-gcc ]; then mkdir -p ${musl} && cd ${musl} && ../../lib/musl/configure; fi
	make -j2 -C ${musl}
	if ! [ -r ${luasand}/CMakeCache.txt ]; then mkdir -p ${luasand} && cd ${luasand} && CC=../musl/obj/musl-gcc cmake ../../lib/lua_sandbox ; fi

	make -C ${luasand} luasandbox
	make -C src musl

clean:
	rm -rf ${luasand}
	rm -rf ${musl}
	make -C src clean
