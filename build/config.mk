# included by makefile

pwd := $(shell pwd)
mil := ${pwd}/build/milagro
extras := ${pwd}/docs/demo

# --------
# defaults
gcc := gcc
ar := ar
ranlib := ranlib
ld := ld
cflags_protection := -fstack-protector-all -D_FORTIFY_SOURCE=2 -fno-strict-overflow
cflags := -O2 ${cflags_protection}
musl := ${pwd}/build/musl
platform := posix

# ------------
# lua settings
luasrc := ${pwd}/lib/lua53/src
ldadd := ${pwd}/lib/lua53/src/liblua.a
lua_embed_opts := ""

# ----------------
# milagro settings
rsa_bits := ""
ecc_curves := ED25519,BLS383,GOLDILOCKS,SECP256K1
milagro_cmake_flags := -DBUILD_SHARED_LIBS=OFF -DBUILD_PYTHON=OFF -DBUILD_DOXYGEN=OFF -DWORD_SIZE=32 -DAMCL_CURVE=${ecc_curves} -DAMCL_RSA=${rsa_bits} -DCMAKE_SHARED_LIBRARY_LINK_FLAGS="" -DC99=1 -DPAIRING_FRIENDLY_BLS383='BLS' -DCOMBA=1
milib := ${pwd}/lib/milagro-crypto-c/lib
ldadd += ${milib}/libamcl_curve_ED25519.a
ldadd += ${milib}/libamcl_curve_BLS383.a
ldadd += ${milib}/libamcl_pairing_BLS383.a
ldadd += ${milib}/libamcl_curve_GOLDILOCKS.a
ldadd += ${milib}/libamcl_curve_SECP256K1.a
ldadd += ${milib}/libamcl_core.a

# ------------------------
# target specific settings

ifneq (,$(findstring win,$(MAKECMDGOALS)))
gcc := x86_64-w64-mingw32-gcc
ar  := x86_64-w64-mingw32-ar
ranlib := x86_64-w64-mingw32-ranlib
ld := x86_64-w64-mingw32-ld
system := Windows
cflags := ${cflags_protection} -D'ARCH=\"WIN\"' -DARCH_WIN -O3 -Wall -Wextra -pedantic -std=gnu99
ldflags := -L/usr/x86_64-w64-mingw32/lib
ldadd += -l:libm.a -l:libpthread.a -lssp
endif

ifneq (,$(findstring cyg,$(MAKECMDGOALS)))
gcc := gcc
ar  := ar
ranlib := ranlib
ld := ld
system := Windows
cflags := ${cflags_protection} -D'ARCH=\"WIN\"' -DARCH_WIN -O3 -Wall -Wextra -pedantic -std=gnu99
ldadd += -l:libm.a -l:libpthread.a -lssp
endif


ifneq (,$(findstring cortex,$(MAKECMDGOALS)))
gcc := arm-none-eabi-gcc
ar  := arm-none-eabi-ar
objcopy := arm-none-eabi-objcopy
ranlib := arm-none-eabi-ranlib
ld := arm-none-eabi-ld
system := Generic
ldadd += -lm
cflags_protection := ""
cflags := ${cflags_protection} -DARCH_CORTEX -O3 -Wall -Wextra -pedantic -std=gnu99 -mcpu=cortex-m4 -mthumb -mlittle-endian -mthumb-interwork -Wstack-usage=1024 -DLIBRARY -Os -Wno-main -ffreestanding -nostartfiles
milagro_cmake_flags += -DCMAKE_SYSTEM_PROCESSOR="arm" -DCMAKE_CROSSCOMPILING=1 -DCMAKE_C_COMPILER_WORKS=1
ldflags+=-mcpu=cortex-m4 -mthumb -mlittle-endian -mthumb-interwork -Wstack-usage=1024 -ggdb -Wno-main -ffreestanding -T cortex_m.ld -nostartfiles -Wl,-gc-sections
endif

ifneq (,$(findstring redis,$(MAKECMDGOALS)))
cflags := ${cflags_protection} -DARCH_REDIS -Wall -std=gnu99
cflags += -O1 -ggdb -DDEBUG=1
endif

ifneq (,$(findstring ios,$(MAKECMDGOALS)))
milagro_cmake_flags += -DCMAKE_SYSTEM_PROCESSOR="arm" -DCMAKE_CROSSCOMPILING=1 -DCMAKE_C_COMPILER_WORKS=1
milagro_cmake_flags += -DCMAKE_OSX_SYSROOT="/" -DCMAKE_OSX_DEPLOYMENT_TARGET=""
endif

ifneq (,$(findstring musl,$(MAKECMDGOALS)))
gcc := musl-gcc
cflags := -Os -static -Wall -std=gnu99 -fPIC ${cflags_protection} -D'ARCH=\"MUSL\"' -D__MUSL__ -DARCH_MUSL
ldflags := -static
system := Linux
endif

ifneq (,$(findstring linux,$(MAKECMDGOALS)))
cflags := ${cflags} -fPIC ${cflags_protection} -D'ARCH=\"LINUX\"' -DARCH_LINUX
ldflags := -lm -lpthread
system := Linux
endif

ifneq (,$(findstring jemalloc,$(MAKECMDGOALS)))
cflags += -DUSE_JEMALLOC
ldflags += -ljemalloc
endif


