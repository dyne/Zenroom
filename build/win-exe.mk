## Initialize build defaults
include build/init.mk

COMPILER := $(shell which x86_64-w64-mingw32-gcc)
COMPILER_CXX := $(shell which x86_64-w64-mingw32-g++)

ar  := $(shell which x86_64-w64-mingw32-ar)
ranlib := $(shell which x86_64-w64-mingw32-ranlib)
ld := $(shell which x86_64-w64-mingw32-g++)
system := Windows
cflags += -fPIC -mthreads ${defines}
cflags += -D'ARCH="WIN"' -DARCH_WIN -DLUA_USE_WINDOWS
ldflags += -L/usr/x86_64-w64-mingw32/lib
ldadd += -l:libm.a -l:libpthread.a -lssp
ldadd += -lstdc++

# activate CCACHE etc.
include build/plugins.mk

all: ${BUILD_DEPS} stamp-exe-windres zenroom.exe zencode-exec.exe

stamp-exe-windres:
	sh build/stamp-exe.sh

cli_sources := src/cli-zenroom.o src/repl.o
zenroom.exe: ${ZEN_SOURCES} ${cli_sources}
	$(info === Linking Windows zenroom.exe)
	${ld} ${cflags} ${ZEN_SOURCES} ${cli_sources} \
		-o $@ zenroom.res ${ldflags} ${ldadd}

zencode-exec.exe: ${ZEN_SOURCES} src/zencode-exec.o
	$(info === Linking Windows zencode-exec.exe)
	${ld} ${cflags} ${ZEN_SOURCES} src/zencode-exec.o \
		-o $@ zenroom.res ${ldflags} ${ldadd}

include build/deps.mk
