load ../bats_setup
load ../bats_zencode
SUBDOC=ecdh

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

@test "Alice signs a message" {
    cat <<EOF | zexe sign_from_alice.zen alice_keys.json
Rule check version 2.0.0
Scenario ecdh
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
    cat <<EOF | zexe join_sign_pubkey.zen sign_alice_keyring.json alice_pubkey.json
Scenario ecdh
Given I have a 'ecdh public key' in 'Alice'
and I have a 'ecdh signature'
Then print the 'ecdh signature'
and print the 'ecdh public key'
EOF
    save_output sign_pubkey.json

    cat <<EOF | zexe verify_from_alice.zen sign_pubkey.json
Rule check version 2.0.0
Scenario ecdh
Given I have a 'ecdh public key'
and I have a 'ecdh signature'
When I write string 'This is my authenticated message.' in 'message'
and I verify the 'message' has a ecdh signature in 'ecdh signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF
    save_output verify_alice_signature.json
    assert_output '{"message":"This_is_my_authenticated_message.","output":["Signature_is_valid"]}'
}

@test "Fail verification on a different message" {
    cat <<EOF > wrong_message.zen
Rule check version 2.0.0
Scenario ecdh
Given I have a 'ecdh public key'
and I have a 'ecdh signature'
When I write string 'This is the wrong message.' in 'message'
and I verify the 'message' has a ecdh signature in 'ecdh signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF
    run $ZENROOM_EXECUTABLE -z wrong_message.zen -a sign_pubkey.json
    assert_failure
}

@test "Fail verification on a different public key" {
    cat <<EOF | rngzexe create_wrong_pubkey.zen sign_alice_keyring.json
Scenario ecdh
Given I have a 'ecdh signature'
When I create the ecdh key
and I create the ecdh public key
Then print the 'ecdh signature'
and print the 'ecdh public key'
EOF
    save_output wrong_pubkey.json
    cat <<EOF > wrong_pubkey.zen
Rule check version 2.0.0
Scenario ecdh
Given I have a 'ecdh public key'
and I have a 'ecdh signature'
When I write string 'This is my authenticated message.' in 'message'
and I verify the 'message' has a ecdh signature in 'ecdh signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF
    run $ZENROOM_EXECUTABLE -z wrong_pubkey.zen -a wrong_pubkey.json
    assert_failure
}

@test "Alice signs a big file" {
    cat <<EOF | $ZENROOM_EXECUTABLE -z > bigfile.json
Rule check version 2.0.0
Given Nothing
When I create the random object of '1000000' bytes
and I rename 'random object' to 'bigfile'
Then print the 'bigfile' as 'base64'
EOF

    cat <<EOF | zexe sign_bigfile.zen alice_keys.json bigfile.json
Rule check version 2.0.0
Scenario 'ecdh'
Given that I am known as 'Alice'
and I have my 'keyring'
and I have a 'base64' named 'bigfile'
When I create the ecdh signature of 'bigfile'
Then print the 'ecdh signature'
EOF
    save_output sign_bigfile_keyring.json
}

@test "Verify a big file signed by Alice" {
    cat <<EOF | zexe join_sign_pubkey.zen sign_bigfile_keyring.json alice_pubkey.json
Scenario ecdh
Given I have a 'ecdh public key' in 'Alice'
and I have a 'ecdh signature'
Then print the 'ecdh signature'
and print the 'ecdh public key'
EOF
    save_output sign_pubkey.json

    cat <<EOF | zexe verify_from_alice.zen sign_pubkey.json bigfile.json
Rule check version 2.0.0
Scenario 'ecdh'
Given I have a 'ecdh public key'
and I have a 'ecdh signature'
and I have a 'base64' named 'bigfile'
When I verify the 'bigfile' has a ecdh signature in 'ecdh signature' by 'Alice'
Then print the string 'Bigfile Signature is valid'
EOF
    save_output verify_alice_signature.json
    assert_output '{"output":["Bigfile_Signature_is_valid"]}'
}
