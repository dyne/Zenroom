# Copyright 2017-2018 Dyne.org foundation
# SPDX-FileCopyrightText: 2017-2021 Dyne.org foundation
#
# SPDX-License-Identifier: AGPL-3.0-or-later

pwd := $(shell pwd)
# ARCH ?=$(shell uname -m)
PREFIX ?= /usr/local
# VERSION is set in src/Makefile
VERSION := $(shell awk '/ZENROOM_VERSION :=/ { print $$3; exit }' src/Makefile | tee VERSION)

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

.PHONY: meson meson-re meson-test
meson:
	meson -Dexamples=true -Ddocs=true -Doptimization=3 build meson
	ninja -C meson
meson-re:
	meson --reconfigure -Dexamples=true -Ddocs=true -Doptimization=3 build meson
	ninja -C meson
meson-test:
	ninja -C meson test

meson-analyze:
	SCANBUILD=$(pwd)/build/scanbuild.sh ninja -C meson scan-build

sonarqube:
	@echo "Configure login token in build/sonarqube.sh"
	cp -v build/sonar-project.properties .
	./build/sonarqube.sh

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
		make -C src linux

# static dependencies in lib
# lpeglabel:
# 	CC=${gcc} CFLAGS="${cflags} -I${pwd}/lib/lua53/src" AR="${ar}" make -C lib/lpeglabel

zlib:
	CC=${gcc} CFLAGS="${cflags}" \
	LDFLAGS="${ldflags}" AR="${ar}" RANLIB=${ranlib} \
	pwd="${pwd}" make -C ${pwd}/build/zlib -f ZenMakefile

android-lua53:
	CC=${gcc} CFLAGS="${cflags} ${lua_cflags}" \
	LDFLAGS="${ldflags}" AR="${ar}" RANLIB=${ranlib} \
	make -C ${pwd}/lib/lua53/src ${platform}

musl-lua53:
	CC=${gcc} CFLAGS="${cflags} ${lua_cflags}" \
	LDFLAGS="${ldflags}" AR="${ar}" RANLIB=${ranlib} \
	make -C ${pwd}/lib/lua53/src ${platform}

lua53:
	CC=${gcc} CFLAGS="${cflags} ${lua_cflags}" \
	LDFLAGS="${ldflags}" AR="${ar}" RANLIB=${ranlib} \
	make -C ${pwd}/lib/lua53/src ${platform}

cortex-lua53:
	CC=${gcc} CFLAGS="${cflags} ${lua_cflags} -DLUA_BAREBONE" \
	LDFLAGS="${ldflags}" AR="${ar}" RANLIB=${ranlib} \
	make -C ${pwd}/lib/lua53/src ${platform}

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
		CC=${gcc} CFLAGS="${cflags}" AR=${ar} RANLIB=${ranlib} LD=${ld} \
		make -C ${pwd}/lib/milagro-crypto-c/build; \
	fi
	make quantum-proof

quantum-proof:
	@echo "-- Building Quantum-Proof libs"
	cd ${pwd}/lib/pqclean && make

check-milagro: milagro
	CC=${gcc} CFLAGS="${cflags}" make -C ${pwd}/lib/milagro-crypto-c test

# -------------------
# Test suites for all platforms
include ${pwd}/build/tests.mk

install: destbin=${DESTDIR}${PREFIX}/bin/zenroom
install: destdocs=${DESTDIR}${PREFIX}/share/zenroom
install:
	install -p -s src/zenroom ${destbin}
	install -d ${destdocs}/docs
	if [ -d docs/website/site ]; then cd docs/website/site && cp -ra * ${destdocs}/docs/; cd -; fi
	install -d ${destdocs}/examples \
		&& cp -ra examples/* ${destdocs}/examples/
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
	make clean -C ${pwd}/lib/lua53/src
	make clean -C ${pwd}/lib/pqclean
	rm -rf ${pwd}/lib/milagro-crypto-c/build
	make clean -C ${pwd}/src
	make clean -C ${pwd}/bindings
	rm -f ${extras}/index.*
	rm -rf ${pwd}/build/asmjs
	rm -rf ${pwd}/build/wasm
	rm -rf ${pwd}/build/rnjs
	rm -rf ${pwd}/build/npm
	rm -rf ${pwd}/build/demo
	rm -f ${pwd}/build/swig_wrap.c
	rm -f ${pwd}/.python-version

clean-src:
	rm -f src/zen_ecdh_factory.c src/zen_ecp_factory.c src/zen_big_factory.c
	make clean -C src

distclean:
	rm -rf ${musl}
