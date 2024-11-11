COMPILER ?= gcc

cc := ${COMPILER}

quantum_proof_cc := ${cc}
zenroom_cc := ${cc}
ed25519_cc := ${cc}
libtcc_cc := ${cc}
lua_cc := ${cc}

ifdef CCACHE
	milagro_cmake_flags += -DCMAKE_C_COMPILER_LAUNCHER=ccache
	quantum_proof_cc := ccache ${cc}
	zenroom_cc := ccache ${cc}
	ed25519_cc := ccache ${cc}
	libtcc_cc := ccache ${cc}
	lua_cc := ccache ${cc}
endif
