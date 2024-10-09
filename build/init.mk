BRANCH := $(shell git symbolic-ref HEAD | cut -d/ -f3-)
COMMIT := $(shell git rev-parse --short HEAD)
VERSION := $(shell git describe --tags | cut -d- -f1)
CURRENT_YEAR := $(shell date +%Y)

ZEN_SOURCES := \
    src/zenroom.o src/zen_error.o \
    src/lua_functions.o src/lua_modules.o src/lualibs_detected.o src/lua_shims.o \
    src/encoding.o src/base58.o src/rmd160.o src/segwit_addr.o \
    src/zen_memory.o src/mutt_sprintf.o \
    src/zen_io.o src/zen_parse.o src/zen_config.o \
    src/zen_octet.o src/zen_ecp.o src/zen_ecp2.o src/zen_big.o \
    src/zen_fp12.o src/zen_random.o src/zen_hash.o \
    src/zen_ecdh_factory.o src/zen_ecdh.o \
    src/zen_aes.o src/zen_qp.o src/zen_ed.o src/zen_float.o src/zen_time.o \
    src/api_hash.o src/randombytes.o src/zen_fuzzer.o \
    src/cortex_m.o src/p256-m.o src/zen_p256.o src/zen_rsa.o src/zen_bbs.o

ZEN_INCLUDES += -Isrc -Ilib/lua54/src									\
-Ilib/milagro-crypto-c/build/include -Ilib/milagro-crypto-c/include		\
-Ilib/ed25519-donna -Ilib/mimalloc/include -Ilib/tinycc -Wall -Wextra

BUILD_DEPS := apply-patches milagro lua54 embed-lua quantum-proof	\
ed25519-donna

JS_INIT_MEM := 8MB
JS_MAX_MEM := 256MB
JS_STACK_SIZE := 7MB

pwd := $(shell pwd)
mil := ${pwd}/build/milagro
website := ${pwd}/docs

# libs defaults
luasrc := ${pwd}/lib/lua54/src
ldadd := ${pwd}/lib/lua54/src/liblua.a
lua_embed_opts := ""
ecdh_curve ?= SECP256K1
ecp_curve  ?= BLS381
milib := ${pwd}/lib/milagro-crypto-c/build/lib
ldadd += ${milib}/libamcl_curve_${ecp_curve}.a
ldadd += ${milib}/libamcl_pairing_${ecp_curve}.a
ldadd += ${milib}/libamcl_curve_${ecdh_curve}.a
ldadd += ${milib}/libamcl_rsa_2048.a ${milib}/libamcl_rsa_4096.a
ldadd += ${milib}/libamcl_core.a
ldadd += ${pwd}/lib/pqclean/libqpz.a
ldadd += ${pwd}/lib/ed25519-donna/libed25519.a
# ldadd += ${pwd}/lib/mimalloc/build/libmimalloc-static.a

# ----------------
# zenroom defaults
cc := gcc
zenroom_cc := ${cc}
# defined further below
# quantum_proof_cc := ${cc}
# ed25519_cc := ${cc}
# lua_cc := ${cc}
ld := ld
ar := $(shell which ar) # cmake requires full path
ranlib := ranlib
cflags_protection := -fstack-protector-all -D_FORTIFY_SOURCE=2
cflags_protection += -fno-strict-overflow
cflags_debug := -Og -ggdb -DDEBUG=1 -Wall -Wextra -pedantic
cflags := ${ZEN_INCLUDES}
musl := build/musl
platform := posix

##########################
# {{{ Dependency settings

# ------------
# lua settings
lua_cc ?= ${cc}
lua_cflags := -DLUA_COMPAT_5_3 -DLUA_COMPAT_MODULE -DLUA_COMPAT_BITLIB -I${pwd}/lib/milagro-crypto-c/build/include -I${pwd}/src -I${pwd}/lib/milagro-crypto-c/build/include -I ${pwd}/lib/mimalloc/include

# ----------------
# milagro settings
rsa_bits := "2048,4096"
# other ecdh curves := ED25519 C25519 NIST256 BRAINPOOL ANSSI HIFIVE
# GOLDILOCKS NIST384 C41417 NIST521 NUMS256W NUMS256E NUMS384W
# NUMS384E NUMS512W NUMS512E SECP256K1 BN254 BN254CX BLS381 BLS383
# BLS24 BLS48 FP256BN FP512BN BLS461
# see lib/milagro-crypto-c/cmake/AMCLParameters.cmake
milagro_cmake_flags += -DBUILD_SHARED_LIBS=OFF -DBUILD_PYTHON=OFF -DBUILD_DOXYGEN=OFF -DBUILD_DOCS=OFF -DBUILD_BENCHMARKS=OFF -DBUILD_EXAMPLES=OFF -DWORD_SIZE=32 -DBUILD_PAILLIER=OFF -DBUILD_X509=OFF -DBUILD_WCC=OFF -DBUILD_MPIN=OFF -DAMCL_CURVE=${ecdh_curve},${ecp_curve} -DAMCL_RSA=${rsa_bits} -DAMCL_PREFIX=AMCL_ -DCMAKE_SHARED_LIBRARY_LINK_FLAGS="" -DC99=1 -DPAIRING_FRIENDLY_BLS381='BLS' -DCOMBA=1 -DBUILD_TESTING=OFF

#-----------------
# quantum-proof
quantum_proof_cc ?= ${cc}
quantum_proof_cflags ?= -I ${pwd}/src -I ${pwd}/lib/mimalloc/include -I.

#-----------------
# ed25519 settings
ed25519_cc ?= ${cc}

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
