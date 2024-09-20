## Initialize build defaults
include build/init.mk

## Specific compiler settings for all built dependencies
gcc := musl-gcc
cflags +=  ${cflags_protection}
cflags += -Os -static -std=gnu99 -fPIC -DLIBCMALLOC
cflags += -DARCH=\"MUSL\" -D__MUSL__ -DARCH_MUSL
ldflags := -static
system := Linux

## Additional dependencies
BUILD_DEPS += tinycc
all: ${BUILD_DEPS} zencc

## Additional dependency libraries
# ldadd += /usr/lib/x86_64-linux-gnu/libtcc.a -lm
ldadd += ${pwd}/lib/tinycc/libtcc.a

## Additional source code
ZEN_SOURCES += src/zencc.o src/cflag.o

## Final linking target
zencc: ${ZEN_SOURCES}
	$(info === Linking the zencc embedded C compiler)
	${gcc} ${cflags} ${ZEN_SOURCES} -o $@ ${ldflags} ${ldadd}

## Genereal dependency configs at bottom
include build/deps.mk
