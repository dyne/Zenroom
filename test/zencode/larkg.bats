load ../bats_setup
load ../bats_zencode
SUBDOC=larkg

@test "Generate LARKG keypair for Alice" {
    cat <<EOF | rngzexe keygen.zen
Scenario larkg
Given I am known as 'Alice'
When I create the keyring
and I create the larkg key
Then print my 'keyring'
and print my 'larkg public key'
and print my 'larkg rho'
EOF
    save_output alice_larkg.json

    # Split keyring, public key and rho into separate files for later steps
    cat <<EOF | zexe split_alice.zen alice_larkg.json
Scenario larkg
Given I am known as 'Alice'
and I have my 'keyring'
and I have my 'larkg public key'
and I have my 'larkg rho'
Then print my 'keyring'
EOF
    save_output alice_keyring.json

    cat <<EOF | zexe split_pubkey.zen alice_larkg.json
Scenario larkg
Given I am known as 'Alice'
and I have my 'larkg public key'
and I have my 'larkg rho'
Then print the 'larkg public key'
and print the 'larkg rho'
EOF
    save_output alice_pubparams.json
}

@test "Sender derives next public key for Alice" {
    cat <<EOF | zexe derive_pk.zen alice_pubparams.json
Scenario larkg
Given I have a 'larkg public key'
and I have a 'larkg rho'
When I derive next larkg public key from 'larkg public key' with rho 'larkg rho'
Then print the 'larkg derived public key'
and print the 'larkg credential'
EOF
    save_output derived_pk_and_cred.json
}

@test "Alice derives her next secret key from the credential" {
    cat <<EOF | zexe derive_sk.zen alice_keyring.json derived_pk_and_cred.json
Scenario larkg
Given I am known as 'Alice'
and I have my 'keyring'
and I have a 'larkg credential'
When I derive next larkg secret key with credential 'larkg credential'
Then print my 'keyring'
EOF
    save_output alice_keyring_derived.json
}

@test "Fail derivation with corrupted credential" {
    # Corrupt the credential by replacing it with random bytes of the same length
    cat <<EOF | rngzexe corrupt_cred.zen
Scenario larkg
Given nothing
When I create the random of '928' bytes
and I rename 'random' to 'larkg credential'
Then print the 'larkg credential'
EOF
save_output corrupted_cred.json

    cat <<EOF > fail_derive_sk.zen
Scenario larkg
Given I am known as 'Alice'
and I have my 'keyring'
and I have a 'larkg credential'
When I derive next larkg secret key with credential 'larkg credential'
Then print the 'larkg secret key'
EOF

    run $ZENROOM_EXECUTABLE -z -k alice_keyring.json -a corrupted_cred.json fail_derive_sk.zen
    assert_line --partial 'LARKG authentication failed'
}

@test "Ratchet: two consecutive key derivations" {
    cat <<EOF | zexe extract_rho.zen alice_pubparams.json
Scenario larkg
Given I have a 'larkg rho'
Then print the 'larkg rho'
EOF
    save_output alice_rho.json

    # Step 1: sender derives pk_1 from pk_0
    cat <<EOF | rngzexe derive_pk1.zen alice_pubparams.json
Scenario larkg
Given I have a 'larkg public key'
and I have a 'larkg rho'
When I derive next larkg public key from 'larkg public key' with rho 'larkg rho'
Then print the 'larkg derived public key'
and print the 'larkg credential'
EOF
    save_output step1_pk_cred.json

    # Step 1: Alice derives sk_1
    cat <<EOF | zexe derive_sk1.zen alice_keyring.json step1_pk_cred.json
Scenario larkg
Given I am known as 'Alice'
and I have my 'keyring'
and I have a 'larkg credential'
When I derive next larkg secret key with credential 'larkg credential'
Then print my 'keyring'
EOF
    save_output alice_keyring1.json

    # Step 2: sender derives pk_2 from pk_1, using only rho (no collision)
    cat <<EOF | rngzexe derive_pk2.zen step1_pk_cred.json alice_rho.json
Scenario larkg
Given I have a 'larkg derived public key'
and I have a 'larkg rho'
When I derive next larkg public key from 'larkg derived public key' with rho 'larkg rho'
Then print the 'larkg derived public key'
and print the 'larkg credential'
EOF
    save_output step2_pk_cred.json

    # Step 2: Alice derives sk_2 from sk_1
    cat <<EOF | zexe derive_sk2.zen alice_keyring1.json step2_pk_cred.json
Scenario larkg
Given I am known as 'Alice'
and I have my 'keyring'
and I have a 'larkg credential'
When I derive next larkg secret key with credential 'larkg credential'
Then print my 'keyring'
EOF
    save_output alice_keyring2.json
}
