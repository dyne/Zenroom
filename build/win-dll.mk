## Initialize build defaults
include build/init.mk

COMPILER := $(shell which x86_64-w64-mingw32-gcc)
COMPILER_CXX := $(shell which x86_64-w64-mingw32-g++)

ar  := $(shell which x86_64-w64-mingw32-ar)
ranlib := $(shell which x86_64-w64-mingw32-ranlib)
ld := $(shell which x86_64-w64-mingw32-g++)
system := Windows
cflags += -fPIC -DLIBRARY -mthreads ${defines}
cflags += -D'ARCH="WIN"' -DARCH_WIN -DLUA_USE_WINDOWS
ldflags += -L/usr/x86_64-w64-mingw32/lib -shared
ldadd += -l:libm.a -l:libpthread.a -lssp -Wl,--out-implib,libzenroom_dll.lib
ldadd += -lstdc++

# activate CCACHE etc.
include build/plugins.mk

all: ${BUILD_DEPS} stamp-exe-windres zenroom.dll

stamp-exe-windres:
	sh build/stamp-exe.sh

zenroom.dll: ${ZEN_SOURCES}
	$(info === Linking Windows zenroom.dll)
	${ld} ${cflags} ${ZEN_SOURCES} \
		-o $@ zenroom.res ${ldflags} ${ldadd}

include build/deps.mk
