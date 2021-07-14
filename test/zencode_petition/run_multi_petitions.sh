#!/usr/bin/env bash

RNGSEED='random'
####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
# # OR: out=../../docs/examples/zencode_cookbook

# out=/dev/shm/files


Participants=10

users=""
for i in $(seq $Participants)
do
      users+=" Participant_${i}"
done

## ISSUER creation
cat <<EOF | zexe issuer_keygen.zen  | save . issuer_key.json
Scenario credential
Given I am 'The Authority'
when I create the issuer key
Then print my 'keys'
EOF

cat <<EOF | zexe issuer_public_key.zen -k issuer_key.json  | save . credentialIssuerpublic_key.json
Scenario credential: publish verifier
Given that I am known as 'The Authority'
and I have my 'keys'
When I create the issuer public key
Then print my 'issuer public key'
EOF
##

generate_participant() {
    local name=$1
    ## PARTICIPANT
	cat <<EOF | zexe keygen_${1}.zen  | save . keypair_${1}.json
Scenario multidarkroom
Scenario credential
Given I am '${1}'
When I create the credential key
Then print my 'keys'
EOF

	cat <<EOF | zexe request_${1}.zen -k keypair_${1}.json  | save . request_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keys'
When I create the credential request
Then print my 'credential request'
EOF
	##

	## ISSUER SIGNS
	cat <<EOF | zexe issuer_sign_${1}.zen -k issuer_key.json -a request_${1}.json  | save . issuer_signature_${1}.json
Scenario credential
Given I am 'The Authority'
and I have my 'keys'
and I have a 'credential request' inside '${1}'
when I create the credential signature
and I create the issuer public key
Then print the 'credential signature'
and print the 'issuer public key'
EOF
	##

	## PARTICIPANT AGGREGATES SIGNED CREDENTIAL
	cat <<EOF | zexe aggr_cred_${1}.zen -k keypair_${1}.json -a issuer_signature_${1}.json  |  save . verified_credential_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keys'
and I have a 'credential signature'
when I create the credentials
then print my 'credentials'
and print my 'keys'
EOF
}

# generate n signed credentials

for user in ${users[@]}
do
    echo  "now generating the participant: "  ${user}
    generate_participant ${user}
done





# Create the petition

cat <<EOF | zexe petitionRequest.zen -k verified_credential_Participant_1.json -a credentialIssuerpublic_key.json  | save . petitionRequest.json
# Two scenarios are needed for this script, "credential" and "petition".
	Scenario credential: read and validate the credentials
	Scenario petition: create the petition
# Here I state my identity
    Given that I am known as 'Participant_1'
# Here I load everything needed to proceed
    Given I have my 'keys'
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

# Approve the petition

cat <<EOF | zexe petitionApprove.zen -k petitionRequest.json -a credentialIssuerpublic_key.json  | save . petition.json
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

cp -v petition.json petitionEmpty.json 

sign_petition() {
    cat <<EOF | zexe petitionSign.zen -k verified_credential_$1.json -a credentialIssuerpublic_key.json | save . petitionSignature.json
Scenario credential
Scenario petition: sign petition
    Given I am '${1}'
    Given I have my valid 'keys'
    Given I have my 'credentials'
    Given I have a valid 'issuer public key' inside 'The Authority'
    When I aggregate all the issuer public keys
	When I create the petition signature 'More privacy for all!'
    Then print the 'petition signature'
    and print the 'issuer public key'
EOF

echo "signed petition for $1"

}

aggregate_petition() {
cat <<EOF | zexe petitionAggregateSignature.zen -k petition.json -a petitionSignature.json  | save . petitionAggregated.json
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

mv petitionAggregated.json petition.json

echo "aggregated petition for $1"
cat petition.json | jq .

}

echo "Signing and Aggregating"

for user in ${users[@]}
do
    sign_petition $user
    aggregate_petition $user
done

exit 0

echo "Tallying the petition"

cat <<EOF | debug petitionTally.zen -k verified_credential_Participant_1.json -a petition.json  | save . petitionTally.json
Scenario credential
Scenario petition: tally
    Given that I am 'Participant_1'
    Given I have my 'keys'
    Given I have a valid 'petition'
    When I create a petition tally
    Then print the 'petition tally'
EOF


echo Counting the signatures

cat <<EOF | zexe petitionCount.zen -k petitionTally.json -a petition.json  | save . petitionCount.json
Scenario credential
Scenario petition: count
    Given that I have a valid 'petition'
    Given I have a valid 'petition tally'
    When I count the petition results
    Then print the 'petition results' as 'number'
    Then print the 'uid' from 'petition'
EOF
