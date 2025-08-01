## Initialize build defaults
include build/init.mk

COMPILER ?= gcc
COMPILER_CXX ?= g++

ldadd += -lm -lstdc++

ifdef LINUX
	system := Linux
	cflags += -fPIC -D'ARCH="LINUX"' -DARCH_LINUX
endif
ifdef OSX
	COMPILER := clang
	cflags += -fPIC -D'ARCH="OSX"' -DARCH_OSX
endif

ifdef ASAN
	system := Linux
	cflags := -fPIC -D'ARCH="LINUX"' -DARCH_LINUX
	cflags += -g -DDEBUG=1 -Wall -fno-omit-frame-pointer
#	cflags += -Wno-error=shift-count-overflow
#   big_256_28.c:911:32: runtime error: left shift of 220588237 by 20 places cannot be represented in type 'int'
	cflags += ${cflags_asan} ${ZEN_INCLUDES}
	ldflags := -fsanitize=address -fsanitize=undefined
endif

# activate CCACHE etc.
include build/plugins.mk

all: deps zenroom zencode-exec

deps: ${BUILD_DEPS}

cli_sources := src/cli-zenroom.o src/repl.o
zenroom: ${ZEN_SOURCES} ${cli_sources}
	$(info === Building the zenroom CLI)
	${cxx} ${cflags} ${ZEN_SOURCES} ${cli_sources} \
		-o $@ ${ldflags} ${ldadd} -lreadline

zencode-exec: ${ZEN_SOURCES} src/zencode-exec.o
	$(info === Building the zencode-exec utility)
	${cxx} ${cflags} ${ZEN_SOURCES} src/zencode-exec.o \
		-o $@ ${ldflags} ${ldadd}

libzenroom.so: deps ${ZEN_SOURCES}
	$(info === Building the zenroom shared library)
	${cxx} ${cflags} -shared ${ZEN_SOURCES} \
		-o $@ ${ldflags} ${ldadd}

# OSX specific target
libzenroom.dylib: deps ${ZEN_SOURCES}
	$(info === Building the zenroom shared dynamic library)
	${cxx} ${cflags} -shared ${ZEN_SOURCES} -dynamiclib \
		-o $@ ${ldflags} ${ldadd}

include build/deps.mk
