COMPILER ?= gcc
COMPILER_CXX ?= g++

cc := ${COMPILER}
cxx := ${COMPILER_CXX}

quantum_proof_cc := ${cc}
zenroom_cc := ${cc}
ed25519_cc := ${cc}
lua_cc := ${cc}
longfellow_cxx := ${cxx}
zstd_cc := ${cc}
zk-circuit-lang_cxx := ${cxx}

ifdef RELEASE
	cflags +=  -O3 ${cflags_protection}
else
	cflags += ${cflags_debug}
endif

ifdef GPROF
	cflags += -pg
endif

ifdef LIBRARY
	cflags += -fPIC -DLIBRARY
endif

ifdef CCACHE
	milagro_cmake_flags += -DCMAKE_C_COMPILER_LAUNCHER=ccache
	quantum_proof_cc := ccache ${cc}
	mlkem_cc := ccache ${cc}
	zenroom_cc := ccache ${cc}
	ed25519_cc := ccache ${cc}
	libtcc_cc := ccache ${cc}
	lua_cc := ccache ${cc}
	zstd_cc := ccache ${cc}
	longfellow_cxx := ccache ${cxx}
	zk-circuit-lang_cxx := ccache ${cxx}
endif
