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
echo '{"a": 1}' > $tmp
cat <<EOF | zexe fail_nothing.zen -a $tmp
rule check version 1.0.0
	 Given nothing
	 When I create the random object of '256' bits
	 Then print the 'random object'
EOF
# if ! test $? == 1; then
# 	echo "ERROR in Given nothing"
# 	exit 1; fi
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
	 Given I have a 'number' named 'myNumber' inside 'myObject'
	 Then print the 'myNumber'
EOF


cat <<EOF | zexe have_valid_arrays.zen -a $tmp
Given I have a valid 'string array' named 'myArray' in 'myObject'
Given I have a valid 'string' named 'myString' in 'myObject'
Given I have a valid 'number' named 'myNumber' in 'myObject'
When I randomize the 'myArray' array
Then print all data
EOF

cat <<EOF  > $tmp
{"Andrea":{
      "keypair":{
         "private_key":"IIiTD89L6/sbIvaUc5jAVR88ySigaBXppS5GLUjm7Dv2OLKbNIVdiZ48jpLGskKVDPpukKe4R0A=",
         "public_key":"BBgzMLWv0ZTiMBwCxF7kEIv/y7NmilO4vmZGRj/edBY5rDchp7dmo+z4g4/13mdN/3b8+o5GxTNw3SHzQC4uxd0="
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

	"Bobbino":{
      "keypair":{
         "private_key":"IIiTD89L6/sbIvaUc5jAVR88ySigaBXppS5GLUjm7Dv2OLKbNIVdiZ48jpLGskKVDPpukKe4R0A=",
         "public_key":"BBgzMLWv0ZTiMBwCxF7kEIv/y7NmilO4vmZGRj/edBY5rDchp7dmo+z4g4/13mdN/3b8+o5GxTNw3SHzQC4uxd0="
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

cat <<EOF | zexe have_my.zen -a $tmp
rule check version 1.0.0
scenario 'ecdh'
	 Given I am 'Andrea'
	 and I have my 'keypair'
	 Then print the 'keypair'
EOF

cat <<EOF | zexe have_my_valid.zen -a $tmp
rule check version 1.0.0
scenario 'ecdh'
	 Given I am 'Andrea'
	 and I have my valid 'keypair'
	 Then print the 'keypair'
EOF

cat <<EOF | zexe is_valid.zen -a $tmp
rule check version 1.0.0
scenario 'ecdh'
	 Given I am 'Andrea'
	 and my 'keypair' is valid
	 Then print all data
EOF

cat <<EOF | zexe have_inside_a.zen -a $tmp
rule check version 1.0.0
scenario 'ecdh'
	 Given I have a 'number' named 'robba' inside 'stuff'
	 Then print the 'robba'
EOF
# ambiguity explained:
cat <<EOF | zexe have_a_inside.zen -a $tmp
rule check version 1.0.0
scenario 'ecdh'
	 Given I have a 'keypair' inside 'Bobbino'
	 Then print the 'keypair'
EOF
# TODO: rename in Given I have inside 'Bobbino' a 'keypair'
# diverso da Given I have a 'keypair' inside 'Bobbino'
# also same statements with valid
# also from (maybe move to scenario ecdh)
cat <<EOF | zexe have_inside_a.zen -a $tmp
rule check version 1.0.0
scenario 'ecdh'
	 Given I have a valid 'keypair' from 'Andrea'
#	 when schema
	 Then print all data
EOF

# array
cat <<EOF | zexe have_a_implicit_array.zen -a $tmp
rule check version 1.0.0
scenario 'ecdh'
	 Given I have a 'string array' named 'peppe' inside 'stuff'
	 Then print the 'peppe'
EOF
cat <<EOF | zexe have_a_implicit_array.zen -a $tmp
rule check version 1.0.0
scenario 'ecdh'
	 Given I have a valid 'string array' named 'peppe' inside 'stuff'
	 Then print the 'peppe'
EOF

cat <<EOF | zexe have_a_implicit_array.zen -a $tmp
rule check version 1.0.0
scenario 'ecdh'
	 Given I have a valid 'number' named 'quantity' inside 'stuff'
	 Then print the 'quantity'
EOF


rm -f $tmp
success
