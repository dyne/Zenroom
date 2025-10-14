## Initialize build defaults
include build/init.mk

COMPILER ?= /opt/musl-dyne/gcc-musl/bin/x86_64-linux-musl-gcc
COMPILER_CXX ?= /opt/musl-dyne/gcc-musl/bin/x86_64-linux-musl-g++

cflags += -Os -g0 -static -std=gnu99 -fPIC -D'ARCH="MUSL"' -D__MUSL__ -DARCH_MUSL
ldflags += -static -s
system := Linux

# activate CCACHE etc.
include build/plugins.mk

all: deps zenroom lua-exec zencode-exec

deps: ${BUILD_DEPS}

aux_source  := src/zencode-exec
cli_sources := src/cli-zenroom.o src/repl.o
zenroom: ${ZEN_SOURCES} ${cli_sources}
	$(info === Building the zenroom CLI)
	${cxx} ${cflags} ${ZEN_SOURCES} ${cli_sources} \
		-o $@ ${ldflags} ${ldadd}

lua-exec: ${ZEN_SOURCES}
	$(info === Building the lua-exec utility)
	${zenroom_cc} ${cflags} -DLUA_EXEC \
		-c ${aux_source}.c -o ${aux_source}.o
	${cxx} ${cflags} ${ZEN_SOURCES} ${aux_source}.o \
		-o $@ ${ldflags} ${ldadd}

zencode-exec: ${ZEN_SOURCES}
	$(info === Building the zencode-exec utility)
	${zenroom_cc} ${cflags} -c ${aux_source}.c -o ${aux_source}.o
	${cxx} ${cflags} ${ZEN_SOURCES} ${aux_source}.o \
		-o $@ ${ldflags} ${ldadd}

include build/deps.mk
