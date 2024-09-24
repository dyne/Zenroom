## Initialize build defaults
include build/init.mk

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
	cflags += ${cflags_protection}
endif

all: ${BUILD_DEPS} zenroom.command zencode-exec.command

cli_sources := src/cli-zenroom.o src/repl.o
zenroom.command: ${ZEN_SOURCES} ${cli_sources}
	$(info === Building the zenroom CLI)
	${zenroom_cc} ${cflags} ${ZEN_SOURCES} ${cli_sources} -o $@ ${ldflags} ${ldadd}

zencode-exec.command: ${ZEN_SOURCES} src/zencode-exec.o
	$(info === Building the zencode-exec utility)
	${zenroom_cc} ${cflags} ${ZEN_SOURCES} src/zencode-exec.o -o $@ ${ldflags} ${ldadd}

include build/deps.mk
