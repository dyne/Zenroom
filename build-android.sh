#!/usr/bin/env bash
export NDK_HOME=$ANDROID_HOME/ndk-bundle/
export ANDROID_API=21


build () {
	export NDK_TOOLCHAIN=/tmp/ndk-arch-$ANDROID_API
	echo "Creating a toolchain for $2 in $NDK_TOOLCHAIN"
	rm -fr $NDK_TOOLCHAIN;
	$NDK_HOME/build/tools/make_standalone_toolchain.py --arch $1 --api $ANDROID_API --install-dir $NDK_TOOLCHAIN --stl gnustl
	export PATH=${NDK_TOOLCHAIN}/${2}/bin:${PATH}:${NDK_TOOLCHAIN}/bin
	
	export CC="$2-gcc"
	export CXX="$2-g++"
	export RANLIB="$2-ranlib"
	export LD="$2-ld"
	export AR="$2-ar"

	#Define the Android API level

	export CFLAGS="-D__ANDROID_API__=$ANDROID_API"

	make clean
	make android

	cp src/zenroom.so libzenroom-$1.so
}

if [ ! -d "$NDK_HOME" ]; then
  echo "ANDROID_HOME environment variable seems to not be setted or NDK is not installed"
  exit 1
fi

build "arm" "arm-linux-androideabi"
build "x86" "i686-linux-android" 
