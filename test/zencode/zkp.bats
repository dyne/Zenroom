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


@test "create the petition" {
    cat <<EOF | zexe petitionRequest.zen credentialParticipantAggregatedCredential.json credentialIssuerpublic_key.json
	Scenario credential: read and validate the credentials
	Scenario petition: create the petition
# Here I state my identity
    Given that I am known as 'Alice'
# Here I load everything needed to proceed
    Given I have my 'keyring'
    Given I have my 'credentials'
    Given I have a 'issuer public key' inside 'MadHatter'
# In the "when" phase we have the cryptographical creation of the petition
    When I aggregate all the issuer public keys
    When I create the credential proof
    When I create the petition 'More privacy for all!'
# Here we are printing out what is needed to the get the petition approved
    Then print the 'issuer public key'
	Then print the 'credential proof'
	Then print the 'petition'
# Here we're just printing the "uid" as string, instead of the default base64
# so that it's human readable - this is not needed to advance in the flow
	Then print the 'uid' from 'petition' as 'string'
EOF
    save_output petitionRequest.json
}

@test "approve the petition" {
    cat <<EOF | zexe petitionApprove.zen petitionRequest.json credentialIssuerpublic_key.json
Scenario credential
Scenario petition: approve
    Given that I have a 'issuer public key' inside 'MadHatter'
    Given I have a 'credential proof'
    Given I have a 'petition'
    When I aggregate all the issuer public keys
    When I verify the credential proof
    When I verify the new petition to be empty
    Then print the 'petition'
    Then print the 'issuer public key'
	Then print the 'uid' from 'petition' as 'string'
EOF
    save_output petitionApproved.json
}

@test "sign the petition" {
    cat <<EOF | zexe petitionSign.zen credentialParticipantAggregatedCredential.json credentialIssuerpublic_key.json
Scenario credential
Scenario petition: sign petition
    Given I am 'Alice'
    Given I have my valid 'keyring'
    Given I have my 'credentials'
    Given I have a valid 'issuer public key' inside 'MadHatter'
    When I aggregate all the issuer public keys
	When I create the petition signature 'More privacy for all!'
    Then print the 'petition signature'
EOF
    save_output petitionSignature.json
}

@test "aggregate the petition signature" {
    cat <<EOF | zexe petitionAggregateSignature.zen petitionApproved.json petitionSignature.json
Scenario credential
Scenario petition: aggregate signature
    Given that I have a 'petition signature'
    Given I have a 'petition'
    Given I have a 'issuer public key'
    When the petition signature is not a duplicate
    When the petition signature is just one more
    When I add the signature to the petition
    and I aggregate all the issuer public keys
    Then print the 'petition'
    Then print the 'issuer public key'
EOF
    save_output petitionAggregatedSignature.json
}

@test "tally the petition" {
    cat <<EOF | zexe petitionTally.zen credentialParticipantAggregatedCredential.json petitionAggregatedSignature.json
Scenario credential
Scenario petition: tally
    Given that I am 'Alice'
    Given I have my 'keyring'
    Given I have a valid 'petition'
    When I create a petition tally
    Then print the 'petition tally'
    Then print the 'petition'
EOF
    save_output petitionTally.json
}

@test "count the petition signatures" {
    cat <<EOF | zexe petitionCount.zen petitionTally.json
Scenario credential
Scenario petition: count
    Given that I have a valid 'petition'
    Given I have a valid 'petition tally'
    When I count the petition results
    Then print the 'petition results' as 'number'
    Then print the 'uid' from 'petition'
EOF
    save_output petitionCount.json
}
