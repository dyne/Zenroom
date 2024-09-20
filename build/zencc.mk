include build/init.mk

defines := -DLIBCMALLOC
gcc := musl-gcc
cflags := -Os -static -std=gnu99 -fPIC ${cflags_protection} -DARCH=\"MUSL\" -D__MUSL__ -DARCH_MUSL ${defines} ${ZEN_INCLUDES}
ldflags := -static
system := Linux

BUILD_DEPS := apply-patches milagro lua54 embed-lua quantum-proof	\
ed25519-donna tinycc
ldadd := ${pwd}/lib/lua54/src/liblua.a
ldadd += ${milib}/libamcl_curve_${ecp_curve}.a
ldadd += ${milib}/libamcl_pairing_${ecp_curve}.a
ldadd += ${milib}/libamcl_curve_${ecdh_curve}.a
ldadd += ${milib}/libamcl_rsa_2048.a ${milib}/libamcl_rsa_4096.a
ldadd += ${milib}/libamcl_core.a
ldadd += ${pwd}/lib/pqclean/libqpz.a
ldadd += ${pwd}/lib/ed25519-donna/libed25519.a
ldadd += ${pwd}/lib/tinycc/libtcc.a

zencc: ${BUILD_DEPS} ${ZEN_SOURCES} src/cli-zenroom.o
	$(info Building zencc embedded C compiler)
	${gcc} ${cflags} ${ZEN_SOURCES} src/cli-zenroom.o -o zencc	\
	${ldflags} ${ldadd}

include build/deps.mk
