# Automatic settings configuration
# included by makefile

# {{{ DEFAULTS

pwd := $(shell pwd)
mil := ${pwd}/build/milagro
website := ${pwd}/docs

# libs defaults
luasrc := ${pwd}/lib/lua53/src
ldadd := ${pwd}/lib/lua53/src/liblua.a
lua_embed_opts := ""
ecdh_curve ?= SECP256K1
ecp_curve  ?= BLS381
milib := ${pwd}/lib/milagro-crypto-c/build/lib
ldadd += ${milib}/libamcl_curve_${ecp_curve}.a
ldadd += ${milib}/libamcl_pairing_${ecp_curve}.a
ldadd += ${milib}/libamcl_curve_${ecdh_curve}.a
ldadd += ${milib}/libamcl_core.a
ldadd += ${pwd}/lib/pqclean/libqpz.a
ldadd += ${pwd}/lib/zstd/libzstd.a
ldadd += ${pwd}/lib/ed25519-donna/libed25519.a
ldadd += ${pwd}/lib/blake2/libblake2.a
ldadd += ${pwd}/lib/mimalloc/build/libmimalloc-static.a

# ----------------
# zenroom defaults
gcc := gcc
ar := $(shell which ar) # cmake requires full path
ranlib := ranlib
ld := ld
cflags_protection := -fstack-protector-all -D_FORTIFY_SOURCE=2 -fno-strict-overflow
defines := -DMIMALLOC
defines += $(if ${COMPILE_LUA}, -DLUA_COMPILED)
cflags := -O2 ${cflags_protection}
musl := ${pwd}/build/musl
platform := posix

# }}}

# {{{ TARGET SPECIFIC

ifneq (,$(findstring win,$(MAKECMDGOALS)))
defines += -D'ARCH=\"WIN\"' -DARCH_WIN
gcc := $(shell which x86_64-w64-mingw32-gcc)
ar  := $(shell which x86_64-w64-mingw32-ar)
ranlib := $(shell which x86_64-w64-mingw32-ranlib)
ld := $(shell which x86_64-w64-mingw32-ld)
system := Windows
cflags := -mthreads ${defines}
ldflags := -L/usr/x86_64-w64-mingw32/lib
ldadd += -l:libm.a -l:libpthread.a -lssp
endif

ifneq (,$(findstring cortex,$(MAKECMDGOALS)))
gcc := arm-none-eabi-gcc
objcopy := arm-none-eabi-objcopy
ranlib := arm-none-eabi-ranlib
ld := arm-none-eabi-ld
system := Generic
ldadd += -lm
cflags := -DARCH_CORTEX -mcpu=cortex-m3 -mthumb -mlittle-endian -mthumb-interwork -Wstack-usage=1024 -DLIBRARY -Wno-main -ffreestanding -nostartfiles -specs=nano.specs -specs=nosys.specs
milagro_cmake_flags += -DCMAKE_SYSTEM_PROCESSOR="arm" -DCMAKE_CROSSCOMPILING=1 -DCMAKE_C_COMPILER_WORKS=1 -DBUILD_TESTING=0
ldflags+=-mcpu=cortex-m3 -mthumb -mlittle-endian -mthumb-interwork -Wstack-usage=1024 -Wno-main -ffreestanding -T cortex_m.ld -nostartfiles -Wl,-gc-sections -ggdb
endif

ifneq (,$(findstring aarch64,$(MAKECMDGOALS)))
defines := -DLIBCMALLOC
BUILDS := $(filter-out mimalloc,$(BUILDS))
ldadd := $(filter-out ${pwd}/lib/mimalloc/build/libmimalloc-static.a,${ldadd})
gcc := aarch64-linux-gnu-gcc 
objcopy := aarch64-linux-gnu-objcopy
ranlib := aarch64-linux-gnu-ranlib
ld := aarch64-linux-gnu 
system := Linux 
ldadd += -lm
cflags := -O3 -fPIC -D'ARCH=\"LINUX\"' -DARCH_LINUX ${defines}
ldflags := -lm -lpthread
milagro_cmake_flags += -DCMAKE_SYSTEM_PROCESSOR="aarch64" -DCMAKE_CROSSCOMPILING=1 -DCMAKE_C_COMPILER_WORKS=1
endif

