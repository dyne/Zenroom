
TARGETS := ${BUILDS}

# .PHONY: meson meson-re meson-test

prepare-meson:
	mkdir -p ${pwd}/meson
	ln -sf ${pwd}/lib/milagro-crypto-c/build ${pwd}/meson/milagro-crypto-c
	ln -sf ${pwd}/lib/pqclean/libqpz.a ${pwd}/meson/libqpz.a
	ln -sf ${pwd}/lib/lua53/src/liblua.a ${pwd}/meson/liblua.a
	ln -sf ${pwd}/lib/ed25519-donna/libed25519.a ${pwd}/meson/libed25519.a
	ln -sf ${pwd}/lib/blake2/libblake2.a ${pwd}/meson/libblake2.a
	ln -sf ${pwd}/lib/mimalloc/build/libmimalloc-static.a ${pwd}/meson/libmimalloc-static.a

run-meson:
	CC="${gcc}" AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	meson -Dexamples=true -Ddocs=true -Doptimization=3 \
	-Decdh_curve=${ecdh_curve} -Decp_curve=${ecp_curve} \
	-Ddefault_library=both build meson

asan-meson:
	CC="clang" CXX="clang++" AR="llvm-ar"  CFLAGS="-fsanitize=address -fno-omit-frame-pointer" LDFLAGS="-fsanitize=address ${ldflags}" LDADD="${ldadd}" \
	meson -Dexamples=false -Ddocs=false -Doptimization=0 \
	-Decdh_curve=${ecdh_curve} -Decp_curve=${ecp_curve} \
	-Ddefault_library=both -Db_sanitize=address build meson

meson: linux-meson
meson-ccache: linux-meson
meson-debug:  linux-meson
meson-debug-ccache: linux-meson
meson-clang-ccache: linux-meson
meson-clang-debug-ccache: linux-meson

linux-meson: ${TARGETS} prepare-meson run-meson
	ninja -C meson

linux-meson-release: ${TARGETS} prepare-meson run-meson
	ninja -C meson

linux-meson-clang-release: ${TARGETS} prepare-meson run-meson
	ninja -C meson

linux-meson-debug: ${TARGETS} prepare-meson run-meson
	ninja -C meson

linux-meson-clang-debug: ${TARGETS} prepare-meson run-meson
	ninja -C meson

linux-meson-asan: ${TARGETS} prepare-meson asan-meson
	ninja -C meson

meson-test:
	echo '#!/bin/sh' > ${pwd}/test/zenroom
	echo "${pwd}/meson/zenroom "'$$*' >> ${pwd}/test/zenroom
	chmod +x ${pwd}/test/zenroom
	echo '#!/bin/sh' > ${pwd}/test/zencode-exec
	echo "${pwd}/meson/zencode-exec "'$$*' >> ${pwd}/test/zencode-exec
	chmod +x ${pwd}/test/zencode-exec
	ninja -C meson test

meson-analyze:
	SCANBUILD=$(pwd)/build/scanbuild.sh ninja -C meson scan-build
