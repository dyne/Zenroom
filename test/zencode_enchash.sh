#!/bin/sh


alias zenroom="${1:-./src/zenroom}"

t=`mktemp -d`

cat <<EOF | zenroom -z | tee $t/hex.json
rule output encoding hex
Given nothing
When I write string 'a string to be hashed' in 'source'
and I create the hash of 'source'
Then print the 'hash'
EOF


cat <<EOF | zenroom -z -a $t/hex.json
rule input encoding hex
rule input untagged
rule output encoding hex
Given I have a 'hash'
When I set 'myhash' to 'c24463f5e352da20cb79a43f97436cce57344911e1d0ec0008cbedb5fabcca33' as 'hex'
and I verify 'myhash' is equal to 'hash'
Then print the 'hash'
EOF

cat <<EOF | zenroom -z | tee $t/base64.json
rule output encoding base64
Given nothing
When I write string 'a string to be hashed' in 'source'
and I create the hash of 'source' using 'sha512'
Then print the 'hash'
EOF


cat <<EOF | zenroom -z | tee $t/url64.json
rule output encoding url64
Given nothing
When I write string 'a string to be hashed' in 'source'
and I create the hash of 'source' using 'sha256'
Then print the 'hash'
EOF

