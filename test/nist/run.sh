#!/usr/bin/env zsh

echo "============================="
echo " HASH VECTOR TESTS FROM NIST "
echo "============================="

alias zenroom="${1:-../../src/zenroom}"


check() {
	tmp=`mktemp`
	echo -n $1 > $tmp
	echo "== $1 ShortMsg"
	zenroom -a ${1}ShortMsg.rsp -k $tmp check_rsp.lua
	echo "== $1 LongMsg"
	zenroom -a ${1}LongMsg.rsp  -k $tmp check_rsp.lua
	rm -f $tmp
}

check "SHA256"
check "SHA512"

# TODO: fix sha384 match to nist vectors
# check "SHA384"
# TODO: fix sha3_* match to nist vectors
# check "SHA3_256"
# check "SHA3_512"
