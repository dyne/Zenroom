#!/usr/bin/env bash

set -e

[ -r ${ANDROID_NDK_HOME}/README.md ] || {
	>&2 echo "ANDROID_NDK_HOME environment not set"
	exit 1
}

command -v x86_64-linux-android21-clang > /dev/null || {
	>&2 echo "ANDROID_NDK binaries not found in path: x86_64-linux-android21-clang"
	exit 1
}

rm -rf zenroom-android zenroom-android.aar


build() {
	local target="$1"
	local platform="android21"
	local cflags=""
	local abi=""
	local ndk_libs_path="toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/"
	ndk_libs="$1-linux-android"
	[ "$1" == "armv7a" ] && {
		platform="androideabi21"
		abi="armeabi-v7a"
		ndk_libs="arm-linux-androideabi"
	}
	[ "$1" == "aarch64" ] && {
		cflags="-march=armv8-a+crypto"
		abi="arm64-v8a"
	}
	[ "$1" == "i686" ] && {
		cflags="-mpclmul"
		abi="x86"
	}
	[ "$1" == "x86_64" ] && {
		cflags="-mpclmul"
		abi="x86_64"
	}
	make clean
	rm -f bindings/java/zenroom_jni.o
	mkdir -p zenroom-android/jni/${abi}
	make -f build/android.mk all DEBUG=1 \
		 longfellow_cflags="${cflags}" \
		 ANDROID_ABI="${abi}" ANDROID_TARGET="${target}" \
		 ANDROID_PLATFORM="${platform}" \
		 RELEASE=1
	cp -v libzenroom.so zenroom-android/jni/${abi}/
	cp -v ${ANDROID_NDK_HOME}/${ndk_libs_path}/${ndk_libs}/libc++_shared.so zenroom-android/jni/${abi}/
}

build x86_64
build aarch64
build i686
build armv7a

#VERSION=`git describe --tags | cut -d- -f1`
cp -v bindings/java/classes.jar zenroom-android/
cat << EOF > zenroom-android/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="dyne.zenroom">
    <application />
</manifest>
EOF
cd zenroom-android && zip -r -9 ../zenroom-android.aar .; cd -
>&2 echo "=== Android build done:"
>&2 ls -l zenroom-android.aar
>&2 tree zenroom-android
>&2 sha256sum zenroom-android.aar