ifneq (,$(findstring riscv64,$(MAKECMDGOALS)))
gcc := riscv64-linux-gnu-gcc
ar  := riscv64-linux-gnu-ar
objcopy := riscv64-linux-gnu-objcopy
ranlib := riscv64-linux-gnu-ranlib
ld := riscv64-linux-gnu-ld
system := Generic
ldadd += -lm
cflags := ""
milagro_cmake_flags += -DCMAKE_CROSSCOMPILING=1 -DCMAKE_C_COMPILER_WORKS=1
ldflags += -Wstack-usage=1024
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
ifneq (,$(findstring ios,$(MAKECMDGOALS)))
cflags := $(filter-out -DMIMALLOC,$(cflags))
BUILDS := $(filter-out mimalloc,$(BUILDS))
ldadd := $(filter-out ${pwd}/lib/mimalloc/build/libmimalloc-static.a,${ldadd})
milagro_cmake_flags += -DCMAKE_SYSTEM_PROCESSOR="arm" -DCMAKE_CROSSCOMPILING=1 -DCMAKE_C_COMPILER_WORKS=1
milagro_cmake_flags += -DCMAKE_OSX_SYSROOT="/" -DCMAKE_OSX_DEPLOYMENT_TARGET=""
endif

ifneq (,$(findstring musl,$(MAKECMDGOALS)))
defines := -DLIBCMALLOC
BUILDS := $(filter-out mimalloc,$(BUILDS))
ldadd := $(filter-out ${pwd}/lib/mimalloc/build/libmimalloc-static.a,${ldadd})
gcc := musl-gcc
defines := -DLIBCMALLOC
cflags := -Os -static -std=gnu99 -fPIC ${cflags_protection} -D'ARCH=\"MUSL\"' -D__MUSL__ -DARCH_MUSL ${defines}
ldflags := -static
system := Linux
endif

ifneq (,$(findstring linux,$(MAKECMDGOALS)))
defines += $(if ${COMPILE_LUA}, -DLUA_COMPILED)
cflags := ${cflags} -fPIC ${cflags_protection} -D'ARCH=\"LINUX\"' -DARCH_LINUX ${defines}
ldflags := -lm -lpthread
system := Linux
endif

ifneq (,$(findstring raspi,$(MAKECMDGOALS)))
defines := -DLIBCMALLOC
BUILDS := $(filter-out mimalloc,$(BUILDS))
ldadd := $(filter-out ${pwd}/lib/mimalloc/build/libmimalloc-static.a,${ldadd})
pi := ${CROSS_PI_PATH}
gcc := ${pi}/bin/arm-linux-gnueabihf-gcc
ar := ${pi}/bin/arm-linux-gnueabihf-ar
cflags := -O3 -march=armv6 -mfloat-abi=hard -mfpu=vfp -I${pi}/arm-linux-gnueabihf/include -fPIC -D'ARCH=\"LINUX\"' -DARCH_LINUX ${defines}
ldflags := -L${pi}arm-linux-gnueabihf/lib -lm -lpthread
system := Linux
endif

#milagro_cmake_flags += -DCMAKE_SYSROOT=${sysroot} -DCMAKE_LINKER=${ld} -DCMAKE_C_LINK_EXECUTABLE="<CMAKE_LINKER> <FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>"
# -DCMAKE_ANDROID_NDK=${sysroot}
#milagro_cmake_flags += -DCMAKE_ANDROID_STANDALONE_TOOLCHAIN=${ndk} -DCMAKE_SYSTEM_VERSION=26

ifneq (,$(findstring java,$(MAKECMDGOALS)))
jdk = ${JAVA_HOME}
ldflags += -shared
cflags += -fPIC -DLIBRARY -D'ARCH=\"LINUX\"' -DARCH_LINUX
cflags += -DLUA_USE_DLOPEN -I${jdk}/include -I${jdk}/include/linux
system := Java
endif

ifneq (,$(findstring android,$(MAKECMDGOALS)))
cflags := $(filter-out -DMIMALLOC,$(cflags))
BUILDS := $(filter-out mimalloc,$(BUILDS))
ldadd := $(filter-out ${pwd}/lib/mimalloc/build/libmimalloc-static.a,${ldadd})
ndk = ${NDK_HOME}
toolchain = ${ndk}/toolchains/llvm/prebuilt/linux-x86_64
gcc = ${toolchain}/bin/clang
ar = ${toolchain}/bin/llvm-ar
ldadd += -lm -llog
ldflags := -shared
cflags += -fPIC -DLIBRARY -D'ARCH=\"LINUX\"' -DARCH_LINUX -DARCH_ANDROID
cflags += -DLUA_USE_DLOPEN -I${ndk}/sysroot/usr/include
system := Android
android := 18
endif

ifneq (,$(findstring android-arm,$(MAKECMDGOALS)))
cflags := $(filter-out -DMIMALLOC,$(cflags))
BUILDS := $(filter-out mimalloc,$(BUILDS))
ldadd := $(filter-out ${pwd}/lib/mimalloc/build/libmimalloc-static.a,${ldadd})
target = arm-linux-androideabi
ld = ${toolchain}/bin/${target}-link
sysroot = ${ndk}/platforms/android-${android}/arch-arm
cflags += -D__ANDROID_API__=${android} -I${ndk}/sysroot/usr/include/arm-linux-androideabi --target=armv7-none-linux-androideabi --gcc-toolchain=${ndk}/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64 --sysroot=${sysroot}
milagro_cmake_flags += -DCMAKE_SYSTEM_NAME=${system} -DCMAKE_ANDROID_NDK=${ndk} -DCMAKE_ANDROID_API=${android}
endif

