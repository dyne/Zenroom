## Initialize build defaults
include build/init.mk

COMPILER ?= gcc
COMPILER_CXX ?= g++

ldadd += -lm

ifdef LINUX
	system := Linux
	cflags += -fPIC -D'ARCH="LINUX"' -DARCH_LINUX
endif
ifdef OSX
	COMPILER := clang
	COMPILER_CXX := clang++
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

all: deps zenroom lua-exec zencode-exec

deps: ${BUILD_DEPS}

# main() for zencode-exec and lua-exec
aux_source  := src/zencode-exec
cli_sources := src/cli-zenroom.o src/repl.o
zenroom: ${ZEN_SOURCES} ${cli_sources}
	$(info === Building the zenroom CLI)
	${cxx} ${cflags} ${ZEN_SOURCES} ${cli_sources} \
		-o $@ ${ldflags} ${ldadd} -lreadline

lua-exec: cflags += -DLUA_EXEC
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
