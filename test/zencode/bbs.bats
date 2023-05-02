load ../bats_setup
load ../bats_zencode
SUBDOC=bbs

@test "Generate random keys for Alice and Bob" {
    cat <<EOF | rngzexe keygen.zen
Scenario bbs
Given I am known as 'Alice'
When I create the keyring
and I create the bbs key
Then print my 'keyring'
EOF
    save_output alice_keys.json
    cat << EOF | rngzexe pubkey.zen alice_keys.json
Scenario bbs
Given I am known as 'Alice'
Given I have my 'keyring'
When I create the bbs public key
Then print my 'bbs public key'
EOF
    save_output alice_pubkey.json
    cat <<EOF | rngzexe keygen.zen
Scenario bbs
Given I am known as 'Bob'
When I create the keyring
and I create the bbs key
Then print my 'keyring'
EOF
    save_output bob_keys.json
    cat << EOF | rngzexe pubkey.zen bob_keys.json
Scenario bbs
Given I am known as 'Bob'
Given I have my 'keyring'
When I create the bbs public key
Then print my 'bbs public key'
EOF
    save_output bob_pubkey.json
}

@test "check that secret key doesn't change on pubkey generation" {
    cat << EOF | zexe keygen_immutable.zen
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
    cat << EOF | save_asset bbssk.json
{"bbssk": "42"}
EOF
    cat << EOF | zexe sk2pk.zen bbssk.json
Scenario bbs
Given I have a 'integer' named 'bbssk'
When I create the bbs public key with secret key 'bbssk'
Then print 'bbs public key'
EOF
    save_output pubkey_from_sk.json
}

@test "Alice signs a message" {
    cat << EOF | save_asset 3messages.json
{
    "myStringArray": [
		"Hello World! This is my string array, element [0]",
		"Hello World! This is my string array, element [1]",
		"Hello World! This is my string array, element [2]"
	]
}
EOF
    cat <<EOF | zexe sign_from_alice.zen 3messages.json alice_keys.json
Rule check version 2.0.0
Scenario bbs
Given that I am known as 'Alice'
and I have my 'keyring'
Given I have a 'string array' named 'myStringArray'
When I create the bbs public key
When I create the bbs signature of 'myStringArray' using sha256
Then print the 'myStringArray'
and print the 'bbs signature'
EOF
    save_output sign_bbs_sha256.json
}
