# This file is part of Zenroom (https://zenroom.dyne.org)
#
# Copyright (C) 2026 Dyne.org foundation
# designed, written and maintained by Denis Roio <jaromil@dyne.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

NIWI_CC ?= gcc
NIWI_CXX ?= g++
NIWI_CFLAGS ?= -O2 -I../../src -I. -Isrc -Iinclude -I../../lib/longfellow-zk \
               -I../../lib/milagro-crypto-c/build/include \
               -fstack-protector-all -D_FORTIFY_SOURCE=2 -fno-strict-overflow
NIWI_AR ?= ar

NIWI_AMCL := ../../lib/milagro-crypto-c/build/lib/libamcl_core.a

NIWI_SOURCES := src/niwi.c.o src/encoding.c.o src/hash.c.o src/npro.c.o src/commitment.c.o src/extract.c.o

all: libniwi.a

libniwi.a: $(NIWI_SOURCES)
	$(NIWI_AR) -r $@ $(NIWI_SOURCES)

clean:
	rm -f src/*.c.o tests/*.o
	rm -f *.a test_abi test_encoding test_hash test_npro test_commitment test_niwi_proof_serde test_extract test_bench

%.c.o: %.c
	$(NIWI_CC) -std=c11 $(NIWI_CFLAGS) -c -o $@ $<

%.cc.o: %.cc
	$(NIWI_CXX) -std=c++20 $(NIWI_CFLAGS) -c -o $@ $<

# ---- Tests ----

test: test_abi test_encoding test_hash test_npro test_commitment test_niwi_proof_serde test_extract
	./test_abi
	./test_encoding
	./test_hash
	./test_npro
	./test_commitment
	./test_niwi_proof_serde
	./test_extract
	@echo "=== All lib/niwi tests passed ==="

test_abi: tests/test_abi.c.o libniwi.a
	$(NIWI_CC) -std=c11 $(NIWI_CFLAGS) -o $@ tests/test_abi.c.o -L. -lniwi

test_encoding: tests/test_encoding.c.o libniwi.a
	$(NIWI_CC) -std=c11 $(NIWI_CFLAGS) -o $@ tests/test_encoding.c.o -L. -lniwi

test_hash: tests/test_hash.c.o libniwi.a
	$(NIWI_CC) -std=c11 $(NIWI_CFLAGS) -o $@ tests/test_hash.c.o -L. -lniwi $(NIWI_AMCL)

test_npro: tests/test_npro.c.o libniwi.a
	$(NIWI_CC) -std=c11 $(NIWI_CFLAGS) -o $@ tests/test_npro.c.o -L. -lniwi $(NIWI_AMCL)

test_commitment: tests/test_commitment.c.o libniwi.a
	$(NIWI_CC) -std=c11 $(NIWI_CFLAGS) -o $@ tests/test_commitment.c.o -L. -lniwi $(NIWI_AMCL)

test_niwi_proof_serde: tests/test_niwi_proof_serde.c.o libniwi.a
	$(NIWI_CC) -std=c11 $(NIWI_CFLAGS) -o $@ tests/test_niwi_proof_serde.c.o -L. -lniwi $(NIWI_AMCL)

test_extract: tests/test_extract.c.o libniwi.a
	$(NIWI_CC) -std=c11 $(NIWI_CFLAGS) -o $@ tests/test_extract.c.o -L. -lniwi $(NIWI_AMCL)

# ---- Benchmarks ----

bench: test_bench
	./test_bench

test_bench: tests/test_bench.c.o libniwi.a
	$(NIWI_CC) -std=c11 $(NIWI_CFLAGS) -O2 -o $@ tests/test_bench.c.o -L. -lniwi $(NIWI_AMCL) -lrt
