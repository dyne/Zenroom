## Initialize build defaults
include build/init.mk

BUILD_DEPS += mimalloc
BUILD_DEPS += tinycc

COMPILER ?= gcc

## Specific compiler settings for all built dependencies
ifdef RELEASE
	cflags +=  -O3 ${cflags_protection} -fPIC
else
	cflags += ${cflags_debug} -fPIC
endif

# activate CCACHE etc.
include build/plugins.mk

all: deps prepare config ninja

# MAIN TARGETS
deps: ${BUILD_DEPS}

# subtargets
prepare:
	mkdir -p meson
	ln -sf ../lib/milagro-crypto-c/build meson/milagro-crypto-c
	ln -sf ../lib/pqclean/libqpz.a meson/libqpz.a
	ln -sf ../lib/lua54/src/liblua.a meson/liblua.a
	ln -sf ../lib/ed25519-donna/libed25519.a meson/libed25519.a
	ln -sf ../lib/mimalloc/build/libmimalloc-static.a meson/libmimalloc-static.a
	ln -sf ../lib/tinycc/libtcc.a meson/libtcc.a

config:
	CC="${zenroom_cc}" AR="${ar}" CFLAGS="${cflags}"			\
	LDFLAGS="${ldflags}" LDADD="${ldadd}" meson -Dexamples=true	\
	-Ddocs=true -Doptimization=3 -Decdh_curve=${ecdh_curve}		\
	-Decp_curve=${ecp_curve} -Ddefault_library=both build meson

ninja:
	ninja -C meson

asan:
	CC="clang" CXX="clang++" AR="llvm-ar" CFLAGS="-fsanitize=address	\
	-fno-omit-frame-pointer" LDFLAGS="-fsanitize=address ${ldflags}"	\
	LDADD="${ldadd}" meson -Dexamples=false -Ddocs=false				\
	-Doptimization=0 -Decdh_curve=${ecdh_curve}							\
	-Decp_curve=${ecp_curve} -Ddefault_library=both						\
	-Db_sanitize=address build meson
	ninja -C meson

prepare-test:
	echo '#!/bin/sh' > ${pwd}/test/zenroom
	echo "${pwd}/meson/zenroom "'$$*' >> ${pwd}/test/zenroom
	chmod +x ${pwd}/test/zenroom
	echo '#!/bin/sh' > ${pwd}/test/zencode-exec
	echo "${pwd}/meson/zencode-exec "'$$*' >> ${pwd}/test/zencode-exec
	chmod +x ${pwd}/test/zencode-exec

test: prepare-test
	ninja -C meson test

benchmark: prepare-test
	ninja -C meson benchmark

analyze:
	SCANBUILD=$(pwd)/build/scanbuild.sh ninja -C meson scan-build

include build/deps.mk
