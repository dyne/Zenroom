#!/usr/bin/env bash

[[ -r test ]] || {
    print "Run from base directory: ./test/$0"
    return 1
}

if ! test -r ./test/utils.sh; then
    echo "run executable from its own directory: $0"; exit 1; fi
. ./test/utils.sh

run_zenroom_on_cortexm_qemu() {
	qemu_zenroom_run "$*"
	cat ./outlog
}

if [[ "$1" == "cortexm" ]]; then
	zen=run_zenroom_on_cortexm_qemu
fi

crypto_tests=(
	test/octet.lua
	test/octet_conversion.lua
	test/hash.lua
	test/ecdh.lua
	test/dh_session.lua
	test/nist/aes_gcm.lua
	test/nist/aes_cbc.lua
	test/nist/aes_ctr.lua
	test/ecp_generic.lua
	test/elgamal.lua
	test/bls_pairing.lua
	test/coconut_test.lua
	test/crypto_abc_zeta.lua
)

len=${#crypto_tests[@]}
for ((i=0; i < len; i++)); do
    run_zenroom_on_cortexm_qemu ${crypto_tests[$i]}
done
