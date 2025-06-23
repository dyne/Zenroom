#!/usr/bin/env bash

[ -r ${ANDROID_NDK_HOME}/README.md ] || {
	>&3 echo "ANDROID_NDK_HOME environment not set"
	exit 1
}

command -v x86_64-linux-android21-clang > /dev/null || {
	>&3 echo "ANDROID_NDK binaries not found in path: x86_64-linux-android21-clang"
	exit 1
}

build() {
	local andro=android21
	cflags="-I ${pwd}/src -I. -I../zstd -DWITHOUT_OPENSSL"
	[ "$1" == "armv7a" ] && {
		andro=androideabi21
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
	mkdir -p zenroom-android/${1}
	make -f build/posix.mk libzenroom.so LIBRARY=1 \
		 longfellow_cflags="${cflags}" \
		 COMPILER=${1}-linux-${andro}-clang \
		 COMPILER_CXX=${1}-linux-${andro}-clang++ \
		 ANDROID_ABI=${abi} APP_STL=c++_static \
		 RELEASE=1
	cp -v libzenroom.so zenroom-android/${1}/
}

#build x86_64
#build aarch64
build i686
#build armv7a

>&3 echo "Build done!"
>&3 tree zenroom-android
