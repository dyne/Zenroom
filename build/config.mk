# included by makefile

pwd := $(shell pwd)
mil := ${pwd}/build/milagro
website := ${pwd}/docs

# ------------
# lua settings
luasrc := ${pwd}/lib/lua53/src
ldadd := ${pwd}/lib/lua53/src/liblua.a
lua_embed_opts := ""
lua_cflags := -DLUA_COMPAT_5_3 -DLUA_COMPAT_MODULE -DLUA_COMPAT_BITLIB -I${pwd}/lib/milagro-crypto-c/build/include -I${pwd}/src -I${pwd}/lib/milagro-crypto-c/build/include

# ----------------
# zenroom defaults
gcc := gcc
ar := $(shell which ar) # cmake requires full path
ranlib := ranlib
ld := ld
cflags_protection := -fstack-protector-all -D_FORTIFY_SOURCE=2 -fno-strict-overflow
cflags := -O2 ${cflags_protection}
musl := ${pwd}/build/musl
platform := posix

# ----------------
# milagro settings
rsa_bits := ""
# other ecdh curves := ED25519 C25519 NIST256 BRAINPOOL ANSSI HIFIVE
# GOLDILOCKS NIST384 C41417 NIST521 NUMS256W NUMS256E NUMS384W
# NUMS384E NUMS512W NUMS512E SECP256K1 BN254 BN254CX BLS381 BLS383
# BLS24 BLS48 FP256BN FP512BN BLS461
# see lib/milagro-crypto-c/cmake/AMCLParameters.cmake
ecdh_curve := SECP256K1
ecp_curve  := BLS381
milagro_cmake_flags := -DBUILD_SHARED_LIBS=OFF -DBUILD_PYTHON=OFF -DBUILD_DOXYGEN=OFF -DBUILD_DOCS=OFF -DBUILD_BENCHMARKS=OFF -DBUILD_EXAMPLES=OFF -DWORD_SIZE=32 -DBUILD_PAILLIER=OFF -DBUILD_X509=OFF -DBUILD_WCC=OFF -DBUILD_MPIN=OFF -DAMCL_CURVE=${ecdh_curve},${ecp_curve} -DAMCL_RSA=${rsa_bits} -DAMCL_PREFIX=AMCL_ -DCMAKE_SHARED_LIBRARY_LINK_FLAGS="" -DC99=1 -DPAIRING_FRIENDLY_BLS381='BLS' -DCOMBA=1
milib := ${pwd}/lib/milagro-crypto-c/build/lib
ldadd += ${milib}/libamcl_curve_${ecp_curve}.a
ldadd += ${milib}/libamcl_pairing_${ecp_curve}.a
ldadd += ${milib}/libamcl_curve_${ecdh_curve}.a
ldadd += ${milib}/libamcl_core.a

#-----------------
# quantum-proof
ldadd += ${pwd}/lib/pqclean/libqpz.a

# ----------------
# zstd settings
ldadd += ${pwd}/lib/zstd/libzstd.a

#-----------------
# ed25519 settings
ldadd += ${pwd}/lib/ed25519-donna/libed25519.a

# ------------------------
# target specific settings

ifneq (,$(findstring win,$(MAKECMDGOALS)))
gcc := $(shell which x86_64-w64-mingw32-gcc)
ar  := $(shell which x86_64-w64-mingw32-ar)
ranlib := $(shell which x86_64-w64-mingw32-ranlib)
ld := $(shell which x86_64-w64-mingw32-ld)
system := Windows
cflags := -mthreads -D'ARCH=\"WIN\"' -DARCH_WIN
ldflags := -L/usr/x86_64-w64-mingw32/lib
ldadd += -l:libm.a -l:libpthread.a -lssp
endif

ifneq (,$(findstring cyg,$(MAKECMDGOALS)))
gcc := gcc
ar  := ar
ranlib := ranlib
ld := ld
system := Windows
cflags := -mthreads -D'ARCH=\"WIN\"' -DARCH_WIN
ldadd := ${pwd}/lib/lua53/src/liblua.a
ldadd += ${milib}/libamcl_curve_${ecp_curve}.lib
ldadd += ${milib}/libamcl_pairing_${ecp_curve}.lib
ldadd += ${milib}/libamcl_curve_${ecdh_curve}.lib
ldadd += ${milib}/amcl_core.lib
ldadd += -l:libm.a -l:libpthread.a -lssp
endif


