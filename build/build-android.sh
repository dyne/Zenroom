#!/usr/bin/env bash

ANDROID_HOME=${ANDROID_HOME:=~/Android/Sdk}
export NDK_HOME=${NDK_HOME:=${ANDROID_HOME}/ndk-bundle}

LIB_SRC_PATH=${LIB_SRC_PATH:=${PWD}/src}
LIB_DST_PATH=${LIB_DST_PATH:=${PWD}/build/target/android/jniLibs}

build () {

	echo "${0}: Building Android ${2} libs ..."
	make clean
	make android-$1
	mkdir -p ${LIB_DST_PATH}/${3}
	cp ${LIB_SRC_PATH}/zenroom.so ${LIB_DST_PATH}/${3}/libzenroom.so
}

if [ ! -d "$NDK_HOME" ]; then
  echo "ANDROID_HOME environment variable seems to not be set or NDK is not installed"
  exit 1
fi

build "x86" "i686-linux-android" "x86"
build "arm" "arm-linux-androideabi" "armeabi-v7a"
build "aarch64" "aarch64-linux-android" "arm64-v8a"
echo "Built Android libs placed under ${LIB_DST_PATH}"
