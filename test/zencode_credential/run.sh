#!/usr/bin/env bash


####################
# common script init
if ! test -r ../utils.sh; then
	echo "run executable from its own directory: $0"; exit 1; fi
. ../utils.sh
Z="`detect_zenroom_path` `detect_zenroom_conf`"
####################

# credential request

cat << EOF | zexe credential_keygen.zen | tee keypair.keys
Scenario credential: credential keygen
    Given that I am known as 'Alice'
    When I create the credential keypair
    Then print my 'credential keypair'
EOF

cat << EOF | zexe create_request.zen -k keypair.keys | tee request.json
Scenario credential: create request
    Given that I am known as 'Alice'
    and I have my valid 'credential keypair'
    When I create the credential request
    Then print my 'credential request'
EOF

# credential issuance

cat << EOF | zexe issuer_keygen.zen | tee issuer_keypair.keys
Scenario credential: issuer keygen
    Given that I am known as 'MadHatter'
    When I create the issuer keypair
    Then print my 'issuer keypair'
EOF

cat << EOF | zexe publish_verifier.zen -k issuer_keypair.keys | tee verifier.json
Scenario credential: publish verifier
    Given that I am known as 'MadHatter'
    and I have my valid 'issuer keypair'
    Then print my 'verifier' from 'issuer keypair'
EOF

# credential signature

cat << EOF | zexe issuer_sign.zen -a request.json -k issuer_keypair.keys | tee signature.json
Scenario credential: issuer sign
    Given that I am known as 'MadHatter'
    and I have my valid 'issuer keypair'
    and I have a 'credential request' inside 'Alice'
    When I create the credential signature
    Then print the 'credential signature'
    and print the 'verifier'
EOF

cat << EOF | zexe aggregate_signature.zen -a signature.json -k keypair.keys | tee credentials.json
Scenario credential: aggregate signature
    Given that I am known as 'Alice'
    and I have my valid 'credential keypair'
    and I have a valid 'credential signature'
    When I create the credentials
    Then print my 'credentials'
    and print my 'credential keypair'
EOF

# zero-knowledge credential proof emission and verification

cat << EOF | zexe create_proof.zen -k credentials.json -a verifier.json | tee proof.json
Scenario credential: create proof
    Given that I am known as 'Alice'
    and I have my valid 'credential keypair'
    and I have a valid 'verifier' inside 'MadHatter'
    and I have my valid 'credentials'
    When I aggregate the verifiers
    and I create the credential proof
    Then print the 'credential proof'
EOF


cat << EOF | zexe verify_proof.zen -k proof.json -a verifier.json
Scenario credential: verify proof
    Given that I have a valid 'verifier' inside 'MadHatter'
    and I have a valid 'credential proof'
    When I aggregate the verifiers
    and I verify the credential proof
    Then print 'Success'
EOF
