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
NIWI_CFLAGS ?= -O2 -I. -Isrc -Iinclude -I../../src -I../../lib/longfellow-zk \
               -I../../lib/milagro-crypto-c/build/include \
               -fstack-protector-all -D_FORTIFY_SOURCE=2 -fno-strict-overflow
NIWI_CXXFLAGS ?= $(NIWI_CFLAGS) -fno-exceptions
NIWI_AR ?= ar

# libniwi.a is linked into libzenroom.so by the top-level linux-lib target.
# Keep the archive objects PIC even when the archive is first built through
# linux-exe with non-library top-level flags.
NIWI_CFLAGS += -fPIC

NIWI_AMCL := ../../lib/milagro-crypto-c/build/lib/libamcl_curve_SECP256K1.a \
             ../../lib/milagro-crypto-c/build/lib/libamcl_core.a
NIWI_ZK_DEPS := ../../lib/longfellow-zk/liblongfellow-zk.a \
                ../../lib/zk-circuit-lang/libzk-circuit-lang.a \
                ../../lib/zstd/libzstd.a \
                $(NIWI_AMCL)

NIWI_SOURCES := src/niwi.c.o src/encoding.c.o src/hash.c.o src/npro.c.o src/commitment.c.o src/challenge_schedule.c.o src/extract.c.o \
                src/pbsch_commitment.c.o src/pbsch_commitment_lf.cc.o \
                src/secp256k1/secp256k1_curve.cc.o src/secp256k1/secp256k1_witness.cc.o \
                src/relations/bip340_relation.cc.o src/relations/zkcc_p256_relation.cc.o \
                src/relations/rpbsch_relation.cc.o src/relations/rpbsch_ligero_relation.cc.o

all: libniwi.a

libniwi.a: $(NIWI_SOURCES)
	rm -f $@
	$(NIWI_AR) -r $@ $(NIWI_SOURCES)

