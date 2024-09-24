## Initialize build defaults
include build/init.mk

ifdef DEBUG
	cflags += ${cflags_debug}
else
	cflags += ${cflags_protection}
endif

# activate CCACHE etc.
include build/plugins.mk

all: deps zenroom.command zencode-exec.command

deps: ${BUILD_DEPS}

cli_sources := src/cli-zenroom.o src/repl.o
zenroom.command: ${ZEN_SOURCES} ${cli_sources}
	$(info === Building the zenroom CLI)
	${zenroom_cc} ${cflags} ${ZEN_SOURCES} ${cli_sources} -o $@ ${ldflags} ${ldadd}

zencode-exec.command: ${ZEN_SOURCES} src/zencode-exec.o
	$(info === Building the zencode-exec utility)
	${zenroom_cc} ${cflags} ${ZEN_SOURCES} src/zencode-exec.o -o $@ ${ldflags} ${ldadd}

include build/deps.mk
