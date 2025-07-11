## Initialize build defaults
include build/init.mk

COMPILER ?= /opt/musl-dyne/bin/x86_64-linux-musl-gcc
COMPILER_CXX ?= /opt/musl-dyne/bin/x86_64-linux-musl-g++

cflags += -static -std=gnu99 -fPIC -D'ARCH="MUSL"' -D__MUSL__ -DARCH_MUSL
ldflags += -static
system := Linux

# activate CCACHE etc.
include build/plugins.mk

all: deps zenroom zencode-exec

deps: ${BUILD_DEPS}

cli_sources := src/cli-zenroom.o src/repl.o
zenroom: ${ZEN_SOURCES} ${cli_sources}
	$(info === Building the zenroom CLI)
	${cxx} ${cflags} ${ZEN_SOURCES} ${cli_sources} \
		-o $@ ${ldflags} ${ldadd}

zencode-exec: ${ZEN_SOURCES} src/zencode-exec.o
	$(info === Building the zencode-exec utility)
	${cxx} ${cflags} ${ZEN_SOURCES} src/zencode-exec.o \
		-o $@ ${ldflags} ${ldadd}

include build/deps.mk
