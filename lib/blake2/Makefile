# This Makefile can be used with GNU Make or BSD Make

LIB := libblake2.a
OBJECTS := blake2b.o
RM ?= rm
CFLAGS := ${CFLAGS} -I ../argon2

all: $(LIB)

%.o: %.c
	$(CC) $(CFLAGS) -fPIC -c -o $@ $<

$(LIB): $(OBJECTS)
	$(AR) -r $@ $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(LIB)
