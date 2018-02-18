INCFLAGS := -I../../lib/lua_sandbox/include/luasandbox
CFLAGS   += $(INCFLAGS) -Wall -std=gnu99
SOURCES := mono.o md5.o lzf_d.o depacks.o brieflz.o base58.o rc4.o randombytes.o norx.o luazen.o lzf_c.o

# indicate where .c files are
vpath %.c ../../lib/luazen/src

all: luazen.a

luazen.a: ${SOURCES}
	ar rcc libluazen.a *.o

clean:
	rm -f *.o *.a

.c.o:
	$(CC) $(CFLAGS) -c $< -o $@ -DVERSION=\"${VERSION}\"
