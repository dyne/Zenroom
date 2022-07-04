#!/usr/bin/env bash

####################
# common script init
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

cat <<EOF | zexe copy_random.zen
Given nothing

When I create the random 'random'
When I copy 'random' to 'dest'

Then print 'random'
Then print 'dest'
EOF

cat <<EOF | save random zeroseed.json
{"zeroseed": "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"}
EOF
cat <<EOF | debug seed.zen -a zeroseed.json
Given I have a 'hex' named 'zeroseed'

When I create the random object of '16' bytes
and I rename 'random object' to 'first'

When I seed the random with 'zeroseed'
and I create the random object of '16' bytes

When I verify 'random object' is equal to 'first'

Then print string 'random seed OK'
EOF

cat <<EOF | zexe random_from_array.zen
rule check version 1.0.0
Given nothing
When I create the array of '32' random objects of '256' bits
and I pick the random object in 'array'
and I remove the 'random object' from 'array'
and the 'random object' is not found in 'array'
Then print the 'random object'
EOF

cat <<EOF | zexe array_32_256.zen | save random arr.json
rule output encoding url64
Given nothing
When I create the array of '32' random objects of '256' bits
and I rename the 'array' to 'bonnetjes'
Then print the 'bonnetjes'
EOF

cat <<EOF | zexe array_rename_remove.zen -a arr.json
rule input encoding url64
rule output encoding hex
Given I have a 'url64 array' named 'bonnetjes'
When I pick the random object in 'bonnetjes'
and I rename the 'random object' to 'lucky one'
and I remove the 'lucky one' from 'bonnetjes'
# redundant check
and the 'lucky one' is not found in 'bonnetjes'
Then print the 'lucky one'
EOF


cat <<EOF | zexe random_numbers.zen | tee array_random_nums.json
Given nothing
When I create the array of '64' random numbers
Then print the 'array' as 'number'
EOF


cat <<EOF | zexe random_numbers.zen | tee array_random_nums.json
Given nothing
When I create the array of '64' random numbers modulo '100'
and I create the aggregation of array 'array'
Then print the 'array' as 'number'
and print the 'aggregation' as 'number'
EOF

success
