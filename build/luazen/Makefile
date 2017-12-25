INCFLAGS := -I../../lib/lua_sandbox/include/luasandbox
CFLAGS   += $(INCFLAGS) -Wall -std=gnu99

luazen.a:
	${CC} -c ${CFLAGS} ../../lib/luazen/src/*.c
	ar rcc libluazen.a *.o

clean:
	rm -f *.o *.a
