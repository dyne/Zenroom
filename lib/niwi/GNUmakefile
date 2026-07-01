# lib/niwi GNUmakefile

NIWI_CC ?= gcc
NIWI_CXX ?= g++
NIWI_CFLAGS ?= -O2 -I../../src -I. -Iinclude -I../../lib/longfellow-zk \
               -fstack-protector-all -D_FORTIFY_SOURCE=2 -fno-strict-overflow
NIWI_AR ?= ar

NIWI_SOURCES := src/niwi.c.o

all: libniwi.a

libniwi.a: $(NIWI_SOURCES)
	$(NIWI_AR) -r $@ $(NIWI_SOURCES)

clean:
	rm -f src/*.c.o tests/*.o
	rm -f *.a test_abi

%.c.o: %.c
	$(NIWI_CC) -std=c11 $(NIWI_CFLAGS) -c -o $@ $<

%.c.o: %.c
	$(NIWI_CC) -std=c11 $(NIWI_CFLAGS) -c -o $@ $<

%.cc.o: %.cc
	$(NIWI_CXX) -std=c++20 $(NIWI_CFLAGS) -c -o $@ $<

# ---- Tests ----

test: test_abi
	./test_abi

test_abi: tests/test_abi.c.o libniwi.a
	$(NIWI_CC) -std=c11 $(NIWI_CFLAGS) -o $@ tests/test_abi.c.o -L. -lniwi
