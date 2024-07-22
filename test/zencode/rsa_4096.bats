load ../bats_setup
load ../bats_zencode
SUBDOC=rsa

@test "Generate asymmetric keys for Alice and Bob" {
    cat <<EOF | rngzexe alice_rsa_keygen.zen
Scenario rsa
Given I am known as 'Alice'
When I create the keyring
and I create the rsa key
Then print my 'keyring'
EOF
    save_output alice_rsa_keys.json
    cat << EOF | zexe alice_rsa_pubkey.zen alice_rsa_keys.json
Scenario rsa
Given I am known as 'Alice'
Given I have my 'keyring'
When I create the rsa public key
Then print my 'rsa public key'
EOF
    save_output alice_rsa_pubkey.json
    cat <<EOF | rngzexe bob_rsa_keygen.zen
Scenario rsa
Given I am known as 'Bob'
When I create the keyring
and I create the rsa key
Then print my 'keyring'
EOF
    save_output bob_rsa_keys.json
    cat << EOF | zexe bob_rsa_pubkey.zen bob_rsa_keys.json
Scenario rsa
Given I am known as 'Bob'
Given I have my 'keyring'
When I create the rsa public key
Then print my 'rsa public key'
EOF
    save_output bob_rsa_pubkey.json
}

@test "check that secret key doesn't changes on pubkey generation" {
    cat << EOF | zexe keygen_immutable_rsa.zen
Scenario rsa
Given I am known as 'Carl'
When I create the rsa key
and I copy the 'rsa' from 'keyring' to 'rsa before'
and I create the rsa public key
and I copy the 'rsa' from 'keyring' to 'rsa after'
and I verify 'rsa before' is equal to 'rsa after'
Then print 'rsa before' as 'hex'
and print 'rsa after' as 'hex'
EOF
}

@test "Alice signs a message" {
    cat <<EOF | zexe sign_rsa_from_alice.zen alice_rsa_keys.json
Rule check version 4.32.6
Scenario rsa
Given that I am known as 'Alice'
and I have my 'keyring'
When I write string 'This is my authenticated message.' in 'message'
and I create the rsa signature of 'message'
Then print the 'message'
and print the 'rsa signature'
EOF
    save_output sign_rsa_alice_output.json
}


@test "Verify a message signed by Alice" {
    cat <<EOF | zexe join_sign_rsa_pubkey.zen sign_rsa_alice_output.json alice_rsa_pubkey.json
Scenario rsa
Given I have a 'rsa public key' in 'Alice'
and I have a 'rsa signature'
and I have a 'string' named 'message'
Then print the 'rsa signature'
and print the 'rsa public key'
and print the 'message'
EOF
    save_output sign_rsa_pubkey.json

    cat <<EOF | zexe verify_rsa_from_alice.zen sign_rsa_pubkey.json
Rule check version 4.32.6
Scenario rsa
Given I have a 'rsa public key'
and I have a 'rsa signature'
and I have a 'string' named 'message'
When I verify the 'message' has a rsa signature in 'rsa signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF
    save_output verify_rsa_alice_signature.json
    assert_output '{"message":"This_is_my_authenticated_message.","output":["Signature_is_valid"]}'
}

@test "Fail verification on a different message" {
    cat <<EOF > wrong_rsa_message.zen
Rule check version 4.32.6
Scenario rsa
Given I have a 'rsa public key'
and I have a 'rsa signature'
When I write string 'This is the wrong message.' in 'message'
and I verify the 'message' has a rsa signature in 'rsa signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF
    run $ZENROOM_EXECUTABLE -z -a sign_rsa_pubkey.json wrong_rsa_message.zen
    assert_line --partial 'The rsa signature by Alice is not authentic'
}

@test "Fail verification on a different public key" {
    cat <<EOF | rngzexe create_rsa_wrong_pubkey.zen sign_rsa_alice_output.json
Scenario rsa
Given I have a 'rsa signature'
and I have a 'string' named 'message'
When I create the rsa key
and I create the rsa public key
Then print the 'rsa signature'
and print the 'rsa public key'
and print the 'message'
EOF
    save_output wrong_rsa_pubkey.json
    cat <<EOF > wrong_rsa_pubkey.zen
Rule check version 4.32.6
Scenario rsa
Given I have a 'rsa public key'
and I have a 'rsa signature'
and I have a 'string' named 'message'
When I verify the 'message' has a rsa signature in 'rsa signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF
    run $ZENROOM_EXECUTABLE -z -a wrong_rsa_pubkey.json wrong_rsa_pubkey.zen
    assert_line --partial 'The rsa signature by Alice is not authentic'
}

@test "Alice signs a big file" {
    cat <<EOF | $ZENROOM_EXECUTABLE -z > bigfile_rsa.json
Rule check version 4.32.6
Given Nothing
When I create the random object of '1000000' bytes
and I rename 'random object' to 'bigfile'
Then print the 'bigfile' as 'base64'
EOF

    cat <<EOF | zexe sign_rsa_bigfile.zen alice_rsa_keys.json bigfile_rsa.json
Rule check version 4.32.6
Scenario rsa
Given that I am known as 'Alice'
and I have my 'keyring'
and I have a 'base64' named 'bigfile'
When I create the rsa signature of 'bigfile'
Then print the 'rsa signature'
EOF
    save_output sign_rsa_bigfile_keyring.json
}

@test "Verify a big file signed by Alice" {
    cat <<EOF | zexe join_sign_pubkey.zen sign_rsa_bigfile_keyring.json alice_rsa_pubkey.json
Scenario rsa
Given I have a 'rsa public key' in 'Alice'
and I have a 'rsa signature'
Then print the 'rsa signature'
and print the 'rsa public key'
EOF
    save_output sign_rsa_pubkey_big.json

    cat <<EOF | zexe verify_rsa_from_alice_big.zen sign_rsa_pubkey_big.json bigfile_rsa.json
Rule check version 4.32.6
Scenario rsa
Given I have a 'rsa public key'
and I have a 'rsa signature'
and I have a 'base64' named 'bigfile'
When I verify the 'bigfile' has a rsa signature in 'rsa signature' by 'Alice'
Then print the string 'Bigfile Signature is valid'
EOF
    save_output verify_rsa_alice_signature_big.json
    assert_output '{"output":["Bigfile_Signature_is_valid"]}'
}
