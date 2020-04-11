osx: apply-patches milagro lua53 embed-lua
	CC=${gcc} LD=${ld} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src osx
	@cp -v ${pwd}/src/zenroom.command ${pwd}/build

osx-debug: cflags := -O1 -ggdb ${cflags_protection} -DDEBUG=1
osx-debug: osx

osx-python3: apply-patches milagro lua53 embed-lua
	swig -python -py3 ${pwd}/build/swig.i
	${gcc} ${cflags} -c ${pwd}/build/swig_wrap.c \
		-o src/zen_python.o
	CC=${gcc} LD=${ld} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src python
	@mkdir -p ${pwd}/build/python3 && cp -v ${pwd}/src/_zenroom.so ${pwd}/build/python3

osx-go: apply-patches milagro lua53 embed-lua
	swig -go -cgo -intgosize 32 ${pwd}/build/swig.i
	${gcc} ${cflags} -c ${pwd}/build/swig_wrap.c -o src/zen_go.o
	CC=${gcc} LD=${ld} CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
		make -C src go
	cp -v ${pwd}/src/libzenroomgo.so ${pwd}/bindings/golang/zenroom/lib/

ios-lib:
	TARGET=${ARCH} AR=${ar} CC=${gcc} CFLAGS="${cflags}" make -C src ios-lib
	cp -v src/zenroom-ios-${ARCH}.a build/

ios-armv7: ARCH := armv7
ios-armv7: OS := iphoneos
ios-armv7: gcc := $(shell xcrun --sdk iphoneos -f gcc 2>/dev/null)
ios-armv7: ar := $(shell xcrun --sdk iphoneos -f ar 2>/dev/null)
ios-armv7: ld := $(shell xcrun --sdk iphoneos -f ld 2>/dev/null)
ios-armv7: ranlib := $(shell xcrun --sdk iphoneos -f ranlib 2>/dev/null)
ios-armv7: SDK := $(shell xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
ios-armv7: cflags := -O2 -fPIC ${cflags_protection} -D'ARCH=\"OSX\"' -isysroot ${SDK} -arch ${ARCH} -D NO_SYSTEM -DARCH_OSX
ios-armv7: ldflags := -lm
ios-armv7: platform := ios
ios-armv7: apply-patches milagro lua53 embed-lua ios-lib

ios-arm64: ARCH := arm64
ios-arm64: OS := iphoneos
ios-arm64: gcc := $(shell xcrun --sdk iphoneos -f gcc 2>/dev/null)
ios-arm64: ar := $(shell xcrun --sdk iphoneos -f ar 2>/dev/null)
ios-arm64: ld := $(shell xcrun --sdk iphoneos -f ld 2>/dev/null)
ios-arm64: ranlib := $(shell xcrun --sdk iphoneos -f ranlib 2>/dev/null)
ios-arm64: SDK := $(shell xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
ios-arm64: cflags := -O2 -fPIC ${cflags_protection} -D'ARCH=\"OSX\"' -isysroot ${SDK} -arch ${ARCH} -D NO_SYSTEM -DARCH_OSX
ios-arm64: ldflags := -lm
ios-arm64: platform := ios
ios-arm64: apply-patches milagro lua53 embed-lua ios-lib

ios-sim: ARCH := x86_64
ios-sim: OS := iphonesimulator
ios-sim: gcc := $(shell xcrun --sdk iphonesimulator -f gcc 2>/dev/null)
ios-sim: ar := $(shell xcrun --sdk iphonesimulator -f ar 2>/dev/null)
ios-sim: ld := $(shell xcrun --sdk iphonesimulator -f ld 2>/dev/null)
ios-sim: ranlib := $(shell xcrun --sdk iphonesimulator -f ranlib 2>/dev/null)
ios-sim: SDK := $(shell xcrun --sdk iphonesimulator --show-sdk-path 2>/dev/null)
ios-sim: cflags := -O2 -fPIC ${cflags_protection} -D'ARCH=\"OSX\"' -isysroot ${SDK} -arch ${ARCH} -D NO_SYSTEM -DARCH_OSX
ios-sim: ldflags := -lm
ios-sim: platform := ios
ios-sim: apply-patches milagro lua53 embed-lua ios-lib

osx-lib: ARCH := x86_64
osx-lib: cflags := -O2 -fPIC ${cflags_protection} -D'ARCH=\"OSX\"' -DARCH_OSX
osx-lib: ldflags := -lm
osx-lib: apply-patches milagro lua53 embed-lua ios-lib
osx-lib:
	TARGET=${ARCH} AR=${ar} CC=${gcc} CFLAGS="${cflags}" make -C src ios-lib
	cp -v src/zenroom-ios-${ARCH}.a build/libzenroom.a

ios-fat:
	lipo -create build/zenroom-ios-x86_64.a build/zenroom-ios-arm64.a build/zenroom-ios-armv7.a -output build/zenroom-ios.a
