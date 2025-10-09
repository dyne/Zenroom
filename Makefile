# Copyright 2017-2018 Dyne.org foundation
# SPDX-FileCopyrightText: 2017-2021 Dyne.org foundation
#
# SPDX-License-Identifier: AGPL-3.0-or-later

.PHONY: help

pwd := $(shell pwd)
# ARCH ?=$(shell uname -m)
PREFIX ?= /usr/local
# VERSION is set in build/init.mk
# DESTDIR is supported by install target

help:
	@echo "✨ Welcome to the Zenroom build system"
	@awk 'BEGIN {FS = ":.*##"; printf "🛟 Usage: make \033[36m<target>\033[0m\n👇🏽 List of targets:\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf " \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5)} ' Makefile

# help: ## 🛟  Show this help message
# 	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf " \033[36m 👉 %-14s\033[0m %s\n", $$1, $$2}'

posix-exe: ## Dynamic executable for generic POSIX
	$(MAKE) -f build/posix.mk

posix-lib: ## Dynamic library for generic POSIX
	$(MAKE) -f build/posix.mk libzenroom.so LIBRARY=1

linux-exe: ## Dynamic executable for GNU/Linux
	$(MAKE) -f build/posix.mk LINUX=1

linux-lib: ## Dynamic library for GNU/Linux
	$(MAKE) -f build/posix.mk libzenroom.so LINUX=1 LIBRARY=1

debug-asan: ## Address sanitizer debug build
	$(MAKE) -f build/posix.mk LINUX=1 deps BUILD_DEPS="apply-patches milagro"
	$(MAKE) -f build/posix.mk ASAN=1
	$(MAKE) -f build/posix.mk libzenroom.so ASAN=1

debug-gprof: ## Address sanitizer debug build
	$(MAKE) -f build/posix.mk LINUX=1 GPROF=1
	$(MAKE) -f build/posix.mk libzenroom.so LINUX=1 GPROF=1

quick-asan: # quick debug rebuild skipping deps and embed-lua
	$(MAKE) -f build/posix.mk ASAN=1 BUILD_DEPS=""
	$(MAKE) -f build/posix.mk libzenroom.so ASAN=1 BUILD_DEPS=""

musl: ## Static executable for Musl
	$(MAKE) -f build/musl.mk

win-exe: ## Executable for Windows x86 64bit
	$(MAKE) -f build/win-exe.mk

win-dll: ## Dynamic lib (DLL) for Windows x86 64bit
	$(MAKE) -f build/win-dll.mk

osx-exe: ## Executable for Apple MacOS
	$(MAKE) -f build/posix.mk OSX=1

osx-lib: ## Library for Apple MacOS native
	$(MAKE) -f build/posix.mk libzenroom.dylib OSX=1 LIBRARY=1

ios-armv7: ## Libraries for Apple iOS native armv7
	$(MAKE) -f build/apple-ios.mk ios-armv7
ios-arm64: ## Libraries for Apple iOS native arm64
	$(MAKE) -f build/apple-ios.mk ios-arm64
ios-sim: ## Libraries for Apple iOS simulator on XCode
	$(MAKE) -f build/apple-ios.mk ios-sim

# ios-arm64: # TODO: build/old/osx.mk Dynamic lib (dylib) for Apple iOS ARM64
# 	$(MAKE) -f build/apple-osx.mk ios-arm64

# ios-sim: ## TODO: build/old/osx.mk Dynamic lib (dylib) for Apple iOS simulator
# 	$(MAKE) -f build/apple-ios.mk ios-sim

node-wasm: ## WebAssembly (WASM) for Javascript in-browser (Emscripten)
	yarn --cwd bindings/javascript
	yarn --cwd bindings/javascript build

check: ## Run tests using the current binary executable build
	meson setup meson/ build/ -D \
	"tests=['determinism','vectors','lua','zencode','blockchain','bindings','api']"
	ninja -C meson test

wrap-js: # Generate the ./zenroom exec wrapper on node-wasm builds
	$(info Generate JS wrapper in ./zenroom)
	@sed 's@=ROOT=@'"${pwd}"'@' test/zexe_js_wrapper.sh > zenroom
	@chmod +x zenroom

check-js: ## Run tests using the WASM build for Node
	yarn --cwd bindings/javascript test
	$(MAKE) wrap-js
	meson setup meson/ build/ -D "tests=['lua','zencode']"
	ninja -C meson test

check-rs: test-exec := ${pwd}/test/zenroom_exec_rs/target/debug/zenroom_exec_rs
check-rs:
	cargo build --manifest-path ${pwd}/test/zenroom_exec_rs/Cargo.toml
	@echo -e "#!/bin/sh\n${test-exec} \$$@\n" > zenroom
	@chmod +x zenroom
	meson setup meson/ build/ -D "tests=['lua']"
	ninja -C meson test

check-osx: ## Run tests using the OSX binary executable build
	meson setup meson/ build/ -D \
	"tests=['determinism','vectors','lua','zencode','bindings']"
	ninja -C meson test

install: destbin=${DESTDIR}${PREFIX}/bin
install: destdocs=${DESTDIR}${PREFIX}/share/zenroom
install:
	install -p -s zenroom ${destbin}/zenroom
	install -p -s zencode-exec ${destbin}/zencode-exec
	install -p -s lua-exec ${destbin}/lua-exec
	install -d ${destdocs}/docs
	if [ -d docs/website/site ]; then cd docs/website/site && cp -ra * ${destdocs}/docs/; cd -; fi
	if [ -d docs/Zencode_Whitepaper.pdf ]; then cp -ra docs/Zencode_Whitepaper.pdf ${destdocs}/; fi
	cp README.md ${destdocs}/README.txt
	cp LICENSE.txt ${destdocs}/LICENSE.txt
	cp ChangeLog.md ${destdocs}/ChangeLog.txt

clean:
	rm -rf ${pwd}/meson
	$(MAKE) clean -C ${pwd}/lib/lua54/src
	$(MAKE) clean -C ${pwd}/lib/pqclean
	$(MAKE) clean -C ${pwd}/lib/mlkem
	$(MAKE) clean -C ${pwd}/lib/longfellow-zk
	rm -rf ${pwd}/lib/milagro-crypto-c/build
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
	rm -f ${pwd}/lib/ed25519-donna/libed25519.a
	rm -f ${pwd}/lib/ed25519-donna/*.o
	rm -f ${pwd}/zenroom
	rm -f ${pwd}/zencode-exec
	rm -f ${pwd}/lua-exec
	rm -f ${pwd}/luac54
	rm -f ${pwd}/libzenroom.so
	rm -f ${pwd}/zenroom.js
	rm -f ${pwd}/zenroom.web.js

# -------------------
# Parsing the documentation
needed-docs:
	cd ${pwd}/docs/doc_needed; ./run.sh

# -------------------
# Linux benchamrk
linux-benchmark:
	./test/benchmark/all_tests/bench.sh

clean-test:
	git clean -f docs
	git restore docs