ifneq (,$(findstring cortex,$(MAKECMDGOALS)))
gcc := arm-none-eabi-gcc
objcopy := arm-none-eabi-objcopy
ranlib := arm-none-eabi-ranlib
ld := arm-none-eabi-ld
system := Generic
ldadd += -lm
cflags_protection := ""
cflags := ${cflags_protection} -DARCH_CORTEX -mcpu=cortex-m3 -mthumb -mlittle-endian -mthumb-interwork -Wstack-usage=1024 -DLIBRARY -Wno-main -ffreestanding -nostartfiles -specs=nano.specs -specs=nosys.specs
milagro_cmake_flags += -DCMAKE_SYSTEM_PROCESSOR="arm" -DCMAKE_CROSSCOMPILING=1 -DCMAKE_C_COMPILER_WORKS=1 -DBUILD_TESTING=0
ldflags+=-mcpu=cortex-m3 -mthumb -mlittle-endian -mthumb-interwork -Wstack-usage=1024 -Wno-main -ffreestanding -T cortex_m.ld -nostartfiles -Wl,-gc-sections -ggdb
endif

ifneq (,$(findstring aarch64,$(MAKECMDGOALS)))
gcc := aarch64-linux-gnu-gcc 
objcopy := aarch64-linux-gnu-objcopy
ranlib := aarch64-linux-gnu-ranlib
ld := aarch64-linux-gnu 
system := Linux 
ldadd += -lm
cflags := -O3 -fPIC -D'ARCH=\"LINUX\"' -DARCH_LINUX
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
cflags_protection := ""
cflags := ${cflags_protection}
milagro_cmake_flags += -DCMAKE_CROSSCOMPILING=1 -DCMAKE_C_COMPILER_WORKS=1
ldflags += -Wstack-usage=1024
endif

ifneq (,$(findstring ios,$(MAKECMDGOALS)))
milagro_cmake_flags += -DCMAKE_SYSTEM_PROCESSOR="arm" -DCMAKE_CROSSCOMPILING=1 -DCMAKE_C_COMPILER_WORKS=1
milagro_cmake_flags += -DCMAKE_OSX_SYSROOT="/" -DCMAKE_OSX_DEPLOYMENT_TARGET=""
endif

ifneq (,$(findstring c++,$(MAKECMDGOALS)))
gcc := g++
endif

ifneq (,$(findstring musl,$(MAKECMDGOALS)))
gcc := musl-gcc
cflags := -Os -static -std=gnu99 -fPIC ${cflags_protection} -D'ARCH=\"MUSL\"' -D__MUSL__ -DARCH_MUSL
ldflags := -static
system := Linux
endif

ifneq (,$(findstring linux,$(MAKECMDGOALS)))
cflags := ${cflags} -fPIC ${cflags_protection} -D'ARCH=\"LINUX\"' -DARCH_LINUX
ldflags := -lm -lpthread
system := Linux
cflags += $(if ${COMPILE_LUA}, -DLUA_COMPILED)
endif

ifneq (,$(findstring clang,$(MAKECMDGOALS)))
gcc := clang
endif

ifneq (,$(findstring raspi,$(MAKECMDGOALS)))
pi := ${CROSS_PI_PATH}
gcc := ${pi}/bin/arm-linux-gnueabihf-gcc
ar := ${pi}/bin/arm-linux-gnueabihf-ar
cflags := -O3 -march=armv6 -mfloat-abi=hard -mfpu=vfp -I${pi}/arm-linux-gnueabihf/include -fPIC -D'ARCH=\"LINUX\"' -DARCH_LINUX
ldflags := -L${pi}arm-linux-gnueabihf/lib -lm -lpthread
system := Linux
endif

ifneq (,$(findstring jemalloc,$(MAKECMDGOALS)))
cflags += -DUSE_JEMALLOC
ldflags += -ljemalloc
endif


#milagro_cmake_flags += -DCMAKE_SYSROOT=${sysroot} -DCMAKE_LINKER=${ld} -DCMAKE_C_LINK_EXECUTABLE="<CMAKE_LINKER> <FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>"
# -DCMAKE_ANDROID_NDK=${sysroot}
#milagro_cmake_flags += -DCMAKE_ANDROID_STANDALONE_TOOLCHAIN=${ndk} -DCMAKE_SYSTEM_VERSION=26

ifneq (,$(findstring java,$(MAKECMDGOALS)))
jdk = ${JAVA_HOME}
ldflags += -shared
cflags += -fPIC ${cflags_protection} -DLIBRARY -D'ARCH=\"LINUX\"' -DARCH_LINUX
cflags += -DLUA_USE_DLOPEN -I${jdk}/include -I${jdk}/include/linux
system := Java
endif

