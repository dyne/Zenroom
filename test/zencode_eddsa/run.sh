#!/usr/bin/env bash
SUBDOC=eddsa
# RNGSEED="random"
####################
# common script init
. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

cat <<EOF | save $SUBDOC secret_key.json
{
	"secret key": "Cwj9CcqHNoBnXBo8iDfnhFkQeDun4Y4LStd2m3TEAYAg"
}
EOF
cat <<EOF | save $SUBDOC message.json
{
"message": "Dear Bob, this message was written by Alice and signed with EdDSA" ,
"message array":[
	"Hello World! This is my string array, element [0]",
	"Hello World! This is my string array, element [1]",
	"Hello World! This is my string array, element [2]"
	],
"message dictionary": {
	"sender":"Alice",
	"message":"Hello Bob!",
	"receiver":"Bob"
	}
}
EOF

cat << EOF | zexe alice_keygen.zen | save $SUBDOC alice_keys.json
Rule check version 2.0.0
Scenario 'eddsa': Create the eddsa private key
Given I am known as 'Alice'
When I create the eddsa key
Then print my 'keyring'
EOF

cat <<EOF | zexe alice_key_upload.zen -k secret_key.json | jq .
Rule check version 2.0.0
Scenario 'eddsa' : Create and publish the eddsa public key
Given I am 'Alice'
and I have a 'base58' named 'secret key'

# here we upload the key
When I create the eddsa key with secret key 'secret key'
# an equivalent statement is
# When I create the eddsa key with secret 'secret key'

Then print the 'keyring'
EOF


cat <<EOF | zexe alice_key_upload2.zen -k secret_key.json | jq .
Rule check version 2.0.0
Scenario 'eddsa' : Create and publish the eddsa public key
Given I am 'Alice'
and I have a 'base58' named 'secret key'

# here we upload the key
When I create the eddsa key with secret 'secret key'

Then print the 'keyring'
EOF

cat << EOF | zexe alice_pubkey.zen -k alice_keys.json | save $SUBDOC alice_pubkey.json
Rule check version 2.0.0
Scenario 'eddsa': Create the eddsa public key
Given I am known as 'Alice'
Given I have my 'keyring'
When I create the eddsa public key
Then print my 'eddsa public key'
EOF

cat << EOF | zexe bob_keygen.zen | save $SUBDOC bob_keys.json
Scenario eddsa
Given I am known as 'Bob'
When I create the keyring
When I create the eddsa key
Then print my 'keyring'
EOF

cat << EOF | zexe bob_pubkey.zen -k bob_keys.json | save $SUBDOC bob_pubkey.json
Scenario eddsa
Given I am known as 'Bob'
Given I have my 'keyring'
When I create the eddsa public key
Then print my 'eddsa public key'
EOF

# check that secret key doesn't changes on pubkey generation
cat << EOF | zexe keygen_immutable.zen | save $SUBDOC carl_keys.json
Scenario eddsa
Given I am known as 'Carl'
When I create the eddsa key
and I copy the 'eddsa' in 'keyring' to 'eddsa before'
and I create the eddsa public key
and I copy the 'eddsa' in 'keyring' to 'eddsa after'
and I verify 'eddsa before' is equal to 'eddsa after'
Then print 'eddsa before' as 'hex'
and print 'eddsa after' as 'hex'
EOF

cat <<EOF | zexe sign_from_alice.zen -a message.json -k alice_keys.json | save $SUBDOC signed_from_alice.json
Rule check version 2.0.0
Scenario 'eddsa': Alice sign the messages

# Declearing who I am and load all the the stuff
Given that I am known as 'Alice'
Given I have my 'keyring'
Given I have a 'string' named 'message'
Given I have a 'string array' named 'message array'
Given I have a 'string dictionary' named 'message dictionary'

# Creating the signatures and rename them
When I create the eddsa signature of 'message'
and I rename the 'eddsa signature' to 'eddsa_signature.message'
When I create the eddsa signature of 'message array'
and I rename the 'eddsa signature' to 'eddsa_signature.message_array'
When I create the eddsa signature of 'message dictionary'
and I rename the 'eddsa signature' to 'eddsa_signature.message_dictionary'

# Printing both the messages and the signatures
Then print the 'message'
Then print the 'eddsa_signature.message'
Then print the 'message array'
Then print the 'eddsa_signature.message_array'
Then print the 'message dictionary'
Then print the 'eddsa_signature.message_dictionary'
EOF

cat <<EOF | zexe verify_from_alice.zen -k alice_pubkey.json -a signed_from_alice.json | save $SUBDOC verified_from_alice.json
Rule check version 2.0.0
Scenario 'eddsa': Bob verifies Alice signature

# Declearing who I am and load all the stuff
Given that I am known as 'Bob'
and I have a 'eddsa public key' from 'Alice'
and I have a 'string' named 'message'
and I have a 'string array' named 'message array'
and I have a 'string dictionary' named 'message dictionary'
and I have a 'eddsa signature' named 'eddsa_signature.message'
and I have a 'eddsa signature' named 'eddsa_signature.message_array'
and I have a 'eddsa signature' named 'eddsa_signature.message_dictionary'

# Verifying the signatures
When I verify the 'message' has a eddsa signature in 'eddsa_signature.message' by 'Alice'
and I verify the 'message array' has a eddsa signature in 'eddsa_signature.message_array' by 'Alice'
and I verify the 'message dictionary' has a eddsa signature in 'eddsa_signature.message_dictionary' by 'Alice'

# Print the original messages and a string of success
Then print the 'message'
and print the 'message array'
and print the 'message dictionary'
Then print string 'Zenroom certifies that signatures are all correct!'
EOF

cat <<EOF | zexe sign_from_alice2.zen -k alice_keys.json | save $SUBDOC sign_alice_keyring2.json
Rule check version 2.0.0
Scenario 'eddsa'
Given that I am known as 'Alice'
and I have my 'keyring'
When I write string 'This is my authenticated message.' in 'message'
and I create the eddsa signature of 'message'
Then print the 'message'
and print the 'eddsa signature'
EOF

cat <<EOF | zexe verify_from_alice2.zen -k alice_pubkey.json -a sign_alice_keyring2.json | jq .
Rule check version 2.0.0
Scenario 'eddsa'
Given I have a 'eddsa public key' from 'Alice'
and I have a 'string' named 'message'
and I have a 'eddsa signature'
When I verify the 'message' has a eddsa signature in 'eddsa signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF

success

rm *.json *.zen
