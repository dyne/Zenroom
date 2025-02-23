# hard-code build information
.c.o:
	$(zenroom_cc) \
	$(cflags) \
	-c $< -o $@ \
	-DVERSION=\"${VERSION}\" \
	-DCURRENT_YEAR=\"${CURRENT_YEAR}\" \
	-DCOMMIT=\"${COMMIT}\" \
	-DBRANCH=\"${BRANCH}\" \
	-DCFLAGS="${cflags}"

embed-lua: lua_embed_opts := $(if ${COMPILE_LUA}, compile)
embed-lua:
	@echo "Embedding all files in src/lua"
	./build/embed-lualibs ${lua_embed_opts}
	@echo "File generated: src/lualibs_detected.c"

src/zen_ecdh_factory.c:
	${pwd}/build/codegen_ecdh_factory.sh ${ecdh_curve}

src/zen_ecp_factory.c:
	${pwd}/build/codegen_ecp_factory.sh ${ecp_curve}

src/zen_big_factory.c:
	${pwd}/build/codegen_ecp_factory.sh ${ecp_curve}

apply-patches: src/zen_ecdh_factory.c src/zen_ecp_factory.c src/zen_big_factory.c

lua54:
	CC="${lua_cc}" CFLAGS="${cflags} ${lua_cflags}" \
	LDFLAGS="${ldflags}" AR="${ar}" RANLIB=${ranlib} \
	$(MAKE) -C ${pwd}/lib/lua54/src liblua.a

milagro:
	@echo "-- Building milagro (${system})"
	if ! [ -r ${pwd}/lib/milagro-crypto-c/build/CMakeCache.txt ]; then \
		cd ${pwd}/lib/milagro-crypto-c && \
		mkdir -p build && \
		cd build && \
		CC=${cc} LD=${ld} AR=${ar} \
		cmake ../ -DCMAKE_C_FLAGS="${cflags}" -DCMAKE_SYSTEM_NAME="${system}" \
		-DCMAKE_AR=${ar} -DCMAKE_C_COMPILER=${cc} ${milagro_cmake_flags}; \
	fi
	if ! [ -r ${pwd}/lib/milagro-crypto-c/build/lib/libamcl_core.a ]; then \
		RANLIB=${ranlib} LD=${ld} \
		$(MAKE) -C ${pwd}/lib/milagro-crypto-c/build; \
	fi

quantum-proof:
	$(info -- Building Quantum-Proof libs)
	CC="${quantum_proof_cc}" \
	LD=${ld} \
	AR=${ar} \
	RANLIB=${ranlib} \
	CFLAGS="${quantum_proof_cflags} ${cflags}" \
	LDFLAGS="${ldflags}" \
	${MAKE} -C ${pwd}/lib/pqclean

check-milagro: milagro
	CC=${cc} CFLAGS="${cflags}" $(MAKE) -C ${pwd}/lib/milagro-crypto-c test

ed25519-donna:
	echo "-- Building ED25519 for EDDSA"
	CC="${ed25519_cc}" \
	AR=${ar} \
	CFLAGS="${cflags}" \
	LDFLAGS="${ldflags}" \
	$(MAKE) -C ${pwd}/lib/ed25519-donna

mlkem:
	$(info -- Building MLKEM Native PQ lib)
	CC="${mlkem_cc}" \
	AR=${ar} \
	LD=${ld} \
	RANLIB=${ranlib} \
	CFLAGS="${mlkem_cflags} ${cflags}" \
	LDFLAGS="${mkkem_ldflags} ${ldflags}" \
	${MAKE} -C ${pwd}/lib/mlkem \
			test/build/libmlkem.a \
			OPT=0 Q="" AUTO=0
