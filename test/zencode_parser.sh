#!/usr/bin/env zsh

echo "==========================="
echo "Zencode syntax parser tests"
alias zenroom="${1:-./src/zenroom}"
set -e

cat << EOF | zenroom -z
rule check version 1.0.0
Scenario coconut: credential keygen
Given that I am known as 'Alice'
When I create the credential keypair
Then print my 'credential keypair'
EOF

cat << EOF | zenroom -z
rule check version 1.0.0
Scenario coconut: issuer keygen
Given that I am known as 'MadHatter'
When I create the issuer keypair
Then print my 'issuer keypair'
EOF

set +e
# force error: check processing stop

cat << EOF | zenroom -z
rule check version 1.0.0
Scenario coconut: issuer keygen
Given that I am known as 'MadHatter'
0YOUI4qhIeXmIpyK
Then print 'Success' 'OK'
EOF
[[ $? == 0 ]] && return 1

cat << EOF | zenroom -z
rule check version 1.0.0
Scenario coconut: issuer keygen
Given that I am known as 'MadHatter'
and 0YOUI4qhIeXmIpyK
Then print 'Success' 'OK'
EOF
[[ $? == 0 ]] && return 1

cat << EOF | zenroom -z
rule check version 1.0.0
Scenario coconut: issuer keygen
Given that I am known as 'MadHatter'
Given 0YOUI4qhIeXmIpyK
Then print 'Success' 'OK'
EOF
[[ $? == 0 ]] && return 1

echo 'OK'
