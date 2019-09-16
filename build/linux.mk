musl: ldadd += /usr/lib/${ARCH}-linux-musl/libc.a
musl: apply-patches lua53 embed-lua milagro
	CC=${gcc} AR="${ar}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src musl
		@cp -v src/zenroom build/zenroom

musl-local: ldadd += /usr/local/musl/lib/libc.a
musl-local: apply-patches lua53 embed-lua milagro
	CC=${gcc} AR="${ar}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src musl

musl-system: gcc := gcc
musl-system: ldadd += -lm
musl-system: apply-patches lua53 embed-lua milagro
	CC=${gcc} AR="${ar}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src musl

bsd: cflags := -O3 ${cflags_protection} -fPIE -fPIC -DARCH_BSD
bsd: ldadd += -lm
bsd: apply-patches lua53 milagro embed-lua
	CC=${gcc} AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src linux
		@cp -v src/zenroom build/zenroom


linux: cflags := -O3 ${cflags_protection} -fPIE -fPIC
linux: apply-patches lua53 milagro embed-lua
	CC=${gcc} AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src linux
		@cp -v src/zenroom build/zenroom

android-arm android-x86: apply-patches lua53 milagro embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	LD="${ld}" RANLIB="${ranlib}" AR="${ar}" \
		make -C src $@

cortex-arm: ldflags += -Wl,-Map=./zenroom.map
cortex-arm:	apply-patches cortex-lua53 milagro embed-lua
	CC=${gcc} AR="${ar}" OBJCOPY="${objcopy}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src arm

aarch64: ldflags += -Wl,-Map=./zenroom.map
aarch64: apply-patches cortex-lua53 milagro embed-lua
	CC=${gcc} AR="${ar}" OBJCOPY="${objcopy}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src arm


linux-debug: apply-patches lua53 milagro embed-lua
	CC=${gcc} AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src linux
	@cp -v src/zenroom build/zenroom

linux-profile: linux-debug

linux-c++: linux

linux-jemalloc: linux

linux-debug-jemalloc: cflags += -O1 -ggdb ${cflags_protection} -DDEBUG=1 -Wstack-usage=4096
linux-debug-jemalloc: linux

linux-clang: gcc := clang
linux-clang: linux

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
linux-lib: apply-patches lua53 milagro embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src linux-lib

linux-lib-debug: cflags += -shared -DLIBRARY
linux-lib-debug: apply-patches lua53 milagro embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src linux-lib

PYV := $(shell python3 -c "import platform;print(platform.python_version().replace('.', '_'))");
UNAME := $(shell uname)

linux-python3: apply-patches lua53 milagro embed-lua
	swig -python -py3 ${pwd}/build/swig.i
	${gcc} ${cflags} -c ${pwd}/build/swig_wrap.c \
		-o src/zen_python.o
	CC=${gcc} LD=${ld} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src python
	@mv -v ${pwd}/build/zenroom.py ${pwd}/bindings/python3/zenroom/zenroom_swig.py
	@mkdir -p ${pwd}/bindings/python3/zenroom/libs/${UNAME}/${PYV}
	@mv -v ${pwd}/src/_zenroom.so ${pwd}/bindings/python3/zenroom/libs/${UNAME}/${PYV}

linux-go: apply-patches lua53 milagro embed-lua
	swig -go -cgo -intgosize 32 ${pwd}/build/swig.i
	${gcc} ${cflags} -c ${pwd}/build/swig_wrap.c -o src/zen_go.o
	CC=${gcc} LD=${ld} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src go
	cp -v ${pwd}/src/libzenroomgo.so ${pwd}/bindings/golang/zenroom/lib/
