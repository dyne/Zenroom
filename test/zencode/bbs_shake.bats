load ../bats_setup
load ../bats_zencode
SUBDOC=bbs

@test "Generate random keys for Alice and Bob" {
    cat <<EOF | rngzexe keygen_shake.zen
Scenario bbs
Given I am known as 'Alice'
When I create the keyring
and I create the bbs key
Then print my 'keyring'
EOF
    save_output alice_keys_shake.json
    cat << EOF | rngzexe pubkey_shake.zen alice_keys_shake.json
Scenario bbs
Given I am known as 'Alice'
Given I have my 'keyring'
When I create the bbs public key
Then print my 'bbs public key'
EOF
    save_output alice_pubkey_shake.json
    cat <<EOF | rngzexe keygen_shake.zen
Scenario bbs
Given I am known as 'Bob'
When I create the keyring
and I create the bbs key
Then print my 'keyring'
EOF
    save_output bob_keys_shake.json
    cat << EOF | rngzexe pubkey_shake.zen bob_keys_shake.json
Scenario bbs
Given I am known as 'Bob'
Given I have my 'keyring'
When I create the bbs public key
Then print my 'bbs public key'
EOF
    save_output bob_pubkey_shake.json
}

@test "check that secret key doesn't change on pubkey generation" {
    cat << EOF | zexe keygen_immutable_shake.zen
Scenario bbs
Given I am known as 'Carl'
When I create the bbs key
and I copy the 'bbs' in 'keyring' to 'bbs before'
and I create the bbs public key
and I copy the 'bbs' in 'keyring' to 'bbs after'
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
When I create the bbs public key with secret key 'bbssk'
Then print 'bbs public key'
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
When I create the bbs signature of 'message' using 'shake256'
Then print the 'message'
and print the 'bbs signature'
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
When I create the bbs signature of 'myStringArray' using 'shake256'
Then print the 'myStringArray'
and print the 'bbs signature'
EOF
    save_output sign_bbs_shake256_shake.json
}

@test "Alice signs the draft messages" {
    cat << EOF | save_asset key_data_shake.json
{
    "Alice": {
        "keyring": {
            "bbs": "Sjmv/9Yk1p6BgIsuhDhcyAv4atrfdk4DDKpGwjHyqNc="        
            }
    }
}
EOF
cat << EOF | save_asset multi_msg_data_shake.json
{
    "myStringArray": [
        "9872ad089e452c7b6e283dfac2a80d58e8d0ff71cc4d5e310a1debdda4a45f02",
        "87a8bd656d49ee07b8110e1d8fd4f1dcef6fb9bc368c492d9bc8c4f98a739ac6",
        "96012096adda3f13dd4adbe4eea481a4c4b5717932b73b00e31807d3c5894b90",
        "ac55fb33a75909edac8994829b250779298aa75d69324a365733f16c333fa943",
        "d183ddc6e2665aa4e2f088af9297b78c0d22b4290273db637ed33ff5cf703151",
        "515ae153e22aae04ad16f759e07237b43022cb1ced4c176e0999c6a8ba5817cc",
        "496694774c5604ab1b2544eababcf0f53278ff5040c1e77c811656e8220417a2",
        "77fe97eb97a1ebe2e81e4e3597a3ee740a66e9ef2412472c23364568523f8b91",
        "7372e9daa5ed31e6cd5c825eac1b855e84476a1d94932aa348e07b7320912416",
        "c344136d9ab02da4dd5908bbba913ae6f58c2cc844b802a6f811f5fb075f9b80"
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
Given I have a 'string' named 'bbs hash'
When I create the bbs signature of 'myStringArray' using 'bbs hash'
Then print the 'bbs signature'
Then print the string 'Test vectors originated from: draft-irtf-cfrg-bbs-signatures-latest Sections 7.3'
EOF
    save_output test_sign_bbs_shake256_shake.json
    assert_output '{"bbs_signature":"g+YpSgMblmV4WO63sXRFncese07+tsObJgJAk2DDtPQkhrnaK6MiTiaD51XQhC91Sl03iDUv3+A36vi5qSK99V3ONWVIk5hPOAydtpDCqURMQ6tnyShA2m4Z93nUEu2MfJeaeP3fukCpw40e4SSd5g==","output":["Test_vectors_originated_from:_draft-irtf-cfrg-bbs-signatures-latest_Sections_7.3"]}'
}


@test "Verify the draft messages signed by Alice" {
    cat << EOF | save_asset alice_pubkey_shake.json
{
    "Alice":{
        "bbs_public_key" : "qv+YMnglevxF+p1E0VbEVNcW+xolDf7RMtZbIAkzH2GMYjwU76FiRfUMyS5gM0BRCH8a6SZpuJaQ9f65LpFWj5Wo4obRELAR6ayZI/2HEjj1fRKVOVdxMx/27e5D5MzG"  
    } 
}
EOF
    cat <<EOF | zexe join_sign_pubkey_shake.zen test_sign_bbs_shake256_shake.json alice_pubkey_shake.json
Scenario bbs
Given I have a 'bbs public key' in 'Alice'
and I have a 'bbs signature'
Then print the 'bbs signature'
and print the 'bbs public key'
EOF
    save_output sign_pubkey_shake.json

    cat <<EOF | zexe verify_from_alice_shake.zen multi_msg_data_shake.json sign_pubkey_shake.json
Rule check version 2.0.0
Scenario bbs
Given I have a 'bbs public key'
and I have a 'bbs signature'
and I have a 'hex array' named 'myStringArray'
and I have a 'string' named 'bbs hash'
When I verify the 'myStringArray' has a bbs signature in 'bbs signature' by 'Alice' using 'bbs hash'
Then print the string 'Signature is valid'
EOF
    save_output verify_alice_signature_shake.json
    assert_output '{"output":["Signature_is_valid"]}'
}

@test "Fail verification on a different message" {
    cat <<EOF | save_asset wrong_message_shake.zen
Rule check version 2.0.0
Scenario bbs
Given I have a 'bbs public key'
and I have a 'bbs signature'
and I have a 'string array' named 'myStringArray'
When I verify the 'myStringArray' has a bbs signature in 'bbs signature' by 'Alice' using 'shake256'
Then print the string 'Signature is valid'
EOF
    run $ZENROOM_EXECUTABLE -z -a '3messages_shake.json' -k sign_pubkey_shake.json wrong_message_shake.zen
    assert_line '[W]  The bbs signature by Alice is not authentic'
}

@test "Fail verification on a different public key" {
    cat <<EOF | zexe join_sign_pubkey_shake.zen test_sign_bbs_shake256_shake.json bob_pubkey_shake.json
Scenario bbs
Given I have a 'bbs public key' in 'Bob'
and I have a 'bbs signature'
Then print the 'bbs signature'
and print the 'bbs public key'
EOF
    save_output sign_pubkey_shake.json

    cat <<EOF | save_asset verify_from_wrong_pk_shake.zen  
Scenario bbs
Given I have a 'bbs public key'
and I have a 'bbs signature'
and I have a 'hex array' named 'myStringArray'
When I verify the 'myStringArray' has a bbs signature in 'bbs signature' by 'Alice' using 'shake256'
Then print the string 'Signature is valid'
EOF
    run $ZENROOM_EXECUTABLE -z -a multi_msg_data_shake.json -k sign_pubkey_shake.json verify_from_wrong_pk_shake.zen
    assert_line '[W]  The bbs signature by Alice is not authentic'
}
