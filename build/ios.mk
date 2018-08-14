
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
ios-armv7: apply-patches lua53 milagro lpeglabel ios-lib

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
ios-arm64: apply-patches lua53 milagro lpeglabel ios-lib

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
ios-sim: apply-patches lua53 milagro lpeglabel ios-lib

ios-fat:
	lipo -create build/zenroom-ios-x86_64.a build/zenroom-ios-arm64.a build/zenroom-ios-armv7.a -output build/zenroom-ios.a
