## Initialize build defaults
include build/init.mk

COMPILER ?= gcc
COMPILER ?= g++

ifdef LINUX
	system := Linux
	cflags += -fPIC -D'ARCH="LINUX"' -DARCH_LINUX
	ldadd += -lm
endif

ifdef ASAN
	system := Linux
	cflags := -fPIC -D'ARCH="LINUX"' -DARCH_LINUX
	cflags += -g -DDEBUG=1 -Wall -fno-omit-frame-pointer
#	cflags += -Wno-error=shift-count-overflow
#   big_256_28.c:911:32: runtime error: left shift of 220588237 by 20 places cannot be represented in type 'int'
	cflags += ${cflags_asan} ${ZEN_INCLUDES}
	ldflags := -fsanitize=address -fsanitize=undefined
	ldadd += -lm
else
ifdef RELEASE
	cflags += -O3 ${cflags_protection}
else
# default is DEBUG
	cflags += ${cflags_debug}
endif
endif
ifdef GPROF
	cflags += -pg
endif
ifdef OSX
	COMPILER := clang
	cflags += -fPIC -D'ARCH="OSX"' -DARCH_OSX
endif

ifdef LIBRARY
	cflags += -fPIC -DLIBRARY
endif

# activate CCACHE etc.
include build/plugins.mk

include build/deps.mk

all: deps zenroom zencode-exec

deps: ${BUILD_DEPS}

cli_sources := src/cli-zenroom.o src/repl.o
zenroom: ${ZEN_SOURCES} ${cli_sources}
	$(info === Building the zenroom CLI)
	${zenroom_cc} ${cflags} ${ZEN_SOURCES} ${cli_sources} \
		-o $@ ${ldflags} ${ldadd} -lreadline

zencode-exec: ${ZEN_SOURCES} src/zencode-exec.o
	$(info === Building the zencode-exec utility)
	${zenroom_cc} ${cflags} ${ZEN_SOURCES} src/zencode-exec.o \
		-o $@ ${ldflags} ${ldadd}

libzenroom.so: deps ${ZEN_SOURCES}
	$(info === Building the zenroom shared library)
	${zenroom_cc} ${cflags} -shared ${ZEN_SOURCES} \
		-o $@ ${ldflags} ${ldadd}

# OSX specific target
libzenroom.dylib: deps ${ZEN_SOURCES}
	$(info === Building the zenroom shared dynamic library)
	${zenroom_cc} ${cflags} -shared ${ZEN_SOURCES} -dynamiclib \
		-o $@ ${ldflags} ${ldadd}
