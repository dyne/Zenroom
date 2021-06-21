#!/bin/sh

# TODO: correct import / export of hex and bin

alias zenroom='${1:-../../src/zenroom}' # -c memmanager=\"lw\"'

cat <<EOF | zenroom -z | tee alice_conversion.json
rule output encoding base64
Scenario ecdh
Given I am 'Alice'
When I create the keypair
Then print my 'keypair'
EOF

cat <<EOF | zenroom -z -a alice_conversion.json
rule input encoding base64
rule output encoding bin
Given I have a 'keypair' in 'Alice'
Then print all data
EOF

cat <<EOF | zenroom -z -a alice_conversion.json | tee abase.json
rule input encoding url64
rule output encoding base64
rule output format json
Scenario ecdh
Given I am 'Alice'
and I have my valid 'keypair'
Then print my 'keypair'
EOF


# cat <<EOF | zenroom -z -a abase.json | tee ahex.json
# rule input encoding base64
# rule output encoding hex
# rule output format json
# Given I am 'Alice'
# and I have my valid 'keypair'
# Then print my 'keypair'
# EOF

# cat <<EOF | zenroom -z -a alice_conversion.json | tee abin.json
# rule input encoding hex
# rule output encoding bin
# rule output format json
# Given I am 'Alice'
# and I have my valid 'keypair'
# Then print my 'keypair'
# EOF


cat <<EOF | zenroom -z -a abase.json
rule input encoding base64
rule output encoding hex
rule output format json
Scenario ecdh
Given I am 'Alice'
and I have my valid 'keypair'
Then print my 'keypair'
EOF

