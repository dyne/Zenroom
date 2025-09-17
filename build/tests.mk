
prepare-executables:
	echo '#!/bin/sh' > ${pwd}/test/zenroom
	echo "${pwd}/src/zenroom "'$$*' >> ${pwd}/test/zenroom
	chmod +x ${pwd}/test/zenroom
	echo '#!/bin/sh' > ${pwd}/test/zencode-exec
	echo "${pwd}/src/zencode-exec "'$$*' >> ${pwd}/test/zencode-exec
	chmod +x ${pwd}/test/zencode-exec

.PHONY: prepare-executables

# bats function
bats = @test/bats/bin/bats $(1)
bats_file = @test/bats/bin/bats $(1).bats
# temporary target for testing the tests
check-bats: prepare-executables
	@cp -v src/zenroom test/zenroom
	$(call bats, test/lua)
	$(call bats, test/determinism)
	$(call bats, test/zencode)

# ECP arithmetic test vectors from milagro, removed from normal tests
# since in zenroom built without debug is not allowed to import an ECP
# from x/y coords.
# ${1} test/ecp_bls383.lua && \
# ${1} test/big_bls383.lua && \
# ${1} test/ecdsa_vectors.lua && \

check:
	@echo "Test target 'check' supports various modes, please specify one:"
	@echo "\t check-linux, check-osx, check-js, check-py, check-rs, check-go"
	@echo "For an efficient test suite, use target: meson-test"

luacheck:
	@echo "Running Luacheck analysis (requires lua-check installed)"
	luacheck --config src/lua/.luacheckrc --codes src/lua/**.lua

check-osx: test-exec := ./src/zenroom
check-osx: prepare-executables
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
check-linux: prepare-executables
	@cp -v ${test-exec} test/zenroom
	rm -f /tmp/zenroom-test-summary.txt
	$(call bats, test/lua)
	$(call bats, test/determinism)
	$(call crypto-integration,${test-exec})
	$(call zencode-integration,${test-exec})
	@echo "----------------"
	@echo "All tests passed for LINUX binary build"
	@echo "----------------"


check-js: test-exec := node ${pwd}/test/zenroom_exec.js ${pwd}/zenroom.js
check-js:
	@echo "#!/bin/sh\n${test-exec} \$$@\n" > test/zenroom && chmod +x test/zenroom
	$(call bats, test/lua/native.bats)
	$(call bats, test/lua/crypto.bats)
	@echo "----------------"
	@echo "All tests passed for JS binary build"
	@echo "----------------"

check-py: test-exec := python3 ${pwd}/test/zenroom_exec.py
check-py:
	@echo -e "#!/bin/sh\n${test-exec} \$$@\n" > test/zenroom && chmod +x test/zenroom
	$(call bats, test/lua/native.bats)
	$(call bats, test/lua/crypto.bats)
	@echo "----------------"
	@echo "All tests passed for PYTHON build"
	@echo "----------------"

check-rs: test-exec := ${pwd}/test/zenroom_exec_rs/target/debug/zenroom_exec_rs
check-rs:
	cargo build --manifest-path ${pwd}/test/zenroom_exec_rs/Cargo.toml
	@echo -e "#!/bin/sh\n${test-exec} \$$@\n" > test/zenroom && chmod +x test/zenroom
	$(call bats, test/lua/native.bats)
	$(call bats, test/lua/crypto.bats)
	@echo "----------------"
	@echo "All tests passed for RUST build"
	@echo "----------------"

check-go: test-exec := ${pwd}/test/zenroom_exec_go/main
check-go:
	cd ${pwd}/test/zenroom_exec_go && go build
	@echo -e "#!/bin/sh\n${test-exec} \$$@\n" > test/zenroom && chmod +x test/zenroom
	$(call bats, test/lua/native.bats)
	$(call bats, test/lua/crypto.bats)
	@echo "----------------"
	@echo "All tests passed for GO build"
	@echo "----------------"
