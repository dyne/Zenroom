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
#	echo "ERROR in Given nothing"
#	exit 1; fi
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
      "keyring":{
	 "ecdh":"IIiTD89L6/sbIvaUc5jAVR88ySigaBXppS5GLUjm7Dv2OLKbNIVdiZ48jpLGskKVDPpukKe4R0A="
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
      "keyring":{
	 "ecdh":"IIiTD89L6/sbIvaUc5jAVR88ySigaBXppS5GLUjm7Dv2OLKbNIVdiZ48jpLGskKVDPpukKe4R0A="
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
	 and I have my 'keyring'
	 Then print the 'keyring'
EOF

cat <<EOF | zexe have_my_valid.zen -a $tmp
rule check version 1.0.0
scenario 'ecdh'
	 Given I am 'Andrea'
	 and I have my valid 'keyring'
	 Then print the 'keyring'
EOF

cat <<EOF | zexe is_valid.zen -a $tmp
rule check version 1.0.0
scenario 'ecdh'
	 Given I am 'Andrea'
	 and my 'keyring' is valid
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
	 Given I have a 'keyring' inside 'Bobbino'
	 Then print the 'keyring'
EOF
# TODO: rename in Given I have inside 'Bobbino' a 'keypair'
# diverso da Given I have a 'keypair' inside 'Bobbino'
# also same statements with valid
# also from (maybe move to scenario ecdh)
cat <<EOF | zexe have_inside_a.zen -a $tmp
rule check version 1.0.0
scenario 'ecdh'
	 Given I have a valid 'keyring' from 'Andrea'
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

cat <<EOF | save given named_by_simple.json
{
	"friend": "Bob",
	"Bob": "Gnignigni"
}
EOF

cat <<EOF | zexe named_by.zen -a named_by_simple.json

# Given I have a 'string' named 'friend'
Given I have a 'string' named by 'friend'

Then print all data

EOF

cat <<EOF | save given named_by_inside.json
{
	"Sender": "Alice",
	"Alice": {
		"keyring": {
			"ecdh": "2mZDRS1rE4jT5EuozwZfbS+GLE7ogBfgWOr30wXoe3g="
		}
	},
	"Friends": {
		"Bob": "BJX5HFLhTxd+QeCcywWP4i7QXufoI83j/VvzoaTlfHjJBJeEIhCIUQHIm+paH/aJWHSnAQC0Mea0IiYb7z4Z4bk=",
		"Jenna": "BNRzlJ4csYlWgycGGiK/wgoEw3OizCdx9MWg06rxUBTP5rP9qPASOW5KY8YgmNjW5k7lLpboboHrsApWsvgkMN4="
	},
	"Recipient": "Bob",
	"Message": "Hi, Bob!"
}
EOF

cat <<EOF | zexe named_by_inside.zen -a named_by_inside.json
Scenario 'ecdh':
Given my name is in a 'string' named 'Sender'
Given that I have my 'keyring'
Given I have a 'string' named 'Recipient'
Given I have a 'string' named 'Message'

# below the statement needed
Given that I have a 'public key' named by 'Recipient' inside 'Friends'

When I rename the object named by 'Recipient' to 'SecretRecipient'
When I encrypt the secret message of 'Message' for 'SecretRecipient'
When I rename the 'secret message' to 'SecretMessage'

Then print the 'SecretMessage'
Then print the 'SecretRecipient'
EOF

rm -f $tmp


cat <<EOF | save given name_named_in.json
{ 
	"UserData": {
	        "Sender": "Alice"
	},
	"Alice": {
		"keyring": {
			"ecdh": "2mZDRS1rE4jT5EuozwZfbS+GLE7ogBfgWOr30wXoe3g="
		}
	}
}
EOF

cat <<EOF | zexe name_named_in.zen -a name_named_in.json | jq .
Scenario 'ecdh'
# below the statement needed
Given my name is in a 'string' named 'Sender' inside 'UserData'

Given that I have my 'keyring'
Then print my data
EOF


cat <<EOF | save given nested_dictionary_in.json
{ 
"@context": [ 
"https://www.w3.org/ns/did/v1", 
"https://w3id.org/security/suites/ed25519-2020/v1" 
], 
"id": "did:example:123456789abcdefghi", 
"authentication": [ 
{ 
"id": "did:example:123456789abcdefghi#keys-1", 
"type": "Ed25519VerificationKey2020", 
"controller": "did:example:123456789abcdefghi", 
"publicKeyMultibase": "zH3C2AVvLMv6gmMNam3uVAjZpfkcJCwDwnZn6z3wXmqPV" 
} 
] 
} 
EOF

cat <<EOF | zexe nested_dict_in.zen -a nested_dictionary_in.json
Given that I have a 'string' named 'id' in 'authentication'
Then print all data
EOF
 

success
