
## tests that require too much memory
himem-tests = \
 @${1} test/sort.lua && \
 ${1} test/literals.lua && \
 ${1} test/pm.lua && \
 ${1} test/nextvar.lua

## GC tests break memory management with umm
# in particular steps (2)
# ${1} test/gc.lua && \
# ${1} test/calls.lua && \



lowmem-tests = \
		@${1} test/vararg.lua && \
		${1} test/utf8.lua && \
		${1} test/tpack.lua && \
		${1} test/strings.lua && \
		${1} test/math.lua && \
		${1} test/goto.lua && \
		${1} test/events.lua && \
		${1} test/code.lua && \
		${1} test/locals.lua && \
		${1} test/schema.lua

crypto-tests = \
	@${1} test/octet.lua && \
	${1} test/hash.lua && \
	${1} test/ecdh.lua && \
	${1} test/ecdh_aes-gcm_vectors.lua && \
	${1} test/big_bls383.lua && \
	${1} test/ecp_bls383.lua && \
	${1} test/pair_bls383.lua

shell-tests = \
	test/octet-json.sh ${1} && \
	test/integration_asymmetric_crypto.sh ${1}

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
	@echo "\t check-osx, check-shared, check-static, check-js"
	@echo "\t check-debug, check-crypto, debug-crypto"

check-osx: test-exec-lowmem := ${pwd}/src/zenroom.command
check-osx: test-exec := ${pwd}/src/zenroom.command
check-osx:
	${test-exec} test/constructs.lua
	$(call lowmem-tests,${test-exec-lowmem})
	$(call crypto-tests,${test-exec-lowmem})
	$(call shell-tests,${test-exec-lowmem})
	@echo "----------------"
	@echo "All tests passed for SHARED binary build"
	@echo "----------------"

check-shared: test-exec-lowmem := ${pwd}/src/zenroom-shared
check-shared: test-exec := ${pwd}/src/zenroom-shared
check-shared:
	${test-exec} test/constructs.lua
	$(call lowmem-tests,${test-exec-lowmem})
	$(call crypto-tests,${test-exec-lowmem})
	$(call shell-tests,${test-exec-lowmem})
	@echo "----------------"
	@echo "All tests passed for SHARED binary build"
	@echo "----------------"


check-static: test-exec := ${pwd}/src/zenroom-static
check-static: test-exec-lowmem := ${pwd}/src/zenroom-static
check-static:
	${test-exec} test/constructs.lua
	$(call lowmem-tests,${test-exec-lowmem})
	$(call crypto-tests,${test-exec-lowmem})
	$(call shell-tests,${test-exec-lowmem})
	@echo "----------------"
	@echo "All tests passed for STATIC binary build"
	@echo "----------------"

check-js: test-exec := nodejs ${pwd}/test/zenroom_exec.js ${pwd}/src/zenroom.js
check-js:
	cp src/zenroom.js.mem .
	$(call lowmem-tests,${test-exec})
	$(call crypto-tests,${test-exec})
	@echo "----------------"
	@echo "All tests passed for JS binary build"
	@echo "----------------"

check-debug: test-exec-lowmem := valgrind --max-stackframe=2064480 ${pwd}/src/zenroom-shared -u -d
check-debug: test-exec := valgrind --max-stackframe=2064480 ${pwd}/src/zenroom-shared -u -d
check-debug:
	$(call lowmem-tests,${test-exec-lowmem})
	$(call crypto-tests,${test-exec})
	@echo "----------------"
	@echo "All tests passed for DEBUG binary build"
	@echo "----------------"

check-crypto: test-exec := ./src/zenroom-shared -d
check-crypto:
	$(call crypto-tests,${test-exec})
	@echo "-----------------------"
	@echo "All CRYPTO tests passed"
	@echo "-----------------------"


debug-crypto: test-exec := valgrind --max-stackframe=2064480 ${pwd}/src/zenroom-shared -u -d
debug-crypto:
	$(call crypto-tests,${test-exec})
	$(call shell-tests,${test-exec-lowmem})

#	./test/integration_asymmetric_crypto.sh ${test-exec}

#	./test/octet-json.sh ${test-exec}

