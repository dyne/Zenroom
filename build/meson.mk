
TARGETS := apply-patches milagro lua53 embed-lua zstd quantum-proof

# .PHONY: meson meson-re meson-test

prepare-meson:
	mkdir -p ${pwd}/meson
	ln -sf ${pwd}/lib/milagro-crypto-c/build ${pwd}/meson/milagro-crypto-c
	ln -sf ${pwd}/lib/zstd/libzstd.a ${pwd}/meson/libzstd.a
	ln -sf ${pwd}/lib/pqclean/libqpz.a ${pwd}/meson/libqpz.a
	ln -sf ${pwd}/lib/lua53/src/liblua.a ${pwd}/meson/liblua.a

run-meson:
	CC=${gcc} AR="${ar}"  CFLAGS="${cflags}" LDFLAGS="${ldflags}" LDADD="${ldadd}" \
	meson -Dexamples=true -Ddocs=true -Doptimization=3 \
	-Decdh_curve=${ecdh_curve} -Decp_curve=${ecp_curve} \
	-Ddefault_library=static build meson

meson: linux-meson-clang-debug

linux-meson-release: ${TARGETS} prepare-meson run-meson
	ninja -C meson

linux-meson-clang-release: ${TARGETS} prepare-meson run-meson
	ninja -C meson

linux-meson-debug: ${TARGETS} prepare-meson run-meson
	ninja -C meson

linux-meson-clang-debug: ${TARGETS} prepare-meson run-meson
	ninja -C meson

meson-test:
	ninja -C meson test

meson-analyze:
	SCANBUILD=$(pwd)/build/scanbuild.sh ninja -C meson scan-build
