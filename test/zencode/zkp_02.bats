load ../bats_setup
load ../bats_zencode

SUBDOC=zkp

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
EOF
    save_output petitionTally.json
}

@test "count the petition signatures" {
    cat <<EOF | zexe petitionCount.zen petitionTally.json petitionAggregatedSignature.json
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
