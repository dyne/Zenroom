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

x86-linux: ## Dynamic executable for Linux x86 64bit
	$(MAKE) -f build/linux.mk

x86-musl: ## Static executable for Linux x86 64bit
	$(MAKE) -f build/musl-linux.mk

# bindings: ## Language binding for host platform
# 	$(MAKE) -f build/linux.mk deps zencode-exec

x86-win-exe: ## Executable for Windows x86 64bit
	$(MAKE) -f build/win-exe.mk

x86-win-dll: ## Dynamic lib (DLL) for Windows x86 64bit
	$(MAKE) -f build/win-dll.mk

arm64-ios: ## Dynamic lib (dylib) for Apple iOS ARM64
	$(MAKE) -f build/apple-osx.mk ios-arm64

sim-ios: ## Dynamic lib (dylib) for Apple iOS simulator
	$(MAKE) -f build/apple-ios.mk ios-sim

wasm: ## WebAssembly (WASM) for Javascript in-browser (Emscripten)
	yarn --cwd bindings/javascript
	yarn --cwd bindings/javascript build


install: destbin=${DESTDIR}${PREFIX}/bin
install: destdocs=${DESTDIR}${PREFIX}/share/zenroom
install:
	install -p -s src/zenroom ${destbin}/zenroom
	install -p -s src/zencode-exec ${destbin}/zencode-exec
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
	rm -rf ${pwd}/lib/milagro-crypto-c/build
	rm -rf ${pwd}/lib/mimalloc/build
	make -C ${pwd}/lib/tinycc distclean
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
	rm -f ${pwd}/test/zencode-exec
	rm -f ${pwd}/test/zenroom

clean-src:
	rm -f src/zen_ecdh_factory.c src/zen_ecp_factory.c src/zen_big_factory.c
	$(MAKE) clean -C src

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
	rm -f test/zenroom
	rm -f test/zencode-exec
