## Initialize build defaults
include build/init.mk

## Specific compiler settings for all built dependencies
defines := -DLIBCMALLOC
gcc := musl-gcc
cflags :=  ${ZEN_INCLUDES} ${cflags_protection} ${defines}
cflags += -Os -static -std=gnu99 -fPIC
cflags += -DARCH=\"MUSL\" -D__MUSL__ -DARCH_MUSL
ldflags := -static
system := Linux

## Additional dependencies
BUILD_DEPS += tinycc
# all: ${BUILD_DEPS} zencc
all: zencc
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
