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

cat <<EOF | zexe hash_left.zen | tee left.json
Given nothing
When I write string 'a left string to be hashed' in 'source'
and I create the hash of 'source'
and I rename 'hash' to 'left'
Then print 'left'
EOF

cat <<EOF | zexe hash_right.zen | tee right.json
Given nothing
When I write string 'a right string to be hashed' in 'source'
and I create the hash of 'source'
and I rename 'hash' to 'right'
Then print 'right'
EOF

cat <<EOF | zexe hash_eq.zen -a left.json -k right.json
Given I have a 'base64' named 'left'
When I write string 'a left string to be hashed' in 'source'
and I create the hash of 'source'
When I verify 'left' is equal to 'hash'
Then print the string 'OK'
EOF

# cat <<EOF | zexe hash_neq.zen -a left.json -k right.json
# Given I have a 'base64' named 'left'
# and I have a 'base64' named 'right'
# When I verify 'left' is equal to 'right'
# Then print the string 'OK'
# EOF

cat <<EOF | zexe num_eq_base10.zen
rule check version 1.0.0
Given nothing
When I write number '42' in 'left'
and I write number '42' in 'right'
and I verify 'left' is equal to 'right'
Then print the string 'OK'
EOF

# cat <<EOF | zexe num_neq_base10.zen
# rule check version 1.0.0
# Given nothing
# When I write number '142' in 'left'
# and I write number '42' in 'right'
# and I verify 'left' is equal to 'right'
# Then print the string 'OK'
# EOF


cat <<EOF | zexe cmp_base10.zen
rule check version 1.0.0
Given nothing
When I write number '10' in 'left'
and I write number '20' in 'right'
and number 'left' is less or equal than 'right'
Then print the string 'OK'
EOF

# cat <<EOF | zexe cmp_nlt_base10.zen
# rule check version 1.0.0
# Given nothing
# When I write number '10' in 'left'
# and I write number '20' in 'right'
# and number 'right' is less than 'left'
# Then print the string 'OK'
# EOF



cat <<EOF | zexe cmp_base16.zen
rule check version 1.0.0
Given nothing
When I set 'left' to '0a' base '16'
and I set 'right' to '14' base '16'
and number 'left' is less or equal than 'right'
Then print the string 'OK'
EOF

cat <<EOF | zexe cmp_base16_less.zen
rule check version 1.0.0
Given nothing
When I set 'left' to '0a' base '16'
and I set 'right' to '14' base '16'
and number 'left' is less than 'right'
Then print the string 'OK'
EOF

success
