#!/usr/bin/env bash


####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

cat <<EOF | zexe create_petition.zen -k ../zencode_credential/credentials.json -a ../zencode_credential/verifier.json > petition_request.json
Scenario credential
Scenario petition: create
    Given that I am known as 'Alice'
    and I have my valid 'credential keypair'
    and I have my valid 'credentials'
    and I have a valid 'verifier' inside 'MadHatter'
    When I aggregate the verifiers
    and I create the credential proof
    and I create the petition 'poll'
    Then print all data
EOF


cat <<EOF | zexe approve_petition.zen -k petition_request.json -a ../zencode_credential/verifier.json > petition.json
Scenario credential
Scenario petition: approve
    Given that I have a 'verifier' inside 'MadHatter'
    and I have a 'credential proof'
    and I have a 'petition'
    When I aggregate the verifiers
    and I verify the credential proof
    and I verify the new petition to be empty
    Then print the 'petition'
    and print the 'verifiers'
EOF


cat <<EOF | zexe sign_petition.zen -k ../zencode_credential/credentials.json -a ../zencode_credential/verifier.json > petition_signature.json
Scenario credential
Scenario petition: sign petition
    Given I am 'Alice'
    and I have my valid 'credential keypair'
    and I have my 'credentials'
    and I have a valid 'verifier' inside 'MadHatter'
    When I aggregate the verifiers
    and I create the petition signature 'poll'
    Then print the 'petition signature'
EOF

cat <<EOF | zexe aggregate_petition_signature.zen -k petition.json -a petition_signature.json > petition_increase.json
Scenario credential
Scenario petition: aggregate signature
    Given that I have a valid 'petition signature'
    and I have a valid 'petition'
    and I have a valid 'verifiers'
    When the petition signature is not a duplicate
    and the petition signature is just one more
    and I add the signature to the petition
    Then print the 'petition'
    and print the 'verifiers'
EOF

cat <<EOF | zexe tally_petition.zen -k ../zencode_credential/credentials.json -a petition_increase.json > tally.json
Scenario credential
Scenario petition: tally
    Given that I am 'Alice'
    and I have my valid 'credential keypair'
    and I have a valid 'petition'
    When I create a petition tally
    Then print all data
EOF

cat <<EOF | zexe count_petition.zen -k tally.json -a petition_increase.json
Scenario credential
Scenario petition: count
    Given that I have a valid 'petition'
    and I have a valid 'petition tally'
    When I count the petition results
    Then print the 'petition results' as 'number'
    and print the 'uid' as 'string' inside 'petition'
EOF
