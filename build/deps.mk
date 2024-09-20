# hard-code build information
.c.o:
	$(gcc) $(cflags) -c $< -o $@ \
	-DVERSION=\"${VERSION}\" \
	-DCURRENT_YEAR=\"${CURRENT_YEAR}\" \
	-DMAKETARGET=\"${MAKECMDGOALS}\" \
	-DCOMMIT=\"${COMMIT}\" \
	-DBRANCH=\"${BRANCH}\" \
	-DCFLAGS="${CFLAGS}"

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

milagro-debug: milagro
milagro:
	@echo "-- Building milagro (${system})"
	if ! [ -r ${pwd}/lib/milagro-crypto-c/build/CMakeCache.txt ]; then \
		cd ${pwd}/lib/milagro-crypto-c && \
		mkdir -p build && \
		cd build && \
		CC=${gcc} LD=${ld} AR=${ar} \
		cmake ../ -DCMAKE_C_FLAGS="${cflags}" -DCMAKE_SYSTEM_NAME="${system}" \
		-DCMAKE_AR=${ar} -DCMAKE_C_COMPILER=${gcc} ${milagro_cmake_flags}; \
	fi
	if ! [ -r ${pwd}/lib/milagro-crypto-c/build/lib/libamcl_core.a ]; then \
		RANLIB=${ranlib} LD=${ld} \
		$(MAKE) -C ${pwd}/lib/milagro-crypto-c/build; \
	fi

mimalloc-debug: mimalloc
mimalloc:
	$(info -- Building mimalloc (${system}))
	if ! [ -r ${pwd}/lib/mimalloc/build/CMakeCache.txt ]; then \
		cd ${pwd}/lib/mimalloc && \
                mkdir -p build && \
                cd build && \
                CC=${gcc} LD=${ld} AR=${AR} \
                cmake ../ ${mimalloc_cmake_flags} \
                -DCMAKE_C_FLAGS="${cflags} ${mimalloc_cflags}" \
                -DCMAKE_SYSTEM_NAME="${system}" \
                -DCMAKE_AR=${ar} -DCMAKE_C_COMPILER=${gcc} \
	        -DCMAKE_CXX_COMPILER=$(subst gcc,g++,${gcc}); \
	fi
	if ! [ -r ${pwd}/lib/mimalloc/build/libmimalloc-static.a ]; then \
                RANLIB=${ranlib} LD=${ld} \
                ${MAKE} -C ${pwd}/lib/mimalloc/build; \
	fi

quantum-proof-ccache: quantum-proof
quantum-proof-debug: quantum-proof
quantum-proof:
	$(info -- Building Quantum-Proof libs)
	CC="${quantum_proof_cc}" \
	LD=${ld} \
	AR=${ar} \
	RANLIB=${ranlib} \
	LD=${ld} \
	CFLAGS="${quantum_proof_cflags} ${cflags}" \
	LDFLAGS="${ldflags}" \
	${MAKE} -C ${pwd}/lib/pqclean

check-milagro: milagro
	CC=${gcc} CFLAGS="${cflags}" $(MAKE) -C ${pwd}/lib/milagro-crypto-c test

ed25519-donna-ccache: ed25519-donna
ed25519-donna:
	echo "-- Building ED25519 for EDDSA"
	CC="${ed25519_cc}" \
	AR=${ar} \
	CFLAGS="${cflags}" \
	LDFLAGS="${ldflags}" \
	$(MAKE) -C ${pwd}/lib/ed25519-donna

tinycc-ccache: tinycc
tinycc:
	$(info -- Building tinycc embedded C compiler)
	cd ${pwd}/lib/tinycc && CC="${gcc}" AR=${ar} CFLAGS="${cflags}"	\
	LDFLAGS="${ldflags}" ./configure --config-musl && make libtcc.a	\
	libtcc1.a
