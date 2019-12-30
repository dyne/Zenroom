#!/bin/sh

seed="0xDEADBEEF"

alias zenroom="${1:-./src/zenroom}" # -c rngseed=\\\"$seed\\\""
#  memmanager=\\\"lw\\\",

t=`mktemp -d`
cat <<EOF | zenroom -z | tee $t/arr.json
rule output encoding url64
Given nothing
When I create the array of '32' random objects of '256' bits
and I rename the 'array' to 'bonnetjes'
Then print the 'bonnetjes'
EOF

cat <<EOF | zenroom -z -a $t/arr.json
rule input encoding url64
rule output encoding hex
Given I have a valid array in 'bonnetjes'
When I pick the random object in array 'bonnetjes'
and I rename the 'random object' to 'lucky one'
and I remove the 'lucky one' from array 'bonnetjes'
# redundant check
and the 'lucky one' is not found in array 'bonnetjes'
Then print the 'lucky one'
and print the 'bonnetjes'
EOF

cat <<EOF | zenroom -z
rule output encoding url64
Given nothing
When I create the array of '32' random curve points
and I rename the 'array' to 'curve points'
and I create the aggregation of array 'curve points'
Then print the 'aggregation'
EOF


cat <<EOF | zenroom -z -a $t/arr.json | tee $t/ecp.json
rule input encoding url64
rule output encoding url64
Given I have a valid array in 'bonnetjes'
When I create the 'ECP' hashes of objects in array 'bonnetjes'
# When for each x in 'bonnetjes' create the array of 'ECP.hashtopoint(x)'
Then print the 'hashes'
EOF

cat <<EOF | zenroom -z -a $t/arr.json -k $t/ecp.json
rule input encoding url64
rule output encoding url64
Given I have a valid array in 'bonnetjes'
and I have a valid array of 'ECP' in 'hashes'
# When I pick the random object in array 'hashes'
# and I remove the 'random object' from array 'hashes'
When for each x='hashes' y='bonnetjes' is true 'x == ECP.hashtopoint(y)'
Then print the 'hashes'
EOF
# 'x == ECP.hashtopoint(y)'


cat <<EOF | zenroom -z -a $t/arr.json | json_pp
rule input encoding url64
rule output encoding url64
Given I have a valid array in 'bonnetjes'
When for each 'bonnetjes' create the array using 'sha256(x)'
Then print the 'array'
and print the 'bonnetjes'
EOF
# 'x == ECP.hashtopoint(y)'


rm -f $t/*
rmdir $t
# When I check 'hashes' and 'bonnetjes'
# When I check 'hashes' and 'bonnetjes' such as