#milagro_cmake_flags += -DCMAKE_SYSROOT=${sysroot} -DCMAKE_LINKER=${ld} -DCMAKE_C_LINK_EXECUTABLE="<CMAKE_LINKER> <FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>"
# -DCMAKE_ANDROID_NDK=${sysroot}
#milagro_cmake_flags += -DCMAKE_ANDROID_STANDALONE_TOOLCHAIN=${ndk} -DCMAKE_SYSTEM_VERSION=26

ifneq (,$(findstring android,$(MAKECMDGOALS)))
ndk = /opt/android-ndk-r18b
toolchain = ${ndk}/toolchains/llvm/prebuilt/linux-x86_64
gcc = ${toolchain}/bin/clang
ar = ${toolchain}/bin/llvm-ar
ldadd += -lm -llog
ldflags += -shared
cflags += -fPIC ${cflags_protection} -DLIBRARY -D'ARCH=\"LINUX\"' -DARCH_LINUX -DARCH_ANDROID
cflags += -DLUA_USE_DLOPEN -I${ndk}/sysroot/usr/include
system := Android
android := 18
milagro_cmake_flags += -DCMAKE_SYSTEM_NAME=${system} -DCMAKE_ANDROID_NDK=${ndk} -DCMAKE_ANDROID_API=${android}
endif

ifneq (,$(findstring android-arm,$(MAKECMDGOALS)))
target = arm-linux-androideabi
ld = ${toolchain}/bin/${target}-link
sysroot = ${ndk}/platforms/android-${android}/arch-arm
cflags += -D__ANDROID_API__=${android} -I${ndk}/sysroot/usr/include/arm-linux-androideabi --target=armv7-none-linux-androideabi --gcc-toolchain=${ndk}/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64 --sysroot=${sysroot}
endif

ifneq (,$(findstring android-x86,$(MAKECMDGOALS)))
target = x86
ld = ${toolchain}/bin/${target}-link
sysroot = ${ndk}/platforms/android-${android}/arch-x86
cflags += -D__ANDROID_API__=${android} -I${ndk}/sysroot/usr/include/i686-linux-android --target=i686-linux-android --gcc-toolchain=${ndk}/toolchains/${target}-4.9/prebuilt/linux-x86_64 --sysroot=${sysroot}
endif

ifneq (,$(findstring osx,$(MAKECMDGOALS)))
cflags := ${cflags} -fPIC ${cflags_protection} -D'ARCH=\"OSX\"' -DARCH_OSX
ld := ${gcc}
ldflags := -lm
system := Darwin
endif

ifneq (,$(findstring python2,$(MAKECMDGOALS)))
cflags += $(shell python2.7-config --cflags) -fPIC
ldflags += $(shell python2.7-config --ldflags)
endif

ifneq (,$(findstring python3,$(MAKECMDGOALS)))
cflags += $(shell python3-config --cflags) -fPIC
ldflags += $(shell python3-config --ldflags)
endif

ifneq (,$(findstring javascript,$(MAKECMDGOALS)))
gcc := ${EMSCRIPTEN}/emcc
ar := ${EMSCRIPTEN}/emar
ld := ${gcc}
system:= Javascript
# lua_embed_opts := "compile"
ldflags := -s "EXPORTED_FUNCTIONS='[\"_zenroom_exec\",\"_zenroom_exec_tobuf\",\"_set_debug\"]'" -s "EXTRA_EXPORTED_RUNTIME_METHODS='[\"ccall\",\"cwrap\"]'" -s USE_SDL=0 -s USE_PTHREADS=0 -lm
cflags := -O2 -Wall -I ${EMSCRIPTEN}/system/include/libc -DLIBRARY
endif

ifneq (,$(findstring esp32,$(MAKECMDGOALS)))
gcc := ${pwd}/build/xtensa-esp32-elf/bin/xtensa-esp32-elf-gcc
ld  := ${pwd}/build/xtensa-esp32-elf/bin/xtensa-esp32-elf-ld
ar  := ${pwd}/build/xtensa-esp32-elf/bin/xtensa-esp32-elf-ar
ranlib := ${pwd}/build/xtensa-esp32-elf/bin/xtensa-esp32-elf-ranlib
system := Generic
# TODO: not working, cmake doesn't uses the specified linked (bug?)
milagro_cmake_flags := -DCMAKE_LINKER=${ld} -DCMAKE_C_LINK_EXECUTABLE="<CMAKE_LINKER> <FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>"
cflags := -I. -mlongcalls  #${cflags_protection} -D'ARCH=\"LINUX\"' -DARCH_LINUX
ldflags += -L${pwd}/build/xtensa-esp32-elf/lib -Teagle.app.v6.ld
ldadd += ${ldadd} -nostdlib -Wl,--start-group -lmain -lc -Wl,--end-group -lgcc
# ldadd += ${ldadd} -l:libm.a -l:libpthread.a -lssp
endif



# ifneq (,$(findstring ios,$(MAKECMDGOALS)))
# gcc := $(shell xcrun --sdk iphoneos -f gcc 2>/dev/null)
# ar := $(shell xcrun --sdk iphoneos -f ar 2>/dev/null)
# ld := $(shell xcrun --sdk iphoneos -f ld 2>/dev/null)
# ldflags := lm
# ranlib := $(shell xcrun --sdk iphoneos -f ranlib 2>/dev/null)
# SDK := $(shell xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
# cflags := -O2 -fPIC ${cflags_protection} -D'ARCH=\"OSX\"' -isysroot ${SDK} -arch ${ARCH} -D NO_SYSTEM -DARCH_OSX
# endif
