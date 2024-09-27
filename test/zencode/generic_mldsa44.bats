load ../bats_setup
load ../bats_zencode
SUBDOC=mldsa44

@test "Generate asymmetric keys for Alice and Bob" {
    cat <<EOF | rngzexe alice_keygen.zen
Scenario qp
Given I am known as 'Alice'
When I create the keyring
and I create the mldsa44 key
Then print my 'keyring'
EOF
    save_output alice_keys.json
    cat << EOF | zexe alice_pubkey.zen alice_keys.json
Scenario qp
Given I am known as 'Alice'
Given I have my 'keyring'
When I create the mldsa44 public key
Then print my 'mldsa44 public key'
EOF
    save_output alice_pubkey.json
    cat <<EOF | rngzexe bob_keygen.zen
Scenario qp
Given I am known as 'Bob'
When I create the keyring
and I create the mldsa44 key
Then print my 'keyring'
EOF
    save_output bob_keys.json
    cat << EOF | zexe bob_pubkey.zen bob_keys.json
Scenario qp
Given I am known as 'Bob'
Given I have my 'keyring'
When I create the mldsa44 public key
Then print my 'mldsa44 public key'
EOF
    save_output bob_pubkey.json
}

@test "check that secret key doesn't changes on pubkey generation" {
    cat << EOF | zexe keygen_immutable.zen
Scenario qp
Given I am known as 'Carl'
When I create the mldsa44 key
and I copy the 'mldsa44' from 'keyring' to 'mldsa44 before'
and I create the mldsa44 public key
and I copy the 'mldsa44' from 'keyring' to 'mldsa44 after'
and I verify 'mldsa44 before' is equal to 'mldsa44 after'
Then print 'mldsa44 before' as 'hex'
and print 'mldsa44 after' as 'hex'
EOF
}

@test "Alice signs a message" {
    cat <<EOF | zexe sign_from_alice.zen alice_keys.json
Rule check version 4.42.0
Scenario qp
Given that I am known as 'Alice'
and I have my 'keyring'
When I write string 'This is my authenticated message.' in 'message'
and I create the mldsa44 signature of 'message'
Then print the 'message'
and print the 'mldsa44 signature'
EOF
    save_output sign_alice_output.json
}


@test "Verify a message signed by Alice" {
    cat <<EOF | zexe join_sign_pubkey.zen sign_alice_output.json alice_pubkey.json
Scenario qp
Given I have a 'mldsa44 public key' in 'Alice'
and I have a 'mldsa44 signature'
and I have a 'string' named 'message'
Then print the 'mldsa44 signature'
and print the 'mldsa44 public key'
and print the 'message'
EOF
    save_output sign_pubkey.json

    cat <<EOF | zexe verify_from_alice.zen sign_pubkey.json
Rule check version 4.42
Scenario qp
Given I have a 'mldsa44 public key'
and I have a 'mldsa44 signature'
and I have a 'string' named 'message'
When I verify the 'message' has a mldsa44 signature in 'mldsa44 signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF
    save_output verify_alice_signature.json
    assert_output '{"message":"This_is_my_authenticated_message.","output":["Signature_is_valid"]}'
}

@test "Alice signs a message with a ctx" {
    cat <<EOF | zexe sign_from_alice_ctx.zen alice_keys.json
Rule check version 4.42
Scenario qp
Given that I am known as 'Alice'
and I have my 'keyring'
When I write string 'This is my authenticated message.' in 'message'
and I set 'ctx' to '480c658c0cb3e040bde084345cef0df7' as 'hex'
and I create the mldsa44 signature of 'message'
Then print the 'message'
and print the 'mldsa44 signature'
and print the 'ctx'
EOF
    save_output sign_alice_ctx_output.json
}

