# This Makefile can be used with GNU Make or BSD Make

LIB := libed25519.a
OBJECTS := ed25519.o
RM ?= rm
CFLAGS := ${CFLAGS} -I../milagro-crypto-c/build/include -DED25519_CUSTOMHASH -DED25519_TEST
# TODO: in future this condition may have to change for
# other x64 operating systems (e.g. iOS)
UNAME_S := $(shell uname -s)
ifneq (${UNAME_S},Darwin)
ifeq (,$(findstring clang,$(CC)))
	CFLAGS := ${CFLAGS} -DED25519_FORCE_32BIT
endif
endif

all: $(LIB)

%.o: %.c
	$(CC) $(CFLAGS) -fPIC -c -o $@ $<

$(LIB): $(OBJECTS)
	$(AR) -r $@ $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(LIB)
