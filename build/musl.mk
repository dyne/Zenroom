## Initialize build defaults
include build/init.mk

BUILD_DEPS := apply-patches milagro lua54 embed-lua mlkem	\
				quantum-proof ed25519-donna

COMPILER := musl-gcc

cflags += -static -std=gnu99 -fPIC -D'ARCH="MUSL"' -D__MUSL__ -DARCH_MUSL
ldflags += -static
system := Linux

ldadd := ${pwd}/lib/lua54/src/liblua.a
ldadd += ${milib}/libamcl_curve_${ecp_curve}.a
ldadd += ${milib}/libamcl_pairing_${ecp_curve}.a
ldadd += ${milib}/libamcl_curve_${ecdh_curve}.a
ldadd += ${milib}/libamcl_rsa_2048.a ${milib}/libamcl_rsa_4096.a
ldadd += ${milib}/libamcl_x509.a
ldadd += ${milib}/libamcl_core.a
ldadd += ${pwd}/lib/pqclean/libqpz.a
ldadd += ${pwd}/lib/ed25519-donna/libed25519.a
ldadd += ${pwd}/lib/mlkem/test/build/libmlkem.a

# activate CCACHE etc.
include build/plugins.mk

all: deps zenroom zencode-exec

deps: ${BUILD_DEPS}

cli_sources := src/cli-zenroom.o src/repl.o
zenroom: ${ZEN_SOURCES} ${cli_sources}
	$(info === Building the zenroom CLI)
	${zenroom_cc} ${cflags} ${ZEN_SOURCES} ${cli_sources} \
		-o $@ ${ldflags} ${ldadd}

zencode-exec: ${ZEN_SOURCES} src/zencode-exec.o
	$(info === Building the zencode-exec utility)
	${zenroom_cc} ${cflags} ${ZEN_SOURCES} src/zencode-exec.o \
		-o $@ ${ldflags} ${ldadd}

include build/deps.mk
