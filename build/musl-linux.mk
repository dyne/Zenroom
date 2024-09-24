## Initialize build defaults
include build/init.mk

cc := musl-gcc
quantum_proof_cc := ${cc}
ed25519_cc := ${cc}
libcc_cc := ${cc}
lua_cc := ${cc}
zenroom_cc := ${cc}

## Additional dependencies
BUILD_DEPS += tinycc

cflags += -DLIBCMALLOC
cflags += -static -std=gnu99 -fPIC -D'ARCH="MUSL"' -D__MUSL__ -DARCH_MUSL
ldflags += -static
system := Linux

ifdef CCACHE
	milagro_cmake_flags += -DCMAKE_C_COMPILER_LAUNCHER=ccache
	quantum_proof_cc := ccache ${cc}
	ed25519_cc := ccache ${cc}
	libcc_cc := ccache ${cc}
	lua_cc := ccache ${cc}
	zenroom_cc := ccache ${cc}
endif
ifdef DEBUG
	cflags += ${cflags_debug}
else
	cflags += -O3 ${cflags_protection}
endif

all: ${BUILD_DEPS} zenroom zencode-exec zencc

cli_sources := src/cli-zenroom.o src/repl.o
zenroom: ${ZEN_SOURCES} ${cli_sources}
	$(info === Building the zenroom CLI)
	${zenroom_cc} ${cflags} ${ZEN_SOURCES} ${cli_sources} \
		-o $@ ${ldflags} ${ldadd}

zencode-exec: ${ZEN_SOURCES} src/zencode-exec.o
	$(info === Building the zencode-exec utility)
	${zenroom_cc} ${cflags} ${ZEN_SOURCES} src/zencode-exec.o \
		-o $@ ${ldflags} ${ldadd}

zencc: ldadd += ${pwd}/lib/tinycc/libtcc.a
zencc: ${ZEN_SOURCES} src/zencc.o src/cflag.o
	$(info === Building the zencode-exec utility)
	${zenroom_cc} ${cflags} ${ZEN_SOURCES} src/zencc.o src/cflag.o \
		-o $@ ${ldflags} ${ldadd}

include build/deps.mk
