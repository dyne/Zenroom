
# bats function
bats = @test/bats/bin/bats $(1)
bats_file = @test/bats/bin/bats $(1).bats
# temporary target for testing the tests
check-bats:
	@cp -v src/zenroom test/zenroom
	$(call bats, test/lua)
	$(call bats, test/determinism)
	$(call bats, test/zencode)

# removed for memory usage in wasm
#	    ${1} test/coroutine.lua

# ECP arithmetic test vectors from milagro, removed from normal tests
# since in zenroom built without debug is not allowed to import an ECP
# from x/y coords.
# ${1} test/ecp_bls383.lua && \
# ${1} test/big_bls383.lua && \
# ${1} test/ecdsa_vectors.lua && \

cortex-m-crypto-tests = \
	${1}test/octet.lua && \
	${1}test/octet_conversion.lua && \
	${1}test/hash.lua && \
	${1}test/ecdh.lua && \
	${1}test/dh_session.lua && \
	${1}test/crypto_nist/aes_gcm.lua && \
	${1}test/crypto_nist/aes_cbc.lua && \
	${1}test/crypto_nist/aes_ctr.lua && \
	${1}test/ecp_generic.lua && \
	${1}test/elgamal.lua && \
	${1}test/bls_pairing.lua && \
	${1}test/coconut_test.lua && \
	${1}test/coconut_abc_zeta.lua

cortex-m-crypto-tests = \
	test/cortex_m_crypto_tests.sh

cortex-m-zencode-integration = \
	./test/zencode_parser.sh ${1} && \
	cd test/zencode_given && ./run.sh ${1}; cd -; \
	cd test/zencode_cookbook && ./run-all.sh ${1}; cd -; \
	cd test/zencode_numbers && ./run.sh ${1}; cd -; \
	cd test/zencode_random && ./run.sh ${1}; cd -; \
	cd test/zencode_array && ./run.sh ${1}; cd -; \
	cd test/zencode_dictionary && ./run.sh ${1}; cd -; \
	cd test/zencode_hash && ./run.sh ${1}; cd -; \
	cd test/zencode_http && ./run.sh ${1}; cd -; \
	cd test/zencode_ecdh && ./run.sh ${1}; cd -; \
	cd test/zencode_eddsa && ./run.sh ${1}; cd -; \
	cd test/zencode_secshare && ./run.sh ${1}; cd -; \
	cd test/zencode_credential && ./run.sh ${1}; cd -; \
	cd test/zencode_petition && ./run.sh ${1}; cd -;

cortex-m-crypto-integration = \
	test/octet-json.sh ${1} && \
	test/integration_asymmetric_crypto.sh ${1}

crypto-integration = \
	$(call bats, test/vectors/sha.bats test/vectors/eddsa.bats test/vectors/qp.bats test/vectors/blake2.bats) || exit 1; \
	cd test/crypto_json &&  ./run.sh ${1}; cd -; \
	cd test/crypto_ecdh &&  ./run.sh ${1}; cd -;

# TODO: complete with tamale and date
lua-modules = \
	@${1} test/faces.lua && \
	${1} test/slaxml.lua

zencode-integration = \
	$(call bats, test/zencode);



# ${1} test/closure.lua && \

# failing js tests due to larger memory required:
# abort("Cannot enlarge memory arrays. Either (1) compile with -s
# TOTAL_MEMORY=X with X higher than the current value 16777216, (2)
# compile with -s ALLOW_MEMORY_GROWTH=1 which allows increasing the
# size at runtime but prevents some optimizations, (3) set
# Module.TOTAL_MEMORY to a higher value before the program runs, or
# (4) if you want malloc to return NULL (0) instead of this abort,
# compile with -s ABORTING_MALLOC=0 ") at Error
# himem:
#  ${1} test/constructs.lua && \
#  ${1} test/cjson-test.lua
# lowmem:
#  ${1} test/coroutine.lua && \

# these all pass but require cjson_full to run
# 	${test-exec} test/cjson-test.lua

# these require the debug extension too much
# ${test-exec} test/coroutine.lua

# these may serve to verify the boundary of maximum memory
# since some trigger warnings when compiled with full debug
# $(call himem-tests,${test-exec})

check:
	@echo "Test target 'check' supports various modes, please specify one:"
	@echo "\t check-linux, check-osx, check-js check-py"
	@echo "\t check-debug, check-crypto, debug-crypto"
	@echo "\t check-cortex-m"

check-osx: test-exec := ./src/zenroom.command
check-osx:
	@cp -v ${test-exec} test/zenroom
	$(call bats, test/lua)
	$(call bats, test/determinism)
	rm -f /tmp/zenroom-test-summary.txt
	$(call crypto-integration,${test-exec})
	$(call zencode-integration,${test-exec})
	@echo "----------------"
	@echo "All tests passed for OSX binary build"
	@echo "----------------"

check-linux: test-exec := ./src/zenroom
check-linux:
	@cp -v ${test-exec} test/zenroom
	rm -f /tmp/zenroom-test-summary.txt
	$(call bats, test/lua)
	$(call bats, test/determinism)
	$(call crypto-integration,${test-exec})
	$(call zencode-integration,${test-exec})
	@echo "----------------"
	@echo "All tests passed for LINUX binary build"
	@echo "----------------"


