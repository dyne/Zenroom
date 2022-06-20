# This Makefile can be used with GNU Make or BSD Make

LIB := libed25519.a
OBJECTS := ed25519.o
RM ?= rm
CFLAGS := ${CFLAGS} -DED25519_FORCE_32BIT -DED25519_REFHASH -DED25519_TEST

all: $(LIB)

%.o: %.c
	$(CC) $(CFLAGS) -fPIC -c -o $@ $<

$(LIB): $(OBJECTS)
	$(AR) -r $@ $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(LIB)
