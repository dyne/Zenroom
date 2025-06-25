## Initialize build defaults
include build/init.mk

COMPILER := ${ANDROID_TARGET}-linux-${ANDROID_PLATFORM}-clang
COMPILER_CXX := ${ANDROID_TARGET}-linux-${ANDROID_PLATFORM}-clang++

system := Linux
cflags += -fPIC -DLIBRARY -O3 ${cflags_protection} -DWITHOUT_OPENSSL

include build/plugins.mk
include build/deps.mk

all: deps libzenroom.so

deps: ${BUILD_DEPS}

libzenroom.so: deps ${ZEN_SOURCES} bindings/java/zenroom_jni.o
	$(info === Building the zenroom shared lib for Android)
	APP_STL="c++_shared" ANDROID_ABI=${ANDROID_ABI} \
	${COMPILER} ${cflags} -shared ${ZEN_SOURCES} \
		bindings/java/zenroom_jni.o \
		-o $@ ${ldflags} ${ldadd} \
		-llog -lm -frtti -fexceptions -lc++_shared -latomic
