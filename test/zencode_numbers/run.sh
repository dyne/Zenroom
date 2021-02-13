#!/usr/bin/env bash


####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh

is_cortexm=false
if [[ "$1" == "cortexm" ]]; then
	is_cortexm=true
fi

Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

cat <<EOF | zexe hash_string.zen | tee hex.json
rule output encoding hex
Given nothing
When I write string 'a string to be hashed' in 'source'
and I create the hash of 'source'
Then print the 'hash'
EOF

cat <<EOF | zexe cmp_base10.zen
rule check version 1.0.0
Given nothing
When I write number '10' in 'left'
and I write number '20' in 'right'
and number 'left' is less or equal than 'right'
Then print 'OK'
EOF


cat <<EOF | zexe cmp_base16.zen
rule check version 1.0.0
Given nothing
When I set 'left' to '0a' base '16'
and I set 'right' to '14' base '16'
and number 'left' is less or equal than 'right'
Then print 'OK'
EOF

cat <<EOF | zexe cmp_base16_less.zen
rule check version 1.0.0
Given nothing
When I set 'left' to '0a' base '16'
and I set 'right' to '14' base '16'
and number 'left' is less than 'right'
Then print 'OK'
EOF

success
