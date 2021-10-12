#!/usr/bin/env bash

RNGSEED="random"
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

cat <<EOF | zexe alice_keygen.zen | save ecdh alice_keypair.json
Scenario 'ecdh': Create the keypair
Given that I am known as 'Alice'
When I create the keypair
Then print my data
EOF

cat <<EOF | zexe alice_keypub.zen -k alice_keypair.json | save ecdh alice_pub.json
Scenario 'ecdh': Publish the public key
Given that I am known as 'Alice'
and I have my 'keypair'
Then print my 'public key' from 'keypair'
EOF

cat <<EOF | zexe DSA01.zen -k alice_keypair.json | save ecdh alice_signs_to_bob.json
Rule check version 1.0.0
Scenario 'ecdh': Alice signs a message for Bob
	Given that I am known as 'Alice'
	and I have my 'keypair'
	When I write string 'This is my signed message to Bob.' in 'draft'
	and I create the signature of 'draft'
	Then print my 'signature'
	and print my 'draft'
EOF

cat <<EOF | zexe DSA02.zen -k alice_pub.json -a alice_signs_to_bob.json | save ecdh verify_sign.json
rule check version 1.0.0
# rule input encoding base64
Scenario 'ecdh': Bob verifies the signature from Alice
	Given that I am known as 'Bob'
	and I have a 'public key' from 'Alice'
	and I have a 'signature' from 'Alice'
	and I have a 'string' named 'draft' in 'Alice'
	When I verify the 'draft' is signed by 'Alice'
	Then print the string 'signature correct'
	and print the 'draft' as 'string'
EOF

cat <<EOF | save . Identity_example.json
{
  "Identity": {
    "UserNo": 1021,
    "RecordNo": 22,
    "DateOfIssue": "2020-01-01",
    "Name": "Giacomo",
    "FirstNames": "Rossi",
    "DateOfBirth": "1977-01-01",
    "PlaceOfBirth": "Milano",
    "Address": "Piazza Venezia",
    "TelephoneNo": "327 1234567"
  }
}
EOF

cat <<EOF | zexe DSA01-table.zen -k alice_keypair.json -a Identity_example.json | save ecdh alice_signs_table_to_bob.json
Rule check version 1.0.0
Scenario 'ecdh': Alice signs a message for Bob
	Given that I am known as 'Alice'
	and I have my 'keypair'
	and I have a 'string dictionary' named 'Identity'
	When I create the signature of 'Identity'
	Then print the 'signature'
	and print the 'Identity'
EOF

cat <<EOF | zexe DSA02-table.zen -k alice_pub.json -a alice_signs_table_to_bob.json | save ecdh verify_table_sign.json
rule check version 1.0.0
# rule input encoding base64
Scenario 'ecdh': Bob verifies the signature from Alice
	Given that I am known as 'Bob'
	and I have a 'public key' from 'Alice'
	and I have a 'signature'
	and I have a 'string dictionary' named 'Identity'
	When I verify the 'Identity' has a signature in 'signature' by 'Alice'
	Then print the string 'table signature correct'
EOF


cat <<EOF | zexe bob_keygen.zen | save ecdh bob_keypair.json
Scenario 'ecdh': Create the keypair
Given that I am known as 'Bob'
When I create the keypair
Then print my data
EOF

cat <<EOF | zexe bob_keypub.zen -k bob_keypair.json | save ecdh bob_pub.json
Scenario 'ecdh': Publish the public key
Given that I am known as 'Bob'
and I have my 'keypair'
Then print my 'public key' from 'keypair'
EOF

cat <<EOF | zexe AES05.zen -k alice_keypair.json -a bob_pub.json | save ecdh alice_to_bob.json
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

cat <<EOF | zexe AES06.zen -k bob_keypair.json -a alice_pub.json | save ecdh bob_keyring.json
Rule check version 1.0.0
Scenario 'ecdh': Bob gathers public keys in his keyring
	Given that I am 'Bob'
	and I have my 'keypair'
	and I have a 'public key' from 'Alice'
	Then print my 'keypair'
	and print the 'public key'
EOF

cat <<EOF | zexe AES07.zen -k bob_keyring.json -a alice_to_bob.json | save ecdh asym_clear_message.json
Rule check version 1.0.0
Scenario 'ecdh': Bob decrypts the message from Alice
	Given that I am known as 'Bob'
	and I have my 'keypair'
	and I have a 'base64' named 'Alice' in 'public key'
	and I have a 'secret message'	
	When I decrypt the text of 'secret message' from 'Alice'
	Then print the 'text' as 'string'
	and print the 'header' from 'secret message' as 'string'
EOF

echo
echo '##################################'
echo '## NEW KEY MANAGEMENT TESTS'
echo '##################################'
echo

#####################
## new key management
cat << EOF | zexe keygen.zen | save ecdh alice_keys.json
Scenario ecdh
Given I am known as 'Alice'
When I create the ecdh key
Then print my 'keys'
EOF

cat << EOF | zexe pubkey.zen -k alice_keys.json | save ecdh alice_pubkey.json
Scenario ecdh
Given I am known as 'Alice'
Given I have my 'keys'
When I create the ecdh public key
Then print my 'ecdh public key'
EOF

cat << EOF | zexe keygen.zen | save ecdh bob_keys.json
Scenario ecdh
Given I am known as 'Bob'
When I create the ecdh key
Then print my 'keys'
EOF

cat << EOF | zexe pubkey.zen -k bob_keys.json | save ecdh bob_pubkey.json
Scenario ecdh
Given I am known as 'Bob'
Given I have my 'keys'
When I create the ecdh public key
Then print my 'ecdh public key'
EOF

# check that secret key doesn't changes on pubkey generation
cat << EOF | zexe keygen_immutable.zen | save ecdh carl_keys.json
Scenario ecdh
Given I am known as 'Carl'
When I create the ecdh key
and I copy the 'ecdh' in 'keys' to 'ecdh before'
and I create the ecdh public key
and I copy the 'ecdh' in 'keys' to 'ecdh after'
and I verify 'ecdh before' is equal to 'ecdh after'
Then print 'ecdh before'
and print 'ecdh after'
EOF

cat alice_keys.json | jq .
cat <<EOF | zexe enc_to_bob.zen -k alice_keys.json -a bob_pubkey.json | save ecdh enc_alice_to_bob.json
Rule check version 1.0.0
Scenario 'ecdh': Alice encrypts a message for Bob
	Given that I am known as 'Alice'
	and I have my 'keys'
	and I have a 'ecdh' public key from 'Bob'
	When I write string 'This is my secret message.' in 'message'
	and I write string 'This is the header' in 'header'
	and I encrypt the secret message of 'message' for 'Bob'
	and I create the ecdh public key
	Then print the 'secret message'
	and print my 'ecdh public key'
	and print my 'keys'
	and print all data
EOF

cat <<EOF | zexe dec_from_alice.zen -k bob_keys.json -a enc_alice_to_bob.json | save ecdh dec_bob_from_alice.json
Rule check version 1.0.0
Scenario 'ecdh': Bob decrypts the message from Alice
	Given that I am known as 'Bob'
	and I have my 'keys'
	and I have a 'ecdh' public key from 'Alice'
	and I have a 'secret message'
	When I decrypt the text of 'secret message' from 'Alice'
	Then print the 'text' as 'string'
	and print the 'header' from 'secret message' as 'string'
EOF



success
