#!/usr/bin/env bash


####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

cat <<EOF | zexe array_32_256.zen > arr.json
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

# cat <<EOF | zexe array_hashtopoint.zen -a arr.json > ecp.json
# rule input encoding url64
# rule output encoding url64
# Given I have a 'array' named 'bonnetjes'
# When I create the hash to point 'ECP' of each object in 'bonnetjes'
# # When for each x in 'bonnetjes' create the of 'ECP.hashtopoint(x)'
# Then print the 'hashes'
# EOF

# cat <<EOF | zexe array_ecp_check.zen -a arr.json -k ecp.json > hashes.json
# rule input encoding url64
# rule output encoding url64
# Given I have a 'array' named 'bonnetjes'
# and I have a 'ecp array' named 'hashes'
# # When I pick the random object in array 'hashes'
# # and I remove the 'random object' from array 'hashes'
# When for each x in 'hashes' y in 'bonnetjes' is true 'x == ECP.hashtopoint(y)'
# Then print the 'hashes'
# EOF
# # 'x == ECP.hashtopoint(y)'


cat <<EOF | zexe left_array_from_hash.zen -a arr.json > left_arr.json
rule input encoding url64
rule output encoding url64
Given I have a 'url64 array' named 'bonnetjes'
When I create the hashes of each object in 'bonnetjes'
and rename the 'hashes' to 'left array'
Then print the 'left array'
EOF


cat <<EOF | zexe right_array_from_hash.zen -a arr.json > right_arr.json
rule input encoding url64
rule output encoding url64
Given I have a 'url64 array' named 'bonnetjes'
When I create the hashes of each object in 'bonnetjes'
and rename the 'hashes' to 'right array'
Then print the 'right array'
EOF

# comparison

cat <<EOF | zexe array_comparison.zen -a left_arr.json -k right_arr.json
rule input encoding url64
rule output encoding url64
Given I have a 'url64 array' named 'left array'
and I have a 'url64 array' named 'right array'
When I verify 'left array' is equal to 'right array'
Then print 'OK'
EOF

cat <<EOF | zexe array_remove_object.zen -a arr.json > right_arr.json
rule input encoding url64
rule output encoding url64
Given I have a 'url64 array' named 'bonnetjes'
When I pick the random object in 'bonnetjes'
and I remove 'random object' from 'bonnetjes'
and I create the hashes of each object in 'bonnetjes'
and rename the 'hashes' to 'right array'
Then print the 'right array'
EOF

# verify that arrays are not equal
cat <<EOF | zexe array_not_comparison.zen -a left_arr.json -k right_arr.json
rule input encoding url64
rule output encoding url64
Given I have a 'url64 array' named 'left array'
and I have a 'url64 array' named 'right array'
When I verify 'left array' is not equal to 'right array'
Then print 'OK'
EOF


# 'x == ECP.hashtopoint(y)'

cat <<EOF > nesting.json
{
  "first" : { "inside" : "first.inside" },
  "second" : { "inside" : "second.inside" },
  "third" : "three"
}
EOF

cat <<EOF | zexe pick_nested.zen -a nesting.json
rule check version 1.0.0
rule input encoding string
Given I have a 'string' named 'inside' inside 'first'
and I have a 'string' named 'third'
When I write string 'first.inside' in 'test'
and I write string 'three' in 'tertiur'
and I verify 'third' is equal to 'tertiur'
Then print the 'test' as 'string'
EOF

cat <<EOF | zexe random_from_array.zen
rule check version 1.0.0
Given nothing
When I create the array of '32' random objects of '256' bits
and I pick the random object in 'array'
and I remove 'random object' from 'array'
and the 'random object' is not found in 'array'
Then print the 'random object'
EOF

cat <<EOF | zexe leftmost_split.zen
rule check version 1.0.0
Given nothing
When I set 'whole' to 'Zenroom works great' as 'string'
and I split the leftmost '3' bytes of 'whole'
Then print the 'leftmost' as 'string'
and print the 'whole' as 'string'
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

