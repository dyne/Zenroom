load ../bats_setup
load ../bats_zencode
SUBDOC=bbs

@test "Generate random keys for Alice and Bob" {
    cat <<EOF | rngzexe keygen_shake.zen
Scenario bbs
Given I am known as 'Alice'
When I create the keyring
and I create the bbs shake key
Then print my 'keyring'
EOF
    save_output alice_keys_shake.json
    cat << EOF | rngzexe pubkey_shake.zen alice_keys_shake.json
Scenario bbs
Given I am known as 'Alice'
Given I have my 'keyring'
When I create the bbs shake public key
Then print my 'bbs shake public key'
EOF
    save_output alice_pubkey_shake.json
    cat <<EOF | rngzexe keygen_shake.zen
Scenario bbs
Given I am known as 'Bob'
When I create the keyring
and I create the bbs shake key
Then print my 'keyring'
EOF
    save_output bob_keys_shake.json
    cat << EOF | rngzexe pubkey_shake.zen bob_keys_shake.json
Scenario bbs
Given I am known as 'Bob'
Given I have my 'keyring'
When I create the bbs shake public key
Then print my 'bbs shake public key'
EOF
    save_output bob_pubkey_shake.json
}

@test "check that secret key doesn't change on pubkey generation" {
    cat << EOF | zexe keygen_immutable_shake.zen
Scenario bbs
Given I am known as 'Carl'
When I create the bbs shake key
and I copy the 'bbs shake' from 'keyring' to 'bbs before'
and I create the bbs shake public key
and I copy the 'bbs shake' from 'keyring' to 'bbs after'
and I verify 'bbs before' is equal to 'bbs after'
Then print 'bbs before' as 'hex'
and print 'bbs after' as 'hex'
EOF
}

@test "Generate pk from given sk" {
    cat << EOF | save_asset bbssk_shake.json
{"bbssk": "42"}
EOF
    cat << EOF | zexe sk2pk_shake.zen bbssk_shake.json
Scenario bbs
Given I have a 'integer' named 'bbssk'
When I create the bbs shake public key with secret key 'bbssk'
Then print 'bbs shake public key'
EOF
    save_output pubkey_from_sk_shake.json
}

@test "Alice signs a single message" {

    cat <<EOF | zexe sign_from_alice_shake.zen alice_keys_shake.json
Rule check version 2.0.0
Scenario bbs
Given that I am known as 'Alice'
and I have my 'keyring'
When I write string 'This is my authenticated message.' in 'message'
When I create the bbs shake signature of 'message'
Then print the 'message'
and print the 'bbs shake signature'
EOF
    save_output alice_single_sign_shake.json
}


@test "Alice signs multiple messages" {
    cat << EOF | save_asset 3messages_shake.json
{
    "myStringArray": [
		"Hello World! This is my string array, element [0]",
		"Hello World! This is my string array, element [1]",
		"Hello World! This is my string array, element [2]"
	]
}
EOF
    cat <<EOF | zexe sign_from_alice_shake.zen 3messages_shake.json alice_keys_shake.json
Rule check version 2.0.0
Scenario bbs
Given that I am known as 'Alice'
and I have my 'keyring'
Given I have a 'string array' named 'myStringArray'
When I create the bbs shake signature of 'myStringArray'
Then print the 'myStringArray'
and print the 'bbs shake signature'
EOF
    save_output sign_bbs_shake256_shake.json
}

