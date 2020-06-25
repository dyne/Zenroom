#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

cat <<EOF | tee SYM01.zen | $Z -z > secret.json
rule check version 1.0.0
Scenario simple: Generate a random password
Given nothing
When I create a random 'password'
Then print the 'password'
EOF

cat <<EOF | tee SYM02.zen | $Z -z > cipher_message.json
Scenario simple: Encrypt a message with the password
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

cat <<EOF | tee SYM03.zen | $Z -a cipher_message.json -z
Scenario simple: Decrypt the message with the password
Given I have a 'secret message'
When I write string 'my secret word' in 'password'
and I decrypt the secret message with 'password'
Then print as 'string' the 'text' inside 'message'
and print as 'string' the 'header' inside 'message'
EOF

cat <<EOF | tee alice_keygen.zen | $Z -z > alice_keypair.json
Scenario 'simple': Create the keypair
Given that I am known as 'Alice'
When I create the keypair
Then print my data
EOF

cat <<EOF | tee alice_keypub.zen | $Z -z -k alice_keypair.json > alice_pub.json
Scenario 'simple': Publish the public key
Given that I am known as 'Alice'
and I have my 'public key'
Then print my 'public key'
EOF

cat <<EOF | tee DSA01.zen | $Z -z -k alice_keypair.json | tee alice_signs_to_bob.json
Rule check version 1.0.0
Scenario 'simple': Alice signs a message for Bob
	Given that I am known as 'Alice'
	and I have my 'keypair'
	When I write string 'This is my signed message to Bob.' in 'draft'
	and I create the signature of 'draft'
	Then print my 'signature'
	and print my 'draft'
EOF

cat <<EOF | tee DSA02.zen | $Z -z -k alice_pub.json -a alice_signs_to_bob.json
rule check version 1.0.0
Scenario 'simple': Bob verifies the signature from Alice
	Given that I am known as 'Bob'
	and I have a 'public key' from 'Alice'
	and I have a 'signature' from 'Alice'
	and I have a 'draft'
	When I verify the 'draft' is signed by 'Alice'
	Then print 'signature' 'correct' as 'string'
	and print as 'string' the 'draft'
EOF

cat <<EOF | tee bob_keygen.zen | $Z -z > bob_keypair.json
Scenario 'simple': Create the keypair
Given that I am known as 'Bob'
When I create the keypair
Then print my data
EOF

cat <<EOF | tee bob_keypub.zen | $Z -z -k bob_keypair.json > bob_pub.json
Scenario 'simple': Publish the public key
Given that I am known as 'Bob'
and I have my 'public key'
Then print my 'public key'
EOF

cat <<EOF | tee AES05.zen | $Z -z -k alice_keypair.json -a bob_pub.json | tee alice_to_bob.json
Rule check version 1.0.0
Scenario 'simple': Alice encrypts a message for Bob
	Given that I am known as 'Alice'
	and I have my 'keypair'
	and I have a 'public key' from 'Bob'
	When I write string 'This is my secret message.' in 'message'
	and I write string 'This is the header' in 'header'
	and I encrypt the message for 'Bob'
	Then print the 'secret message'
EOF

cat <<EOF | tee AES06.zen | $Z -z -k bob_keypair.json -a alice_pub.json | tee bob_keyring.json
Rule check version 1.0.0
Scenario 'simple': Bob gathers public keys in his keyring
	Given that I am 'Bob'
	and I have my 'keypair'
	and I have a 'public key' from 'Alice'
	Then print my 'keypair'
	and print the 'public key'
EOF

cat <<EOF | tee AES07.zen | $Z -z -k bob_keyring.json -a alice_to_bob.json
Rule check version 1.0.0
Scenario 'simple': Bob decrypts the message from Alice
	Given that I am known as 'Bob'
	and I have my 'keypair'
	and I have a 'public key' from 'Alice'
	and I have a 'secret message'
	When I decrypt the secret message from 'Alice'
	Then print as 'string' the 'message'
	and print as 'string' the 'header' inside 'secret message'
EOF