check-js: test-exec := node ${pwd}/test/zenroom_exec.js ${pwd}/src/zenroom.js
check-js:
	@echo -e "#!/bin/sh\n${test-exec} \$$@\n" > test/zenroom && chmod +x test/zenroom
	$(call bats, test/lua/lowmem.bats)
	$(call bats, test/lua/crypto.bats)
	@echo "----------------"
	@echo "All tests passed for JS binary build"
	@echo "----------------"

check-py: test-exec := python3 ${pwd}/test/zenroom_exec.py
check-py:
	@echo -e "#!/bin/sh\n${test-exec} \$$@\n" > test/zenroom && chmod +x test/zenroom
	$(call bats, test/lua/lowmem.bats)
	$(call bats, test/lua/crypto.bats)
	@echo "----------------"
	@echo "All tests passed for PYTHON build"
	@echo "----------------"

check-rs: test-exec := ${pwd}/test/zenroom_exec_rs/target/debug/zenroom_exec_rs
check-rs:
	cargo build --manifest-path ${pwd}/test/zenroom_exec_rs/Cargo.toml
	@echo -e "#!/bin/sh\n${test-exec} \$$@\n" > test/zenroom && chmod +x test/zenroom
	$(call bats, test/lua/lowmem.bats)
	$(call bats, test/lua/crypto.bats)
	@echo "----------------"
	@echo "All tests passed for RUST build"
	@echo "----------------"

check-go: test-exec := ${pwd}/test/zenroom_exec_go/main
check-go:
	cd ${pwd}/test/zenroom_exec_go && go build
	@echo -e "#!/bin/sh\n${test-exec} \$$@\n" > test/zenroom && chmod +x test/zenroom
	$(call bats, test/lua/lowmem.bats)
	$(call bats, test/lua/crypto.bats)
	@echo "----------------"
	@echo "All tests passed for GO build"
	@echo "----------------"

check-debug: test-exec := valgrind --max-stackframe=5000000 ${pwd}/src/zenroom
check-debug:
	@echo "#!/bin/sh\n${test-exec}\n" > test/zenroom && chmod +x test/zenroom
	rm -f /tmp/zenroom-test-summary.txt
	$(call bats, test/lua/lowmem.bats)
	$(call bats, test/lua/crypto.bats)
	cat /tmp/zenroom-test-summary.txt
	@echo "----------------"
	@echo "All tests passed for DEBUG binary build"
	@echo "----------------"

# $(call determinism-tests,${test-exec})

check-crypto: test-exec := ./src/zenroom
check-crypto:
	@cp -v ${test-exec} test/zenroom
	$(call bats, test/lua/crypto.bats)
	$(call bats, test/determinism)

# $(call determinism-tests,${test-exec})
# $(call crypto-tests,${test-exec})
# $(call crypto-integration,${test-exec})
# $(call zencode-integration,${test-exec})
# cat /tmp/zenroom-test-summary.txt
# @echo "-----------------------"
# @echo "All CRYPTO tests passed"
# @echo "-----------------------"

check-crypto-lw: test-exec := ./src/zenroom -c memmanager=lw
check-crypto-lw:
	rm -f /tmp/zenroom-test-summary.txt
	$(call bats, test/determinism)
	$(call bats, test/lua/crypto.bats)
	$(call zencode-integration,${test-exec})
	cat /tmp/zenroom-test-summary.txt
	@echo "-----------------------"
	@echo "All CRYPTO tests passed with lw memory manager"
	@echo "-----------------------"


check-crypto-stb: test-exec := ./src/zenroom -c print=stb
check-crypto-stb:
	rm -f /tmp/zenroom-test-summary.txt
	$(call bats, test/determinism)
	$(call bats, test/lua/crypto.bats)
	$(call zencode-integration,${test-exec})
	cat /tmp/zenroom-test-summary.txt
	@echo "-----------------------"
	@echo "All CRYPTO tests passed with lw memory manager"
	@echo "-----------------------"

check-crypto-mutt: test-exec := ./src/zenroom -c print=mutt
check-crypto-mutt:
	rm -f /tmp/zenroom-test-summary.txt
	$(call bats, test/determinism)
	$(call bats, test/lua/crypto.bats)
	$(call zencode-integration,${test-exec})
	cat /tmp/zenroom-test-summary.txt
	@echo "-----------------------"
	@echo "All CRYPTO tests passed with lw memory manager"
	@echo "-----------------------"

check-crypto-debug: test-exec := valgrind --max-stackframe=5000000 ${pwd}/src/zenroom
check-crypto-debug:
	@echo "#!/bin/sh\n${test-exec}\n" > test/zenroom && chmod +x test/zenroom
	rm -f /tmp/zenroom-test-summary.txt
	$(call bats, test/lua/crypto.bats)
	cat /tmp/zenroom-test-summary.txt

check-cortex-m:
	rm -f /tmp/zenroom-test-summary.txt
	rm -f ./outlog
	$(call cortex-m-crypto-tests)
	$(call cortex-m-crypto-integration,cortexm)
	$(call cortex-m-zencode-integration,cortexm)
	cat /tmp/zenroom-test-summary.txt
	@echo "-----------------------"
	@echo "All CRYPTO tests passed"
	@echo "-----------------------"

#	./test/integration_asymmetric_crypto.sh ${test-exec}

#	./test/octet-json.sh ${test-exec}

