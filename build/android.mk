## Initialize build defaults
include build/init.mk

COMPILER := ${ANDROID_TARGET}-linux-${ANDROID_PLATFORM}-clang
COMPILER_CXX := ${ANDROID_TARGET}-linux-${ANDROID_PLATFORM}-clang++

system := Linux
cflags := -I ${pwd}/src -I. -I../zstd -fPIC -DLIBRARY -I${ANDROID_NDK_HOME}/openssl/${ANDROID_TARGET}/include

ifdef DEBUG
	cflags += -ggdb -DDEBUG=1 ${ZEN_INCLUDES}
endif
ifdef RELEASE
	cflags += -O3 ${ZEN_INCLUDES}
endif
include build/plugins.mk
include build/deps.mk

all: deps libzenroom.so

deps: ${BUILD_DEPS}

libzenroom.so: deps ${ZEN_SOURCES} bindings/java/zenroom_jni.o
	$(info === Building the zenroom shared lib for Android)
	APP_STL="c++_shared" ANDROID_ABI=${ANDROID_ABI} \
	${COMPILER} ${cflags} -shared ${ZEN_SOURCES} \
		bindings/java/zenroom_jni.o \
		-o $@ ${ldflags} ${ldadd} ${ANDROID_NDK_HOME}/openssl/${ANDROID_TARGET}/lib/libcrypto.a \
		-llog -lm -frtti -fexceptions -lc++_shared -latomic