ifneq (,$(findstring android,$(MAKECMDGOALS)))
ndk = ${NDK_HOME}
toolchain = ${ndk}/toolchains/llvm/prebuilt/linux-x86_64
gcc = ${toolchain}/bin/clang
ar = ${toolchain}/bin/llvm-ar
ldadd += -lm -llog
ldflags := -shared
cflags += -fPIC ${cflags_protection} -DLIBRARY -D'ARCH=\"LINUX\"' -DARCH_LINUX -DARCH_ANDROID
cflags += -DLUA_USE_DLOPEN -I${ndk}/sysroot/usr/include
system := Android
android := 18
endif

ifneq (,$(findstring android-arm,$(MAKECMDGOALS)))
target = arm-linux-androideabi
ld = ${toolchain}/bin/${target}-link
sysroot = ${ndk}/platforms/android-${android}/arch-arm
cflags += -D__ANDROID_API__=${android} -I${ndk}/sysroot/usr/include/arm-linux-androideabi --target=armv7-none-linux-androideabi --gcc-toolchain=${ndk}/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64 --sysroot=${sysroot}
milagro_cmake_flags += -DCMAKE_SYSTEM_NAME=${system} -DCMAKE_ANDROID_NDK=${ndk} -DCMAKE_ANDROID_API=${android}
endif

ifneq (,$(findstring android-x86,$(MAKECMDGOALS)))
target = x86
ld = ${toolchain}/bin/${target}-link
sysroot = ${ndk}/platforms/android-${android}/arch-x86
cflags += -D__ANDROID_API__=${android} -I${ndk}/sysroot/usr/include/i686-linux-android --target=i686-linux-android --gcc-toolchain=${ndk}/toolchains/${target}-4.9/prebuilt/linux-x86_64 --sysroot=${sysroot}
milagro_cmake_flags += -DCMAKE_SYSTEM_NAME=${system} -DCMAKE_ANDROID_NDK=${ndk} -DCMAKE_ANDROID_API=${android}
endif

ifneq (,$(findstring android-aarch64,$(MAKECMDGOALS)))
target = aarch64-linux-android
ld = ${toolchain}/bin/${target}-link
android := 21
sysroot = ${ndk}/platforms/android-${android}/arch-arm64
cflags += -D__ANDROID_API__=${android} -I${ndk}/sysroot/usr/include/aarch64-linux-android --target=aarch64-linux-android21 --gcc-toolchain=${ndk}/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64 --sysroot=${sysroot}
milagro_cmake_flags += -DCMAKE_SYSTEM_NAME=${system} -DCMAKE_ANDROID_NDK=${ndk} -DCMAKE_ANDROID_API=${android} -DCMAKE_SYSTEM_PROCESSOR=aarch64
endif

ifneq (,$(findstring osx,$(MAKECMDGOALS)))
cflags := ${cflags} -fPIC ${cflags_protection} -D'ARCH=\"OSX\"' -DARCH_OSX
ld := ${gcc}
ldflags := -lm
system := Darwin
endif

ifneq (,$(findstring javascript,$(MAKECMDGOALS)))
gcc := ${EMSCRIPTEN}/emcc
ar := ${EMSCRIPTEN}/emar
ld := ${gcc}
ranlib := ${EMSCRIPTEN}/emranlib
system:= Javascript
# lua_embed_opts := "compile"
ldflags := -s "EXPORTED_FUNCTIONS='[\"_zenroom_exec\",\"_zencode_exec\"]'" -s "EXPORTED_RUNTIME_METHODS='[\"ccall\",\"cwrap\",\"printErr\",\"print\"]'" -s USE_SDL=0 -s USE_PTHREADS=0 -lm
cflags := -Wall -I ${EMSCRIPTEN}/system/include/libc -DLIBRARY
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

ifneq (,$(findstring release,$(MAKECMDGOALS)))
cflags := -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -fno-strict-overflow
endif

# clang doesn't supports -Wstack-usage=4096

ifneq (,$(findstring debug,$(MAKECMDGOALS)))
cflags := -Og -ggdb -DDEBUG=1 -Wall -Wextra -pedantic
cflags += $(if ${COMPILE_LUA}, -DLUA_COMPILED)
endif

ifneq (,$(findstring profile,$(MAKECMDGOALS)))
cflags += -Og -ggdb -pg -DDEBUG=1
endif

ifneq (,$(findstring meson,$(MAKECMDGOALS)))
# meson always builds a shared lib
cflags += -fPIC
endif

ifneq (,$(findstring python2,$(MAKECMDGOALS)))
cflags += $(shell python2.7-config --cflags) -fPIC
ldflags += $(shell python2.7-config --ldflags)
endif

ifneq (,$(findstring python3,$(MAKECMDGOALS)))
cflags += $(shell python3-config --cflags) -fPIC
ldflags += $(shell python3-config --ldflags)
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
