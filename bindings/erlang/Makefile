MIX := mix
CC := gcc
# CFLAGS += -dynamiclib -fPIC -Wl,-undefined -Wl,dynamic_lookup -shared
CFLAGS += -fPIC -shared -I. -I../../lib/lua53/src
ERLANG_PATH = $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)
CFLAGS += -I$(ERLANG_PATH)
# ERL_INCLUDE_PATH := /usr/lib/erlang/usr/include

ifneq ($(OS),Windows_NT)
	CFLAGS += -fPIC

	ifeq ($(shell uname),Darwin)
		LDFLAGS += -dynamiclib -undefined dynamic_lookup
	endif
endif

all:
	$(MIX) compile

zenroom.so: module.o
	$(AR) xv libzenroom-x86_64.a
	rm -f libzenroom-x86_64.a
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ *o

test:
	$(CC) $(CFLAGS) -o test.so test.c

clean:
	rm -f *.so *.o *.c.* *.beam *.a

.c.o:
	$(CC) $(CFLAGS) -c $< -o $@
