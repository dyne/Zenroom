# Copyright 2017-2018 Dyne.org foundation
# SPDX-FileCopyrightText: 2017-2021 Dyne.org foundation
#
# SPDX-License-Identifier: AGPL-3.0-or-later

pwd := $(shell pwd)
# ARCH ?=$(shell uname -m)
PREFIX ?= /usr/local
# VERSION is set in src/Makefile
VERSION := $(shell awk '/ZENROOM_VERSION :=/ { print $$3; exit }' src/Makefile | tee VERSION)
# Targets to be build in this order
BUILDS := apply-patches milagro lua53 embed-lua zstd quantum-proof ed25519-donna mimalloc blake2

# DESTDIR is supported by install target

# include platform specific configurations pattern-matching target labels
include ${pwd}/build/config.mk

all:
	@echo "Choose a target:"
	@echo "- linux, linux-lib, linux-clang, linux-debug"
	@echo "- javascript-web, javascript-wasm, javascript-demo, javascript-rn (need EMSDK)"
	@echo "- linux-python3, linux-go, osx-python3, osx-go (language bindings)"
	@echo "- osx, osx-lib, ios-lib, ios-armv7, ios-arm64, ios-sim (need Apple/OSX)"
	@echo "- win, win-dll (cross-compile using MINGW on Linux)"
	@echo "- musl, musl-local, musl-system (full static build)"
	@echo "- android-arm android-x86 android-aarch64"
	@echo "- cortex-arm, linux-riscv64, aarch64"
	@echo "for android and ios see scripts in build/"

# if ! [ -r build/luac ]; then ${gcc} -I${luasrc} -o build/luac ${luasrc}/luac.c ${luasrc}/liblua.a -lm; fi

.PHONY: zstd

sonarqube:
	@echo "Configure login token in build/sonarqube.sh"
	cp -v build/sonar-project.properties .
	./build/sonarqube.sh

embed-lua: lua_embed_opts := $(if ${COMPILE_LUA}, compile)
embed-lua:
	@echo "Embedding all files in src/lua"
	./build/embed-lualibs ${lua_embed_opts}
	@echo "File generated: src/lualibs_detected.c"

src/zen_ecdh_factory.c:
	${pwd}/build/codegen_ecdh_factory.sh ${ecdh_curve}

src/zen_ecp_factory.c:
	${pwd}/build/codegen_ecp_factory.sh ${ecp_curve}

src/zen_big_factory.c:
	${pwd}/build/codegen_ecp_factory.sh ${ecp_curve}

apply-patches: src/zen_ecdh_factory.c src/zen_ecp_factory.c src/zen_big_factory.c

# build targets for javascript (emscripten)
include ${pwd}/build/javascript.mk

# build targets for windows (mingw32 cross compile on Linux)
include ${pwd}/build/windows.mk

# build targets for linux systems (also musl and android)
include ${pwd}/build/linux.mk

# build targets for the meson build system (mostly linux)
include ${pwd}/build/meson.mk

# build targets for apple systems (OSX and IOS)
include ${pwd}/build/osx.mk

# build docker images and releasing
include ${pwd}/build/docker.mk

# build luarock module
include ${pwd}/build/luarock.mk

# experimental target for xtensa embedded boards
esp32: apply-patches milagro lua53
	CC=${pwd}/build/xtensa-esp32-elf/bin/xtensa-esp32-elf-${gcc} \
	LD=${pwd}/build/xtensa-esp32-elf/bin/xtensa-esp32-elf-ld \
	CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		$(MAKE) -C src linux

# static dependencies in lib
# lpeglabel:
# 	CC=${gcc} CFLAGS="${cflags} -I${pwd}/lib/lua53/src" AR="${ar}" $(MAKE) -C lib/lpeglabel

android-lua53:
	CC="${lua_cc}" CFLAGS="${cflags} ${lua_cflags}" \
	LDFLAGS="${ldflags}" AR="${ar}" RANLIB=${ranlib} \
	$(MAKE) -C ${pwd}/lib/lua53/src ${platform}

musl-lua53:
	CC="${lua_cc}" CFLAGS="${cflags} ${lua_cflags}" \
	LDFLAGS="${ldflags}" AR="${ar}" RANLIB=${ranlib} \
	$(MAKE) -C ${pwd}/lib/lua53/src ${platform}

lua53:
	CC="${lua_cc}" CFLAGS="${cflags} ${lua_cflags}" \
	LDFLAGS="${ldflags}" AR="${ar}" RANLIB=${ranlib} \
	$(MAKE) -C ${pwd}/lib/lua53/src ${platform}

cortex-lua53:
	CC="${lua_cc}" CFLAGS="${cflags} ${lua_cflags} -DLUA_BAREBONE" \
	LDFLAGS="${ldflags}" AR="${ar}" RANLIB=${ranlib} \
	$(MAKE) -C ${pwd}/lib/lua53/src ${platform}

milagro-debug: milagro
milagro:
	@echo "-- Building milagro (${system})"
	if ! [ -r ${pwd}/lib/milagro-crypto-c/build/CMakeCache.txt ]; then \
		cd ${pwd}/lib/milagro-crypto-c && \
		mkdir -p build && \
		cd build && \
		CC=${gcc} LD=${ld} \
		cmake ../ -DCMAKE_C_FLAGS="${cflags}" -DCMAKE_SYSTEM_NAME="${system}" \
		-DCMAKE_AR=${ar} -DCMAKE_C_COMPILER=${gcc} ${milagro_cmake_flags}; \
	fi
	if ! [ -r ${pwd}/lib/milagro-crypto-c/build/lib/libamcl_core.a ]; then \
		RANLIB=${ranlib} LD=${ld} \
		$(MAKE) -C ${pwd}/lib/milagro-crypto-c/build; \
	fi

