#!/usr/bin/env bash

# https://pad.dyne.org/code/#/2/code/edit/NTsTFsGUExxvnycVzM32AJvZ/

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

tmp=`mktemp`
cat <<EOF | zexe nothing.zen
rule check version 1.0.0
Given nothing
When I create the random object of '256' bits
Then print the 'random object'
EOF

set +e
echo '{}' > $tmp
cat <<EOF | zexe fail_nothing.zen -a $tmp 2>/dev/null
rule check version 1.0.0
	 Given nothing
	 When I create the random object of '256' bits
	 Then print the 'random object'
EOF
if ! test $? == 1; then
	echo "ERROR in Given nothing"
	exit 1; fi
set -e

echo '{ "anykey": "anyvalue" }' > $tmp
cat <<EOF | zexe have_anyvalue.zen -a $tmp
rule check version 1.0.0
rule input encoding string
rule output encoding string
	 Given I have a 'string' named 'anykey'
	 Then print the 'anykey'
EOF

echo '{ "anykey": "616e7976616c7565" }' > $tmp
cat <<EOF | zexe have_anyhex.zen -a $tmp
rule check version 1.0.0
	 Given I have a 'hex' named 'anykey'
	 Then print the 'anykey' as 'string'
EOF


cat <<EOF > $tmp
{
	"myObject":{
		"myNumber":1000,
		"myString":"Hello World!",
		"myArray":[
			"String1",
			"String2",
			"String3"
		]
	}
}
EOF

cat <<EOF | zexe have_number.zen -a $tmp
rule check version 1.0.0
	 Given I have a 'number' named 'myNumber'
	 Then print the 'myNumber'
EOF


cat <<EOF | zexe have_valid_arrays.zen -a $tmp
# Given I have a valid array of 'string' in 'myArray'
Given I have a valid 'str' in 'myString'
Given I have a valid 'number' in 'myNumber'
When I randomize the 'myArray' array
Then print all data
EOF

cat <<EOF  > $tmp
{"Andrea":{
      "keypair":{
         "private_key":"IIiTD89L6_sbIvaUc5jAVR88ySigaBXppS5GLUjm7Dv2OLKbNIVdiZ48jpLGskKVDPpukKe4R0A",
         "public_key":"BFKQTA1ZiebF0is_LtMcVgu4QXC-HOjMpCwDPLuvuXGVAgORIn5NUm7Ey7UDljeNrTCZvhEqxCPjSvWLtIuSYXeZcHWENp7oO37nv7hL2Qj1vMwwlpeRhnSZnjhnKYjq5aTQV1T-eH3e0UcJASzvnb8"
      },
   },
   "stuff": {
    "robba":"1000",
	"quantity":1000,
    "peppe":[
        "peppe2",
        "peppe3",
        "peppe4"
        ]
	},

	"Bobbino":{"Bob":{
      "keypair":{
         "private_key":"IIiTD89L6_sbIvaUc5jAVR88ySigaBXppS5GLUjm7Dv2OLKbNIVdiZ48jpLGskKVDPpukKe4R0A",
         "public_key":"BFKQTA1ZiebF0is_LtMcVgu4QXC-HOjMpCwDPLuvuXGVAgORIn5NUm7Ey7UDljeNrTCZvhEqxCPjSvWLtIuSYXeZcHWENp7oO37nv7hL2Qj1vMwwlpeRhnSZnjhnKYjq5aTQV1T-eH3e0UcJASzvnb8"
				},
			},
	  "robbaB":"1000",
    "peppeB":[
        "peppe2B",
        "peppe3B",
        "peppe4B"
        ]
	}

 }
EOF

cat <<EOF | tee have_my.zen | $Z -z -a $tmp
rule check version 1.0.0
scenario 'simple'
	 Given I am 'Andrea'
	 and I have my 'keypair'
	 Then print the 'keypair'
EOF

cat <<EOF | tee have_my_valid.zen | $Z -z -a $tmp
rule check version 1.0.0
scenario 'simple'
	 Given I am 'Andrea'
	 and I have my valid 'keypair'
	 Then print the 'keypair'
EOF

cat <<EOF | tee is_valid.zen | $Z -z -a $tmp
rule check version 1.0.0
scenario 'simple'
	 Given I am 'Andrea'
	 and the 'keypair' is valid
	 Then print all data
EOF


cat <<EOF | tee have_a_inside.zen | $Z -z -a $tmp
rule check version 1.0.0
scenario 'simple'
	 Given I have a 'robba' inside 'stuff'
	 Then print the 'robba'
EOF
cat <<EOF | tee have_inside_a.zen | $Z -z -a $tmp
rule check version 1.0.0
scenario 'simple'
	 Given I have inside 'stuff' a 'robba'
	 Then print the 'stuff'
EOF
# ambiguity explained:
cat <<EOF | tee have_a_inside.zen | $Z -z -a $tmp
rule check version 1.0.0
scenario 'simple'
	 Given I have a 'keypair' inside 'Bobbino'
	 Then print the 'keypair'
EOF
cat <<EOF | tee have_inside_a.zen | $Z -z -a $tmp
rule check version 1.0.0
scenario 'simple'
	 Given I have inside 'Bobbino' a 'keypair'
	 Then print the 'Bobbino'
EOF
# TODO: rename in Given I have inside 'Bobbino' a 'keypair'
# diverso da Given I have a 'keypair' inside 'Bobbino'
# also same statements with valid
# also from (maybe move to scenario simple)
cat <<EOF | tee have_inside_a.zen | $Z -z -a $tmp
rule check version 1.0.0
scenario 'simple'
	 Given I have a valid 'public key' from 'Andrea'
	 when schema
	 Then print all data
EOF

# array
cat <<EOF | tee have_a_implicit_array.zen | $Z -z -a $tmp
rule check version 1.0.0
scenario 'simple'
	 Given I have a 'peppe' inside 'stuff'
	 Then print the 'peppe'
EOF
cat <<EOF | tee have_a_implicit_array.zen | $Z -z -a $tmp
rule check version 1.0.0
scenario 'simple'
	 Given I have a valid 'array' named 'peppe' inside 'stuff'
	 Given I have a valid 'array' named 'peppe'
	 Then print the 'peppe'
EOF

cat <<EOF | tee have_a_implicit_array.zen | $Z -z -a $tmp
rule check version 1.0.0
scenario 'simple'
	 Given I have a valid 'number' named 'quantity' inside 'stuff'
	 Then print the 'peppe'
EOF



rm -f $tmp
