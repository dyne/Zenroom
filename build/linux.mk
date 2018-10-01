musl: ldadd += /usr/lib/${ARCH}-linux-musl/libc.a
musl: apply-patches lua53 milagro lpeglabel
	CC=${gcc} AR="${ar}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src musl
		@cp -v src/zenroom-static build/zenroom.x86

musl-local: ldadd += /usr/local/musl/lib/libc.a
musl-local: apply-patches lua53 milagro lpeglabel
	CC=${gcc} AR="${ar}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src musl

musl-system: gcc := gcc
musl-system: ldadd += -lm
musl-system: apply-patches lua53 milagro lpeglabel
	CC=${gcc} AR="${ar}" CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src musl

linux: apply-patches lua53 milagro lpeglabel
	CC=${gcc} AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src linux

linux-debug:
linux-debug: cflags := -O1 -ggdb -D'ARCH=\"LINUX\"' ${cflags_protection} -DARCH_LINUX -DDEBUG=1
linux-debug: apply-patches lua53 milagro lpeglabel linux

linux-clang: gcc := clang
linux-clang: apply-patches lua53 milagro lpeglabel linux

linux-sanitizer: gcc := clang
linux-sanitizer: cflags := -O1 -ggdb -D'ARCH=\"LINUX\"' ${cflags_protection} -DARCH_LINUX -DDEBUG=1 -fsanitize=address -fno-omit-frame-pointer
linux-sanitizer: apply-patches lua53 milagro lpeglabel linux
	ASAN_OPTIONS=verbosity=1:log_threads=1 \
	ASAN_SYMBOLIZER_PATH=/usr/bin/asan_symbolizer \
	ASAN_OPTIONS=abort_on_error=1 \
		./src/zenroom-shared -i -d

linux-lib: cflags += -shared -DLIBRARY
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src linux-lib

linux-python3: apply-patches lua53 milagro lpeglabel
	swig -python -py3 ${pwd}/build/swig.i
	${gcc} ${cflags} -c ${pwd}/build/swig_wrap.c \
		-o src/zen_python.o
	CC=${gcc} LD=${ld} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src python
	@mkdir -p ${pwd}/build/python3 && cp -v ${pwd}/src/_zenroom.so ${pwd}/build/python3

linux-python2: apply-patches lua53 milagro lpeglabel
	swig -python ${pwd}/build/swig.i
	${gcc} ${cflags} -c ${pwd}/build/swig_wrap.c \
		-o src/zen_python.o
	CC=${gcc} LD=${ld} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src python
	@mkdir -p ${pwd}/build/python2 && cp -v ${pwd}/src/_zenroom.so ${pwd}/build/python2

linux-go: apply-patches lua53 milagro lpeglabel
	swig -go -cgo -intgosize 32 ${pwd}/build/swig.i
	${gcc} ${cflags} -c ${pwd}/build/swig_wrap.c -o src/zen_go.o
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	make -C src go
	@mkdir -p ${pwd}/build/go && cp -v ${pwd}/src/libzenroomgo.so ${pwd}/build/go

linux-java: cflags += -I /opt/jdk/include -I /opt/jdk/include/linux
linux-java: apply-patches lua53 milagro lpeglabel
	swig -java ${pwd}/build/swig.i
	${gcc} ${cflags} -c ${pwd}/build/swig_wrap.c -o src/zen_java.o
	CC=${gcc} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src java

android: gcc := $(CC)
android: ar := $(AR)
android: ranlib := $(RANLIB)
android: ld := $(ld)
android: cflags := ${cflags} -std=c99 -shared -DLUA_USE_DLOPEN
android: apply-patches lua53 milagro lpeglabel
	LDFLAGS="--sysroot=/tmp/ndk-arch-21/sysroot" CC=${gcc} CFLAGS="${cflags}" make -C src android