mimalloc-debug: mimalloc
mimalloc:
	$(info -- Building mimalloc (${system}))
	if ! [ -r ${pwd}/lib/mimalloc/build/CMakeCache.txt ]; then \
		cd ${pwd}/lib/mimalloc && \
                mkdir -p build && \
                cd build && \
                CC=${gcc} LD=${ld} \
                cmake ../ ${mimalloc_cmake_flags} \
                -DCMAKE_C_FLAGS="${cflags} ${mimalloc_cflags}" \
                -DCMAKE_SYSTEM_NAME="${system}" \
                -DCMAKE_AR=${ar} -DCMAKE_C_COMPILER=${gcc} \
	        -DCMAKE_CXX_COMPILER=$(subst gcc,g++,${gcc}); \
	fi
	if ! [ -r ${pwd}/lib/mimalloc/build/libmimalloc-static.a ]; then \
                RANLIB=${ranlib} LD=${ld} \
                ${MAKE} -C ${pwd}/lib/mimalloc/build; \
	fi

quantum-proof-ccache: quantum-proof
quantum-proof-debug: quantum-proof
quantum-proof:
	$(info -- Building Quantum-Proof libs)
	CC="${quantum_proof_cc}" \
	LD=${ld} \
	AR=${ar} \
	RANLIB=${ranlib} \
	LD=${ld} \
	CFLAGS="${quantum_proof_cflags} ${cflags}" \
	LDFLAGS="${ldflags}" \
	${MAKE} -C ${pwd}/lib/pqclean

check-milagro: milagro
	CC=${gcc} CFLAGS="${cflags}" $(MAKE) -C ${pwd}/lib/milagro-crypto-c test

zstd:
	echo "-- Building ZSTD"
	CC="${zstd_cc}" \
	LD=${ld} \
	AR=${ar} \
	RANLIB=${ranlib} \
	LD=${ld} \
	CFLAGS="${cflags}" \
	LDFLAGS="${ldflags}" \
	$(MAKE) libzstd.a -C ${pwd}/lib/zstd \
	ZSTD_LIB_DICTBUILDER=0 \
	ZSTD_LIB_DEPRECATED=0 \
	ZSTD_LEGACY_SUPPORT=0 \
	HUF_FORCE_DECOMPRESS_X1=1 \
	ZSTD_FORCE_DECOMPRESS_SEQUENCES_SHORT=1 \
	ZSTD_STRIP_ERROR_STRINGS=0 \
	ZSTD_NO_INLINE=1

ed25519-donna-ccache: ed25519-donna
ed25519-donna:
	echo "-- Building ED25519 for EDDSA"
	CC="${ed25519_cc}" \
	AR=${ar} \
	CFLAGS="${cflags}" \
	LDFLAGS="${ldflags}" \
	$(MAKE) -C ${pwd}/lib/ed25519-donna

blake2:
	$(info -- Building Blake2 hash)
	CC="${blake2_cc}" \
	AR=${ar} \
	CFLAGS="${cflags}" \
	LDFLAGS="${ldflags}" \
	$(MAKE) -C ${pwd}/lib/blake2

# -------------------
# Test suites for all platforms
include ${pwd}/build/tests.mk

install: destbin=${DESTDIR}${PREFIX}/bin/zenroom
install: destdocs=${DESTDIR}${PREFIX}/share/zenroom
install:
	install -p -s src/zenroom ${destbin}
	install -d ${destdocs}/docs
	if [ -d docs/website/site ]; then cd docs/website/site && cp -ra * ${destdocs}/docs/; cd -; fi
	if [ -d docs/Zencode_Whitepaper.pdf ]; then cp -ra docs/Zencode_Whitepaper.pdf ${destdocs}/; fi
	cp README.md ${destdocs}/README.txt
	cp LICENSE.txt ${destdocs}/LICENSE.txt
	cp ChangeLog.md ${destdocs}/ChangeLog.txt

install-lua: destlib=${LIBDIR}
install-lua:
	mkdir -p ${destlib}
	cp src/octet.so ${destlib}
	cp src/ecdh.so ${destlib}

clean:
	rm -rf ${pwd}/meson
	$(MAKE) clean -C ${pwd}/lib/lua53/src
	$(MAKE) clean -C ${pwd}/lib/pqclean
	rm -rf ${pwd}/lib/milagro-crypto-c/build
	rm -rf ${pwd}/lib/mimalloc/build
	$(MAKE) clean -C ${pwd}/lib/zstd
	$(MAKE) clean -C ${pwd}/lib/blake2
	$(MAKE) clean -C ${pwd}/src
	if [ -d "bindings" ]; then $(MAKE) clean -C ${pwd}/bindings; fi
	rm -f ${extras}/index.*
	rm -rf ${pwd}/build/asmjs
	rm -rf ${pwd}/build/wasm
	rm -rf ${pwd}/build/rnjs
	rm -rf ${pwd}/build/npm
	rm -rf ${pwd}/build/demo
	rm -f ${pwd}/build/swig_wrap.c
	rm -f ${pwd}/.python-version
	rm -f ${pwd}/src/zenroom
	rm -f ${pwd}/lib/ed25519-donna/libed25519.a
	rm -f ${pwd}/lib/ed25519-donna/*.o

clean-src:
	rm -f src/zen_ecdh_factory.c src/zen_ecp_factory.c src/zen_big_factory.c
	$(MAKE) clean -C src

distclean:
	rm -rf ${musl}

# -------------------
# Parsing the documentation
needed-docs:
	cd ${pwd}/docs/doc_needed; ./run.sh
