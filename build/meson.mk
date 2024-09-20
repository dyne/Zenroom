## Initialize build defaults
include build/init.mk

BUILD_DEPS += mimalloc
BUILD_DEPS += tinycc
## Specific compiler settings for all built dependencies
ifdef RELEASE
	cflags +=  -O3 ${cflags_protection} -fPIC
else
	cflags += ${cflags_debug} -fPIC
endif
ifdef CLANG
	cc := clang
	zenroom_cc := ${cc}
	quantum_proof_cc := ${cc}
	ed25519_cc := ${cc}
	lua_cc := ${cc}
endif
ifdef CCACHE
	milagro_cmake_flags += -DCMAKE_C_COMPILER_LAUNCHER=ccache
	mimalloc_cmake_flags += -DCMAKE_C_COMPILER_LAUNCHER=ccache
	mimalloc_cmake_flags += -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
	zenroom_cc := ccache ${cc}
	quantum_proof_cc := ccache ${cc}
	ed25519_cc := ccache ${cc}
	lua_cc := ccache ${cc}
endif

# MAIN TARGETS
all: ${BUILD_DEPS} prepare
	CC="${zenroom_cc}" AR="${ar}" CFLAGS="${cflags}"			\
	LDFLAGS="${ldflags}" LDADD="${ldadd}" meson -Dexamples=true	\
	-Ddocs=true -Doptimization=3 -Decdh_curve=${ecdh_curve}		\
	-Decp_curve=${ecp_curve} -Ddefault_library=both build meson
	ninja -C meson
gcc: all

asan:
	CC="clang" CXX="clang++" AR="llvm-ar" CFLAGS="-fsanitize=address	\
	-fno-omit-frame-pointer" LDFLAGS="-fsanitize=address ${ldflags}"	\
	LDADD="${ldadd}" meson -Dexamples=false -Ddocs=false				\
	-Doptimization=0 -Decdh_curve=${ecdh_curve}							\
	-Decp_curve=${ecp_curve} -Ddefault_library=both						\
	-Db_sanitize=address build meson
	ninja -C meson

# subtargets
prepare:
	mkdir -p meson
	ln -sf ../lib/milagro-crypto-c/build meson/milagro-crypto-c
	ln -sf ../lib/pqclean/libqpz.a meson/libqpz.a
	ln -sf ../lib/lua54/src/liblua.a meson/liblua.a
	ln -sf ../lib/ed25519-donna/libed25519.a meson/libed25519.a
	ln -sf ../lib/mimalloc/build/libmimalloc-static.a meson/libmimalloc-static.a
	ln -sf ../lib/tinycc/libtcc.a meson/libtcc.a

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
