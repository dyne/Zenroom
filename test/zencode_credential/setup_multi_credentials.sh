#!/usr/bin/env bash

# output path:  ${out}/

# RNGSEED="hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh

Z="`detect_zenroom_path` `detect_zenroom_conf`"

out=../../docs/examples/zencode_cookbook

# OR: out=/dev/shm/files

mkdir -p $out

Participants=10

users=""
for i in $(seq $Participants)
do
  users+=" Participant_${i}"
done


## ISSUER creation
cat <<EOF | zexe ${out}/issuer_keygen.zen  | jq . | tee ${out}/issuer_key.json
Scenario credential
Given I am 'The Authority'
when I create the issuer key
Then print my 'keyring'
EOF

cat <<EOF | zexe ${out}/issuer_public_key.zen -k ${out}/issuer_key.json  | jq . | tee ${out}/credentialIssuerpublic_key.json
Scenario credential: publish verifier
Given that I am known as 'The Authority'
and I have my 'keyring'
When I create the issuer public key
Then print my 'issuer public key'
EOF
##

generate_participant() {
    local name=$1
    ## PARTICIPANT
	cat <<EOF | zexe ${out}/keygen_${1}.zen  | jq . | tee ${out}/keypair_${1}.json
Scenario multidarkroom
Scenario credential
Given I am '${1}'
When I create the credential key
Then print my 'keyring'
EOF

	cat <<EOF | zexe ${out}/request_${1}.zen -k ${out}/keypair_${1}.json  | jq . | tee ${out}/request_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keyring'
When I create the credential request
Then print my 'credential request'
EOF
	##

	## ISSUER SIGNS
	cat <<EOF | zexe ${out}/issuer_sign_${1}.zen -k ${out}/issuer_key.json -a ${out}/request_${1}.json  | jq . | tee ${out}/issuer_signature_${1}.json
Scenario credential
Given I am 'The Authority'
and I have my 'keyring'
and I have a 'credential request' inside '${1}'
when I create the credential signature
and I create the issuer public key
Then print the 'credential signature'
and print the 'issuer public key'
EOF
	##

	## PARTICIPANT AGGREGATES SIGNED CREDENTIAL
	cat <<EOF | zexe ${out}/aggr_cred_${1}.zen -k ${out}/keypair_${1}.json -a ${out}/issuer_signature_${1}.json  | jq . | tee ${out}/verified_credential_${1}.json
Scenario credential
Given I am '${1}'
and I have my 'keyring'
and I have a 'credential signature'
when I create the credentials
then print my 'credentials'
and print my 'keyring'
EOF
}

# generate n signed credentials

for user in ${users[@]}
do
    echo  "now generating the participant: "  ${user}
    generate_participant ${user}
done


