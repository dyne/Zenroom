# This Makefile can be used with GNU Make or BSD Make

LIB := libargon2.a
OBJECTS := thread.o  ref.o  opt.o  genkat.o  encoding.o  core.o  bench.o  argon2.o
RM ?= rm
CFLAGS := ${CFLAGS} -I.. -I.

all: $(LIB)

%.o: %.c
	$(CC) $(CFLAGS) -fPIC -c -o $@ $<

$(LIB): $(OBJECTS)
	$(AR) -r $@ $(OBJECTS)

clean:
	$(RM) $(OBJECTS)
	$(RM) $(LIB)
