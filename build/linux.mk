## Initialize build defaults
include build/init.mk

COMPILER ?= gcc

cc := ${COMPILER}
quantum_proof_cc := ${cc}
ed25519_cc := ${cc}
libcc_cc := ${cc}
lua_cc := ${cc}
zenroom_cc := ${cc}

## Additional dependencies
BUILD_DEPS += tinycc mimalloc
ldadd += -lm
ldadd += ${pwd}/lib/tinycc/libtcc.a
ldadd += ${pwd}/lib/mimalloc/build/libmimalloc-static.a

cflags += -fPIC -D'ARCH="LINUX"' -DARCH_LINUX
system := Linux

ifdef CCACHE
	milagro_cmake_flags += -DCMAKE_C_COMPILER_LAUNCHER=ccache
	quantum_proof_cc := ccache ${cc}
	ed25519_cc := ccache ${cc}
	libcc_cc := ccache ${cc}
	lua_cc := ccache ${cc}
	zenroom_cc := ccache ${cc}
endif
# default is DEBUG
ifdef RELEASE
	cflags += -O3 ${cflags_protection}
else
	cflags += ${cflags_debug}
endif

all: ${BUILD_DEPS} zenroom zencode-exec zencc

cli_sources := src/cli-zenroom.o src/repl.o
zenroom: ${ZEN_SOURCES} ${cli_sources}
	$(info === Building the zenroom CLI)
	${zenroom_cc} ${cflags} ${ZEN_SOURCES} ${cli_sources} \
		-o $@ ${ldflags} ${ldadd} -lreadline

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
