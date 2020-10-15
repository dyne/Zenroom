MIX := mix
CC := gcc
# CFLAGS += -dynamiclib -fPIC -Wl,-undefined -Wl,dynamic_lookup -shared
CFLAGS += -fPIC -shared -I.
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

zenroom.so: zenroom.c
	$(CC) $(CFLAGS) -shared $(LDFLAGS) -o $@ zenroom.c libzenroom-x86_64.so

test:
	$(CC) $(CFLAGS) -o test.so test.c

clean:
	rm -f *.so *.o *.c.* *.beam