@test "Verify a message signed by Alice with a ctx" {
    cat <<EOF | zexe join_sign_pubkey_ctx.zen sign_alice_ctx_output.json alice_pubkey.json
Scenario qp
Given I have a 'mldsa44 public key' in 'Alice'
and I have a 'mldsa44 signature'
and I have a 'string' named 'message'
and I have an 'hex' named 'ctx'
Then print the 'mldsa44 signature'
and print the 'mldsa44 public key'
and print the 'message'
and print the 'ctx'
EOF
    save_output sign_pubkey_ctx.json

    cat <<EOF | zexe verify_from_alice_ctx.zen sign_pubkey_ctx.json
Rule check version 4.42
Scenario qp
Given I have a 'mldsa44 public key'
and I have a 'mldsa44 signature'
and I have a 'string' named 'message'
and I have an 'hex' named 'ctx'
When I verify the 'message' has a mldsa44 signature in 'mldsa44 signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF
    save_output verify_alice_signature_ctx.json
    assert_output '{"message":"This_is_my_authenticated_message.","output":["Signature_is_valid"]}'
}

@test "Fail verification on a different message" {
    cat <<EOF > wrong_message.zen
Rule check version 4.42
Scenario qp
Given I have a 'mldsa44 public key'
and I have a 'mldsa44 signature'
When I write string 'This is the wrong message.' in 'message'
and I verify the 'message' has a mldsa44 signature in 'mldsa44 signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF
    run $ZENROOM_EXECUTABLE -z -a sign_pubkey.json wrong_message.zen
    assert_line --partial 'The mldsa44 signature by Alice is not authentic'
}

@test "Fail verification on a different public key" {
    cat <<EOF | rngzexe create_wrong_pubkey.zen sign_alice_output.json
Scenario qp
Given I have a 'mldsa44 signature'
and I have a 'string' named 'message'
When I create the mldsa44 key
and I create the mldsa44 public key
Then print the 'mldsa44 signature'
and print the 'mldsa44 public key'
and print the 'message'
EOF
    save_output wrong_pubkey.json
    cat <<EOF > wrong_pubkey.zen
Rule check version 4.42
Scenario qp
Given I have a 'mldsa44 public key'
and I have a 'mldsa44 signature'
and I have a 'string' named 'message'
When I verify the 'message' has a mldsa44 signature in 'mldsa44 signature' by 'Alice'
Then print the string 'Signature is valid'
and print the 'message'
EOF
    run $ZENROOM_EXECUTABLE -z -a wrong_pubkey.json wrong_pubkey.zen
    assert_line --partial 'The mldsa44 signature by Alice is not authentic'
}

@test "Alice signs a big file" {
    cat <<EOF | $ZENROOM_EXECUTABLE -z > bigfile.json
Rule check version 4.42
Given Nothing
When I create the random object of '1000000' bytes
and I rename 'random object' to 'bigfile'
Then print the 'bigfile' as 'base64'
EOF

    cat <<EOF | zexe sign_bigfile.zen alice_keys.json bigfile.json
Rule check version 4.42
Scenario qp
Given that I am known as 'Alice'
and I have my 'keyring'
and I have a 'base64' named 'bigfile'
When I create the mldsa44 signature of 'bigfile'
Then print the 'mldsa44 signature'
EOF
    save_output sign_bigfile_keyring.json
}

@test "Verify a big file signed by Alice" {
    cat <<EOF | zexe join_sign_pubkey.zen sign_bigfile_keyring.json alice_pubkey.json
Scenario qp
Given I have a 'mldsa44 public key' in 'Alice'
and I have a 'mldsa44 signature'
Then print the 'mldsa44 signature'
and print the 'mldsa44 public key'
EOF
    save_output sign_pubkey_big.json

    cat <<EOF | zexe verify_from_alice_big.zen sign_pubkey_big.json bigfile.json
Rule check version 4.42
Scenario qp
Given I have a 'mldsa44 public key'
and I have a 'mldsa44 signature'
and I have a 'base64' named 'bigfile'
When I verify the 'bigfile' has a mldsa44 signature in 'mldsa44 signature' by 'Alice'
Then print the string 'Bigfile Signature is valid'
EOF
    save_output verify_alice_signature_big.json
    assert_output '{"output":["Bigfile_Signature_is_valid"]}'
}