ifneq (,$(findstring android-x86,$(MAKECMDGOALS)))
cflags := $(filter-out -DMIMALLOC,$(cflags))
BUILDS := $(filter-out mimalloc,$(BUILDS))
ldadd := $(filter-out ${pwd}/lib/mimalloc/build/libmimalloc-static.a,${ldadd})
target = x86
ld = ${toolchain}/bin/${target}-link
sysroot = ${ndk}/platforms/android-${android}/arch-x86
cflags += -D__ANDROID_API__=${android} -I${ndk}/sysroot/usr/include/i686-linux-android --target=i686-linux-android --gcc-toolchain=${ndk}/toolchains/${target}-4.9/prebuilt/linux-x86_64 --sysroot=${sysroot}
milagro_cmake_flags += -DCMAKE_SYSTEM_NAME=${system} -DCMAKE_ANDROID_NDK=${ndk} -DCMAKE_ANDROID_API=${android}
endif

ifneq (,$(findstring android-aarch64,$(MAKECMDGOALS)))
cflags := $(filter-out -DMIMALLOC,$(cflags))
BUILDS := $(filter-out mimalloc,$(BUILDS))
ldadd := $(filter-out ${pwd}/lib/mimalloc/build/libmimalloc-static.a,${ldadd})
target = aarch64-linux-android
ld = ${toolchain}/bin/${target}-link
android := 21
sysroot = ${ndk}/platforms/android-${android}/arch-arm64
cflags += -D__ANDROID_API__=${android} -I${ndk}/sysroot/usr/include/aarch64-linux-android --target=aarch64-linux-android21 --gcc-toolchain=${ndk}/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64 --sysroot=${sysroot}
milagro_cmake_flags += -DCMAKE_SYSTEM_NAME=${system} -DCMAKE_ANDROID_NDK=${ndk} -DCMAKE_ANDROID_API=${android} -DCMAKE_SYSTEM_PROCESSOR=aarch64
endif

ifneq (,$(findstring osx,$(MAKECMDGOALS)))
cflags += -fPIC -D'ARCH=\"OSX\"' -DARCH_OSX
ld := ${gcc}
ldflags := -lm
system := Darwin
endif

ifneq (,$(findstring javascript,$(MAKECMDGOALS)))
EMSCRIPTEN ?= ${EMSDK}/upstream/emscripten
gcc := ${EMSCRIPTEN}/emcc
ar := ${EMSCRIPTEN}/emar
ld := ${gcc}
ranlib := ${EMSCRIPTEN}/emranlib
system:= Javascript
# lua_embed_opts := "compile"
ldflags := -s "EXPORTED_FUNCTIONS='[\"_zenroom_exec\",\"_zencode_exec\",\"_zenroom_hash_init\",\"_zenroom_hash_update\",\"_zenroom_hash_final\"]'" -s "EXPORTED_RUNTIME_METHODS='[\"ccall\",\"cwrap\",\"printErr\",\"print\"]'" -s USE_SDL=0 -s USE_PTHREADS=0 -lm
cflags := -O2 -Wall -I ${EMSCRIPTEN}/system/include/libc -DLIBRARY ${defines}
endif

ifneq (,$(findstring esp32,$(MAKECMDGOALS)))
gcc := ${pwd}/build/xtensa-esp32-elf/bin/xtensa-esp32-elf-gcc
ld  := ${pwd}/build/xtensa-esp32-elf/bin/xtensa-esp32-elf-ld
ar  := ${pwd}/build/xtensa-esp32-elf/bin/xtensa-esp32-elf-ar
ranlib := ${pwd}/build/xtensa-esp32-elf/bin/xtensa-esp32-elf-ranlib
system := Generic
# TODO: not working, cmake doesn't uses the specified linked (bug?)
milagro_cmake_flags := -DCMAKE_LINKER=${ld} -DCMAKE_C_LINK_EXECUTABLE="<CMAKE_LINKER> <FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>"
cflags := -I. -mlongcalls  #${cflags_protection} ${defines} -D'ARCH=\"LINUX\"' -DARCH_LINUX
ldflags += -L${pwd}/build/xtensa-esp32-elf/lib -Teagle.app.v6.ld
ldadd += ${ldadd} -nostdlib -Wl,--start-group -lmain -lc -Wl,--end-group -lgcc
# ldadd += ${ldadd} -l:libm.a -l:libpthread.a -lssp
endif

