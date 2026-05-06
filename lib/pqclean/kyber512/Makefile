# This Makefile can be used with GNU Make or BSD Make

LIB=libkyber512_clean.a
HEADERS=api.h cbd.h indcpa.h kem.h ntt.h params.h poly.h polyvec.h reduce.h symmetric.h verify.h skem.h kyber_larkg.h
OBJECTS=cbd.o indcpa.o kem.o ntt.o poly.o polyvec.o reduce.o symmetric-shake.o verify.o skem.o kyber_larkg.o ../fips202.o

# CFLAGS=-O3 -Wall -Wextra -Wpedantic -Werror -Wmissing-prototypes -Wredundant-decls -std=c99 -I.. $(EXTRAFLAGS)

all: $(LIB)

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) -fPIC -c -o $@ $<

$(LIB): $(OBJECTS)
	$(AR) -r $@ $(OBJECTS)

RANDOMBYTES=../../../src/randombytes.c

test_larkg: test_larkg.o $(OBJECTS) $(RANDOMBYTES:.c=.o)
	$(CC) $(CFLAGS) -o $@ test_larkg.o $(OBJECTS) $(RANDOMBYTES:.c=.o) -lm

../../../src/randombytes.o: $(RANDOMBYTES)
	$(CC) $(CFLAGS) -fPIC -c -o $@ $(RANDOMBYTES)

test_larkg.o: test_larkg.c $(HEADERS)
	$(CC) $(CFLAGS) -fPIC -c -o $@ test_larkg.c

clean:
	$(RM) $(OBJECTS)
	$(RM) $(LIB)
