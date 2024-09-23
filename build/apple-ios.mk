## Initialize build defaults
include build/init.mk

ifdef CCACHE
	milagro_cmake_flags += -DCMAKE_C_COMPILER_LAUNCHER=ccache
	pfxcc += ccache
endif

OS := iphoneos
cc := $(shell xcrun --sdk iphoneos -f gcc 2>/dev/null)
ar := $(shell xcrun --sdk iphoneos -f ar 2>/dev/null)
ld := $(shell xcrun --sdk iphoneos -f ld 2>/dev/null)
ranlib := $(shell xcrun --sdk iphoneos -f ranlib 2>/dev/null)
cflags += -O2 -fPIC ${cflags_protection}
cflags += -D'ARCH="OSX"' -DNO_SYSTEM -DARCH_OSX
cflags += -DLIBCMALLOC
lua_cflags += -DLUA_USE_IOS
ldflags := -lm
platform := ios
quantum_proof_cc := ${pfxcc} ${cc}
ed25519_cc := ${pfxcc} ${cc}
libcc_cc := ${pfxcc} ${cc}

ios-armv7: cflags += -arch armv7 -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
ios-armv7: ${BUILD_DEPS} ${ZEN_SOURCES}
	TARGET=armv7 libtool -static -o zenroom-ios-armv7.a \
		${ZEN_SOURCES} ${ldadd}

ios-arm64: cflags += -arch arm64 -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
ios-arm64: ${BUILD_DEPS} ${ZEN_SOURCES}
	TARGET=arm64 libtool -static -o zenroom-ios-arm64.a \
		${ZEN_SOURCES} ${ldadd}

ios-sim: cc := ${pfxcc} $(shell xcrun --sdk iphonesimulator -f gcc 2>/dev/null)
ios-sim: ar := $(shell xcrun --sdk iphonesimulator -f ar 2>/dev/null)
ios-sim: ld := $(shell xcrun --sdk iphonesimulator -f ld 2>/dev/null)
ios-sim: ranlib := $(shell xcrun --sdk iphonesimulator -f ranlib 2>/dev/null)
ios-sim: cflags += -arch x86_64 -isysroot $(shell xcrun --sdk iphonesimulator --show-sdk-path 2>/dev/null)
ios-sim: quantum_proof_cc := ${cc}
ios-sim: ed25519_cc := ${cc}
ios-sim: libcc_cc := ${cc}
ios-sim: ${BUILD_DEPS} ${ZEN_SOURCES}
	TARGET=x86_64 libtool -static -o zenroom-ios-x86_64.a \
		${ZEN_SOURCES} ${ldadd}

# ios-fat:
# 	lipo -create \
# 	zenroom-ios-x86_64.a \
# 	zenroom-ios-arm64.a \
# 	-output zenroom-ios.a

include build/deps.mk
