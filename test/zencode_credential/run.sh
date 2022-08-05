#!/usr/bin/env bash

# output path: ${out}/

RNGSEED="hex:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

####################
# common script init
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"

####################

# credential request

n=0
SUBDOC=zencode_cookbook

cat << EOF | zexe credentialParticipantKeygen.zen | save $SUBDOC credentialParticipantKeypair.json
Scenario credential: credential keygen
    Given that I am known as 'Alice'
    When I create the credential key
    Then print my 'keyring'
EOF

cat << EOF | zexe credentialParticipantSignatureRequest.zen -k credentialParticipantKeypair.json | save $SUBDOC credentialParticipantSignatureRequest.json
Scenario credential: create request
    Given that I am known as 'Alice'
    and I have my valid 'keyring'
    When I create the credential request
    Then print my 'credential request'
EOF

# credential issuance


cat << EOF | zexe credentialIssuerKeygen.zen | save $SUBDOC credentialIssuerKeypair.json
Scenario credential: issuer keygen
    Given that I am known as 'MadHatter'
    When I create the issuer key
    Then print my 'keyring'
EOF

cat << EOF | zexe credentialIssuerPublishpublic_key.zen -k credentialIssuerKeypair.json | save $SUBDOC credentialIssuerpublic_key.json
Scenario credential: publish public_key
    Given that I am known as 'MadHatter'
    and I have my 'keyring'
    When I create the issuer public key
    Then print my 'issuer public key'
EOF

cat << EOF | zexe credentialIssuerSignRequest.zen -a credentialParticipantSignatureRequest.json -k credentialIssuerKeypair.json | save $SUBDOC credentialIssuerSignedCredential.json
Scenario credential: issuer sign
    Given that I am known as 'MadHatter'
    and I have my valid 'keyring'
    and I have a 'credential request' inside 'Alice'
    When I create the credential signature
    and I create the issuer public key
    Then print the 'credential signature'
    and print the 'issuer public key'
EOF

cat << EOF | zexe credentialParticipantAggregateCredential.zen -a credentialIssuerSignedCredential.json -k credentialParticipantKeypair.json | save $SUBDOC credentialParticipantAggregatedCredential.json
Scenario credential: aggregate signature
    Given that I am known as 'Alice'
    and I have my 'keyring'
    and I have a 'credential signature'
    When I create the credentials
    Then print my 'credentials'
    and print my 'keyring'
EOF

# zero-knowledge credential proof emission and verification

cat << EOF | zexe credentialParticipantCreateProof.zen -k credentialParticipantAggregatedCredential.json -a credentialIssuerpublic_key.json | save $SUBDOC credentialParticipantProof.json
Scenario credential: create proof
    Given that I am known as 'Alice'
    and I have my 'keyring'
    and I have a 'issuer public key' inside 'MadHatter'
    and I have my 'credentials'
    When I aggregate all the issuer public keys
    and I create the credential proof
    Then print the 'credential proof'
EOF

cat << EOF | zexe credentialAnyoneVerifyProof.zen -k credentialParticipantProof.json -a credentialIssuerpublic_key.json | jq .
Scenario credential: verify proof
    Given that I have a 'issuer public key' inside 'MadHatter'
    and I have a 'credential proof'
    When I aggregate all the issuer public keys
    When I verify the credential proof
    then print the string 'the proof matches the public_key! So you can add zencode after the verify statement, that will execute only if the match occurs.'
EOF

