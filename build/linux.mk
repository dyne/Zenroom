musl: ldadd += /usr/lib/${ARCH}-linux-musl/libc.a
musl: apply-patches lua53 embed-lua milagro
	CC=${gcc} AR="${ar}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src musl
		@cp -v src/zenroom-static build/zenroom.x86

musl-local: ldadd += /usr/local/musl/lib/libc.a
musl-local: apply-patches lua53 embed-lua milagro
	CC=${gcc} AR="${ar}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src musl

musl-local: apply-patches lua53 embed-lua milagro
CC=${gcc} AR="${ar}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
make -C src musl

musl-system: gcc := gcc
musl-system: ldadd += -lm
musl-system: apply-patches lua53 embed-lua milagro
	CC=${gcc} AR="${ar}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src musl

linux: apply-patches lua53 milagro embed-lua
	CC=${gcc} AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src linux

android-arm android-x86: apply-patches lua53 milagro embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	LD="${ld}" RANLIB="${ranlib}" AR="${ar}" \
		make -C src $@

cortex-arm:	apply-patches cortex-lua53 milagro embed-lua
	CC=${gcc} AR="${ar}" OBJCOPY="${objcopy}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src cortex-arm

linux-debug: cflags += -O1 -ggdb ${cflags_protection} -DDEBUG=1 -Wstack-usage=4096
linux-debug: linux

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
		./src/zenroom-shared -i -d

linux-lib: cflags += -shared -DLIBRARY
linux-lib: apply-patches lua53 milagro embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src linux-lib

linux-redis: cflags += -shared -DLIBRARY
linux-redis: apply-patches lua53 milagro embed-lua
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src redis

linux-python3: apply-patches lua53 milagro embed-lua
	swig -python -py3 ${pwd}/build/swig.i
	${gcc} ${cflags} -c ${pwd}/build/swig_wrap.c \
		-o src/zen_python.o
	CC=${gcc} LD=${ld} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src python
	@mkdir -p ${pwd}/build/python3 && cp -v ${pwd}/src/_zenroom.so ${pwd}/build/python3

linux-python2: apply-patches lua53 milagro embed-lua
	swig -python ${pwd}/build/swig.i
	${gcc} ${cflags} -c ${pwd}/build/swig_wrap.c \
		-o src/zen_python.o
	CC=${gcc} LD=${ld} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src python
	@mkdir -p ${pwd}/build/python2 && cp -v ${pwd}/src/_zenroom.so ${pwd}/build/python2

linux-go: apply-patches lua53 milagro embed-lua
	swig -go -cgo -intgosize 32 ${pwd}/build/swig.i
	${gcc} ${cflags} -c ${pwd}/build/swig_wrap.c -o src/zen_go.o
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src go
	@mkdir -p ${pwd}/build/go && cp -v ${pwd}/src/libzenroomgo.so ${pwd}/build/go

linux-java: cflags += -I /opt/jdk/include -I /opt/jdk/include/linux
linux-java: apply-patches lua53 milagro embed-lua
	swig -java ${pwd}/build/swig.i
	${gcc} ${cflags} -c ${pwd}/build/swig_wrap.c -o src/zen_java.o
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src java

# android: gcc := $(CC)
# android: ar := $(AR)
# android: ranlib := $(RANLIB)

# default android target is 'arm-linux-androideabi-'
# android: ndk = /opt/android-ndk-r18b
# android: target = arm-linux-androideabi
# android: toolchain = ${ndk}/toolchains/${target}-4.9/prebuilt/linux-x86_64
# android: cflags += -DLUA_USE_DLOPEN -I${ndk}/sysroot/usr/include -I${ndk}/sysroot/usr/include/arm-linux-androideabi
# android: gcc = ${toolchain}/bin/${target}-gcc
# android: ar = ${toolchain}/bin/${target}-ar
# android: ranlib = ${toolchain}/bin/${target}-ranlib
# android: ld = ${toolchain}/bin/${target}-ld
# android: ldflags += --sysroot=${ndk}/sysroot
