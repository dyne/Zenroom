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
	[ "$1" == "armv7a" ] && andro=androideabi21
	make clean
	mkdir -p zenroom-android/$1
	make posix-lib COMPILER=${1}-linux-$andro-clang RELEASE=1 CCACHE=1
	cp -v libzenroom.so zenroom-android/$1/
}

#build x86_64
build aarch64
#build i686
#build armv7a

>&3 echo "Build done!"
>&3 tree zenroom-android
