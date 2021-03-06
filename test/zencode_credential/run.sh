#!/usr/bin/env bash

# output path: ${out}/

RNGSEED="hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
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

cat << EOF | zexe ${out}/credentialParticipantKeygen.zen | tee ${out}/credentialParticipantKeypair.json
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


cat << EOF | zexe ${out}/credentialParticipantSignatureRequest.zen -k ${out}/credentialParticipantKeypair.json | tee ${out}/credentialParticipantSignatureRequest.json | jq .
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


cat << EOF | zexe ${out}/credentialIssuerKeygen.zen | tee ${out}/credentialIssuerKeypair.json | jq .
Scenario credential: issuer keygen
    Given that I am known as 'MadHatter'
    When I create the issuer key
    Then print my 'keys'
EOF

let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo " Script $n: create the verifier of the issuer    "
echo " 												  "
echo "------------------------------------------------"
echo " "


cat << EOF | zexe ${out}/credentialIssuerPublishVerifier.zen -k ${out}/credentialIssuerKeypair.json | tee ${out}/credentialIssuerVerifier.json | jq .
Scenario credential: publish verifier
    Given that I am known as 'MadHatter'
    and I have my 'keys'
    When I create the issuer verifier
    Then print my 'issuer verifier'
EOF


let n=n+1
echo "                                                "
echo "------------------------------------------------"
echo " Script $n: the issuer signs the credential "
echo " 												  "
echo "------------------------------------------------"
echo " "

# credential signature



cat << EOF | zexe ${out}/credentialIssuerSignRequest.zen -a ${out}/credentialParticipantSignatureRequest.json -k ${out}/credentialIssuerKeypair.json | tee ${out}/credentialIssuerSignedCredential.json | jq .
Scenario credential: issuer sign
    Given that I am known as 'MadHatter'
    and I have my valid 'keys'
    and I have a 'credential request' inside 'Alice'
    When I create the credential signature
    Then print the 'credential signature'
    and print the 'verifier'
EOF

let n=n+6
echo "                                                "
echo "------------------------------------------------"
echo " Script $n: the participant aggregates credential "
echo " with its public key.					  "
echo "------------------------------------------------"
echo " "

cat << EOF | zexe ${out}/credentialParticipantAggregateCredential.zen -a ${out}/credentialIssuerSignedCredential.json -k ${out}/credentialParticipantKeypair.json | tee ${out}/credentialParticipantAggregatedCredential.json | jq .
Scenario credential: aggregate signature
    Given that I am known as 'Alice'
    and I have my 'keys'
    and I have a 'credential signature'
    When I create the credentials
    Then print my 'credentials'
    and print my 'keys'
EOF

let n=n+7
echo "                                                "
echo "------------------------------------------------"
echo " Script $n: the participant creates the proof "
echo " 												  "
echo "------------------------------------------------"
echo " "

# zero-knowledge credential proof emission and verification

cat << EOF | zexe ${out}/credentialParticipantCreateProof.zen -k ${out}/credentialParticipantAggregatedCredential.json -a ${out}/credentialIssuerVerifier.json | tee ${out}/credentialParticipantProof.json | jq .
Scenario credential: create proof
    Given that I am known as 'Alice'
    and I have my 'keys'
    and I have a 'issuer verifier' inside 'MadHatter'
    and I have my 'credentials'
    When I aggregate the verifiers
    and I create the credential proof
    Then print the 'credential proof'
EOF

let n=n+8
echo "                                                "
echo "------------------------------------------------"
echo " Script $n: anybody matches the proof with the verifier"
echo " 												  "
echo "------------------------------------------------"
echo " "

cat << EOF | zexe ${out}/credentialAnyoneVerifyProof.zen -k ${out}/credentialParticipantProof.json -a ${out}/credentialIssuerVerifier.json | jq .
Scenario credential: verify proof
    Given that I have a 'issuer verifier' inside 'MadHatter'
    and I have a 'credential proof'
    When I aggregate the verifiers
    When I verify the credential proof
    Then print 'The proof matches the verifier! So you can add zencode after the verify statement, that will execute only if the match occurs.'
EOF

echo "   "
echo "---"
echo "   "
echo "The whole script was executed, success!"