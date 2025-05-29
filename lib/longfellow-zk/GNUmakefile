CC ?= gcc
AR ?= ar
CFLAGS ?= -O2 -I../../src -I. -fstack-protector-all	\
			-D_FORTIFY_SOURCE=2 -fno-strict-overflow

include sources.mk


all: liblongfellow-zk.a

liblongfellow-zk.a: CFLAGS += -mpclmul
liblongfellow-zk.a: CC := g++
liblongfellow-zk.a: ${SOURCES}
	$(AR) -r $@ ${SOURCES}

# wasm: COMPILER := ${EMSDK}/upstream/emscripten/em++
# wasm: AR := ${EMSDK}/upstream/emscripten/emar
# wasm: CFLAGS += ${cflags_default} -msimd128 -O2 -sSTRICT -flto -fno-rtti -fno-exceptions -I zstd/lib
# wasm: ${SOURCES}
# 	$(AR) -r liblongfellow-zk.a ${SOURCES}

# wasi: COMPILER := /opt/wasi-sdk/bin/clang++
# wasi: AR := /opt/wasi-sdk/bin/ar
# wasi: CFLAGS += ${cflags_default} --target=wasm32-wasi -I /opt/openssl-wasm/precompiled/include -O3 -flto -msimd128 -nostdlib -I zstd/lib
# wasi: ${SOURCES}
# 	$(AR) -r liblongfellow-zk.a ${SOURCES}

clean:
	find . -name "*.cc.o" -type f -delete
	rm -f *.a

# hard-code build information
%.cc.o: %.cc
	$(CC) -std=c++17 \
	$(CFLAGS) \
	-c $< -o $@ \
	-DVERSION=\"${VERSION}\" \
	-DCURRENT_YEAR=\"${CURRENT_YEAR}\" \
	-DCOMMIT=\"${COMMIT}\" \
	-DBRANCH=\"${BRANCH}\"
