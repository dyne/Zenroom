load ../bats_setup
load ../bats_zencode

SUBDOC=zkp

@test "credential key generation" {
    cat << EOF | zexe credentialParticipantKeygen.zen
Scenario credential: 
    Given that I am known as 'Alice'
    When I create the credential key
    Then print my 'keyring'
EOF
    save_output credentialParticipantKeypair.json
}

@test "credential request generation" {
    cat << EOF | zexe credentialParticipantSignatureRequest.zen credentialParticipantKeypair.json
Scenario credential: create request
    Given that I am known as 'Alice'
    and I have my valid 'keyring'
    When I create the credential request
    Then print my 'credential request'
EOF
    save_output credentialParticipantSignatureRequest.json
}

@test "issuer keygen" {
    cat << EOF | zexe credentialIssuerKeygen.zen
Scenario credential: issuer keygen
    Given that I am known as 'MadHatter'
    When I create the issuer key
    Then print my 'keyring'
EOF
    save_output credentialIssuerKeypair.json
}

@test "publish issuer public key" {
    cat << EOF | zexe credentialIssuerPublishpublic_key.zen credentialIssuerKeypair.json
Scenario credential: publish public_key
    Given that I am known as 'MadHatter'
    and I have my 'keyring'
    When I create the issuer public key
    Then print my 'issuer public key'
EOF
     save_output credentialIssuerpublic_key.json
}

@test "issuer sign" {
     cat << EOF | zexe credentialIssuerSignRequest.zen credentialParticipantSignatureRequest.json credentialIssuerKeypair.json
Scenario credential: issuer sign
    Given that I am known as 'MadHatter'
    and I have my valid 'keyring'
    and I have a 'credential request' inside 'Alice'
    When I create the credential signature
    and I create the issuer public key
    Then print the 'credential signature'
    and print the 'issuer public key'
EOF
     save_output credentialIssuerSignedCredential.json
}

@test "aggregate signature" {
     cat << EOF | zexe credentialParticipantAggregateCredential.zen credentialIssuerSignedCredential.json credentialParticipantKeypair.json
Scenario credential: aggregate signature
    Given that I am known as 'Alice'
    and I have my 'keyring'
    and I have a 'credential signature'
    When I create the credentials
    Then print my 'credentials'
    and print my 'keyring'
EOF
     save_output credentialParticipantAggregatedCredential.json
}

@test "create proof" {
    cat << EOF | zexe credentialParticipantCreateProof.zen credentialParticipantAggregatedCredential.json credentialIssuerpublic_key.json
Scenario credential: create proof
    Given that I am known as 'Alice'
    and I have my 'keyring'
    and I have a 'issuer public key' inside 'MadHatter'
    and I have my 'credentials'
    When I aggregate all the issuer public keys
    and I create the credential proof
    Then print the 'credential proof'
EOF
    save_output credentialParticipantProof.json
}

@test "verify proof" {
    cat << EOF | zexe credentialAnyoneVerifyProof.zen credentialParticipantProof.json credentialIssuerpublic_key.json
Scenario credential: verify proof
    Given that I have a 'issuer public key' inside 'MadHatter'
    and I have a 'credential proof'
    When I aggregate all the issuer public keys
    When I verify the credential proof
    then print the string 'the proof matches the public_key! So you can add zencode after the verify statement, that will execute only if the match occurs.'
EOF
    save_output verified_proof.json
    assert_output '{"output":["the_proof_matches_the_public_key!_So_you_can_add_zencode_after_the_verify_statement,_that_will_execute_only_if_the_match_occurs."]}'    
}

@test "check proof untraceability" {
    cat << EOF > $TMP/proofgen.zen
Scenario credential: create randomized proof
    Given that I am known as 'Alice'
    and I have my 'keyring'
    and I have a 'issuer public key' inside 'MadHatter'
    and I have my 'credentials'
    When I aggregate all the issuer public keys
    and I create the credential proof
    Then print the 'credential proof'
EOF
    cat $TMP/proofgen.zen | rngzexe rngproof.zen credentialParticipantAggregatedCredential.json credentialIssuerpublic_key.json
    save_output rngproof.json
    proof1="$output"
    cat $TMP/proofgen.zen | rngzexe rngproof.zen credentialParticipantAggregatedCredential.json credentialIssuerpublic_key.json
    save_output rngproof.json
    proof2="$output"
    assert_not_equal $proof1 $proof2
    cat $TMP/proofgen.zen | rngzexe rngproof.zen credentialParticipantAggregatedCredential.json credentialIssuerpublic_key.json
    save_output rngproof.json
    proof3="$output"
    assert_not_equal $proof3 $proof1
    assert_not_equal $proof3 $proof2
}
