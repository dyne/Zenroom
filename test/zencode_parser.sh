#!/usr/bin/env zsh

echo "============================="
echo " ZENCODE SYNTAX PARSER TESTS"
echo "============================="
echo "ERRORS ARE OK IN THIS SECTION"

alias zenroom="${1:-./src/zenroom}"

[[ -r test ]] || {
    print "Run from base directory: ./test/$0"
    return 1
}

if ! test -r ./test/utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ./test/utils.sh

run_zenroom_on_cortexm_qemu(){
	qemu_zenroom_run "$*"
	cat ./outlog
}

if [[ "$1" == "cortexm" ]]; then
	zenroom=run_zenroom_on_cortexm_qemu
fi

tmpfile=`mktemp`

set -e

cat << EOF > $tmpfile && $zenroom $tmpfile -z
rule check version 1.0.0
Scenario credential: credential keygen
Given that I am known as 'Alice'
When I create the credential keypair
Then print my 'credential keypair'
EOF

cat << EOF > $tmpfile && $zenroom $tmpfile -z
rule check version 1.0.0
Scenario credential: issuer keygen
Given that I am known as 'MadHatter'
When I create the issuer keypair
Then print my 'issuer keypair'
EOF


cat << EOF > $tmpfile && $zenroom $tmpfile -z
rule check version 1.0.0
rule unknown ignore
Scenario credential: issuer keygen
Given that I am known as 'MadHatter'
When I create the issuer keypair
and I don't know what I am doing
Then print my 'issuer keypair'
EOF

set +e
# force error: check processing stop

cat << EOF > $tmpfile && $zenroom $tmpfile -z
rule check version 1.0.0
Scenario credential: issuer keygen
Given that I am known as 'MadHatter'
0YOUI4qhIeXmIpyK
Then print 'Success' 'OK'
EOF
[[ $? == 0 ]] && return 1

cat << EOF > $tmpfile && $zenroom $tmpfile -z
rule check version 1.0.0
Scenario credential: issuer keygen
Given that I am known as 'MadHatter'
and 0YOUI4qhIeXmIpyK
Then print 'Success' 'OK'
EOF
[[ $? == 0 ]] && return 1

cat << EOF > $tmpfile && $zenroom $tmpfile -z
rule check version 1.0.0
Scenario credential: issuer keygen
Given that I am known as 'MadHatter'
Given 0YOUI4qhIeXmIpyK
Then print 'Success' 'OK'
EOF
[[ $? == 0 ]] && return 1

cat << EOF > $tmpfile && $zenroom $tmpfile -z
rule check version 1.0.0
Scenario credential: issuer keygen
Given that I am known as 'MadHatter'
When I create the issuer keypair
and this should fail or 'rule unknown ignore'
Then print my 'issuer keypair'
EOF
[[ $? == 0 ]] && return 1

echo " END OF SYNTAX PARSERS TESTS"
echo "============================="
echo " NO MORE ERRORS SHOULD APPEAR"
echo
echo

rm -rf $tmpfile