@test "Alice signs the draft messages" {
    cat << EOF | save_asset key_data_shake.json
{
    "Alice": {
        "keyring": {
            "bbs_shake": "Lu4PYKijqL7A7pQr/UbL2umgc47mj1pk5yODEc8JoHk="        
            }
    }
}
EOF
cat << EOF | save_asset multi_msg_data_shake.json
{
    "myStringArray": [
    "9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02",
    "c344136d9ab02da4dd5908bbba913ae6f58c2cc844b802a6f811f5fb075f9b80",
    "7372e9daa5ed31e6cd5c825eac1b855e84476a1d94932aa348e07b73",
    "77fe97eb97a1ebe2e81e4e3597a3ee740a66e9ef2412472c",
    "496694774c5604ab1b2544eababcf0f53278ff50",
    "515ae153e22aae04ad16f759e07237b4",
    "d183ddc6e2665aa4e2f088af",
    "ac55fb33a75909ed",
    "96012096",
    ],
    "bbs_hash" : "shake256"
}
EOF
    cat <<EOF | zexe test_sign_from_alice_shake.zen multi_msg_data_shake.json key_data_shake.json
Rule check version 2.0.0
Scenario bbs
Given I am 'Alice' 
Given I have my 'keyring' 
Given I have a 'hex array' named 'myStringArray'
When I write string '' in 'empty string'
When I move 'empty string' in 'myStringArray'
When I create the bbs shake signature of 'myStringArray'
Then print the 'bbs shake signature'
Then print the string 'Test vectors originated from: draft-irtf-cfrg-bbs-signatures-latest_Appendix_D.1.1.1'
EOF
    save_output test_sign_bbs_shake256_shake.json
    assert_output '{"bbs_shake_signature":"iL7rlw+AMWDTBY6s3lBSB8V2qMnk5dx8UknLzyoEbBX43wRwMe7zQ24Et3nZKpzbH+TGzANboWNPF0D53UmBbTynRey+OfZV6mH7cAE3/e0=","output":["Test_vectors_originated_from:_draft-irtf-cfrg-bbs-signatures-latest_Appendix_D.1.1.1"]}'
}


@test "Verify the draft messages signed by Alice" {
    cat << EOF | save_asset alice_pubkey_shake.json
{
    "Alice":{
        "bbs_shake_public_key" : "ktN9HWzTj+o6hzlTMz6rI6TAN34+BJl062K9RZSc3rGPsEkO3NRCmt/1bmXLzkLPGIsxvdvWGeQZuZwsQbOBeesAGWO8Peyq4Nn3AseowATyB/Rsc0peri6OgoM/Pn6l"  
    } 
}
EOF
    cat <<EOF | zexe join_sign_pubkey_shake.zen test_sign_bbs_shake256_shake.json alice_pubkey_shake.json
Scenario bbs
Given I have a 'bbs shake public key' in 'Alice'
and I have a 'bbs shake signature'
Then print the 'bbs shake signature'
and print the 'bbs shake public key'
EOF
    save_output sign_pubkey_shake.json

    cat <<EOF | zexe verify_from_alice_shake.zen multi_msg_data_shake.json sign_pubkey_shake.json
Rule check version 2.0.0
Scenario bbs
Given I have a 'bbs shake public key'
and I have a 'bbs shake signature'
and I have a 'hex array' named 'myStringArray'
When I write string '' in 'empty string'
When I move 'empty string' in 'myStringArray'
When I verify the 'myStringArray' has a bbs shake signature in 'bbs shake signature' by 'Alice'
Then print the string 'Signature is valid'
EOF
    save_output verify_alice_signature_shake.json
    assert_output '{"output":["Signature_is_valid"]}'
}

@test "Fail verification on a different message" {
    cat <<EOF | save_asset wrong_message_shake.zen
Rule check version 2.0.0
Scenario bbs
Given I have a 'bbs shake public key'
and I have a 'bbs shake signature'
and I have a 'string array' named 'myStringArray'
When I verify the 'myStringArray' has a bbs shake signature in 'bbs shake signature' by 'Alice'
Then print the string 'Signature is valid'
EOF
    run $ZENROOM_EXECUTABLE -z -a '3messages_shake.json' -k sign_pubkey_shake.json wrong_message_shake.zen
    assert_line --partial 'The bbs shake signature by Alice is not authentic'
}

@test "Fail verification on a different public key" {
    cat <<EOF | zexe join_sign_pubkey_shake.zen test_sign_bbs_shake256_shake.json bob_pubkey_shake.json
Scenario bbs
Given I have a 'bbs shake public key' in 'Bob'
and I have a 'bbs shake signature'
Then print the 'bbs shake signature'
and print the 'bbs shake public key'
EOF
    save_output sign_pubkey_shake.json

    cat <<EOF | save_asset verify_from_wrong_pk_shake.zen  
Scenario bbs
Given I have a 'bbs shake public key'
and I have a 'bbs shake signature'
and I have a 'hex array' named 'myStringArray'
When I verify the 'myStringArray' has a bbs shake signature in 'bbs shake signature' by 'Alice'
Then print the string 'Signature is valid'
EOF
    run $ZENROOM_EXECUTABLE -z -a multi_msg_data_shake.json -k sign_pubkey_shake.json verify_from_wrong_pk_shake.zen
    assert_line --partial 'The bbs shake signature by Alice is not authentic'
}