# clang doesn't supports -Wstack-usage=4096

ifneq (,$(findstring debug,$(MAKECMDGOALS)))
mimalloc_cmake_flags += -DCMAKE_BUILD_TYPE=Debug
mimalloc_cflags += -DMI_DEBUG_FULL
cflags := -Og -ggdb -DDEBUG=1 -Wall -Wextra -pedantic ${defines}
endif

ifneq (,$(findstring profile,$(MAKECMDGOALS)))
cflags := -Og -ggdb -pg -DDEBUG=1 ${defines}
endif

ifneq (,$(findstring meson,$(MAKECMDGOALS)))
# meson always builds a shared lib
cflags += -fPIC
endif

ifneq (,$(findstring python2,$(MAKECMDGOALS)))
cflags += $(shell python2.7-config --cflags) -fPIC -DLIBRARY
ldflags += $(shell python2.7-config --ldflags)
endif

ifneq (,$(findstring python3,$(MAKECMDGOALS)))
cflags += $(shell python3-config --cflags) -fPIC -DLIBRARY
ldflags += $(shell python3-config --ldflags)
endif

ifneq (,$(findstring c++,$(MAKECMDGOALS)))
gcc := g++
endif

ifneq (,$(findstring clang,$(MAKECMDGOALS)))
gcc := clang
endif

ifneq (,$(findstring ccache,$(MAKECMDGOALS)))
milagro_cmake_flags += -DCMAKE_C_COMPILER_LAUNCHER=ccache
mimalloc_cmake_flags += -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache
quantum_proof_cc := ccache ${gcc}
zstd_cc := ccache ${gcc}
ed25519_cc := ccache ${gcc}
lua_cc := ccache ${gcc}
endif

##########################
# {{{ Dependency settings

# ------------
# lua settings
lua_cc ?= ${gcc}
lua_cflags ?= -DLUA_COMPAT_5_3 -DLUA_COMPAT_MODULE -DLUA_COMPAT_BITLIB -I${pwd}/lib/milagro-crypto-c/build/include -I${pwd}/src -I${pwd}/lib/milagro-crypto-c/build/include -I ${pwd}/lib/mimalloc/include

# ----------------
# milagro settings
rsa_bits := ""
# other ecdh curves := ED25519 C25519 NIST256 BRAINPOOL ANSSI HIFIVE
# GOLDILOCKS NIST384 C41417 NIST521 NUMS256W NUMS256E NUMS384W
# NUMS384E NUMS512W NUMS512E SECP256K1 BN254 BN254CX BLS381 BLS383
# BLS24 BLS48 FP256BN FP512BN BLS461
# see lib/milagro-crypto-c/cmake/AMCLParameters.cmake
milagro_cmake_flags += -DBUILD_SHARED_LIBS=OFF -DBUILD_PYTHON=OFF -DBUILD_DOXYGEN=OFF -DBUILD_DOCS=OFF -DBUILD_BENCHMARKS=OFF -DBUILD_EXAMPLES=OFF -DWORD_SIZE=32 -DBUILD_PAILLIER=OFF -DBUILD_X509=OFF -DBUILD_WCC=OFF -DBUILD_MPIN=OFF -DAMCL_CURVE=${ecdh_curve},${ecp_curve} -DAMCL_RSA=${rsa_bits} -DAMCL_PREFIX=AMCL_ -DCMAKE_SHARED_LIBRARY_LINK_FLAGS="" -DC99=1 -DPAIRING_FRIENDLY_BLS381='BLS' -DCOMBA=1 -DBUILD_TESTING=OFF

#-----------------
# quantum-proof
quantum_proof_cc ?= ${gcc}
quantum_proof_cflags ?= -I ${pwd}/src -I ${pwd}/lib/mimalloc/include -I.

# ----------------
# zstd settings
zstd_cc ?= ${gcc}

#-----------------
# ed25519 settings
ed25519_cc ?= ${gcc}

#-----------------
# blake2 settings
blake2_cc ?= ${gcc}

#-----------------
# mimalloc settings
mimalloc_cmake_flags += -DMI_BUILD_SHARED=OFF -DMI_BUILD_OBJECT=OFF
mimalloc_cmake_flags += -DMI_BUILD_TESTS=OFF -DMI_SECURE=ON
mimalloc_cmake_flags += -DMI_LIBPTHREAD=0 -DMI_LIBRT=0
mimalloc_cmake_flags += -DMI_LIBATOMIC=0
mimalloc_cflags += -fvisibility=hidden -Wstrict-prototypes
mimalloc_cflags += -ftls-model=initial-exec -fno-builtin-malloc
mimalloc_cflags += -DMI_USE_RTLGENRANDOM

# }}}
