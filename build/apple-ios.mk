## Initialize build defaults
include build/init.mk

OS := iphoneos
COMPILER := $(shell xcrun --sdk iphoneos -f gcc 2>/dev/null)
COMPILER_CXX := $(shell xcrun --sdk iphoneos -f g++ 2>/dev/null)
ar := $(shell xcrun --sdk iphoneos -f ar 2>/dev/null)
ld := $(shell xcrun --sdk iphoneos -f ld 2>/dev/null)
ranlib := $(shell xcrun --sdk iphoneos -f ranlib 2>/dev/null)
cflags += -O2 -fPIC ${cflags_protection}
cflags += -D'ARCH="OSX"' -DNO_SYSTEM -DARCH_OSX
cflags += -DLIBCMALLOC
lua_cflags += -DLUA_USE_IOS
ldadd := $(filter-out -lstdc++,$(ldadd))
platform := ios

# activate CCACHE etc.
include build/plugins.mk

# TODO: from some error output in recent XCode we get a list of archs:
# i386,x86_64,x86_64h,arm64,arm64e
# we haven't met yet the need to activate all, contact us if you do.

ios-armv7: cflags += -arch armv7 -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
ios-armv7: ${BUILD_DEPS} ${ZEN_SOURCES}
	TARGET=armv7 libtool -static -o zenroom-ios-armv7.a \
		${ZEN_SOURCES} ${ldadd}

ios-arm64: cflags += -arch arm64 -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
ios-arm64: ${BUILD_DEPS} ${ZEN_SOURCES}
	TARGET=arm64 libtool -static -o zenroom-ios-arm64.a \
		${ZEN_SOURCES} ${ldadd}

ios-sim: cc := $(shell xcrun --sdk iphonesimulator -f gcc 2>/dev/null)
ios-sim: cxx := $(shell xcrun --sdk iphonesimulator -f g++ 2>/dev/null)
ios-sim: ar := $(shell xcrun --sdk iphonesimulator -f ar 2>/dev/null)
ios-sim: ld := $(shell xcrun --sdk iphonesimulator -f ld 2>/dev/null)
ios-sim: ranlib := $(shell xcrun --sdk iphonesimulator -f ranlib 2>/dev/null)
ios-sim: cflags += -arch x86_64 -arch arm64 -isysroot $(shell xcrun --sdk iphonesimulator --show-sdk-path 2>/dev/null)
ios-sim: quantum_proof_cc := ${cc}
ios-sim: zenroom_cc := ${cc}
ios-sim: ed25519_cc := ${cc}
ios-sim: lua_cc := ${cc}
ios-sim: longfellow_cxx := ${cxx}
ios-sim: zstd_cc := ${cc}
ios-sim: ${BUILD_DEPS} ${ZEN_SOURCES}
	TARGET=sim libtool -static -o zenroom-ios-sim.a \
		${ZEN_SOURCES} ${ldadd}

include build/deps.mk
