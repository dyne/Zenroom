#!/bin/sh



alias zenroom='${1:-./src/zenroom}' # -c memmanager=\"lw\"'

t=`mktemp -d`
cat <<EOF | zenroom -z | tee $t/arr.json
rule output encoding base64
Given nothing
When I create the array of '32' random objects of '256' bits
and I rename the 'array' to 'bonnetjes'
Then print the 'bonnetjes'
EOF

cat <<EOF | zenroom -z -a $t/arr.json
rule output encoding base64
rule input encoding base64
Given I have a valid array in 'bonnetjes'
When I pick the random object in 'bonnetjes'
and I rename the 'random object' to 'lucky one'
and I remove the 'lucky one' from 'bonnetjes'
# redundant check
and the 'lucky one' is not found in 'bonnetjes'
Then print the 'lucky one'
and print the 'bonnetjes'
EOF



rm -f $t/*
rmdir $t
