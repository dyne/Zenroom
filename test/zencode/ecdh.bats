load ../bats_setup
load ../bats_zencode
SUBDOC=ecdh

# teardown() { rm -rf $TMP }

@test "Generate a random password" {
    cat <<EOF | zexe SYM01.zen
Scenario ecdh: Generate a random password
Given nothing
When I create the random 'password'
Then print the 'password'
EOF
#    output=`cat $TMP/out`
    save_output secret.json
    assert_output '{"password":"XdjAYj+RY95+uyYMI8fR3+fmP5LyQaN54vyTTVKxZyA="}'
}

@test "Encrypt a message with the password" {
    cat <<EOF | zexe SYM02.zen
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
    save_output cipher_message.json
}


@test "Decrypt the message with the password" {
    cat <<EOF | zexe SYM03.zen cipher_message.json
Scenario ecdh: Decrypt the message with the password
Given I have a 'secret message'
When I write string 'my secret word' in 'password'
and I decrypt the text of 'secret message' with 'password'
Then print the 'text' as 'string'
and print the 'header' from 'secret message' as 'string'
EOF
     save_output clear_message.json
}

@test "Generate asymmetric keys for Alice and Bob" {
    cat <<EOF | zexe keygen.zen
Scenario ecdh
Given I am known as 'Alice'
When I create the keyring
and I create the ecdh key
Then print my 'keyring'
EOF
    save_output alice_keys.json
    cat << EOF | zexe pubkey.zen alice_keys.json
Scenario ecdh
Given I am known as 'Alice'
Given I have my 'keyring'
When I create the ecdh public key
Then print my 'ecdh public key'
EOF
    save_output alice_pubkey.json
    cat <<EOF | zexe keygen.zen
Scenario ecdh
Given I am known as 'Bob'
When I create the keyring
and I create the ecdh key
Then print my 'keyring'
EOF
    save_output bob_keys.json
    cat << EOF | zexe pubkey.zen bob_keys.json
Scenario ecdh
Given I am known as 'Bob'
Given I have my 'keyring'
When I create the ecdh public key
Then print my 'ecdh public key'
EOF
    save_output bob_pubkey.json
}

@test "check that secret key doesn't changes on pubkey generation" {
cat << EOF | zexe keygen_immutable.zen
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
}

@test "Alice encrypts a message for Bob" {
cat <<EOF | zexe enc_to_bob.zen alice_keys.json bob_pubkey.json
Rule check version 1.0.0
Scenario 'ecdh':
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
save_output enc_alice_to_bob.json
}


@test "Bob decrypts the message from Alice" {
cat <<EOF | zexe dec_from_alice.zen bob_keys.json enc_alice_to_bob.json
Rule check version 1.0.0
Scenario 'ecdh':
	Given that I am known as 'Bob'
	and I have my 'keyring'
	and I have a 'ecdh' public key from 'Alice'
	and I have a 'secret message'
	When I decrypt the text of 'secret message' from 'Alice'
	Then print the 'text' as 'string'
	and print the 'header' from 'secret message' as 'string'
EOF
save_output dec_bob_from_alice.json
}

@test "Alice signs a message" {
cat <<EOF | zexe sign_from_alice.zen alice_keys.json
Rule check version 2.0.0
Scenario 'ecdh'
Given that I am known as 'Alice'
and I have my 'keyring'
When I write string 'This is my authenticated message.' in 'message'
and I create the ecdh signature of 'message'
Then print the 'message'
and print the 'ecdh signature'
EOF
save_output sign_alice_keyring.json
}

@test "Verify a message signed by Alice" {
cat <<EOF | zexe verify_from_alice.zen alice_pubkey.json sign_alice_keyring.json
Rule check version 2.0.0
Scenario 'ecdh'
Given I have a 'ecdh' public key from 'Alice'
and I have a 'string' named 'message'
and I have a 'ecdh signature'
When I verify the 'message' has a ecdh signature in 'ecdh signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF
save_output verify_alice_signature.json
assert_output '{"message":"This_is_my_authenticated_message.","output":["Signature_is_valid"]}'
}
