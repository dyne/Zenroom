# This Makefile can be used with GNU Make or BSD Make

LIB := libblake2.a
OBJECTS := blake2xs-ref.o blake2s-ref.o blake2b-ref.o \
	blake2xb-ref.o  blake2sp-ref.o  blake2bp-ref.o
RM ?= rm
CFLAGS := ${CFLAGS}

all: $(LIB)

%.o: %.c
	$(CC) $(CFLAGS) -fPIC -c -o $@ $<

$(LIB): $(OBJECTS)
	$(AR) -r $@ $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(LIB)
