#!/usr/bin/env bash

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh

is_cortexm=false
if [[ "$1" == "cortexm" ]]; then
	is_cortexm=true
fi

Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

cat <<EOF | zexe SYM01.zen > secret.json
rule check version 1.0.0
Scenario ecdh: Generate a random password
Given nothing
When I create the random 'password'
Then print the 'password'
EOF

cat <<EOF | zexe SYM02.zen > cipher_message.json
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

cat <<EOF | zexe SYM03.zen -a cipher_message.json 
Scenario ecdh: Decrypt the message with the password
Given I have a 'secret message'
When I write string 'my secret word' in 'password'
and I decrypt the text of 'secret message' with 'password'
Then print the 'text' as 'string'
and print the 'header' as 'string' in 'secret message'
EOF

cat <<EOF | zexe alice_keygen.zen > alice_keypair.json
Scenario 'ecdh': Create the keypair
Given that I am known as 'Alice'
When I create the keypair
Then print my data
EOF

cat <<EOF | zexe alice_keypub.zen -k alice_keypair.json > alice_pub.json
Scenario 'ecdh': Publish the public key
Given that I am known as 'Alice'
and I have my 'keypair'
Then print my 'public key' from 'keypair'
EOF

cat <<EOF | zexe DSA01.zen -k alice_keypair.json | tee alice_signs_to_bob.json
Rule check version 1.0.0
Scenario 'ecdh': Alice signs a message for Bob
	Given that I am known as 'Alice'
	and I have my 'keypair'
	When I write string 'This is my signed message to Bob.' in 'draft'
	and I create the signature of 'draft'
	Then print my 'signature'
	and print my 'draft'
EOF

cat <<EOF | zexe DSA02.zen -k alice_pub.json -a alice_signs_to_bob.json
rule check version 1.0.0
# rule input encoding base64
Scenario 'ecdh': Bob verifies the signature from Alice
	Given that I am known as 'Bob'
	and I have a 'public key' from 'Alice'
	and I have a 'signature' from 'Alice'
	and I have a 'string' named 'draft' in 'Alice'
	When I verify the 'draft' is signed by 'Alice'
	Then print 'signature correct'
	and print the 'draft' as 'string'
EOF

cat <<EOF | zexe bob_keygen.zen > bob_keypair.json
Scenario 'ecdh': Create the keypair
Given that I am known as 'Bob'
When I create the keypair
Then print my data
EOF

cat <<EOF | zexe bob_keypub.zen -k bob_keypair.json > bob_pub.json
Scenario 'ecdh': Publish the public key
Given that I am known as 'Bob'
and I have my 'keypair'
Then print my 'public key' from 'keypair'
EOF

cat <<EOF | zexe AES05.zen -k alice_keypair.json -a bob_pub.json | tee alice_to_bob.json
Rule check version 1.0.0
Scenario 'ecdh': Alice encrypts a message for Bob
	Given that I am known as 'Alice'
	and I have my 'keypair'
	and I have a 'public key' from 'Bob'
	When I write string 'This is my secret message.' in 'message'
	and I write string 'This is the header' in 'header'
	and I encrypt the secret message of 'message' for 'Bob'
	Then print the 'secret message'
EOF

cat <<EOF | zexe AES06.zen -k bob_keypair.json -a alice_pub.json | tee bob_keyring.json
Rule check version 1.0.0
Scenario 'ecdh': Bob gathers public keys in his keyring
	Given that I am 'Bob'
	and I have my 'keypair'
	and I have a 'public key' from 'Alice'
	Then print my 'keypair'
	and print the 'public key'
EOF

cat <<EOF | zexe AES07.zen -k bob_keyring.json -a alice_to_bob.json
Rule check version 1.0.0
Scenario 'ecdh': Bob decrypts the message from Alice
	Given that I am known as 'Bob'
	and I have my 'keypair'
	and I have a 'base64' named 'Alice' in 'public key'
	and I have a 'secret message'
	When I decrypt the text of 'secret message' from 'Alice'
	Then print the 'text' as 'string'
	and print the 'header' as 'string' inside 'secret message'
EOF

success