clean:
	rm -f src/*.c.o src/*.cc.o tests/*.o src/secp256k1/*.cc.o src/relations/*.cc.o
	rm -f *.a test_abi test_encoding test_hash test_npro test_commitment test_challenge_schedule test_niwi_proof_serde test_extract test_vectors test_bench test_2025_1992_flow_bench test_secp256k1 test_secp256k1_circuit test_zkcc_p256_relation test_bip340_relation test_rpbsch_adapter test_ligero_param test_ligero_bip340 test_rpbsch_sha_circuit test_rpbsch_commitment_circuit test_rpbsch_branch_circuit

%.c.o: %.c
	$(NIWI_CC) -std=c11 $(NIWI_CFLAGS) -c -o $@ $<

%.cc.o: %.cc
	$(NIWI_CXX) -std=c++20 $(NIWI_CXXFLAGS) -c -o $@ $<

# ---- Tests ----

test: test_abi test_encoding test_hash test_npro test_commitment test_challenge_schedule test_niwi_proof_serde test_extract test_vectors test_secp256k1 test_secp256k1_circuit test_zkcc_p256_relation test_bip340_relation test_rpbsch_adapter test_ligero_param test_ligero_bip340 test_rpbsch_sha_circuit test_rpbsch_commitment_circuit test_rpbsch_branch_circuit
	./test_abi
	./test_encoding
	./test_hash
	./test_npro
	./test_commitment
	./test_challenge_schedule
	./test_niwi_proof_serde
	./test_extract
	./test_vectors
	./test_secp256k1
	./test_secp256k1_circuit
	./test_zkcc_p256_relation
	./test_bip340_relation
	./test_rpbsch_adapter
	./test_ligero_param
	./test_ligero_bip340
	./test_rpbsch_sha_circuit
	./test_rpbsch_commitment_circuit
	./test_rpbsch_branch_circuit
	@echo "=== All lib/blindzap tests passed ==="

test_abi: tests/test_abi.c.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_abi.c.o -L. -lniwi $(NIWI_ZK_DEPS)

test_encoding: tests/test_encoding.c.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_encoding.c.o -L. -lniwi $(NIWI_ZK_DEPS)

test_hash: tests/test_hash.c.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_hash.c.o -L. -lniwi $(NIWI_ZK_DEPS)

test_npro: tests/test_npro.c.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_npro.c.o -L. -lniwi $(NIWI_ZK_DEPS)

test_commitment: tests/test_commitment.c.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_commitment.c.o -L. -lniwi $(NIWI_ZK_DEPS)

test_challenge_schedule: tests/test_challenge_schedule.c.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_challenge_schedule.c.o -L. -lniwi $(NIWI_ZK_DEPS)

test_niwi_proof_serde: tests/test_niwi_proof_serde.c.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_niwi_proof_serde.c.o -L. -lniwi $(NIWI_ZK_DEPS)

test_extract: tests/test_extract.c.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_extract.c.o -L. -lniwi $(NIWI_ZK_DEPS)

test_vectors: tests/test_vectors.c.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_vectors.c.o -L. -lniwi $(NIWI_ZK_DEPS)

generate-vectors: test_vectors
	./test_vectors --write

# SECP256K1 tests require C++ and the liblongfellow-zk dependency.
# We link against the archive but this test is standalone — it does not
# depend on the Longfellow archive at link time since SECP headers
# are template-only; the only link requirement is libniwi.a for the
# field/curve/scalar/witness object files.
test_secp256k1: tests/test_secp256k1.cc.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_secp256k1.cc.o -L. -lniwi $(NIWI_ZK_DEPS)

test_secp256k1_circuit: tests/test_secp256k1_circuit.cc.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_secp256k1_circuit.cc.o -L. -lniwi $(NIWI_ZK_DEPS)

test_zkcc_p256_relation: tests/test_zkcc_p256_relation.cc.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_zkcc_p256_relation.cc.o -L. -lniwi $(NIWI_ZK_DEPS)

test_bip340_relation: tests/test_bip340_relation.cc.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_bip340_relation.cc.o -L. -lniwi $(NIWI_ZK_DEPS)

test_rpbsch_adapter: tests/test_rpbsch_adapter.cc.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_rpbsch_adapter.cc.o -L. -lniwi $(NIWI_ZK_DEPS)

test_ligero_param: tests/test_ligero_param.cc.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_ligero_param.cc.o -L. -lniwi $(NIWI_ZK_DEPS)

test_ligero_bip340: tests/test_ligero_bip340.cc.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_ligero_bip340.cc.o -L. -lniwi $(NIWI_ZK_DEPS)

test_rpbsch_sha_circuit: tests/test_rpbsch_sha_circuit.cc.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_rpbsch_sha_circuit.cc.o -L. -lniwi $(NIWI_ZK_DEPS)

test_rpbsch_commitment_circuit: tests/test_rpbsch_commitment_circuit.cc.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_rpbsch_commitment_circuit.cc.o -L. -lniwi $(NIWI_ZK_DEPS)

test_rpbsch_branch_circuit: tests/test_rpbsch_branch_circuit.cc.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -o $@ tests/test_rpbsch_branch_circuit.cc.o -L. -lniwi $(NIWI_ZK_DEPS)

# ---- Benchmarks ----

bench: test_bench
	./test_bench

bench-2025-1992-flow: test_2025_1992_flow_bench
	./test_2025_1992_flow_bench

test_bench: tests/test_bench.c.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -O2 -o $@ tests/test_bench.c.o -L. -lniwi $(NIWI_ZK_DEPS) -lrt

test_2025_1992_flow_bench: tests/test_2025_1992_flow_bench.c.o libniwi.a
	$(NIWI_CXX) $(NIWI_CFLAGS) -O2 -o $@ tests/test_2025_1992_flow_bench.c.o -L. -lniwi $(NIWI_ZK_DEPS) -lrt
