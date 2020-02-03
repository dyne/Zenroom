#!/bin/sh


alias zenroom="${1:-./src/zenroom}"

#t=`mktemp -d`

cat <<EOF | zenroom -z
rule output encoding hex
Given nothing
When I write 'a string to be hashed' in 'source'
and I create the hash of 'source'
Then print the 'hash'
EOF


cat <<EOF | zenroom -z
rule output encoding base64
Given nothing
When I write 'a string to be hashed' in 'source'
and I create the hash of 'source' using 'sha512'
Then print the 'hash'
EOF


cat <<EOF | zenroom -z
rule output encoding url64
Given nothing
When I write 'a string to be hashed' in 'source'
and I create the hash of 'source' using 'sha256'
Then print the 'hash'
EOF
