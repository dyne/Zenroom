load ../bats_setup
load ../bats_zencode
SUBDOC=larkg

derive_larkg_public_candidate() {
    local script_name="$1"
    local public_input="$2"
    local rho_input="$3"
    local public_name="$4"
    local output_name="$5"

    cat <<EOF | rngzexe "$script_name" "$public_input" "$rho_input"
Scenario larkg
Given I have a '$public_name'
and I have a 'larkg rho'
When I derive next larkg public key from '$public_name' with rho 'larkg rho'
Then print the 'larkg derived public key'
and print the 'larkg credential'
EOF
    save_output "$output_name"
}

derive_larkg_secret_candidate() {
    local script_name="$1"
    local keyring_input="$2"
    local credential_input="$3"
    local output_name="$4"

    if cat <<EOF | zexe "$script_name" "$keyring_input" "$credential_input"
Scenario larkg
Given I am known as 'Alice'
and I have my 'keyring'
and I have a 'larkg credential'
When I derive next larkg secret key with credential 'larkg credential'
Then print my 'keyring'
EOF
    then
        save_output "$output_name"
        return 0
    fi
    return 1
}

derive_larkg_until_accepted() {
    local name="$1"
    local public_input="$2"
    local rho_input="$3"
    local public_name="$4"
    local keyring_input="$5"
    local public_output="$6"
    local keyring_output="$7"

    for attempt in $(seq 1 100); do
        derive_larkg_public_candidate \
            "${name}_pk_${attempt}.zen" "$public_input" "$rho_input" \
            "$public_name" "$public_output"
        if derive_larkg_secret_candidate \
            "${name}_sk_${attempt}.zen" "$keyring_input" "$public_output" \
            "$keyring_output"; then
            return 0
        fi
    done

    echo "LARKG did not accept a fresh credential within 100 attempts" >&2
    return 1
}

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
    derive_larkg_until_accepted \
        derive alice_pubparams.json "" 'larkg public key' \
        alice_keyring.json derived_pk_and_cred.json alice_keyring_derived.json
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

@test "Reject a credential with an invalid schema length" {
    cat <<EOF | rngzexe short_cred.zen
Scenario larkg
Given nothing
When I create the random of '1' bytes
and I rename 'random' to 'larkg credential'
Then print the 'larkg credential'
EOF
    save_output short_cred.json

    cat <<EOF > parse_short_cred.zen
Scenario larkg
Given I have a 'larkg credential'
Then print the 'larkg credential'
EOF

    run "$ZENROOM_EXECUTABLE" -z -a short_cred.json parse_short_cred.zen
    assert_failure
    assert_line --partial 'Credential is not valid'
}

@test "Reject rho that does not match the public key" {
    cat <<EOF | zexe public_without_rho.zen alice_pubparams.json
Scenario larkg
Given I have a 'larkg public key'
Then print the 'larkg public key'
EOF
    save_output public_without_rho.json

    cat <<EOF | rngzexe wrong_rho.zen
Scenario larkg
Given nothing
When I create the random of '32' bytes
and I rename 'random' to 'larkg rho'
Then print the 'larkg rho'
EOF
    save_output wrong_rho.json

    cat <<EOF > mismatch_rho.zen
Scenario larkg
Given I have a 'larkg public key'
and I have a 'larkg rho'
When I derive next larkg public key from 'larkg public key' with rho 'larkg rho'
Then print the 'larkg derived public key'
EOF

    run "$ZENROOM_EXECUTABLE" -z -a public_without_rho.json -k wrong_rho.json mismatch_rho.zen
    assert_failure
    assert_line --partial 'LARKG rho does not match the public key'
}

@test "Ratchet: two consecutive key derivations" {
    cat <<EOF | zexe extract_rho.zen alice_pubparams.json
Scenario larkg
Given I have a 'larkg rho'
Then print the 'larkg rho'
EOF
    save_output alice_rho.json

    # Each rejected receiver-side candidate causes a fresh sender credential.
    derive_larkg_until_accepted \
        step1 alice_pubparams.json "" 'larkg public key' \
        alice_keyring.json step1_pk_cred.json alice_keyring1.json

    derive_larkg_until_accepted \
        step2 step1_pk_cred.json alice_rho.json 'larkg derived public key' \
        alice_keyring1.json step2_pk_cred.json alice_keyring2.json
}
