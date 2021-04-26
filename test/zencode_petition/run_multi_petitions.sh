#!/usr/bin/env bash

# output path:  ${out}/

# RNGSEED="hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh

# is_cortexm=false
# if [[ "$1" == "cortexm" ]]; then
# 	is_cortexm=true
# fi

Z="`detect_zenroom_path` `detect_zenroom_conf`"
# OR: out=../../docs/examples/zencode_cookbook

out=/dev/shm/files




mkdir -p $out
 

Participants=10

users=""
for i in $(seq $Participants)
do
      users+=" Participant_${i}"
done


####################
# use zexe if you have zenroom in a system-wide path
#
# zexe() {
#	out="$1"
#	shift 1
#	>&2 echo "test: $out"
#	tee "$out" | zenroom -z $*
# }
####################

# Sign the petition

echo "=============================================================="
echo "====This scripts requires that you first run the script:======"
echo "/zenroom/test/zencode_credential/setup_multiple_credentials.sh"
echo "==============================================================="
echo "================================================================"




# Create the petition

cat <<EOF | zexe ${out}/petitionRequest.zen -k ${out}/verified_credential_Participant_1.json -a ${out}/credentialIssuerpublic_key.json  | jq . | tee ${out}/petitionRequest.json | jq .
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

cat <<EOF | zexe ${out}/petitionApprove.zen -k ${out}/petitionRequest.json -a ${out}/credentialIssuerpublic_key.json  | jq . | tee ${out}/petition.json | jq .
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

cp -v ${out}/petition.json ${out}/petitionEmpty.json 

sign_petition() {
    cat <<EOF | zexe ${out}/petitionSign.zen -k ${out}/verified_credential_$1.json -a ${out}/credentialIssuerpublic_key.json  | jq . | tee ${out}/petitionSignature.json | jq .
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
cat <<EOF | zexe ${out}/petitionAggregateSignature.zen -k ${out}/petition.json -a ${out}/petitionSignature.json  | jq . | tee ${out}/petitionAggregated.json | jq .
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

mv $out/petitionAggregated.json $out/petition.json

echo "aggregated petition for $1"

}

echo Signing and Aggregating

for user in ${users[@]}
do
    sign_petition $user
    aggregate_petition $user
done

echo Tallying the petition

cat <<EOF | zexe ${out}/petitionTally.zen -k ${out}/verified_credential_Participant_1.json -a ${out}/petition.json  | jq . | tee ${out}/petitionTally.json | jq .
Scenario credential
Scenario petition: tally
    Given that I am 'Participant_1'
    Given I have my 'keys'
    Given I have a valid 'petition'
    When I create a petition tally
    Then print the 'petition tally'
EOF


echo Counting the signatures

cat <<EOF | zexe ${out}/petitionCount.zen -k ${out}/petitionTally.json -a ${out}/petition.json  | jq . | tee ${out}/petitionCount.json | jq .
Scenario credential
Scenario petition: count
    Given that I have a valid 'petition'
    Given I have a valid 'petition tally'
    When I count the petition results
    Then print the 'petition results' as 'number'
    Then print the 'uid' from 'petition'
EOF
