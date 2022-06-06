#!/usr/bin/env bash

# output path:  ${out}/

# RNGSEED="hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh

is_cortexm=false
if [[ "$1" == "cortexm" ]]; then
	is_cortexm=true
fi

Z="`detect_zenroom_path` `detect_zenroom_conf`"

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

set -e

out='../../docs/examples/zencode_cookbook'

n=0

let n=1

echo "                                                "
echo "------------------------------------------------"
echo "  script $n: create the petition               "
echo " 												  "
echo "------------------------------------------------"
echo "   											  "


cat <<EOF | zexe ${out}/petitionRequest.zen -k ${out}/credentialParticipantAggregatedCredential.json -a ${out}/credentialIssuerpublic_key.json | tee ${out}/petitionRequest.json | jq .
# Two scenarios are needed for this script, "credential" and "petition".
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

let n=2

echo "                                                "
echo "------------------------------------------------"
echo "  script $n: approve the petition                 "
echo " 												  "
echo "------------------------------------------------"
echo "   											  "


cat <<EOF | zexe ${out}/petitionApprove.zen -k ${out}/petitionRequest.json -a ${out}/credentialIssuerpublic_key.json | tee ${out}/petitionApproved.json | jq .
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

let n=3

echo "                                                "
echo "------------------------------------------------"
echo "  script $n: sign the petition            	  "
echo " 												  "
echo "------------------------------------------------"
echo "   											  "


cat <<EOF | zexe ${out}/petitionSign.zen -k ${out}/credentialParticipantAggregatedCredential.json -a ${out}/credentialIssuerpublic_key.json | tee ${out}/petitionSignature.json | jq .
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

let n=4

echo "                                                "
echo "------------------------------------------------"
echo "  script $n: aggregate petition signatures      "
echo " 												  "
echo " Note: this script should normally output the same"
echo " files 'petitionApproved.json' that it takes as input,"
echo " in this script a different file is produced out of"
echo " mere convenience in the testing phase.           "
echo " 												  "
echo "------------------------------------------------"
echo "   											  "
 

cat <<EOF | zexe ${out}/petitionAggregateSignature.zen -k ${out}/petitionApproved.json -a ${out}/petitionSignature.json | tee ${out}/petitionAggregatedSignature.json | jq .
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

let n=5

echo "                                                "
echo "------------------------------------------------"
echo "  script $n: tally the petition				  "
echo " 												  "
echo "------------------------------------------------"
echo "   											  "


cat <<EOF | zexe ${out}/petitionTally.zen -k ${out}/credentialParticipantAggregatedCredential.json -a ${out}/petitionAggregatedSignature.json | tee ${out}/petitionTally.json | jq .
Scenario credential
Scenario petition: tally
    Given that I am 'Alice'
    Given I have my 'keyring'
    Given I have a valid 'petition'
    When I create a petition tally
    Then print the 'petition tally'
EOF

let n=6

echo "                                                "
echo "------------------------------------------------"
echo "  script $n: count the singnatures              "
echo " 												  "
echo "------------------------------------------------"
echo "   											  "


cat <<EOF | zexe ${out}/petitionCount.zen -k ${out}/petitionTally.json -a ${out}/petitionAggregatedSignature.json | tee ${out}/petitionCount.json | jq .
Scenario credential
Scenario petition: count
    Given that I have a valid 'petition'
    Given I have a valid 'petition tally'
    When I count the petition results
    Then print the 'petition results' as 'number'
    Then print the 'uid' from 'petition'
EOF

echo "   "
echo "---"
echo "   "
echo "The whole script was executed, success!"
