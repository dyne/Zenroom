#!/usr/bin/env bash

# output path: ${out}/

RNGSEED="hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

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
#	jq . | tee "$out" | zenroom -z $*
# }
####################



####################

# credential request

n=0
out='../../docs/examples/zencode_cookbook'

let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo " Script $n: Participant creates a keypair	  "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "

cat << EOF | zexe ${out}/credentialParticipantKeygen.zen | jq . | tee ${out}/credentialParticipantKeypair.json
Scenario credential: credential keygen
    Given that I am known as 'Alice'
    When I create the credential key
    Then print my 'keys'
EOF

let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo " Script $n: Participant creates a credential request "
echo " 												  "
echo "------------------------------------------------"
echo "                                                "


cat << EOF | zexe ${out}/credentialParticipantSignatureRequest.zen -k ${out}/credentialParticipantKeypair.json | jq . | tee ${out}/credentialParticipantSignatureRequest.json
Scenario credential: create request
    Given that I am known as 'Alice'
    and I have my valid 'keys'
    When I create the credential request
    Then print my 'credential request'
EOF

let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo " Script $n: create the keypair of the issuer    "
echo " 												  "
echo "------------------------------------------------"
echo " "

# credential issuance


cat << EOF | zexe ${out}/credentialIssuerKeygen.zen | jq . | tee ${out}/credentialIssuerKeypair.json
Scenario credential: issuer keygen
    Given that I am known as 'MadHatter'
    When I create the issuer key
    Then print my 'keys'
EOF

let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo " Script $n: create the public_key of the issuer    "
echo " 												  "
echo "------------------------------------------------"
echo " "


cat << EOF | zexe ${out}/credentialIssuerPublishpublic_key.zen -k ${out}/credentialIssuerKeypair.json | jq . | tee ${out}/credentialIssuerpublic_key.json
Scenario credential: publish public_key
    Given that I am known as 'MadHatter'
    and I have my 'keys'
    When I create the issuer public key
    Then print my 'issuer public key'
EOF


let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo " Script $n: the issuer signs the credential "
echo " 												  "
echo "------------------------------------------------"
echo " "

# credential signature



cat << EOF | zexe ${out}/credentialIssuerSignRequest.zen -a ${out}/credentialParticipantSignatureRequest.json -k ${out}/credentialIssuerKeypair.json | jq . | tee ${out}/credentialIssuerSignedCredential.json
Scenario credential: issuer sign
    Given that I am known as 'MadHatter'
    and I have my valid 'keys'
    and I have a 'credential request' inside 'Alice'
    When I create the credential signature
    and I create the issuer public key
    Then print the 'credential signature'
    and print the 'issuer public key'
EOF

let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo " Script $n: the participant aggregates credential "
echo " with its public key.					  "
echo "------------------------------------------------"
echo " "

cat << EOF | zexe ${out}/credentialParticipantAggregateCredential.zen -a ${out}/credentialIssuerSignedCredential.json -k ${out}/credentialParticipantKeypair.json | jq . | tee ${out}/credentialParticipantAggregatedCredential.json
Scenario credential: aggregate signature
    Given that I am known as 'Alice'
    and I have my 'keys'
    and I have a 'credential signature'
    When I create the credentials
    Then print my 'credentials'
    and print my 'keys'
EOF

let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo " Script $n: the participant creates the proof "
echo " 												  "
echo "------------------------------------------------"
echo " "

# zero-knowledge credential proof emission and verification

cat << EOF | debug ${out}/credentialParticipantCreateProof.zen -k ${out}/credentialParticipantAggregatedCredential.json -a ${out}/credentialIssuerpublic_key.json | jq . | tee ${out}/credentialParticipantProof.json
Scenario credential: create proof
    Given that I am known as 'Alice'
    and I have my 'keys'
    and I have a 'issuer public key' inside 'MadHatter'
    and I have my 'credentials'
    When I aggregate all the issuer public keys
    and I create the credential proof
    Then print the 'credential proof'
EOF

let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo " Script $n: anybody matches the proof with the public_key"
echo " 												  "
echo "------------------------------------------------"
echo " "

cat << EOF | zexe ${out}/credentialAnyoneVerifyProof.zen -k ${out}/credentialParticipantProof.json -a ${out}/credentialIssuerpublic_key.json | jq .
Scenario credential: verify proof
    Given that I have a 'issuer public key' inside 'MadHatter'
    and I have a 'credential proof'
    When I aggregate all the issuer public keys
    When I verify the credential proof
    Then print 'The proof matches the public_key! So you can add zencode after the verify statement, that will execute only if the match occurs.'
EOF

echo "   "
echo "---"
echo "   "
echo "The whole script was executed, success!"