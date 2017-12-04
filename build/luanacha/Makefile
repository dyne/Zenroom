CC := ../musl/obj/musl-gcc
INCFLAGS := -I../../lib/lua_sandbox/include/luasandbox
CFLAGS   += -std=gnu99 -Os -static -fstack-protector $(INCFLAGS)

luanacha.a:
	${CC} -c ${CFLAGS} ../../lib/luanacha/src/*.c
	ar rcc libluanacha.a *.o

clean:
	rm -f *.o
