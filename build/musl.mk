## Initialize build defaults
include build/init.mk

COMPILER ?= musl-gcc

cflags += -static -std=gnu99 -fPIC -D'ARCH="MUSL"' -D__MUSL__ -DARCH_MUSL
ldflags += -static
system := Linux

ifdef DEBUG
	cflags += ${cflags_debug}
else
	cflags += -O3 ${cflags_protection}
endif

# activate CCACHE etc.
include build/plugins.mk

all: deps zenroom zencode-exec

deps: ${BUILD_DEPS}

cli_sources := src/cli-zenroom.o src/repl.o
zenroom: ${ZEN_SOURCES} ${cli_sources}
	$(info === Building the zenroom CLI)
	${zenroom_cc} ${cflags} ${ZEN_SOURCES} ${cli_sources} \
		-o $@ ${ldflags} ${ldadd}

zencode-exec: ${ZEN_SOURCES} src/zencode-exec.o
	$(info === Building the zencode-exec utility)
	${zenroom_cc} ${cflags} ${ZEN_SOURCES} src/zencode-exec.o \
		-o $@ ${ldflags} ${ldadd}

include build/deps.mk
