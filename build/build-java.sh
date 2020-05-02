#!/usr/bin/env bash

if [ -z "${JAVA_HOME}" ]; then
  echo "JAVA_HOME environment variable is not set. Setting JAVA_HOME to unlinked path from `which javac`"
  export JAVA_HOME=${JAVA_HOME:=`dirname $(dirname $(readlink -f $(which javac)))`}
fi

echo "JAVA_HOME = ${JAVA_HOME}"

LIB_SRC_PATH=${LIB_SRC_PATH:=${PWD}/src}
LIB_DST_PATH=${LIB_DST_PATH:=${PWD}/build/target/java/jniLibs}
LOCAL_ARCH=$(uname -m)

build () {

	echo "${0}: Building Java ${2} JNI lib ..."
	make clean
	make java-$1
	mkdir -p ${LIB_DST_PATH}/${3}
	cp -v ${LIB_SRC_PATH}/zenroom.so ${LIB_DST_PATH}/${3}/libzenroom.so
}


build "${LOCAL_ARCH}" "${LOCAL_ARCH}-linux-java" "${LOCAL_ARCH}"
# build "arm" "arm-linux-androideabi" "armeabi-v7a"
# build "aarch64" "aarch64-linux-android" "arm64-v8a"

# BEGIN test
ZEN_JAVA_LIB_PATH=${LIB_DST_PATH}/${LOCAL_ARCH}
ZEN_JAVA_CLASSPATH="bindings/java"
ZENCODE_SCRIPT="bindings/java/alice_keygen.zen"
ZENCODE_TEST_CLASS="testZenroom"

echo "${0}: Compiling test ${ZENCODE_TEST_CLASS}.java ..."
# build test java source (hack)
cd bindings/java/decode/zenroom/
    javac Zenroom.java
cd -

cd bindings/java
    javac ${ZENCODE_TEST_CLASS}.java
cd -
# create test data
echo "${0}: Creating test zencode ${ZENCODE_SCRIPT}..."
cat << EOF | tee ${ZENCODE_SCRIPT}
rule check version 1.0.0
Scenario 'simple': Create the keypair
Given that I am known as 'Alice'
When I create the keypair
Then print my data
EOF
# run test
Z="java -classpath ${ZEN_JAVA_CLASSPATH} -Djava.library.path=${ZEN_JAVA_LIB_PATH} ${ZENCODE_TEST_CLASS} ${ZENCODE_SCRIPT}"
echo "${0}: Invoking java ${ZENCODE_TEST_CLASS}: ${Z} "
${Z}
# END test

echo "Java JNI libs built under ${LIB_DST_PATH}"
