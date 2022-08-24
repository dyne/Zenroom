load ../bats_setup
load ../bats_zencode

SUBDOC=zkp

# Do not set seed, otherwise petition will go in error "duplicated petition signature"
conf="debug=1"

Participants=10
users=""
for i in $(seq $Participants)
do
      users+=" Participant_${i}"
done

@test "Issuer creation" {
    cat <<EOF | zexe issuer_keygen.zen
Scenario credential
Given I am 'The Authority'
when I create the issuer key
Then print my 'keyring'
EOF
   save_output "issuer_key.json"
}

@test "Issuer public key" {
    cat <<EOF | zexe issuer_public_key.zen issuer_key.json
Scenario credential: publish verifier
Given that I am known as 'The Authority'
and I have my 'keyring'
When I create the issuer public key
Then print my 'issuer public key'
EOF
    save_output 'credentialIssuerpublic_key.json'
}
generate_participant() {
    local name=$1
    ## PARTICIPANT
	cat <<EOF | zexe keygen_${1}.zen
Scenario multidarkroom
Scenario credential
Given I am '${1}'
When I create the credential key
Then print my 'keyring'
EOF
    save_output "keypair_${1}.json"
    rm -f $TMP/out

	cat <<EOF | zexe request_${1}.zen keypair_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keyring'
When I create the credential request
Then print my 'credential request'
EOF
    save_output "request_${1}.json"
    rm -f $TMP/out
	##

	## ISSUER SIGNS
	cat <<EOF | zexe issuer_sign_${1}.zen issuer_key.json request_${1}.json
Scenario credential
Given I am 'The Authority'
and I have my 'keyring'
and I have a 'credential request' inside '${1}'
when I create the credential signature
and I create the issuer public key
Then print the 'credential signature'
and print the 'issuer public key'
EOF
    save_output "issuer_signature_${1}.json"
    rm -f $TMP/out
	##

	## PARTICIPANT AGGREGATES SIGNED CREDENTIAL
	cat <<EOF | zexe aggr_cred_${1}.zen keypair_${1}.json issuer_signature_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keyring'
and I have a 'credential signature'
when I create the credentials
then print my 'credentials'
and print my 'keyring'
EOF
    save_output "verified_credential_${1}.json"
}

@test "Generate n signed credentials" {
    for user in ${users[@]}
    do
        echo  "now generating the participant: "  ${user} >&3
        generate_participant ${user}
    done
}
@test "Create petition" {
    cat <<EOF | zexe petitionRequest.zen verified_credential_Participant_1.json credentialIssuerpublic_key.json
# Two scenarios are needed for this script, "credential" and "petition".
	Scenario credential: read and validate the credentials
	Scenario petition: create the petition
# Here I state my identity
    Given that I am known as 'Participant_1'
# Here I load everything needed to proceed
    Given I have my 'keyring'
    Given I have my 'credentials'
    Given I have a 'issuer public key' inside 'The Authority'
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
    save_output "petitionRequest.json"
}

@test "Approve petition" {
    cat <<EOF | zexe petitionApprove.zen petitionRequest.json credentialIssuerpublic_key.json
Scenario credential
Scenario petition: approve
    Given that I have a 'issuer public key' inside 'The Authority'
    Given I have a 'credential proof'
    Given I have a 'petition'
    When I aggregate all the issuer public keys
    When I verify the credential proof
    When I verify the new petition to be empty
    Then print the 'petition'
    Then print the 'issuer public key'
	Then print the 'uid' from 'petition' as 'string'
EOF
    save_output "petition.json"
    cat $BATS_SUITE_TMPDIR/petition.json | save_asset petitionEmpty.json

}

sign_petition() {
    cat <<EOF | zexe petitionSign.zen verified_credential_$1.json credentialIssuerpublic_key.json
Scenario credential
Scenario petition: sign petition
    Given I am '${1}'
    Given I have my valid 'keyring'
    Given I have my 'credentials'
    Given I have a valid 'issuer public key' inside 'The Authority'
    When I aggregate all the issuer public keys
	When I create the petition signature 'More privacy for all!'
    Then print the 'petition signature'
    # and print the 'issuer public key'
EOF
  save_output "petitionSignature_$1.json"
  rm -f $TMP/out
  echo "signed petition for $1" >&3
}
aggregate_petition() {
    cat <<EOF | zexe petitionAggregateSignature.zen petition.json petitionSignature_$1.json
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
    save_output "petitionAggregated.json"
    rm -f $TMP/out
    echo "aggregated petition for $1" >&3
    cat $BATS_SUITE_TMPDIR/petitionAggregated.json | save_asset petition.json
}

@test "SIgning and aggregating" {
    for user in ${users[@]}
    do
        echo "$user" >&3
        sign_petition $user
        aggregate_petition $user
    done
}
