musl: ldadd += /usr/lib/${ARCH}-linux-musl/libc.a
musl: apply-patches milagro embed-lua lua53
	CC=${gcc} AR="${ar}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src musl
		@cp -v src/zenroom build/zenroom

musl-local: ldadd += /usr/local/musl/lib/libc.a
musl-local: apply-patches milagro embed-lua lua53
	CC=${gcc} AR="${ar}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src musl

musl-system: gcc := gcc
musl-system: ldadd += -lm
musl-system: apply-patches milagro embed-lua lua53
	CC=${gcc} AR="${ar}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src musl

bsd: cflags := -O3 ${cflags_protection} -fPIE -fPIC -DARCH_BSD
bsd: ldadd += -lm
bsd: apply-patches milagro lua53 embed-lua
	CC=${gcc} AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src linux
		@cp -v src/zenroom build/zenroom


linux: cflags := -O3 ${cflags_protection} -fPIE -fPIC
linux: apply-patches milagro lua53 embed-lua
	CC=${gcc} AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src linux
		@cp -v src/zenroom build/zenroom

linux-raspi: apply-patches milagro lua53 embed-lua
	CC=${gcc} AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src linux
		@cp -v src/zenroom build/zenroom

android-arm android-x86 android-aarch64 java-x86_64: apply-patches milagro lua53 embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	LD="${ld}" RANLIB="${ranlib}" AR="${ar}" \
		make -C src $@

cortex-arm: ldflags += -Wl,-Map=./zenroom.map
cortex-arm:	apply-patches milagro cortex-lua53 embed-lua
	CC=${gcc} AR="${ar}" OBJCOPY="${objcopy}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src arm

aarch64: ldflags += -Wl,-Map=./zenroom.map
aarch64: apply-patches milagro cortex-lua53 embed-lua
	CC=${gcc} AR="${ar}" OBJCOPY="${objcopy}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src arm

linux-riscv64: apply-patches milagro lua53 embed-lua
	CC=${gcc} AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src linux
	@cp -v src/zenroom build/zenroom

linux-debug: apply-patches milagro lua53 embed-lua
	CC=${gcc} AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src linux
	@cp -v src/zenroom build/zenroom

linux-profile:
	CC=${gcc} AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src linux
	@cp -v src/zenroom build/zenroom

linux-c++: linux

linux-jemalloc: linux

linux-debug-jemalloc: cflags += -O1 -ggdb ${cflags_protection} -DDEBUG=1 -Wstack-usage=4096
linux-debug-jemalloc: linux

linux-clang: gcc := clang
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
linux-lib: apply-patches milagro lua53 embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src linux-lib

musl-lib: ldadd += /usr/lib/${ARCH}-linux-musl/libc.a
musl-lib: cflags += -DLIBRARY
musl-lib: apply-patches milagro lua53 embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	ECP=${ecp_curve} ECDH=${ecdh_curve} MILIB=${milib} \
	make -C src lib-static

linux-lib-static: cflags := -O3 ${cflags_protection} -fPIE -fPIC
linux-lib-static: cflags += -DLIBRARY
linux-lib-static: apply-patches milagro lua53 embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	ECP=${ecp_curve} ECDH=${ecdh_curve} MILIB=${milib} \
	make -C src lib-static

linux-lib-debug: cflags += -shared -DLIBRARY
linux-lib-debug: apply-patches milagro lua53 embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src linux-lib

linux-python3: linux-lib
	@cp -v ${pwd}/src/libzenroom-${ARCH}.so \
		${pwd}/bindings/python3/zenroom/libzenroom.so

linux-go: apply-patches milagro lua53 embed-lua
	swig -go -cgo -intgosize 32 ${pwd}/build/swig.i
	${gcc} ${cflags} -c ${pwd}/build/swig_wrap.c -o src/zen_go.o
	CC=${gcc} LD=${ld} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src go
	cp -v ${pwd}/src/libzenroomgo.so ${pwd}/bindings/golang/zenroom/lib/

linux-erlang: cflags += -I $(shell erl -eval 'io:format("~s", [lists:concat([code:root_dir(), "/erts-", erlang:system_info(version), "/include"])])' -s init stop -noshell)
linux-erlang: cflags += -DLIBRARY
linux-erlang: apply-patches milagro lua53 embed-lua
	CC=${gcc} LD=${ld} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src erlang
	cp -v src/zenroom.h src/zenroom.so bindings/erlang/
	cd bindings/erlang && ./build
