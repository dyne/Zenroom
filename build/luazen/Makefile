CC := ../musl/obj/musl-gcc
INCFLAGS := -I../../lib/lua_sandbox/include/luasandbox
CFLAGS   += -std=gnu99 -Os -static -fstack-protector $(INCFLAGS)

luazen.a:
	${CC} -c ${CFLAGS} ../../lib/luazen/src/*.c
	ar rcc libluazen.a *.o

clean:
	rm -f *.o *.a
