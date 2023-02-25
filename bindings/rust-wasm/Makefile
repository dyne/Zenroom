include ../../build/config.mk

all:
	@cd ../.. && ./build/codegen_ecp_factory.sh BLS381
	@cd ../.. && ./build/codegen_ecdh_factory.sh SECP256K1
	@cd ../.. && ./build/embed-lualibs
	@mkdir -p ../../lib/milagro-crypto-c/build
	@cd ../../lib/milagro-crypto-c/build && cmake					\
	.. -DCMAKE_C_FLAGS="${cflags}" -DCMAKE_SYSTEM_NAME="${system}"	\
	-DCMAKE_AR=${ar} -DCMAKE_C_COMPILER=${gcc}						\
	${milagro_cmake_flags};
	cargo build
