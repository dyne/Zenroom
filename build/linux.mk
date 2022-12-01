musl: ldadd += /usr/lib/${ARCH}-linux-musl/libc.a
musl: ${BUILDS}
	CC="${gcc}" AR="${ar}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		$(MAKE) -C src musl
		@cp -v src/zenroom build/zenroom

musl-local: ldadd += /usr/local/musl/lib/libc.a
musl-local: ${BUILDS}
	CC="${gcc}" AR="${ar}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		$(MAKE) -C src musl

musl-system: gcc := gcc
musl-system: ldadd += -lm
musl-system: ${BUILDS}
	CC="${gcc}" AR="${ar}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		$(MAKE) -C src musl

bsd: gcc := clang
bsd: cflags := -O3 ${cflags_protection} -fPIE -fPIC -DARCH_BSD
bsd: ldadd += -lm
bsd: ${BUILDS}
	CC="${gcc}" AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		$(MAKE) -C src linux
		@cp -v src/zenroom build/zenroom


linux: cflags := -O2 ${cflags_protection} -fPIE -fPIC
linux: ${BUILDS}
	CC="${gcc}" AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		$(MAKE) -C src linux
		@cp -v src/zenroom build/zenroom

linux-raspi: ${BUILDS}
	CC="${gcc}" AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		$(MAKE) -C src linux
		@cp -v src/zenroom build/zenroom

android-arm android-x86 android-aarch64 java-x86_64: ${BUILDS}
	CC="${gcc}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	LD="${ld}" RANLIB="${ranlib}" AR="${ar}" \
		$(MAKE) -C src $@

cortex-arm: ldflags += -Wl,-Map=./zenroom.map
cortex-arm: ${BUILDS}
	CC="${gcc}" AR="${ar}" OBJCOPY="${objcopy}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	$(MAKE) -C src arm

aarch64: ldflags += -Wl,-Map=./zenroom.map
aarch64: ${BUILDS}
	CC="${gcc}" AR="${ar}" OBJCOPY="${objcopy}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	$(MAKE) -C src aarch64

linux-riscv64: ${BUILDS}
	CC="${gcc}" AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	$(MAKE) -C src linux
	@cp -v src/zenroom build/zenroom

linux-debug: ${BUILDS}
	CC="${gcc}" AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	$(MAKE) -C src linux-debug
	@cp -v src/zenroom build/zenroom

linux-debug-ccache: ${BUILDS}
	CC="${gcc}" AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	$(MAKE) -C src linux-debug
	@cp -v src/zenroom build/zenroom

linux-profile: ${BUILDS}
	CC="${gcc}" AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	$(MAKE) -C src linux
	@cp -v src/zenroom build/zenroom

linux-c++: linux

linux-jemalloc: linux

linux-debug-jemalloc: cflags += -O1 -ggdb ${cflags_protection} -DDEBUG=1 -Wstack-usage=4096
linux-debug-jemalloc: linux

# linux-clang: gcc := clang
linux-clang: linux

linux-clang-debug: gcc := clang
linux-clang-debug: linux

linux-sanitizer: gcc := clang
linux-sanitizer: cflags := -O1 -ggdb ${cflags_protection} -DDEBUG=1
linux-sanitizer: cflags += -fsanitize=address -fno-omit-frame-pointer
linux-sanitizer: linux
	ASAN_OPTIONS=verbosity=1:log_threads=1 \
	ASAN_SYMBOLIZER_PATH=/usr/bin/asan_symbolizer \
	ASAN_OPTIONS=abort_on_error=1 \
		./src/zenroom -i -d

linux-lib: cflags := -O3 ${cflags_protection} -fPIE -fPIC
linux-lib: cflags += -shared -DLIBRARY
linux-lib: ${BUILDS}
	CC="${gcc}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		$(MAKE) -C src linux-lib

musl-lib: ldadd += /usr/lib/${ARCH}-linux-musl/libc.a
musl-lib: cflags += -DLIBRARY
musl-lib: ${BUILDS}
	CC="${gcc}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	ECP=${ecp_curve} ECDH=${ecdh_curve} MILIB=${milib} \
	$(MAKE) -C src lib-static

linux-lib-static: cflags := -O3 ${cflags_protection} -fPIE -fPIC
linux-lib-static: cflags += -DLIBRARY
linux-lib-static: ${BUILDS}
	CC="${gcc}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	ECP=${ecp_curve} ECDH=${ecdh_curve} MILIB=${milib} \
	$(MAKE) -C src lib-static

linux-lib-debug: cflags += -shared -DLIBRARY
linux-lib-debug: ${BUILDS}
	CC="${gcc}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	$(MAKE) -C src linux-lib

linux-python3: linux-lib
	@cp -v ${pwd}/src/libzenroom-${ARCH}.so \
		${pwd}/bindings/python3/zenroom/libzenroom.so

linux-go:
	$(MAKE) meson
	cp meson/libzenroom.so bindings/golang/zenroom/lib
	# cd bindings/golang/zenroom && $(MAKE) test

linux-rust: CMD ?= build
linux-rust:
	$(MAKE) meson
	[ -d bindings/rust/clib ] || mkdir bindings/rust/clib
	cp meson/libzenroom.a bindings/rust/clib
	cp lib/milagro-crypto-c/build/lib/* bindings/rust/clib
	cp meson/*.a bindings/rust/clib
	cp src/zenroom.h bindings/rust
	cd bindings/rust && cargo ${CMD}
