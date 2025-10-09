## Initialize build defaults
include build/init.mk

COMPILER ?= /opt/musl-dyne/gcc-musl/bin/x86_64-linux-musl-gcc
COMPILER_CXX ?= /opt/musl-dyne/gcc-musl/bin/x86_64-linux-musl-g++

cflags += -Os -g0 -static -std=gnu99 -fPIC -D'ARCH="MUSL"' -D__MUSL__ -DARCH_MUSL
ldflags += -static -s
system := Linux

# activate CCACHE etc.
include build/plugins.mk

all: deps zenroom zencode-exec

deps: ${BUILD_DEPS}

ZEXE := src/zencode-exec
cli_sources := src/cli-zenroom.o src/repl.o
zenroom: ${ZEN_SOURCES} ${cli_sources}
	$(info === Building the zenroom CLI)
	${cxx} ${cflags} ${ZEN_SOURCES} ${cli_sources} \
		-o $@ ${ldflags} ${ldadd}

lua-exec: ${ZEN_SOURCES}
	$(info === Building the lua-exec utility)
	${cxx} ${cflags} ${ZEN_SOURCES} src/zencode-exec.c \
		-o $@ ${ldflags} ${ldadd} -DLUA_EXEC

zencode-exec: ${ZEN_SOURCES}
	$(info === Building the zencode-exec utility)
	${cxx} ${cflags} ${ZEN_SOURCES} src/zencode-exec.c \
		-o $@ ${ldflags} ${ldadd} -DZEN_EXEC

include build/deps.mk
