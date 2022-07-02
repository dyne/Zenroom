#!/usr/bin/env bash

# RNGSEED="random"
####################
# common script init
. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################


cat << EOF | zexe keygen.zen | save eddsa alice_keys.json
Scenario eddsa
Given I am known as 'Alice'
When I create the keyring
and I create the eddsa key
Then print my 'keyring'
EOF

cat << EOF | zexe pubkey.zen -k alice_keys.json | save eddsa alice_pubkey.json
Scenario eddsa
Given I am known as 'Alice'
Given I have my 'keyring'
When I create the eddsa public key
Then print my 'eddsa public key'
EOF

cat << EOF | zexe keygen.zen | save eddsa bob_keys.json
Scenario eddsa
Given I am known as 'Bob'
When I create the eddsa key
Then print my 'keyring'
EOF

cat << EOF | zexe pubkey.zen -k bob_keys.json | save eddsa bob_pubkey.json
Scenario eddsa
Given I am known as 'Bob'
Given I have my 'keyring'
When I create the eddsa public key
Then print my 'eddsa public key'
EOF

# check that secret key doesn't changes on pubkey generation
cat << EOF | zexe keygen_immutable.zen | save eddsa carl_keys.json
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

cat <<EOF | zexe sign_from_alice.zen -k alice_keys.json | save eddsa sign_alice_keyring.json
Rule check version 2.0.0
Scenario 'eddsa'
Given that I am known as 'Alice'
and I have my 'keyring'
When I write string 'This is my authenticated message.' in 'message'
and I create the eddsa signature of 'message'
Then print the 'message'
and print the 'eddsa signature'
EOF

cat <<EOF | zexe verify_from_alice.zen -k alice_pubkey.json -a sign_alice_keyring.json
Rule check version 2.0.0
Scenario 'eddsa'
Given I have a 'eddsa public key' from 'Alice'
and I have a 'string' named 'message'
and I have a 'eddsa signature'
When I verify the 'message' has a eddsa signature in 'eddsa signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF

cat <<EOF | zexe sign_from_alice2.zen -k alice_keys.json | save eddsa sign_alice_keyring2.json
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
