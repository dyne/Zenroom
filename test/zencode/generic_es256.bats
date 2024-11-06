load ../bats_setup
load ../bats_zencode
SUBDOC=es256

@test "Generate asymmetric keys for Alice and Bob" {
    cat <<EOF | rngzexe keygen.zen
Scenario es256
Given I am known as 'Alice'
When I create the keyring
and I create the es256 key
Then print my 'keyring'
EOF
    save_output alice_keys.json
    cat << EOF | zexe pubkey.zen alice_keys.json
Scenario es256
Given I am known as 'Alice'
Given I have my 'keyring'
When I create the es256 public key
Then print my 'es256 public key'
EOF
    save_output alice_pubkey.json
    cat <<EOF | rngzexe keygen.zen
Scenario es256
Given I am known as 'Bob'
When I create the keyring
and I create the es256 key
Then print my 'keyring'
EOF
    save_output bob_keys.json
    cat << EOF | zexe pubkey.zen bob_keys.json
Scenario es256
Given I am known as 'Bob'
Given I have my 'keyring'
When I create the es256 public key
Then print my 'es256 public key'
EOF
    save_output bob_pubkey.json
}

@test "check that secret key doesn't changes on pubkey generation" {
    cat << EOF | zexe keygen_immutable.zen
Scenario es256
Given I am known as 'Carl'
When I create the es256 key
and I copy the 'es256' from 'keyring' to 'es256 before'
and I create the es256 public key
and I copy the 'es256' from 'keyring' to 'es256 after'
and I verify 'es256 before' is equal to 'es256 after'
Then print 'es256 before' as 'hex'
and print 'es256 after' as 'hex'
EOF
}

@test "Alice signs a message" {
    cat <<EOF | zexe sign_from_alice.zen alice_keys.json
Rule check version 2.0.0
Scenario es256
Given that I am known as 'Alice'
and I have my 'keyring'
When I write string 'This is my authenticated message.' in 'message'
and I create the es256 signature of 'message'
Then print the 'message'
and print the 'es256 signature'
EOF
    save_output sign_alice_keyring.json
}


@test "Verify a message signed by Alice" {
    cat <<EOF | zexe join_sign_pubkey.zen sign_alice_keyring.json alice_pubkey.json
Scenario es256
Given I have a 'es256 public key' in 'Alice'
and I have a 'es256 signature'
Then print the 'es256 signature'
and print the 'es256 public key'
EOF
    save_output sign_pubkey.json

    cat <<EOF | zexe verify_from_alice.zen sign_pubkey.json
Rule check version 2.0.0
Scenario es256
Given I have a 'es256 public key'
and I have a 'es256 signature'
When I write string 'This is my authenticated message.' in 'message'
and I verify the 'message' has a es256 signature in 'es256 signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF
    save_output verify_alice_signature.json
    assert_output '{"message":"This_is_my_authenticated_message.","output":["Signature_is_valid"]}'
}

@test "Fail verification on a different message" {
    cat <<EOF > wrong_message.zen
Rule check version 2.0.0
Scenario es256
Given I have a 'es256 public key'
and I have a 'es256 signature'
When I write string 'This is the wrong message.' in 'message'
and I verify the 'message' has a es256 signature in 'es256 signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF
    run $ZENROOM_EXECUTABLE -z -a sign_pubkey.json wrong_message.zen
    assert_line --partial 'The es256 signature by Alice is not authentic'
}

@test "Fail verification on a different public key" {
    cat <<EOF | rngzexe create_wrong_pubkey.zen sign_alice_keyring.json
Scenario es256
Given I have a 'es256 signature'
When I create the es256 key
and I create the es256 public key
Then print the 'es256 signature'
and print the 'es256 public key'
EOF
    save_output wrong_pubkey.json
    cat <<EOF > wrong_pubkey.zen
Rule check version 2.0.0
Scenario es256
Given I have a 'es256 public key'
and I have a 'es256 signature'
When I write string 'This is my authenticated message.' in 'message'
and I verify the 'message' has a es256 signature in 'es256 signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF
    run $ZENROOM_EXECUTABLE -z -a wrong_pubkey.json wrong_pubkey.zen
    assert_line --partial 'The es256 signature by Alice is not authentic'
}

@test "Alice signs a big file" {
    cat <<EOF > bigfile.zen
Rule check version 2.0.0
Given Nothing
When I create the random object of '1000000' bytes
and I rename 'random object' to 'bigfile'
Then print the 'bigfile' as 'base64'
EOF
	$ZENROOM_EXECUTABLE -z bigfile.zen > bigfile.json
    cat <<EOF | zexe sign_bigfile.zen alice_keys.json bigfile.json
Rule check version 2.0.0
Scenario es256
Given that I am known as 'Alice'
and I have my 'keyring'
and I have a 'base64' named 'bigfile'
When I create the es256 signature of 'bigfile'
Then print the 'es256 signature'
EOF
    save_output sign_bigfile_keyring.json
}

@test "Verify a big file signed by Alice" {
    cat <<EOF | zexe join_sign_pubkey.zen sign_bigfile_keyring.json alice_pubkey.json
Scenario es256
Given I have a 'es256 public key' in 'Alice'
and I have a 'es256 signature'
Then print the 'es256 signature'
and print the 'es256 public key'
EOF
    save_output sign_pubkey.json

    cat <<EOF | zexe verify_from_alice.zen sign_pubkey.json bigfile.json
Rule check version 2.0.0
Scenario es256
Given I have a 'es256 public key'
and I have a 'es256 signature'
and I have a 'base64' named 'bigfile'
When I verify the 'bigfile' has a es256 signature in 'es256 signature' by 'Alice'
Then print the string 'Bigfile Signature is valid'
EOF
    save_output verify_alice_signature.json
    assert_output '{"output":["Bigfile_Signature_is_valid"]}'
}
