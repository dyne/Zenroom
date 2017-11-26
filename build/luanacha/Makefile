CC := ../musl/obj/musl-gcc
INCFLAGS := -I../../lib/lua_sandbox/include/luasandbox
CFLAGS   += -std=gnu99 -Os $(INCFLAGS)

luanacha.a:
	${CC} -c ${CFLAGS} ../../lib/luanacha/src/*.c
	ar rcc libluanacha.a *.o

clean:
	rm -f *.o
