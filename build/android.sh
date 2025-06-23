#!/usr/bin/env bash

[ -r ${ANDROID_NDK_HOME}/README.md ] || {
	>&2 echo "ANDROID_NDK_HOME environment not set"
	exit 1
}

command -v x86_64-linux-android21-clang > /dev/null || {
	>&2 echo "ANDROID_NDK binaries not found in path: x86_64-linux-android21-clang"
	exit 1
}

build() {
	local target="$1"
	local platform="android21"
	local cflags="-I ${pwd}/src -I. -I../zstd -DWITHOUT_OPENSSL -DJNI=1"
	local abi=""
	[ "$1" == "armv7a" ] && {
		platform="androideabi21"
		abi="armeabi-v7a"
	}
	[ "$1" == "aarch64" ] && {
		cflags="$cflags -march=armv8-a+crypto"
		abi="arm64-v8a"
	}
	[ "$1" == "i686" ] && {
		cflags="$cflags -mpclmul"
		abi="x86"
	}
	[ "$1" == "x86_64" ] && {
		cflags="$cflags -mpclmul"
		abi="x86_64"
	}
	make clean
	rm -f bindings/java/zenroom_jni.o
	mkdir -p zenroom-android/jni/${abi}
	make -f build/android.mk all \
		 COMPILER=${target}-linux-${platform}-clang \
		 COMPILER_CXX=${target}-linux-${platform}-clang++ \
		 longfellow_cflags="${cflags}" \
		 ANDROID_ABI="${abi}" ANDROID_TARGET="${target}" \
		 ANDROID_PLATFORM="${platform}" \
		 RELEASE=1
	cp -v libzenroom.so zenroom-android/jni/${abi}/
}

build x86_64
build aarch64
build i686
build armv7a

cp -v bindings/java/classes.jar zenroom-android/
cd zenroom-android && zip -r -9 ../zenroom-android.aar .; cd -
>&2 echo "=== Android build done:"
>&2 ls -l zenroom-android.aar
>&2 tree zenroom-android
