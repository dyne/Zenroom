load ../bats_setup
load ../bats_zencode
SUBDOC=larkg

@test "LARKG emits tagged boundary objects" {
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
    cat <<EOF | zexe validate.zen alice_larkg.json
Scenario larkg
Given I am known as 'Alice'
and I have my 'keyring'
and I have my 'larkg public key'
and I have my 'larkg rho'
Then print my 'keyring'
and print my 'larkg public key'
EOF
}

@test "LARKG rejects untagged credentials before crypto" {
    cat <<EOF | rngzexe raw_credential.zen
Scenario larkg
Given nothing
When I create the random of '928' bytes
and I rename 'random' to 'larkg credential'
Then print the 'larkg credential'
EOF
    save_output raw_credential.json
    cat <<EOF > parse_raw_credential.zen
Scenario larkg
Given I have a 'larkg credential'
Then print the 'larkg credential'
EOF
    run "$ZENROOM_EXECUTABLE" -z -a raw_credential.json parse_raw_credential.zen
    assert_failure
    assert_line --partial 'Credential is not valid'
}

@test "LARKG rejects invalid rho schema length" {
    cat <<EOF | rngzexe short_rho.zen
Scenario larkg
Given nothing
When I create the random of '1' bytes
and I rename 'random' to 'larkg rho'
Then print the 'larkg rho'
EOF
    save_output short_rho.json
    cat <<EOF > parse_short_rho.zen
Scenario larkg
Given I have a 'larkg rho'
Then print the 'larkg rho'
EOF
    run "$ZENROOM_EXECUTABLE" -z -a short_rho.json parse_short_rho.zen
    assert_failure
    assert_line --partial 'LARKG rho is not valid'
}

@test "LARKG depth-zero contract rejects derivation deterministically" {
    cat <<EOF | rngzexe create.zen
Scenario larkg
Given I am known as 'Alice'
When I create the keyring
and I create the larkg key
Then print my 'larkg public key'
and print my 'larkg rho'
EOF
    save_output public.json
    cat <<EOF > derive.zen
Scenario larkg
Given I am known as 'Alice'
and I have my 'larkg public key'
and I have my 'larkg rho'
When I derive next larkg public key from 'larkg public key' with rho 'larkg rho'
Then print the 'larkg derived public key'
EOF
    run "$ZENROOM_EXECUTABLE" -z -a public.json derive.zen
    assert_failure
    assert_line --partial 'does not support derivation'
}
