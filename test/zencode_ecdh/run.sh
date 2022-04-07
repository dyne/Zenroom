#!/usr/bin/env bash

# RNGSEED="random"
####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh $*
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

cat <<EOF | zexe SYM01.zen | save ecdh secret.json
rule check version 1.0.0
Scenario ecdh: Generate a random password
Given nothing
When I create the random 'password'
Then print the 'password'
EOF

cat <<EOF | zexe SYM02.zen | save ecdh cipher_message.json
Scenario ecdh: Encrypt a message with the password
Given nothing
# only inline input, no KEYS or DATA passed
When I write string 'my secret word' in 'password'
and I write string 'a very short but very confidential message' in 'whisper'
and I write string 'for your eyes only' in 'header'
# header is implicitly used when encrypt
and I encrypt the secret message 'whisper' with 'password'
# anything introduced by 'the' becomes a new variable
Then print the 'secret message'
EOF

cat <<EOF | zexe SYM03.zen -a cipher_message.json | save ecdh clear_message.json
Scenario ecdh: Decrypt the message with the password
Given I have a 'secret message'
When I write string 'my secret word' in 'password'
and I decrypt the text of 'secret message' with 'password'
Then print the 'text' as 'string'
and print the 'header' from 'secret message' as 'string'
EOF


cat << EOF | zexe keygen.zen | save ecdh alice_keys.json
Scenario ecdh
Given I am known as 'Alice'
When I create the keyring
and I create the ecdh key
Then print my 'keyring'
EOF

cat << EOF | zexe pubkey.zen -k alice_keys.json | save ecdh alice_pubkey.json
Scenario ecdh
Given I am known as 'Alice'
Given I have my 'keyring'
When I create the ecdh public key
Then print my 'ecdh public key'
EOF

cat << EOF | zexe keygen.zen | save ecdh bob_keys.json
Scenario ecdh
Given I am known as 'Bob'
When I create the ecdh key
Then print my 'keyring'
EOF

cat << EOF | zexe pubkey.zen -k bob_keys.json | save ecdh bob_pubkey.json
Scenario ecdh
Given I am known as 'Bob'
Given I have my 'keyring'
When I create the ecdh public key
Then print my 'ecdh public key'
EOF

# check that secret key doesn't changes on pubkey generation
cat << EOF | zexe keygen_immutable.zen | save ecdh carl_keys.json
Scenario ecdh
Given I am known as 'Carl'
When I create the ecdh key
and I copy the 'ecdh' in 'keyring' to 'ecdh before'
and I create the ecdh public key
and I copy the 'ecdh' in 'keyring' to 'ecdh after'
and I verify 'ecdh before' is equal to 'ecdh after'
Then print 'ecdh before' as 'hex'
and print 'ecdh after' as 'hex'
EOF

cat alice_keys.json | jq .
cat <<EOF | debug enc_to_bob.zen -k alice_keys.json -a bob_pubkey.json | save ecdh enc_alice_to_bob.json
Rule check version 1.0.0
Scenario 'ecdh': Alice encrypts a message for Bob
	Given that I am known as 'Alice'
	and I have my 'keyring'
	and I have a 'ecdh' public key from 'Bob'
	When I write string 'This is my secret message.' in 'message'
	and I write string 'This is the header' in 'header'
	and I encrypt the secret message of 'message' for 'Bob'
	and I create the ecdh public key
	Then print the 'secret message'
	and print my 'ecdh public key'
	and print my 'keyring'
	and print all data
EOF

cat <<EOF | zexe dec_from_alice.zen -k bob_keys.json -a enc_alice_to_bob.json | save ecdh dec_bob_from_alice.json
Rule check version 1.0.0
Scenario 'ecdh': Bob decrypts the message from Alice
	Given that I am known as 'Bob'
	and I have my 'keyring'
	and I have a 'ecdh' public key from 'Alice'
	and I have a 'secret message'
	When I decrypt the text of 'secret message' from 'Alice'
	Then print the 'text' as 'string'
	and print the 'header' from 'secret message' as 'string'
EOF

cat <<EOF | zexe sign_from_alice.zen -k alice_keys.json | save ecdh sign_alice_keyring.json
Rule check version 2.0.0
Scenario 'ecdh'
Given that I am known as 'Alice'
and I have my 'keyring'
When I write string 'This is my authenticated message.' in 'message'
and I create the signature of 'message'
Then print the 'message'
and print the 'signature'
EOF

cat <<EOF | zexe verify_from_alice.zen -k alice_pubkey.json -a sign_alice_keyring.json
Rule check version 2.0.0
Scenario 'ecdh'
Given I have a 'ecdh' public key from 'Alice'
and I have a 'string' named 'message'
and I have a 'signature'
When I verify the 'message' has a signature in 'signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF

cat <<EOF | zexe sign_from_alice2.zen -k alice_keys.json | save ecdh sign_alice_keyring2.json
Rule check version 2.0.0
Scenario 'ecdh'
Given that I am known as 'Alice'
and I have my 'keys'
When I write string 'This is my authenticated message.' in 'message'
and I create the ecdh signature of 'message'
Then print the 'message'
and print the 'ecdh signature'
EOF

cat <<EOF | zexe verify_from_alice2.zen -k alice_pubkey.json -a sign_alice_keyring2.json | jq .
Rule check version 2.0.0
Scenario 'ecdh'
Given I have a 'ecdh public key' from 'Alice'
and I have a 'string' named 'message'
and I have a 'ecdh signature'
When I verify the 'message' has a ecdh signature in 'ecdh signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF

success

rm *.json *.zen
