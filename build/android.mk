## Initialize build defaults
include build/init.mk

# # COMPILER := ${ANDROID_TARGET}-linux-${ANDROID_PLATFORM}-clang
# # COMPILER_CXX := ${ANDROID_TARGET}-linux-${ANDROID_PLATFORM}-clang++
# cc := ${COMPILER}
# cxx := ${COMPILER_CXX}

# milagro_cmake_flags += -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake -DCMAKE_ANDROID_NDK=${ANDROID_NDK_HOME} -DANDROID_ABI=${ANDROID_ABI} -DANDROID_PLATFORM=${ANDROID_PLATFORM}

system := Linux
cflags += -fPIC -DLIBRARY -O3 ${cflags_protection} -DWITHOUT_OPENSSL

include build/plugins.mk
include build/deps.mk

all: deps libzenroom.so

deps: ${BUILD_DEPS}

libzenroom.so: deps ${ZEN_SOURCES} bindings/java/zenroom_jni.o
	$(info === Building the zenroom shared lib for Android)
	APP_STL=c++_static ANDROID_ABI=${ANDROID_ABI} \
	${COMPILER} ${cflags} -shared ${ZEN_SOURCES} \
		bindings/java/zenroom_jni.o \
		-o $@ ${ldflags} ${ldadd}
